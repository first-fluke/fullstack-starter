# 无状态令牌认证架构

[English](./AUTH.md) | [한국어](./AUTH.ko.md) | 简体中文 | [日本語](./AUTH.jp.md)

## 概述

本模板采用**无状态 JWT/JWE 认证系统**，而非**有状态会话认证**。认证处理完全在后端进行，前端仅负责存储和传输令牌。

## 架构

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant BetterAuth
    participant Backend
    participant API

    User->>BetterAuth: 社交登录 (OAuth)
    BetterAuth->>Frontend: OAuth 访问令牌
    Frontend->>Backend: POST /api/auth/login (OAuth 令牌)
    Backend->>Backend: OAuth 令牌重新验证 (Provider API)
    Backend->>Backend: 用户创建/更新 (DB)
    Backend->>Backend: JWE 令牌签发 (access + refresh)
    Backend->>Frontend: 返回 JWE 令牌
    Frontend->>API: Authorization Header (access_token)
    API->>API: JWE 令牌验证
    API->>User: 返回受保护资源
```

## 核心组件

### 1. 后端 (FastAPI - `apps/api/`)

**关键文件：**

- `src/lib/auth.py` - JWE 令牌生成/验证、OAuth 验证
- `src/auth/router.py` - 认证端点
- `src/users/model.py` - 用户数据库模型
- `src/lib/dependencies.py` - 认证的依赖注入

**关键函数：**

- `create_access_token(user_id)` - 创建 JWE 访问令牌（1 小时过期）
- `create_refresh_token(user_id)` - 创建 JWE 刷新令牌（7 天过期）
- `decode_token(token)` - 验证 JWE 令牌并提取 payload
- `verify_oauth_token(provider, token)` - 重新验证 OAuth 令牌（Google/GitHub/Facebook）
- `get_current_user(request)` - 从 Authorization header 提取用户

**端点：**

- `POST /api/auth/login` - OAuth 登录
- `POST /api/auth/refresh` - 刷新令牌
- `POST /api/auth/logout` - 登出

**安全性：**

- JWE 加密 (A256GCM)
- 访问令牌：1 小时过期
- 刷新令牌：7 天过期
- 基于 Authorization header 的传输

### 2. 前端 (Next.js - `apps/web/`)

**关键文件：**

- `src/lib/auth.ts` - Better Auth 服务器配置（OAuth 提供商）
- `src/lib/auth-client.ts` - Better Auth 客户端和令牌交换逻辑
- `src/lib/api-client.ts` - 带令牌管理的 HTTP 客户端（拦截器）
- `src/app/api/auth/[...all]/route.ts` - Better Auth 路由处理器

**关键操作/函数：**

- Better Auth OAuth 登录 (signIn.social)
- OAuth → 后端 JWT 交换（自动化）
- Authorization header 自动注入
- 401 错误时自动令牌刷新
- 登出时清除令牌

**安全性：**

- localStorage 存储（前缀：`fullstack_`）
- JWE 令牌（由后端签发）
- Authorization header 自动配置

## 令牌管理

### 访问令牌

- **格式：** JWE (JSON Web Encryption)
- **算法：** A256GCM (AES-256-GCM)
- **过期：** 1 小时
- **存储：** `localStorage.fullstack_access_token`
- **使用：** API 请求中的 `Authorization: Bearer {token}` header

### 刷新令牌

- **格式：** JWE
- **算法：** A256GCM
- **过期：** 7 天
- **存储：** `localStorage.fullstack_refresh_token`
- **使用：** 过期时用于续签访问令牌

## 认证流程

### 1. 社交登录

```
用户: 点击 "Google 登录"
    ↓
前端: signIn.social("google")
    ↓
BetterAuth: OAuth 重定向
    ↓
BetterAuth: OAuth access 创建 (cookie)
    ↓
前端: 接收到 OAuth access 令牌
    ↓
前端: exchangeOAuthForBackendJwt() 自动执行
    ↓
后端: POST /api/auth/login { provider, access_token, email, name }
    ↓
后端: OAuth 令牌重新验证 (Google API)
    ↓
后端: 用户数据库查找/创建
    ↓
后端: JWE 令牌签发 (access: 1h, refresh: 7d)
    ↓
前端: JWE 令牌存储到 localStorage
```

### 2. 受保护 API 请求

```
前端: API 请求
    ↓
apiClient: access_token 自动添加到 Authorization header
    ↓
后端: Authorization header 验证
    ↓
后端: JWE 令牌解码
    ↓
后端: user_id 提取
    ↓
后端: 数据库中查找用户
    ↓
API: 返回受保护资源
```

### 3. 令牌刷新（自动）

```
访问令牌过期 (1 小时)
    ↓
API 请求返回 401 错误
    ↓
apiClient: 自动使用 refresh_token
    ↓
后端: POST /api/auth/refresh
    ↓
后端: 签发新的 access_token
    ↓
前端: localStorage 更新
    ↓
请求自动重试
```

### 4. 登出

```
用户: 点击 "登出"
    ↓
前端: signOut()
    ↓
前端: localStorage.clearTokens()
    ↓
前端: apiClient.post("/api/auth/logout")
    ↓
后端: 登出处理（如需要则使客户端令牌失效）
```

## 安全特性

### 1. JWE 加密

- **完全加密：** 加密整个 payload
- **算法：** A256GCM (AES-256-GCM)
- **优势：** （与标准 JWT (JWS) 不同）Payload 不会暴露
- **认证标签 (authTag)：** 确保完整性和伪造检测

### 2. 无状态特性

- **无服务器会话：** 无需在服务器上存储会话状态
- **易于扩展：** 易于负载均衡
- **横向扩展：** 易于添加更多服务器

### 3. 令牌过期策略

- **访问令牌：** 短过期时间（1 小时）- 安全性优化
- **刷新令牌：** 长过期时间（7 天）- 用户便利性
- **自动刷新：** 过期时自动续签

## 数据库模式

### 用户表

```python
class User(Base):
    id: UUID (PK)
    email: String (唯一, 索引)
    name: String (可为空)
    image: String (可为空)
    email_verified: Boolean (默认: False)
    created_at: DateTime
    updated_at: DateTime
```

## 环境变量

### 后端 (apps/api/.env)

```bash
# JWT/JWE (无状态认证)
JWT_SECRET=strong-secret-key-32-chars-or-more
JWE_SECRET_KEY=strong-encryption-key-32-chars-or-more

# 数据库
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app

# Better Auth (仅 OAuth)
BETTER_AUTH_URL=http://localhost:3000
```

### 前端 (apps/web/.env)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# Better Auth
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=strong-secret-key-32-chars-or-more

# OAuth 提供商（可选）
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
```

## API 端点

### POST /api/auth/login

**目的：** 将 OAuth 令牌交换为后端 JWT

**请求体：**

```json
{
  "provider": "google" | "github" | "facebook",
  "access_token": "<OAuth provider token>",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**响应：**

```json
{
  "access_token": "<JWE encrypted access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/refresh

**目的：** 使用刷新令牌签发新的访问令牌

**请求体：**

```json
{
  "refresh_token": "<JWE encrypted refresh token>"
}
```

**响应：**

```json
{
  "access_token": "<JWE encrypted new access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/logout

**目的：** 客户端令牌清理

**响应：** 204 No Content

## 客户端令牌管理

### auth.ts

此文件处理 Better Auth 服务器配置。

### auth-client.ts

处理 Better Auth 客户端初始化和将 OAuth 令牌交换为后端 JWE 令牌的逻辑。

### api-client.ts

配置了拦截器的 Axios 实例，用于自动令牌注入和刷新。

**关键函数：**

- `exchangeOAuthForBackendJwt()` - 自动 OAuth → 后端 JWT 交换
- `setAccessToken()` - 存储访问令牌
- `setRefreshToken()` - 存储刷新令牌
- `clearTokens()` - 清除所有令牌
- `hasBackendAccessToken()` - 检查后端令牌是否存在

**自动特性：**

- Authorization header 自动注入（通过 `apiClient` 拦截器）
- 401 错误时自动令牌刷新
- 重试队列管理
- 内存令牌存储（Map + localStorage）

## OAuth 提供商

### 支持的提供商

| 提供商 | 客户端 ID 环境变量 | 客户端密钥环境变量 | API 端点 |
|----------|------------------------------|-----------------------------------|--------------|
| Google | `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_SECRET` | `https://www.googleapis.com/oauth2/v3/userinfo` |
| GitHub | `GITHUB_CLIENT_ID` | `GITHUB_CLIENT_SECRET` | `https://api.github.com/user` |
| Facebook | `FACEBOOK_CLIENT_ID` | `FACEBOOK_CLIENT_SECRET` | `https://graph.facebook.com/v19.0/me?fields=id,name,email,picture` |

## 主要优势

### 1. 性能提升

- 减少 Better Auth 服务器调用（节省 ~50-100ms）
- 减少后端负载

### 2. 可扩展性

- 由于服务器无状态，易于扩展
- 易于负载均衡

### 3. 移动端友好

- Authorization header 方法最适合移动端
- 比基于 cookie 的认证更简单

### 4. 增强安全性

- JWE 加密防止数据暴露
- 短访问令牌过期时间

## 常见问题

**Q: 为什么使用 JWE 而不是 JWT？**
A: JWE 更安全，因为 payload 完全加密。它防止 payload 暴露，有利于确保完整性。

**Q: 为什么要重新验证 OAuth 令牌？**
A: 通过 OAuth 提供商 API 重新确认用户信息来加强安全性。有助于缓解令牌被盗时的攻击。

**Q: 为什么访问令牌过期时间是 1 小时？**
A: 短过期时间对安全性很重要。如果令牌泄露，可最小化损害范围。可使用刷新令牌（7 天）续签。

## 参考

- [JWE (JSON Web Encryption) RFC 7516](https://datatracker.ietf.org/doc/html/rfc7516)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Better Auth Documentation](https://www.better-auth.com/docs)

**最后更新：** 2025-01-15
