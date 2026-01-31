# Jobs de carrinhos abandonados

Documentação dos jobs assíncronos que marcam carrinhos como abandonados e excluem os abandonados há mais de 7 dias. O gerenciamento e a execução manual dos jobs são feitos pelo **painel do Sidekiq** (`/sidekiq`).

**Diagramas:** fluxo dos jobs e ciclo de vida do carrinho em [docs/DIAGRAMS.md](DIAGRAMS.md) (Mermaid).

---

## Visão geral

| Job | Frequência | Descrição |
|-----|------------|-----------|
| **MarkCartAsAbandonedJob** | A cada 1 hora | Marca como `abandoned` os carrinhos ativos sem interação nas últimas 3 horas. |
| **DeleteOldAbandonedCartsJob** | 1 vez por dia | Exclui (hard ou soft) carrinhos com status `abandoned` e `updated_at` anterior a 7 dias. |

---

## Coluna `last_interaction_at`

- **O que é:** Data/hora da última interação do usuário com o carrinho (listagem, criação, adição ou remoção de itens).
- **Uso:** O job de marcar abandonados considera carrinhos **ativos** com `last_interaction_at` anterior a 3 horas (ou `last_interaction_at` nulo e `updated_at` anterior a 3 horas).
- **Atualização:** Em toda interação bem-sucedida (GET/POST/DELETE no carrinho), o sistema chama `cart.record_interaction!`, que:
  - define `last_interaction_at = Time.current`;
  - se o carrinho estiver com status `abandoned`, altera para `active`.

---

## Status do carrinho

- **active:** Carrinho em uso; pode receber interações e é considerado “válido” na sessão.
- **abandoned:** Carrinho sem interação há 3+ horas; continua existindo, mas o job diário pode excluí-lo após 7 dias. Qualquer nova interação volta o status para `active`.
- **deleted:** Apenas no modo **soft** de exclusão. O carrinho não é removido do banco; apenas o status é alterado. Para a API, o comportamento é o mesmo de “carrinho não encontrado” (404, mensagem apropriada).

---

## Variável de ambiente: `CART_DELETION_MODE`

Controla como o job diário **exclui** carrinhos abandonados há mais de 7 dias.

| Valor | Comportamento |
|-------|----------------|
| **soft** (recomendado) | Atualiza o carrinho para `status = 'deleted'`. O registro permanece no banco; listagem, criação, adição e remoção tratam como “carrinho não encontrado”. |
| **hard** | Chama `destroy` no carrinho (e dependências, conforme model). O registro é removido do banco. |

- **Default sugerido:** `soft`.
- **Exemplo:** `CART_DELETION_MODE=soft` ou `CART_DELETION_MODE=hard`.

---

## Agendamento (cron)

Os jobs são agendados via **sidekiq-scheduler** (configuração em `config/sidekiq.yml` ou no formato usado pelo projeto):

- **MarkCartAsAbandonedJob:** `cron: '0 * * * *'` — executa a cada hora, no minuto 0.
- **DeleteOldAbandonedCartsJob:** `cron: '0 0 * * *'` — executa uma vez por dia à meia-noite.

---

## Gerenciamento pelo painel Sidekiq

1. Acesse o painel: **`/sidekiq`** (com autenticação, se configurada).
2. **Recurring / Cron:** visualize os agendamentos e a próxima execução de cada job.
3. **Execução manual:** é possível enfileirar uma execução imediata do job (conforme opções do Sidekiq/Sidekiq-Scheduler) para testes ou correções pontuais, sem depender do cron.

Não são necessárias rotas HTTP adicionais para disparar os jobs; o painel do Sidekiq é o canal de gerenciamento e execução manual.

---

## Comportamento na API

- **Carrinho com status `deleted`:** Em qualquer ação que use o carrinho da sessão (show, add_item, remove_product), o sistema trata como se o carrinho não existisse (ex.: 404 e mensagem “Carrinho não encontrado”). No create, se não houver carrinho válido, um novo carrinho é criado normalmente.
- **Carrinho `abandoned`:** Se o usuário voltar a interagir (listar, adicionar ou remover itens), o carrinho é reativado (`status = 'active'`) e `last_interaction_at` é atualizado.

---

## Resumo dos arquivos

- **Services:** `Carts::MarkAbandonedService`, `Carts::DeleteOldAbandonedService` (lógica reutilizada pelos jobs).
- **Jobs:** `MarkCartAsAbandonedJob` (em `app/sidekiq/`), `DeleteOldAbandonedCartsJob`.
- **Model:** `Cart#record_interaction!`; escopos `active`, `abandoned`, `not_deleted` (quando aplicável).
- **Controller:** `current_cart` deve ignorar carrinhos com `status == 'deleted'`; chamar `record_interaction!` após interações bem-sucedidas.
