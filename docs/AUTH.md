# Stateless Token Authentication Architecture

[English](./AUTH.md) | [한국어](./AUTH.ko.md) | [简体中文](./AUTH.cn.md) | [日本語](./AUTH.jp.md)

## Overview

This template implements a **stateless JWT/JWE authentication system** instead of **stateful session-based authentication**. Authentication processing is performed entirely on the backend, and the frontend is responsible only for storing and transmitting tokens.

## Architecture

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant BetterAuth
    participant Backend
    participant API

    User->>BetterAuth: Social Login (OAuth)
    BetterAuth->>Frontend: OAuth Access Token
    Frontend->>Backend: POST /api/auth/login (OAuth Token)
    Backend->>Backend: OAuth Token Re-verification (Provider API)
    Backend->>Backend: User Creation/Update (DB)
    Backend->>Backend: JWE Token Issuance (access + refresh)
    Backend->>Frontend: Return JWE Token
    Frontend->>API: Authorization Header (access_token)
    API->>API: JWE Token Verification
    API->>User: Return Protected Resource
```

## Key Components

### 1. Backend (FastAPI - `apps/api/`)

**Essential Files:**

- `src/lib/auth.py` - JWE token generation/validation, OAuth validation
- `src/auth/router.py` - Authentication endpoints
- `src/users/model.py` - User DB model
- `src/lib/dependencies.py` - Dependency injection for auth

**Key Functions:**

- `create_access_token(user_id)` - Create JWE access token (1 hour expiry)
- `create_refresh_token(user_id)` - Create JWE refresh token (7 days expiry)
- `decode_token(token)` - Verify JWE token and extract payload
- `verify_oauth_token(provider, token)` - Re-verify OAuth token (Google/GitHub/Facebook)
- `get_current_user(request)` - Extract user from Authorization header

**Endpoints:**

- `POST /api/auth/login` - OAuth login
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - Logout

**Security:**

- JWE Encryption (A256GCM)
- Access Token: 1 hour expiry
- Refresh Token: 7 days expiry
- Authorization header based transmission

### 2. Frontend (Next.js - `apps/web/`)

**Essential Files:**

- `src/lib/auth.ts` - Better Auth server config (OAuth providers)
- `src/lib/auth-client.ts` - Better Auth client and token exchange logic
- `src/lib/api-client.ts` - HTTP client with token management (interceptors)
- `src/app/api/auth/[...all]/route.ts` - Better Auth route handler

**Key Operations/Functions:**

- Better Auth OAuth login (signIn.social)
- OAuth → Backend JWT exchange (automated)
- Authorization header auto-injection
- Auto token refresh on 401 error
- Token cleanup on logout

**Security:**

- localStorage storage (prefix: `fullstack_`)
- JWE Token (issued by backend)
- Authorization header auto-configuration

## Token Management

### Access Token

- **Format:** JWE (JSON Web Encryption)
- **Algorithm:** A256GCM (AES-256-GCM)
- **Expiry:** 1 hour
- **Storage:** `localStorage.fullstack_access_token`
- **Usage:** `Authorization: Bearer {token}` header in API requests

### Refresh Token

- **Format:** JWE
- **Algorithm:** A256GCM
- **Expiry:** 7 days
- **Storage:** `localStorage.fullstack_refresh_token`
- **Usage:** Used to renew access token when expired

## Auth Flow

### 1. Social Login

```
User: Click "Google Login"
    ↓
Frontend: signIn.social("google")
    ↓
BetterAuth: OAuth redirect
    ↓
BetterAuth: OAuth access creation (cookie)
    ↓
Frontend: OAuth access token received
    ↓
Frontend: exchangeOAuthForBackendJwt() auto execute
    ↓
Backend: POST /api/auth/login { provider, access_token, email, name }
    ↓
Backend: OAuth token re-verification (Google API)
    ↓
Backend: User DB lookup/creation
    ↓
Backend: JWE token issuance (access: 1h, refresh: 7d)
    ↓
Frontend: JWE token localStorage storage
```

### 2. Protected API Request

```
Frontend: API Request
    ↓
apiClient: access_token auto add to Authorization header
    ↓
Backend: Authorization header verification
    ↓
Backend: JWE token decoding
    ↓
Backend: user_id extraction
    ↓
Backend: User lookup in DB
    ↓
API: Protected resource return
```

### 3. Token Refresh (Auto)

```
Access Token Expired (1 hour)
    ↓
401 error on API request
    ↓
apiClient: auto use refresh_token
    ↓
Backend: POST /api/auth/refresh
    ↓
Backend: New access_token issuance
    ↓
Frontend: localStorage update
    ↓
Request auto retry
```

### 4. Logout

```
User: Click "Logout"
    ↓
Frontend: signOut()
    ↓
Frontend: localStorage.clearTokens()
    ↓
Frontend: apiClient.post("/api/auth/logout")
    ↓
Backend: Logout processing (client token invalidation if needed)
```

## Security Features

### 1. JWE Encryption

- **Full Encryption:** Encrypts the entire payload
- **Algorithm:** A256GCM (AES-256-GCM)
- **Advantage:** (Unlike standard JWT (JWS)) Payload is not exposed
- **Authentication Tag (authTag):** Ensures integrity and forgery detection

### 2. Stateless Nature

- **No Server Session:** No need to store session state on the server
- **Easy Scaling:** Easy load balancing
- **Scale Out:** Easy to add more servers

### 3. Token Expiry Strategy

- **Access Token:** Short expiry (1 hour) - Security optimization
- **Refresh Token:** Long expiry (7 days) - User convenience
- **Auto Refresh:** Automatic renewal upon expiry

## Database Schema

### Users Table

```python
class User(Base):
    id: UUID (PK)
    email: String (unique, indexed)
    name: String (nullable)
    image: String (nullable)
    email_verified: Boolean (default: False)
    created_at: DateTime
    updated_at: DateTime
```

## Environment Variables

### Backend (apps/api/.env)

```bash
# JWT/JWE (stateless authentication)
JWT_SECRET=strong-secret-key-32-chars-or-more
JWE_SECRET_KEY=strong-encryption-key-32-chars-or-more

# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app

# Better Auth (OAuth only)
BETTER_AUTH_URL=http://localhost:3000
```

### Frontend (apps/web/.env)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# Better Auth
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=strong-secret-key-32-chars-or-more

# OAuth Providers (optional)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
```

## API Endpoints

### POST /api/auth/login

**Purpose:** Exchange OAuth token for Backend JWT

**Request Body:**

```json
{
  "provider": "google" | "github" | "facebook",
  "access_token": "<OAuth provider token>",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Response:**

```json
{
  "access_token": "<JWE encrypted access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/refresh

**Purpose:** Issue new access token using refresh token

**Request Body:**

```json
{
  "refresh_token": "<JWE encrypted refresh token>"
}
```

**Response:**

```json
{
  "access_token": "<JWE encrypted new access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/logout

**Purpose:** Client-side token cleanup

**Response:** 204 No Content

## Client-side Token Management

### auth.ts

This file handles Better Auth server configuration.

### auth-client.ts

Handles Better Auth client initialization and the logic to exchange OAuth tokens for backend JWE tokens.

### api-client.ts

Manual Axios instance configured with interceptors for automatic token injection and refreshing.

**Key Functions:**

- `exchangeOAuthForBackendJwt()` - Auto OAuth → Backend JWT exchange
- `setAccessToken()` - Store access token
- `setRefreshToken()` - Store refresh token
- `clearTokens()` - Clear all tokens
- `hasBackendAccessToken()` - Check if backend token exists

**Auto Features:**

- Authorization header auto-injection (via `apiClient` interceptors)
- Auto token refresh on 401 error
- Retry queue management
- In-memory token storage (Map + localStorage)

## OAuth Providers

### Supported Providers

| Provider | Client ID Environment Variable | Client Secret Environment Variable | API Endpoint |
|----------|------------------------------|-----------------------------------|--------------|
| Google | `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_SECRET` | `https://www.googleapis.com/oauth2/v3/userinfo` |
| GitHub | `GITHUB_CLIENT_ID` | `GITHUB_CLIENT_SECRET` | `https://api.github.com/user` |
| Facebook | `FACEBOOK_CLIENT_ID` | `FACEBOOK_CLIENT_SECRET` | `https://graph.facebook.com/v19.0/me?fields=id,name,email,picture` |

## Key Benefits

### 1. Performance Improvement

- Reduced Better Auth server calls (~50-100ms savings)
- Reduced backend load

### 2. Scalability

- Easy scaling due to stateless server
- Easy load balancing

### 3. Mobile Friendly

- Authorization header method is optimal for mobile
- Simpler than cookie-based authentication

### 4. Enhanced Security

- Data exposure prevention with JWE encryption
- Short access token expiry time

## FAQ

**Q: Why use JWE instead of JWT?**
A: JWE is safer because the payload is fully encrypted. It prevents payload exposure and is advantageous for ensuring integrity.

**Q: Why re-verify the OAuth token?**
A: To reinforce security by re-confirming user information through the OAuth provider API. It helps mitigate attacks in case of token theft.

**Q: Why is the access token expiry time 1 hour?**
A: A short expiry time is important for security. It minimizes the damage scope if a token is compromised. It can be renewed using the refresh token (7 days).

## References

- [JWE (JSON Web Encryption) RFC 7516](https://datatracker.ietf.org/doc/html/rfc7516)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Better Auth Documentation](https://www.better-auth.com/docs)

**Last Updated:** 2025-01-15
