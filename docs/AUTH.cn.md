# 身份验证

身份验证由 FastAPI 应用统一负责。无论用户选择哪种登录方式，Web 和 Mobile 都会获得相同的第一方 access/refresh token。

## 支持的方式

- 邮箱和密码注册、登录
- Google OAuth 2.0 Authorization Code + PKCE (`S256`)
- GitHub OAuth 2.0 Authorization Code + PKCE (`S256`)
- 使用无版本 Graph API 端点的 Facebook Login
- WebAuthn 通行密钥注册和认证

Provider client secret 只保存在 API 环境中。Web 不运行认证服务器，也不会接收 provider access token。

## OAuth 流程

1. Client 携带已允许的 `redirect_uri` 和应用内 `return_to` 路径打开 `GET /api/auth/oauth/{provider}/authorize`。
2. API 创建一次性 state transaction。Google 和 GitHub 还会收到 PKCE `code_challenge`。
3. Provider 重定向到 API 的 `GET /api/auth/oauth/{provider}/callback`。
4. API 消费 state、交换 provider code，并解析 `(provider, subject)` identity，然后向 client 返回短时有效的一次性 code。
5. Client 调用 `POST /api/auth/oauth/exchange`，消费 code 并获得第一方 access/refresh token。

Native mobile client 会在 authorize request 中加入另一组 S256 PKCE challenge，并在最终交换时提交 verifier，因此 custom scheme callback code 只能由发起流程的应用交换。

State 有效期为 10 分钟，交换 code 有效期为 60 秒。多 replica 部署使用 Redis 保存这些数据。用户拒绝授权时，state 也会被消费。

| Provider | PKCE | Authorization endpoint |
| --- | --- | --- |
| Google | `S256` | `https://accounts.google.com/o/oauth2/v2/auth` |
| GitHub | `S256` | `https://github.com/login/oauth/authorize` |
| Facebook | 否 | `https://www.facebook.com/dialog/oauth` |

Facebook 可能不会返回邮箱。此时 API 会创建一个不可投递的 placeholder email，并以稳定的 Facebook subject 作为 identity key。未经验证的 provider email 不会自动关联到已有本地账号。

## 邮箱、密码和通行密钥

- `POST /api/auth/register`：创建本地用户。
- `POST /api/auth/login`：验证规范化邮箱和 bcrypt password hash。
- `POST /api/auth/refresh`：轮换 refresh token。
- `POST /api/auth/passkeys/register/options` 和 `/verify`：为已登录用户注册通行密钥。
- `POST /api/auth/passkeys/authenticate/options` 和 `/verify`：验证 assertion 并签发 token。

WebAuthn challenge 只能使用一次，五分钟后过期。User verification 为必需项，生产 origin 必须使用 HTTPS。

## API 环境变量

```env
API_PUBLIC_URL=https://api.example.com
OAUTH_ALLOWED_WEB_ORIGINS=["https://example.com"]
OAUTH_ALLOWED_MOBILE_REDIRECT_URIS=["fullstackstarter://auth/callback"]
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
WEBAUTHN_RP_ID=example.com
WEBAUTHN_RP_NAME=Fullstack Starter
WEBAUTHN_ORIGINS=["https://example.com"]
WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS=["AA:BB:..."]
JWE_SECRET_KEY=
REDIS_URL=redis://localhost:6379
```

Provider callback 为 `https://api.example.com/api/auth/oauth/{provider}/callback`。Web 还从 `/.well-known` 提供 Digital Asset Links 和 AASA；请配置 `MOBILE_ANDROID_PACKAGE_NAME`、`MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS` 和 `MOBILE_APPLE_APP_IDS`。Mobile 使用 `APP_BASE_URL` 和 `fullstackstarter://auth/callback` scheme。已提交的 Android host 已注册 callback activity，iOS 则在 `Runner.entitlements` 中启用 `webcredentials` associated domain。

主要实现位于 `apps/api/src/auth/`、`apps/web/src/lib/auth/auth-client.ts` 和 `apps/mobile/lib/core/auth/providers.dart`。部署前请应用新增 `oauth_identities` 与 `passkey_credentials` 的 Alembic migration。
