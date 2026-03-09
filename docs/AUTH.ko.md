# Stateless Token Authentication Architecture

[English](./AUTH.md) | [한국어](./AUTH.ko.md) | [简体中文](./AUTH.cn.md) | [日本語](./AUTH.jp.md)

## 개요

이 템플릿은 **stateful(상태 저장) 세션 기반 인증** 대신 **stateless(무상태) JWT/JWE 인증 시스템**을 구현합니다. 인증 처리는 전적으로 백엔드에서 수행하며, 프론트엔드는 토큰을 저장하고 전송하는 역할만 담당합니다.

## 아키텍처

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
    Backend->>Frontend: JWE Token Return
    Frontend->>API: Authorization Header (access_token)
    API->>API: JWE Token Verification
    API->>User: Protected Resource Return
```

## 핵심 구성 요소

### 1. 백엔드 (FastAPI - `apps/api/`)

**필수 파일:**

- `src/lib/auth.py` - JWE 토큰 생성/검증, OAuth 검증
- `src/auth/router.py` - 인증 endpoint
- `src/users/model.py` - User DB 모델
- `src/lib/dependencies.py` - 인증용 dependency injection

**핵심 함수:**

- `create_access_token(user_id)` - 만료 1시간의 JWE access token 생성
- `create_refresh_token(user_id)` - 만료 7일의 JWE refresh token 생성
- `decode_token(token)` - JWE 토큰 검증 및 payload 추출
- `verify_oauth_token(provider, token)` - OAuth 토큰 재검증 (Google/GitHub/Facebook)
- `get_current_user(request)` - Authorization header에서 사용자 추출

**Endpoints:**

- `POST /api/auth/login` - OAuth 로그인
- `POST /api/auth/refresh` - 토큰 갱신
- `POST /api/auth/logout` - 로그아웃

**보안:**

- JWE 암호화 (A256GCM)
- Access Token: 만료 1시간
- Refresh Token: 만료 7일
- Authorization header 기반 전송

### 2. 프론트엔드 (Next.js - `apps/web/`)

**필수 파일:**

- `src/lib/auth.ts` - Better Auth 서버 설정 (OAuth providers)
- `src/lib/auth-client.ts` - Better Auth 클라이언트 및 토큰 교환 로직
- `src/lib/api-client.ts` - HTTP 클라이언트 및 토큰 관리 (interceptors)
- `src/app/api/auth/[...all]/route.ts` - Better Auth route handler

**핵심 동작/함수:**

- Better Auth OAuth 로그인 (signIn.social)
- OAuth → 백엔드 JWT 교환 (자동)
- Authorization header 자동 주입
- 401 에러 발생 시 자동 토큰 갱신
- 자동 토큰 갱신
- 로그아웃 시 토큰 정리

**보안:**

- localStorage 저장 (prefix: `fullstack_`)
- JWE 토큰 (백엔드 발급)
- Authorization header 자동 설정

## 토큰 관리

### Access Token

- **형식:** JWE (JSON Web Encryption)
- **알고리즘:** A256GCM (AES-256-GCM)
- **만료:** 1시간
- **저장 위치:** `localStorage.fullstack_access_token`
- **사용:** API 요청 시 `Authorization: Bearer {token}` header

### Refresh Token

- **형식:** JWE
- **알고리즘:** A256GCM
- **만료:** 7일
- **저장 위치:** `localStorage.fullstack_refresh_token`
- **사용:** access token 만료 시 갱신에 사용

## 인증 플로우

### 1. 소셜 로그인

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

### 2. 보호된 API 요청

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

### 3. 토큰 갱신 (자동)

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

### 4. 로그아웃

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

## 보안 기능

### 1. JWE 암호화

- **완전 암호화:** payload 전체를 암호화
- **알고리즘:** A256GCM (AES-256-GCM)
- **장점:** (일반적인 JWT(JWS)와 달리) payload가 노출되지 않음
- **Authentication Tag (authTag):** 무결성(Integrity) 보장 및 위변조 탐지

### 2. Stateless 특성

- **서버 세션 없음:** 세션 상태를 서버에 저장할 필요 없음
- **확장 용이:** 로드 밸런싱이 쉬움
- **스케일 아웃:** 서버 증설이 쉬움

### 3. 토큰 만료 전략

- **Access Token:** 짧은 만료(1시간) - 보안 최적화
- **Refresh Token:** 긴 만료(7일) - 사용자 편의성
- **Auto Refresh:** 만료 시 자동 갱신

## 데이터베이스 스키마

### Users 테이블

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

## 환경 변수

### 백엔드 (apps/api/.env)

```bash
# JWT/JWE (stateless authentication)
JWT_SECRET=strong-secret-key-32-chars-or-more
JWE_SECRET_KEY=strong-encryption-key-32-chars-or-more

# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app

# Better Auth (OAuth only)
BETTER_AUTH_URL=http://localhost:3000
```

### 프론트엔드 (apps/web/.env)

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

**목적:** OAuth token을 백엔드 JWT로 교환

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

**목적:** refresh token으로 새로운 access token 발급

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

**목적:** 클라이언트 측 토큰 정리

**Response:** 204 No Content

## 클라이언트 토큰 관리

### auth.ts

Better Auth 서버 설정을 담당하는 파일입니다.

### auth-client.ts

Better Auth 클라이언트 초기화 및 OAuth 토큰을 백엔드 JWE 토큰으로 교환하는 로직을 담당합니다.

### api-client.ts

토큰 자동 주입 및 갱신을 위한 interceptor가 설정된 수동 Axios 인스턴스입니다.

**핵심 함수:**

- `exchangeOAuthForBackendJwt()` - OAuth → 백엔드 JWT 자동 교환
- `setAccessToken()` - access token 저장
- `setRefreshToken()` - refresh token 저장
- `clearTokens()` - 전체 토큰 정리
- `hasBackendAccessToken()` - 백엔드 토큰 존재 여부 확인

**자동 기능:**

- Authorization header 자동 주입 (`apiClient` interceptor)
- 401 에러 발생 시 자동 토큰 갱신
- 재시도 큐 관리
- In-memory 토큰 저장 (Map + localStorage)

## OAuth Providers

### 지원 Provider

| Provider | Client ID Environment Variable | Client Secret Environment Variable | API Endpoint |
|----------|------------------------------|-----------------------------------|--------------|
| Google | `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_SECRET` | `https://www.googleapis.com/oauth2/v3/userinfo` |
| GitHub | `GITHUB_CLIENT_ID` | `GITHUB_CLIENT_SECRET` | `https://api.github.com/user` |
| Facebook | `FACEBOOK_CLIENT_ID` | `FACEBOOK_CLIENT_SECRET` | `https://graph.facebook.com/v19.0/me?fields=id,name,email,picture` |

## 주요 장점

### 1. 성능 개선

- Better Auth 서버 호출 감소 (~50-100ms 절감)
- 백엔드 부하 감소

### 2. 확장성

- 서버 상태가 없어서 손쉬운 스케일링
- 로드 밸런싱 용이

### 3. 모바일 친화적

- Authorization header 방식은 모바일에 최적
- cookie 기반 인증보다 단순

### 4. 보안 강화

- JWE 암호화로 데이터 노출 방지
- 짧은 access token 만료 시간

## FAQ

**Q: 왜 JWT 대신 JWE를 사용하나요?**
A: JWE는 payload가 완전히 암호화되어 더 안전합니다. payload 노출을 방지하고, 무결성 보장에 유리합니다.

**Q: 왜 OAuth token을 재검증하나요?**
A: OAuth provider API를 통해 사용자 정보를 재확인하여 보안을 강화하기 위함입니다. 토큰 탈취 시 공격을 완화하는 데 도움이 됩니다.

**Q: 왜 access token 만료 시간이 1시간인가요?**
A: 짧은 만료 시간은 보안 측면에서 중요합니다. 토큰이 탈취되었을 때 피해 범위를 최소화합니다. refresh token(7일)으로 갱신할 수 있습니다.

## 참고 자료

- [JWE (JSON Web Encryption) RFC 7516](https://datatracker.ietf.org/doc/html/rfc7516)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Better Auth Documentation](https://www.better-auth.com/docs)

**Last Updated:** 2025-01-15
