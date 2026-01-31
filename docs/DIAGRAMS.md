# Diagramas de funcionalidade

Diagramas em [Mermaid](https://mermaid.js.org/) para visualizar fluxos e estados da API de carrinho de compras.

> **Preview no editor:** O preview Markdown do Cursor/VSCode não renderiza Mermaid por padrão. Para ver os diagramas:
> - **Opção 1:** Instale a extensão [Markdown Preview Mermaid Support](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid) (ou "Mermaid") e reabra o preview.
> - **Opção 2:** Abra o repositório no **GitHub** ou **GitLab** — os diagramas são renderizados automaticamente nos arquivos `.md`.
> - **Opção 3:** Use o [editor online do Mermaid](https://mermaid.live/) colando o conteúdo de cada bloco ` ```mermaid `.

---

## Índice

1. [Visão geral da API](#visão-geral-da-api)
2. [Fluxo do carrinho (cliente)](#fluxo-do-carrinho-cliente)
3. [Fluxo POST /cart (criar ou adicionar)](#fluxo-post-cart-criar-ou-adicionar)
4. [Ciclo de vida do carrinho (estados)](#ciclo-de-vida-do-carrinho-estados)
5. [Jobs de carrinhos abandonados](#jobs-de-carrinhos-abandonados)
6. [Fluxo de remoção de produto](#fluxo-de-remoção-de-produto)

---

## Visão geral da API

```mermaid
flowchart LR
  subgraph Cliente
    C[Cliente / App]
  end

  subgraph API["API Rails"]
    P[Produtos<br/>/products]
    Cart[Carrinho<br/>/cart]
    Add[Add Item<br/>/cart/add_item]
    Del[Remove<br/>/cart/:id]
  end

  subgraph Background["Background"]
    Sidekiq[Sidekiq<br/>/sidekiq]
    MJ[MarkCartAsAbandonedJob]
    DJ[DeleteOldAbandonedCartsJob]
  end

  C --> P
  C --> Cart
  C --> Add
  C --> Del
  Sidekiq --> MJ
  Sidekiq --> DJ
  MJ --> Cart
  DJ --> Cart
```

---

## Fluxo do carrinho (cliente)

Sequência típica: criar carrinho, adicionar itens, listar, remover. O carrinho é identificado pela sessão (cookie).

```mermaid
sequenceDiagram
  participant C as Cliente
  participant API as API
  participant DB as Banco

  Note over C,DB: Primeira interação: não há carrinho na sessão
  C->>+API: POST /cart { product_id, quantity }
  API->>DB: Cart.create! + AddOrUpdateService
  DB-->>API: cart
  API->>API: session[:cart_id] = cart.id
  API-->>-C: 201 { id, products, total_price }

  C->>+API: POST /cart/add_item { product_id, quantity }
  API->>API: current_cart (session[:cart_id])
  API->>DB: AddOrUpdateService
  API->>API: record_interaction!
  API-->>-C: 200 { id, products, total_price }

  C->>+API: GET /cart
  API->>API: current_cart
  API->>API: record_interaction!
  API-->>-C: 200 { id, products, total_price }

  C->>+API: DELETE /cart/:product_id
  API->>DB: RemoveProductService
  API->>API: record_interaction!
  API-->>-C: 200 { id, products, total_price }
```

---

## Fluxo POST /cart (criar ou adicionar)

Decisão interna: já existe carrinho na sessão? Se não, cria carrinho e adiciona o produto; se sim, apenas adiciona/atualiza o item.

```mermaid
flowchart TD
  A[POST /cart product_id, quantity] --> B{current_cart<br/>na sessão?}
  B -->|Não| C[Criar Cart]
  C --> D[CartProducts::AddOrUpdateService]
  B -->|Sim| D
  D --> E{Produto existe<br/>e válido?}
  E -->|Não| F[404 ou 422]
  E -->|Sim| G{Carrinho era novo?}
  G -->|Sim| H["session[:cart_id] = cart.id"]
  G -->|Não| I[Manter sessão]
  H --> J[record_interaction!]
  I --> J
  J --> K[201 ou 200 + payload]
```

---

## Ciclo de vida do carrinho (estados)

Estados possíveis do carrinho e transições (interação do usuário vs. jobs).

```mermaid
stateDiagram-v2
  direction TB
  [*] --> active: criar carrinho

  active --> active: interação
  active --> abandoned: job 3h sem interação

  abandoned --> active: interação
  abandoned --> deleted: job 7+ dias abandonado

  deleted --> [*]: 404
```

| Transição | Significado |
|-----------|-------------|
| criar carrinho | `POST /cart` com primeiro produto |
| interação | GET/POST/DELETE no carrinho → `record_interaction!` mantém/reativa |
| job 3h sem interação | **MarkCartAsAbandonedJob** (cron horário) |
| job 7+ dias abandonado | **DeleteOldAbandonedCartsJob** (cron diário) |
| 404 | API responde "Carrinho não encontrado" |

---

## Jobs de carrinhos abandonados

Dois jobs agendados via sidekiq-scheduler: um horário (marcar abandonados) e um diário (excluir antigos).

```mermaid
flowchart LR
  subgraph Scheduler["Sidekiq Scheduler"]
    CronH["Cron: 0 * * * *<br/>(a cada hora)"]
    CronD["Cron: 0 0 * * *<br/>(diário)"]
  end

  subgraph Jobs["Jobs"]
    Mark[MarkCartAsAbandonedJob]
    Delete[DeleteOldAbandonedCartsJob]
  end

  subgraph Services["Services"]
    MarkSvc[Carts::MarkAbandonedService]
    DelSvc[Carts::DeleteOldAbandonedService]
  end

  subgraph DB["Banco"]
    Carts[Carts]
  end

  CronH --> Mark
  CronD --> Delete
  Mark --> MarkSvc
  Delete --> DelSvc
  MarkSvc --> Carts
  DelSvc --> Carts
```

**Fluxo de dados dos jobs:**

```mermaid
sequenceDiagram
  participant Sched as Scheduler
  participant MJ as MarkCartAsAbandonedJob
  participant MS as MarkAbandonedService
  participant DB as Carts (active)

  Sched->>+MJ: A cada hora
  MJ->>+MS: call(threshold: 3h)
  MS->>DB: Cart.active WHERE last_interaction_at < 3h
  loop Para cada cart
    MS->>DB: cart.mark_as_abandoned!
  end
  MS-->>-MJ: { marked_count }
  MJ-->>-Sched: ok

  participant DJ as DeleteOldAbandonedCartsJob
  participant DS as DeleteOldAbandonedService
  participant DB2 as Carts (abandoned)

  Sched->>+DJ: Diariamente
  DJ->>+DS: call(older_than: 7d)
  DS->>DB2: Cart.abandoned WHERE updated_at < 7d
  loop Para cada cart
    DS->>DB2: cart.delete_cart(mode: soft/hard)
  end
  DS-->>-DJ: { deleted_count, mode }
  DJ-->>-Sched: ok
```

---

## Fluxo de remoção de produto

DELETE /cart/:product_id: remoção unitária (padrão) ou total (remove_all=true).

```mermaid
flowchart TD
  A[DELETE /cart/:product_id] --> B{Carrinho na sessão<br/>e não deletado?}
  B -->|Não| C[404 Carrinho não encontrado]
  B -->|Sim| D{Produto está<br/>no carrinho?}
  D -->|Não| E[404 Produto não encontrado no carrinho]
  D -->|Sim| F{remove_all?}
  F -->|false / omitido| G[Remover 1 unidade]
  F -->|true| H[Remover todas as unidades]
  G --> I{quantity restante > 0?}
  I -->|Sim| J[Atualizar quantity]
  I -->|Não| K[Remover CartProduct]
  H --> K
  J --> L[record_interaction!]
  K --> L
  L --> M[200 + payload]
```

---

## Referências

- [docs/API.md](API.md) — Contratos dos endpoints
- [docs/ABANDONED_CARTS_JOBS.md](ABANDONED_CARTS_JOBS.md) — Configuração dos jobs
- [README.md](../README.md) — Visão geral do projeto
