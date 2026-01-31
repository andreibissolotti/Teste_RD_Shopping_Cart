# API Carrinho de Compras (E-commerce)

API REST para gerenciamento de carrinho de compras, desenvolvida em Ruby on Rails como parte do desafio técnico da RD Station.

---

## Sobre o desafio

O projeto implementa uma API de carrinho de compras com as funcionalidades solicitadas: registro e listagem de produtos no carrinho, alteração de quantidades, remoção de itens e gerenciamento de carrinhos abandonados via jobs assíncronos.

**Documentação completa do desafio:** [docs/TEST_DESCRIPTION.md](docs/TEST_DESCRIPTION.md)

---

## Resumo da API

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/cart` | GET | Lista os itens do carrinho atual |
| `/cart` | POST | Cria o carrinho e adiciona o primeiro produto (ou adiciona ao carrinho existente) |
| `/cart/add_item` | POST | Adiciona ou atualiza a quantidade de um produto no carrinho |
| `/cart/:product_id` | DELETE | Remove produto do carrinho (unitário ou total com `?remove_all=true`) |

O carrinho é vinculado à sessão (cookies). A API também expõe CRUD de **produtos** em `/products`.

**Documentação completa da API:** [docs/API.md](docs/API.md)

**Documentação interativa (Swagger UI):** com a aplicação rodando, acesse **http://localhost:3000/api-docs** para explorar e testar os endpoints. Para regenerar o OpenAPI após alterar os specs do rswag: `./scripts/run rswag`.

---

## Sidekiq e carrinhos abandonados

Dois jobs são executados periodicamente:

- **MarkCartAsAbandonedJob** — A cada hora: marca como `abandoned` carrinhos sem interação há 3+ horas.
- **DeleteOldAbandonedCartsJob** — Diariamente: exclui carrinhos abandonados há mais de 7 dias.

O painel do Sidekiq está disponível em `/sidekiq` (aba "Recurring Jobs" para visualizar os agendamentos).

**Documentação completa dos jobs:** [docs/ABANDONED_CARTS_JOBS.md](docs/ABANDONED_CARTS_JOBS.md)

---

## Tecnologias

| Tecnologia | Versão |
|------------|--------|
| Ruby | 3.3.1 |
| Rails | 7.1.3.2 |
| PostgreSQL | 16 |
| Redis | 7.0.15 |
| Sidekiq | 7.2+ |
| sidekiq-scheduler | 5.0+ |

---

## Pré-requisitos

- **Docker** e **Docker Compose** (para execução via scripts)
- Ou: Ruby 3.3.1, PostgreSQL 16, Redis 7.x (para execução local)

---

## Instalação e execução

### Com Docker (recomendado)

Os scripts em `scripts/` centralizam os comandos de execução. Execute-os a partir da raiz do projeto.

**1. Setup inicial** (primeira vez ou após mudanças em dependências):

```bash
./scripts/run setup
```

Isso irá:
- Parar containers existentes
- Reconstruir as imagens
- Instalar dependências e preparar o banco de dados (development e test)

**2. Iniciar a aplicação:**

```bash
./scripts/run
```

Sobe os serviços `web`, `sidekiq`, `db` e `redis`. A API fica disponível em **http://localhost:3000**.

**3. Executar testes:**

```bash
./scripts/run rspec
```

**4. Outros comandos úteis:**

| Comando | Descrição |
|---------|-----------|
| `./scripts/run console` | Abre o Rails console |
| `./scripts/run rails <comando>` | Executa comandos Rails (ex: `rails db:migrate`) |
| `./scripts/run rake <tarefa>` | Executa tarefas Rake |
| `./scripts/run rswag` | Gera o OpenAPI (Swagger) a partir dos specs em `spec/requests/api_docs/` |
| `./scripts/run bash` | Abre shell no container web |

---

### Sem Docker

Com as ferramentas instaladas localmente:

```bash
bundle install
bundle exec rails db:prepare
```

Em um terminal, inicie o Sidekiq:

```bash
bundle exec sidekiq
```

Em outro terminal, inicie o servidor:

```bash
bundle exec rails server
```

Para os testes:

```bash
bundle exec rspec
```

---

## Variáveis de ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DATABASE_URL` | URL de conexão PostgreSQL | Definida no docker-compose |
| `REDIS_URL` | URL do Redis | Definida no docker-compose |
| `INACTIVITY_THRESHOLD_HOURS` | Horas sem interação para marcar carrinho como abandonado | `3` |
| `CART_DELETION_THRESHOLD_DAYS` | Dias em que o carrinho permanece abandonado antes de ser excluído | `7` |
| `CART_DELETION_MODE` | Modo de exclusão de carrinhos abandonados (`soft` ou `hard`) | `soft` |

---

## Estrutura de documentação

| Arquivo | Conteúdo |
|---------|----------|
| [docs/TEST_DESCRIPTION.md](docs/TEST_DESCRIPTION.md) | Descrição completa do desafio técnico |
| [docs/API.md](docs/API.md) | Documentação da API (endpoints, payloads, erros) |
| [docs/ABANDONED_CARTS_JOBS.md](docs/ABANDONED_CARTS_JOBS.md) | Jobs de carrinhos abandonados e configuração |
| [docs/DIAGRAMS.md](docs/DIAGRAMS.md) | Diagramas de funcionalidade (Mermaid): fluxos do carrinho, estados e jobs |
