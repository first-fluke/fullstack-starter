# Arquitetura de Autenticação Stateless com Tokens

## Visão Geral

Este template implementa um **sistema de autenticação stateless JWT/JWE** em vez de **autenticação baseada em sessão stateful**. O processamento de autenticação é realizado inteiramente no backend, e o frontend é responsável apenas por armazenar e transmitir tokens.

## Arquitetura

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant BetterAuth
    participant Backend
    participant API

    User->>BetterAuth: Login Social (OAuth)
    BetterAuth->>Frontend: Token de Acesso OAuth
    Frontend->>Backend: POST /api/auth/login (Token OAuth)
    Backend->>Backend: Re-verificação do Token OAuth (Provider API)
    Backend->>Backend: Criação/Atualização do Usuário (DB)
    Backend->>Backend: Emissão de Token JWE (access + refresh)
    Backend->>Frontend: Retorna Token JWE
    Frontend->>API: Authorization Header (access_token)
    API->>API: Verificação do Token JWE
    API->>User: Retorna Recurso Protegido
```

## Componentes Principais

### 1. Backend (FastAPI - `apps/api/`)

**Arquivos Essenciais:**

- `src/lib/auth.py` - Geração/validação de tokens JWE, validação OAuth
- `src/auth/router.py` - Endpoints de autenticação
- `src/users/model.py` - Modelo de usuário do banco de dados
- `src/lib/dependencies.py` - Injeção de dependência para autenticação

**Funções Principais:**

- `create_access_token(user_id)` - Cria token de acesso JWE (expira em 1 hora)
- `create_refresh_token(user_id)` - Cria token de refresh JWE (expira em 7 dias)
- `decode_token(token)` - Verifica token JWE e extrai payload
- `verify_oauth_token(provider, token)` - Re-verifica token OAuth (Google/GitHub/Facebook)
- `get_current_user(request)` - Extrai usuário do header Authorization

**Endpoints:**

- `POST /api/auth/login` - Login OAuth
- `POST /api/auth/refresh` - Refresh de token
- `POST /api/auth/logout` - Logout

**Segurança:**

- Criptografia JWE (A256GCM)
- Token de Acesso: expira em 1 hora
- Token de Refresh: expira em 7 dias
- Transmissão baseada em header Authorization

### 2. Frontend (Next.js - `apps/web/`)

**Arquivos Essenciais:**

- `src/lib/auth.ts` - Configuração do servidor Better Auth (provedores OAuth)
- `src/lib/auth-client.ts` - Cliente Better Auth e lógica de troca de tokens
- `src/lib/api-client.ts` - Cliente HTTP com gerenciamento de tokens (interceptors)
- `src/app/api/auth/[...all]/route.ts` - Handler de rota Better Auth

**Operações/Funções Principais:**

- Login OAuth do Better Auth (signIn.social)
- Troca OAuth → JWT backend (automatizado)
- Injeção automática de header Authorization
- Refresh automático de token em erro 401
- Limpeza de token no logout

**Segurança:**

- Armazenamento localStorage (prefixo: `fullstack_`)
- Token JWE (emitido pelo backend)
- Configuração automática de header Authorization

## Gerenciamento de Tokens

### Token de Acesso

- **Formato:** JWE (JSON Web Encryption)
- **Algoritmo:** A256GCM (AES-256-GCM)
- **Expiração:** 1 hora
- **Armazenamento:** `localStorage.fullstack_access_token`
- **Uso:** Header `Authorization: Bearer {token}` em requisições API

### Token de Refresh

- **Formato:** JWE
- **Algoritmo:** A256GCM
- **Expiração:** 7 dias
- **Armazenamento:** `localStorage.fullstack_refresh_token`
- **Uso:** Usado para renovar token de acesso quando expirado

## Fluxo de Autenticação

### 1. Login Social

```
Usuário: Clica "Login com Google"
    ↓
Frontend: signIn.social("google")
    ↓
BetterAuth: Redirecionamento OAuth
    ↓
BetterAuth: Criação de acesso OAuth (cookie)
    ↓
Frontend: Recebe token de acesso OAuth
    ↓
Frontend: exchangeOAuthForBackendJwt() executa automaticamente
    ↓
Backend: POST /api/auth/login { provider, access_token, email, name }
    ↓
Backend: Re-verificação do token OAuth (Google API)
    ↓
Backend: Busca/Criação do usuário no DB
    ↓
Backend: Emissão de token JWE (access: 1h, refresh: 7d)
    ↓
Frontend: Armazena token JWE no localStorage
```

### 2. Requisição API Protegida

```
Frontend: Requisição API
    ↓
apiClient: access_token adicionado automaticamente ao header Authorization
    ↓
Backend: Verificação do header Authorization
    ↓
Backend: Decodificação do token JWE
    ↓
Backend: Extração do user_id
    ↓
Backend: Busca do usuário no DB
    ↓
API: Retorna recurso protegido
```

### 3. Refresh de Token (Automático)

```
Token de Acesso Expirado (1 hora)
    ↓
Erro 401 na requisição API
    ↓
apiClient: usa refresh_token automaticamente
    ↓
Backend: POST /api/auth/refresh
    ↓
Backend: Emissão de novo access_token
    ↓
Frontend: Atualiza localStorage
    ↓
Requisição é automaticamente reenviada
```

### 4. Logout

```
Usuário: Clica "Logout"
    ↓
Frontend: signOut()
    ↓
Frontend: localStorage.clearTokens()
    ↓
Frontend: apiClient.post("/api/auth/logout")
    ↓
Backend: Processamento de logout (invalidação do token do cliente se necessário)
```

## Recursos de Segurança

### 1. Criptografia JWE

- **Criptografia Completa:** Criptografa todo o payload
- **Algoritmo:** A256GCM (AES-256-GCM)
- **Vantagem:** (Diferente do JWT padrão (JWS)) O payload não é exposto
- **Tag de Autenticação (authTag):** Garante integridade e detecção de falsificação

### 2. Natureza Stateless

- **Sem Sessão no Servidor:** Não há necessidade de armazenar estado de sessão no servidor
- **Fácil Escalabilidade:** Balanceamento de carga simplificado
- **Scale Out:** Fácil adicionar mais servidores

### 3. Estratégia de Expiração de Tokens

- **Token de Acesso:** Expiração curta (1 hora) - Otimização de segurança
- **Token de Refresh:** Expiração longa (7 dias) - Conveniência do usuário
- **Refresh Automático:** Renovação automática na expiração

## Schema do Banco de Dados

### Tabela de Usuários

```python
class User(Base):
    id: UUID (PK)
    email: String (único, indexado)
    name: String (nullable)
    image: String (nullable)
    email_verified: Boolean (padrão: False)
    created_at: DateTime
    updated_at: DateTime
```

## Variáveis de Ambiente

### Backend (apps/api/.env)

```bash
# JWT/JWE (autenticação stateless)
JWT_SECRET=strong-secret-key-32-chars-or-more
JWE_SECRET_KEY=strong-encryption-key-32-chars-or-more

# Banco de Dados
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app

# Better Auth (apenas OAuth)
BETTER_AUTH_URL=http://localhost:3000
```

### Frontend (apps/web/.env)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# Better Auth
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=strong-secret-key-32-chars-or-more

# Provedores OAuth (opcional)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
```

## Endpoints da API

### POST /api/auth/login

**Propósito:** Trocar token OAuth por JWT do backend

**Corpo da Requisição:**

```json
{
  "provider": "google" | "github" | "facebook",
  "access_token": "<OAuth provider token>",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Resposta:**

```json
{
  "access_token": "<JWE encrypted access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/refresh

**Propósito:** Emitir novo token de acesso usando token de refresh

**Corpo da Requisição:**

```json
{
  "refresh_token": "<JWE encrypted refresh token>"
}
```

**Resposta:**

```json
{
  "access_token": "<JWE encrypted new access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/logout

**Propósito:** Limpeza de tokens do lado do cliente

**Resposta:** 204 No Content

## Gerenciamento de Tokens no Cliente

### auth.ts

Este arquivo lida com a configuração do servidor Better Auth.

### auth-client.ts

Lida com a inicialização do cliente Better Auth e a lógica para trocar tokens OAuth por tokens JWE do backend.

### api-client.ts

Instância Axios manual configurada com interceptors para injeção automática de tokens e refresh.

**Funções Principais:**

- `exchangeOAuthForBackendJwt()` - Troca automática OAuth → JWT backend
- `setAccessToken()` - Armazena token de acesso
- `setRefreshToken()` - Armazena token de refresh
- `clearTokens()` - Limpa todos os tokens
- `hasBackendAccessToken()` - Verifica se existe token do backend

**Recursos Automáticos:**

- Injeção automática de header Authorization (via interceptors do `apiClient`)
- Refresh automático de token em erro 401
- Gerenciamento de fila de retry
- Armazenamento de tokens em memória (Map + localStorage)

## Provedores OAuth

### Provedores Suportados

| Provedor | Variável de Ambiente Client ID | Variável de Ambiente Client Secret | Endpoint da API |
|----------|------------------------------|-----------------------------------|--------------|
| Google | `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_SECRET` | `https://www.googleapis.com/oauth2/v3/userinfo` |
| GitHub | `GITHUB_CLIENT_ID` | `GITHUB_CLIENT_SECRET` | `https://api.github.com/user` |
| Facebook | `FACEBOOK_CLIENT_ID` | `FACEBOOK_CLIENT_SECRET` | `https://graph.facebook.com/v19.0/me?fields=id,name,email,picture` |

## Principais Benefícios

### 1. Melhoria de Performance

- Redução de chamadas ao servidor Better Auth (~50-100ms economizados)
- Redução da carga no backend

### 2. Escalabilidade

- Escalabilidade fácil devido ao servidor stateless
- Balanceamento de carga simplificado

### 3. Mobile-friendly

- Método de header Authorization é ótimo para mobile
- Mais simples que autenticação baseada em cookies

### 4. Segurança Aprimorada

- Prevenção de exposição de dados com criptografia JWE
- Tempo de expiração curto do token de acesso

## FAQ

**P: Por que usar JWE em vez de JWT?**
R: JWE é mais seguro porque o payload é totalmente criptografado. Previne a exposição do payload e é vantajoso para garantir integridade.

**P: Por que re-verificar o token OAuth?**
R: Para reforçar a segurança reconfirmando as informações do usuário através da API do provedor OAuth. Ajuda a mitigar ataques em caso de roubo de token.

**P: Por que o tempo de expiração do token de acesso é 1 hora?**
R: Um tempo de expiração curto é importante para segurança. Minimiza o escopo de danos se um token for comprometido. Pode ser renovado usando o token de refresh (7 dias).

## Referências

- [JWE (JSON Web Encryption) RFC 7516](https://datatracker.ietf.org/doc/html/rfc7516)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Better Auth Documentation](https://www.better-auth.com/docs)

**Última Atualização:** 2025-01-15
