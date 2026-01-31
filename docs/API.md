# Documentação da API

API REST para gerenciamento de produtos e carrinho de compras. Todas as respostas são em JSON.

---

## Base URL

```
http://localhost:3000
```

---

## Índice

1. [Produtos](#produtos)
2. [Carrinho](#carrinho)
3. [Health Check](#health-check)
4. [Códigos de status](#códigos-de-status)
5. [Formato de erros](#formato-de-erros)

---

## Produtos

### Listar produtos

```
GET /products
```

**Resposta de sucesso (200 OK)**

```json
[
  {
    "id": 1,
    "name": "Produto A",
    "price": "10.0",
    "created_at": "2024-01-15T10:00:00.000Z",
    "updated_at": "2024-01-15T10:00:00.000Z"
  }
]
```

---

### Obter produto

```
GET /products/:id
```

**Resposta de sucesso (200 OK)**

```json
{
  "id": 1,
  "name": "Produto A",
  "price": "10.0",
  "created_at": "2024-01-15T10:00:00.000Z",
  "updated_at": "2024-01-15T10:00:00.000Z"
}
```

**Erro (404 Not Found)** — Produto não existe

```json
{
  "status": 404,
  "error": "Record not found"
}
```

---

### Criar produto

```
POST /products
Content-Type: application/json
```

**Corpo da requisição**

```json
{
  "product": {
    "name": "Produto A",
    "price": 10.0
  }
}
```

| Campo | Tipo   | Obrigatório | Descrição                    |
|-------|--------|-------------|------------------------------|
| name  | string | Sim         | Nome do produto              |
| price | number | Sim         | Preço (deve ser ≥ 0)         |

**Resposta de sucesso (201 Created)**

```json
{
  "id": 1,
  "name": "Produto A",
  "price": "10.0",
  "created_at": "2024-01-15T10:00:00.000Z",
  "updated_at": "2024-01-15T10:00:00.000Z"
}
```

**Erro (422 Unprocessable Entity)** — Validação falhou

```json
{
  "name": ["can't be blank"],
  "price": ["must be greater than or equal to 0"]
}
```

---

### Atualizar produto

```
PATCH /products/:id
PUT /products/:id
Content-Type: application/json
```

**Corpo da requisição**

```json
{
  "product": {
    "name": "Produto Atualizado",
    "price": 15.0
  }
}
```

**Resposta de sucesso (200 OK)** — Mesmo formato do produto retornado em GET /products/:id

**Erro (422 Unprocessable Entity)** — Mesmo formato de erros do POST /products

---

### Excluir produto

```
DELETE /products/:id
```

**Resposta de sucesso (204 No Content)** — Corpo vazio

---

## Carrinho

O carrinho é vinculado à sessão do usuário (cookie). É necessário manter os cookies entre as requisições para que o carrinho seja persistido.

### Obter carrinho

```
GET /cart
```

**Resposta de sucesso (200 OK)**

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Produto A",
      "quantity": 2,
      "unit_price": 10.0,
      "total_price": 20.0
    }
  ],
  "total_price": 20.0
}
```

**Erro (404 Not Found)** — Sem carrinho na sessão ou carrinho deletado

```json
{
  "errors": ["Carrinho não encontrado"]
}
```

---

### Criar carrinho (adicionar primeiro item)

```
POST /cart
Content-Type: application/json
```

Cria um novo carrinho e adiciona o primeiro produto. Se já existir carrinho na sessão, adiciona o produto ao carrinho existente.

**Corpo da requisição**

```json
{
  "product_id": 1,
  "quantity": 2
}
```

| Campo     | Tipo   | Obrigatório | Descrição                    |
|-----------|--------|-------------|------------------------------|
| product_id| integer| Sim         | ID do produto                |
| quantity  | integer| Sim         | Quantidade (deve ser > 0)     |

**Resposta de sucesso (201 Created)**

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Produto A",
      "quantity": 2,
      "unit_price": 10.0,
      "total_price": 20.0
    }
  ],
  "total_price": 20.0
}
```

**Erros**

| Status | Condição                    | Exemplo de resposta                                      |
|--------|-----------------------------|----------------------------------------------------------|
| 404    | Produto não existe          | `{ "errors": ["Couldn't find Product with 'id'=99999"] }` |
| 422    | Parâmetro ausente           | `{ "errors": ["Parâmetro: product_id é obrigatório"] }`   |
| 422    | Quantidade inválida         | `{ "errors": ["Quantity must be greater than 0"] }`     |

---

### Adicionar item ao carrinho

```
POST /cart/add_item
Content-Type: application/json
```

Adiciona um produto ao carrinho existente ou atualiza a quantidade se o produto já estiver no carrinho.

**Corpo da requisição**

```json
{
  "product_id": 1,
  "quantity": 2
}
```

| Campo     | Tipo   | Obrigatório | Descrição                    |
|-----------|--------|-------------|------------------------------|
| product_id| integer| Sim         | ID do produto                |
| quantity  | integer| Sim         | Quantidade a adicionar (deve ser > 0) |

**Resposta de sucesso (200 OK)** — Mesmo formato de GET /cart

**Erros**

| Status | Condição                    | Exemplo de resposta                                      |
|--------|-----------------------------|----------------------------------------------------------|
| 404    | Sem carrinho na sessão      | `{ "errors": ["Carrinho não encontrado"] }`              |
| 404    | Produto não existe          | `{ "errors": ["Couldn't find Product..."] }`             |
| 422    | Parâmetro ausente           | `{ "errors": ["Parâmetro: product_id é obrigatório"] }`  |

---

### Remover produto do carrinho

```
DELETE /cart/:product_id
```

Remove o produto do carrinho. Por padrão, remove **uma unidade** por vez. Use `remove_all=true` para remover todas as unidades.

**Parâmetros de query**

| Parâmetro   | Tipo   | Padrão | Descrição                                      |
|-------------|--------|--------|------------------------------------------------|
| remove_all  | boolean| false  | Se `true`, remove todas as unidades do produto |

**Exemplos**

```
DELETE /cart/1           → Remove 1 unidade do produto 1
DELETE /cart/1?remove_all=true  → Remove todas as unidades do produto 1
```

**Resposta de sucesso (200 OK)** — Mesmo formato de GET /cart

**Erros**

| Status | Condição                    | Exemplo de resposta                                      |
|--------|-----------------------------|----------------------------------------------------------|
| 404    | Sem carrinho na sessão      | `{ "errors": ["Carrinho não encontrado"] }`              |
| 404    | Produto não está no carrinho| `{ "errors": ["Produto não encontrado no carrinho"] }`   |

---

## Health Check

```
GET /up
GET /
```

**Resposta de sucesso (200 OK)** — Indica que a aplicação está em execução.

---

## Códigos de status

| Código | Significado              |
|--------|--------------------------|
| 200    | OK                       |
| 201    | Created                  |
| 204    | No Content               |
| 404    | Not Found                |
| 422    | Unprocessable Entity     |
| 500    | Internal Server Error    |

---

## Formato de erros

Erros retornam um objeto JSON com a chave `errors`, contendo um array de mensagens:

```json
{
  "errors": ["Mensagem de erro 1", "Mensagem de erro 2"]
}
```

---

## Observações

- **Sessão:** O carrinho depende de cookies de sessão. Em testes com ferramentas como `curl`, é necessário usar `-c cookies.txt -b cookies.txt` para persistir a sessão.
- **Carrinhos abandonados:** Carrinhos sem interação por 3+ horas são marcados como `abandoned`. Após 7 dias, podem ser excluídos. Ver [ABANDONED_CARTS_JOBS.md](./ABANDONED_CARTS_JOBS.md).
- **Sidekiq:** Painel de jobs em `/sidekiq` (requer Sidekiq em execução para visualizar recurring jobs).
