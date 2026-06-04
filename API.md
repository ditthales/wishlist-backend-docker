# Documentação da API - Wishlist Backend

Esta documentação descreve todos os endpoints disponíveis na API, os parâmetros esperados, os formatos de resposta e as regras de negócio associadas.

---

## 🚀 Informações Gerais

- **URL Base:** `http://localhost:3000`
- **Formato de Dados:** Todas as requisições que enviam dados devem utilizar o cabeçalho `Content-Type: application/json`.
- **Autenticação:** Os endpoints protegidos exigem o cabeçalho `Authorization: Bearer <TOKEN_JWT>`.

---

## 🩺 Endpoint de Health Check

### 1. Verificar Status da Aplicação e do Banco
Retorna o status atual da aplicação e valida se a comunicação com o banco de dados PostgreSQL está ativa realizando uma consulta de teste.

- **URL:** `/health`
- **Método:** `GET`
- **Requisito de Autenticação:** Nenhum (Público)
- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "status": "ONLINE",
    "database": {
      "connected": true,
      "result": {
        "alive": 1
      }
    }
  }
  ```
- **Resposta de Erro (`503 Service Unavailable`):**
  *Se o banco de dados estiver inacessível:*
  ```json
  {
    "status": "OFFLINE",
    "database": {
      "connected": false,
      "error": "PG::ConnectionBad:..."
    }
  }
  ```

---

## 🔐 Autenticação (JWT com Invalidação no Servidor)

Os tokens gerados possuem expiração de **24 horas**. A invalidação de tokens funciona de forma ativa (Opção B): cada usuário possui um `token_version` no banco de dados. Ao fazer logout, essa versão é incrementada, o que invalida imediatamente todos os tokens emitidos anteriormente para aquele usuário.

### 1. Cadastro de Usuário (`POST /auth/signup`)
Cria um novo usuário na plataforma e retorna o JWT de acesso.

- **URL:** `/auth/signup`
- **Método:** `POST`
- **Requisito de Autenticação:** Nenhum (Público)
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `name` | String | Sim | Nome completo do usuário. |
  | `email` | String | Sim | E-mail do usuário (deve ser único e válido). |
  | `password` | String | Sim | Senha (mínimo de 6 caracteres). |
  | `password_confirmation` | String | Sim | Confirmação exata da senha enviada. |

- **Resposta de Sucesso (`201 Created`):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJ0b2tlbl92ZXJzaW9uIjoxLCJleHAiOjE3ODEyNjA2MTB9...",
    "user": {
      "id": 1,
      "name": "João Silva",
      "email": "joao@example.com"
    }
  }
  ```
- **Resposta de Erro (`422 Unprocessable Entity`):**
  ```json
  {
    "errors": [
      "Email has already been taken",
      "Password confirmation doesn't match Password",
      "Name can't be blank"
    ]
  }
  ```

### 2. Login (`POST /auth/login`)
Autentica o usuário com e-mail e senha, retornando um novo token de acesso.

- **URL:** `/auth/login`
- **Método:** `POST`
- **Requisito de Autenticação:** Nenhum (Público)
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `email` | String | Sim | E-mail cadastrado. |
  | `password` | String | Sim | Senha do usuário. |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJ0b2tlbl92ZXJzaW9uIjoxLCJleHAiOjE3ODEyNjA2MTB9...",
    "user": {
      "id": 1,
      "name": "João Silva",
      "email": "joao@example.com"
    }
  }
  ```
- **Resposta de Erro (`401 Unauthorized`):**
  ```json
  {
    "error": "Invalid email or password"
  }
  ```

### 3. Logout (`POST /auth/logout`)
Invalida o token atual do usuário no servidor incrementando a versão ativa do seu token.

- **URL:** `/auth/logout`
- **Método:** `POST`
- **Requisito de Autenticação:** Token JWT Válido no cabeçalho `Authorization`
- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "message": "Logged out successfully"
  }
  ```

---

## 👥 Gerenciamento de Grupos

### 1. Criar Grupo (`POST /groups`)
Cria um novo grupo. O usuário autenticado se torna o criador e é adicionado automaticamente como membro do grupo.

- **URL:** `/groups`
- **Método:** `POST`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `name` | String | Sim | Nome do grupo (ex: "Amigo Oculto 2026"). |
  | `emoji` | String | Não | Emoji que representa o grupo (ex: "🎄"). |

- **Resposta de Sucesso (`201 Created`):**
  ```json
  {
    "id": 5,
    "name": "Amigo Oculto 2026",
    "emoji": "🎄",
    "created_by_id": 1,
    "created_at": "2026-06-02T13:42:20.123Z",
    "updated_at": "2026-06-02T13:42:20.123Z",
    "users": [
      {
        "id": 1,
        "name": "João Silva",
        "email": "joao@example.com",
        "token_version": 1
      }
    ]
  }
  ```

### 2. Listar Meus Grupos (`GET /groups`)
Retorna uma lista de todos os grupos dos quais o usuário autenticado é membro (criados por ele ou que foi convidado).

- **URL:** `/groups`
- **Método:** `GET`
- **Requisito de Autenticação:** Token JWT Válido
- **Resposta de Sucesso (`200 OK`):**
  ```json
  [
    {
      "id": 5,
      "name": "Amigo Oculto 2026",
      "created_by_id": 1,
      "created_at": "2026-06-02T13:42:20.123Z",
      "updated_at": "2026-06-02T13:42:20.123Z",
      "created_by": {
        "id": 1,
        "name": "João Silva",
        "email": "joao@example.com"
      }
    }
  ]
  ```

### 3. Editar Grupo (`PUT/PATCH /groups/:id`)
Permite alterar as propriedades de um grupo.

> [!IMPORTANT]
> **Regra de Negócio:** Apenas o **criador** do grupo tem permissão para editar suas propriedades.

- **URL:** `/groups/:id`
- **Método:** `PATCH` ou `PUT`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `name` | String | Não | Novo nome para o grupo. |
  | `emoji` | String | Não | Novo emoji que representa o grupo (ex: "🎁"). |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "id": 5,
    "name": "Amigo Oculto Família",
    "emoji": "🎁",
    "created_by_id": 1,
    "created_at": "2026-06-02T13:42:20.123Z",
    "updated_at": "2026-06-02T13:45:10.456Z"
  }
  ```
- **Resposta de Erro (`403 Forbidden`):**
  *Se o usuário logado for membro, mas não o criador:*
  ```json
  {
    "error": "Only the group creator can edit it"
  }
  ```

### 4. Deletar Grupo (`DELETE /groups/:id`)
Apaga o grupo permanentemente e remove todos os seus membros da tabela intermediária.

> [!IMPORTANT]
> **Regra de Negócio:** Apenas o **criador** do grupo tem permissão para excluí-lo.

- **URL:** `/groups/:id`
- **Método:** `DELETE`
- **Requisito de Autenticação:** Token JWT Válido
- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "message": "Group deleted successfully"
  }
  ```
- **Resposta de Erro (`403 Forbidden`):**
  ```json
  {
    "error": "Only the group creator can delete it"
  }
  ```

### 5. Adicionar Usuário ao Grupo (`POST /groups/:id/add_user`)
Convida e adiciona outro usuário cadastrado no sistema para o grupo especificado.

> [!IMPORTANT]
> **Regra de Negócio:**
> - O usuário solicitante deve ser um **membro ativo** do grupo.
> - O usuário convidado deve estar previamente cadastrado no sistema.
> - Não é permitido adicionar o mesmo usuário mais de uma vez (membro duplicado).

- **URL:** `/groups/:id/add_user`
- **Método:** `POST`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros no Corpo (JSON - informe pelo menos um dos dois):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `email` | String | Opcional | E-mail do usuário cadastrado (Recomendado). |
  | `user_id` | Integer | Opcional | ID do usuário cadastrado. |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "message": "User added successfully",
    "user": {
      "id": 2,
      "name": "Maria Souza",
      "email": "maria@example.com"
    }
  }
  ```
- **Resposta de Erro (`404 Not Found`):**
  *Se o e-mail ou ID fornecido não constar na base de dados:*
  ```json
  {
    "error": "User not found"
  }
  ```
- **Resposta de Erro (`422 Unprocessable Entity`):**
  *Se o usuário já pertencer ao grupo:*
  ```json
  {
    "error": "User is already a member of this group"
  }
  ```
- **Resposta de Erro (`403 Forbidden`):**
  *Se quem tentar adicionar não fizer parte do grupo:*
  ```json
  {
    "error": "You must be a member of this group to add other users"
  }
  ```

---

## 🎁 Gerenciamento de Produtos

Todos os endpoints de produtos exigem que o usuário autenticado seja um **membro ativo** do grupo ao qual o produto pertence.

### 1. Criar Produto dentro de um Grupo (`POST /groups/:group_id/products`)
Adiciona um novo produto de desejo dentro do grupo. O usuário logado é definido como quem adicionou (`added_by`).

- **URL:** `/groups/:group_id/products`
- **Método:** `POST`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `name` | String | Sim | Nome do produto/presente (ex: "PlayStation 5"). |
  | `description` | String | Não | Detalhes adicionais (cor, tamanho, etc.). |
  | `store_link` | String | Não | Link da loja online para compra. |
  | `image_link` | String | Não | Link direto para uma imagem demonstrativa do produto. |
  | `price` | Decimal | Não | Preço estimado (deve ser maior ou igual a 0). |
  | `for_whom` | String | Não | Para quem é o presente (caso seja diferente de quem adicionou). |

- **Resposta de Sucesso (`201 Created`):**
  ```json
  {
    "id": 12,
    "group_id": 5,
    "added_by_id": 1,
    "bought_by_id": null,
    "name": "PlayStation 5",
    "description": "Edição Standard",
    "store_link": "https://example.com/ps5",
    "image_link": "https://example.com/ps5.jpg",
    "price": "499.99",
    "for_whom": "João Silva",
    "bought": false,
    "created_at": "2026-06-02T14:00:20.123Z",
    "updated_at": "2026-06-02T14:00:20.123Z",
    "added_by": {
      "id": 1,
      "name": "João Silva",
      "email": "joao@example.com"
    }
  }
  ```

### 2. Listar Produtos de um Grupo (`GET /groups/:group_id/products`)
Retorna os produtos cadastrados no grupo, permitindo filtros de busca e paginação estruturada.

- **URL:** `/groups/:group_id/products`
- **Método:** `GET`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros de Query (Opcionais):**
  | Parâmetro | Tipo | Padrão | Descrição |
  | :--- | :--- | :--- | :--- |
  | `page` | Integer | `1` | Página atual da listagem. |
  | `per_page` | Integer | `10` | Quantidade de itens por página (máximo `100`). |
  | `query` | String | - | Busca parcial insensível a maiúsculas (`name`, `description`, `for_whom`). |
  | `bought` | Boolean | - | Filtrar por comprado (`true`) ou não comprado (`false`). |
  | `added_by_id` | Integer | - | Filtrar por quem adicionou o produto. |
  | `bought_by_id` | Integer | - | Filtrar por quem marcou o produto como comprado. |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "products": [
      {
        "id": 12,
        "group_id": 5,
        "added_by_id": 1,
        "bought_by_id": null,
        "name": "PlayStation 5",
        "description": "Edição Standard",
        "store_link": "https://example.com/ps5",
        "image_link": "https://example.com/ps5.jpg",
        "price": "499.99",
        "for_whom": "João Silva",
        "bought": false,
        "created_at": "2026-06-02T14:00:20.123Z",
        "updated_at": "2026-06-02T14:00:20.123Z",
        "added_by": {
          "id": 1,
          "name": "João Silva",
          "email": "joao@example.com"
        },
        "bought_by": null
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_pages": 1,
      "total_count": 1,
      "next_page": null,
      "prev_page": null
    }
  }
  ```

### 3. Editar Produto (`PUT/PATCH /products/:id`)
Permite alterar as propriedades de um produto.

> [!IMPORTANT]
> **Regra de Negócio:** O usuário solicitante deve ser um membro ativo do grupo do produto.

- **URL:** `/products/:id`
- **Método:** `PATCH` ou `PUT`
- **Requisito de Autenticação:** Token JWT Válido
- **Parâmetros no Corpo (JSON):**
  | Campo | Tipo | Obrigatório | Descrição |
  | :--- | :--- | :--- | :--- |
  | `name` | String | Não | Novo nome para o produto. |
  | `price` | Decimal | Não | Novo preço (maior ou igual a 0). |
  | `description` | String | Não | Nova descrição. |
  | ... | ... | ... | Demais campos do produto. |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "id": 12,
    "group_id": 5,
    "added_by_id": 1,
    "bought_by_id": null,
    "name": "PlayStation 5 Slim",
    "price": "449.99",
    "description": "Edição Slim"
  }
  ```

### 4. Deletar Produto (`DELETE /products/:id`)
Remove o produto permanentemente da lista de desejos.

> [!IMPORTANT]
> **Regra de Negócio:** O usuário solicitante deve ser um membro ativo do grupo do produto.

- **URL:** `/products/:id`
- **Método:** `DELETE`
- **Requisito de Autenticação:** Token JWT Válido
- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "message": "Product deleted successfully"
  }
  ```

### 5. Marcar/Desmarcar Produto como Comprado (`POST /products/:id/buy`)
Marca um produto como comprado por você ou desmarca-o caso já estivesse marcado (Comportamento Toggle).

> [!IMPORTANT]
> **Regra de Negócio:**
> - O usuário deve ser membro do grupo do produto.
> - Se o produto **não** estiver comprado, marca como comprado (`bought: true`, `bought_by: current_user`).
> - Se o produto **já** estiver comprado, desmarca para livre novamente (`bought: false`, `bought_by: nil`).

- **URL:** `/products/:id/buy`
- **Método:** `POST`
- **Requisito de Autenticação:** Token JWT Válido
- **Resposta de Sucesso (Marcar como Comprado - `200 OK`):**
  ```json
  {
    "message": "Product marked as bought successfully",
    "product": {
      "id": 12,
      "name": "PlayStation 5",
      "bought": true,
      "bought_by_id": 1,
      "bought_by": {
        "id": 1,
        "name": "João Silva",
        "email": "joao@example.com"
      }
    }
  }
  ```
- **Resposta de Sucesso (Desmarcar/Remover Compra - `200 OK`):**
  ```json
  {
    "message": "Product marked as unbought",
    "product": {
      "id": 12,
      "name": "PlayStation 5",
      "bought": false,
      "bought_by_id": null,
      "bought_by": null
    }
  }
  ```

---

## ⚠️ Códigos de Status Comuns

- `401 Unauthorized`: Token ausente (`Missing Token`) ou inválido/expirado (`Invalid or Expired Token`).
- `403 Forbidden`: O usuário está autenticado mas não pertence ao grupo relacionado.
- `404 Not Found`: Recurso solicitado (grupo, produto ou usuário a adicionar) não existe.
- `422 Unprocessable Entity`: Falha de validação dos campos (ex: preço negativo, nome do produto vazio).

