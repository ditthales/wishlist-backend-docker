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

- **Resposta de Sucesso (`201 Created`):**
  ```json
  {
    "id": 5,
    "name": "Amigo Oculto 2026",
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
  | `name` | String | Sim | Novo nome para o grupo. |

- **Resposta de Sucesso (`200 OK`):**
  ```json
  {
    "id": 5,
    "name": "Amigo Oculto Família",
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

## ⚠️ Códigos de Status Comuns

- `401 Unauthorized`: Token ausente (`Missing Token`) ou inválido/expirado (`Invalid or Expired Token`).
- `403 Forbidden`: O usuário está autenticado mas não tem permissão para a ação (regras de criador/membro).
- `404 Not Found`: Recurso solicitado (grupo ou usuário a ser adicionado) não existe.
- `422 Unprocessable Entity`: Falha nas validações de regras de negócio ou de presença de parâmetros.
