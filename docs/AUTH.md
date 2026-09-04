# Authentication

Authentication is owned by the FastAPI application. Web and mobile clients receive the same first-party access and refresh tokens regardless of how the user signs in.

## Supported methods

- Email and password registration/login
- Google OAuth 2.0 Authorization Code with PKCE (`S256`)
- GitHub OAuth 2.0 Authorization Code with PKCE (`S256`)
- Facebook Login using the unversioned Graph API endpoints
- WebAuthn passkey registration and authentication

Provider client secrets exist only in the API environment. The web application does not run an authentication server and does not receive provider access tokens.

## OAuth flow

1. The client opens `GET /api/auth/oauth/{provider}/authorize` with an allowed `redirect_uri` and an application-relative `return_to` path.
2. The API creates a single-use state transaction. Google and GitHub also receive a PKCE `code_challenge`.
3. The provider redirects to `GET /api/auth/oauth/{provider}/callback` on the API.
4. The API consumes state, exchanges the provider code, resolves the `(provider, subject)` identity, and redirects the client with a short-lived one-time code.
5. The client calls `POST /api/auth/oauth/exchange`. The one-time code is consumed and first-party access/refresh tokens are returned.

Native mobile clients add a second S256 PKCE challenge to the authorize request and submit its verifier during the final exchange. This binds a custom-scheme callback code to the app that initiated the flow.

OAuth state lives for 10 minutes and the client exchange code for 60 seconds. Redis backs both in deployed multi-replica environments. Provider denial also consumes state before returning an error to the client.

### Provider behavior

| Provider | PKCE | Authorization endpoint |
| --- | --- | --- |
| Google | `S256` | `https://accounts.google.com/o/oauth2/v2/auth` |
| GitHub | `S256` | `https://github.com/login/oauth/authorize` |
| Facebook | No | `https://www.facebook.com/dialog/oauth` |

Facebook may omit email. In that case, the API creates a non-deliverable placeholder email while keeping the stable Facebook subject as the identity key. An unverified provider email is never silently linked to an existing local account.

## Email and password

- `POST /api/auth/register` creates a local user and returns tokens.
- `POST /api/auth/login` verifies the normalized email and bcrypt password hash.
- `POST /api/auth/refresh` rotates refresh tokens atomically.
- `POST /api/auth/logout` revokes the current access and refresh tokens.
- `GET /api/auth/me` returns the authenticated user.

## Passkeys

Passkeys use WebAuthn and attach to the same user record.

- `POST /api/auth/passkeys/register/options` requires an access token.
- `POST /api/auth/passkeys/register/verify` consumes the registration ceremony and stores the public-key credential.
- `POST /api/auth/passkeys/authenticate/options` starts authentication for an email address.
- `POST /api/auth/passkeys/authenticate/verify` verifies the assertion, updates the signature counter, and returns access/refresh tokens.

Challenges are single-use and expire after five minutes. User verification is required. Configure the relying-party ID and origins exactly; production WebAuthn origins must use HTTPS.

## API environment

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

Provider callback URLs are:

```text
https://api.example.com/api/auth/oauth/google/callback
https://api.example.com/api/auth/oauth/github/callback
https://api.example.com/api/auth/oauth/facebook/callback
```

The web environment also serves Digital Asset Links and AASA from `/.well-known`; configure `MOBILE_ANDROID_PACKAGE_NAME`, `MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS`, and `MOBILE_APPLE_APP_IDS`. Mobile uses `APP_BASE_URL` and the registered `fullstackstarter://auth/callback` scheme. The committed Android host already registers `com.linusu.flutter_web_auth_2.CallbackActivity`; iOS enables the `webcredentials` associated domain in `Runner.entitlements`.

## Main implementation files

- `apps/api/src/auth/oauth_service.py`: state, PKCE, provider exchange, identity resolution
- `apps/api/src/auth/passkey_service.py`: WebAuthn ceremonies
- `apps/api/src/auth/ephemeral_store.py`: Redis-backed single-use transactions
- `apps/api/src/auth/repository.py`: identities and passkey persistence
- `apps/api/src/auth/router.py`: public authentication API
- `apps/web/src/lib/auth/auth-client.ts`: browser login and WebAuthn helpers
- `apps/mobile/lib/core/auth/providers.dart`: mobile OAuth system-session integration

Apply the Alembic migration that adds `oauth_identities` and `passkey_credentials` before deploying the new API.
