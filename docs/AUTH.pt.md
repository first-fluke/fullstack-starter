# Autenticação

A autenticação é responsabilidade da aplicação FastAPI. Independentemente do método de login, Web e Mobile recebem os mesmos access/refresh tokens próprios da aplicação.

## Métodos suportados

- Cadastro e login com e-mail e senha
- Google OAuth 2.0 Authorization Code com PKCE (`S256`)
- GitHub OAuth 2.0 Authorization Code com PKCE (`S256`)
- Facebook Login com endpoints sem versão da Graph API
- Cadastro e autenticação com passkeys WebAuthn

Os client secrets dos providers existem somente no ambiente da API. A aplicação Web não executa um servidor de autenticação nem recebe access tokens dos providers.

## Fluxo OAuth

1. O client abre `GET /api/auth/oauth/{provider}/authorize` com um `redirect_uri` permitido e um caminho `return_to` relativo à aplicação.
2. A API cria uma state transaction de uso único. Google e GitHub também recebem um `code_challenge` PKCE.
3. O provider redireciona para `GET /api/auth/oauth/{provider}/callback` na API.
4. A API consome o state, troca o provider code, resolve a identity `(provider, subject)` e redireciona o client com um code temporário de uso único.
5. O client chama `POST /api/auth/oauth/exchange`. O code é consumido e os access/refresh tokens são retornados.

O native mobile client adiciona um segundo challenge S256 PKCE ao authorize request e envia o verifier na troca final. Assim, somente o aplicativo que iniciou o fluxo consegue trocar o custom scheme callback code.

O state expira em 10 minutos e o code de troca em 60 segundos. Ambientes com várias replicas armazenam ambos no Redis. Uma recusa do usuário também consome o state.

| Provider | PKCE | Authorization endpoint |
| --- | --- | --- |
| Google | `S256` | `https://accounts.google.com/o/oauth2/v2/auth` |
| GitHub | `S256` | `https://github.com/login/oauth/authorize` |
| Facebook | Não | `https://www.facebook.com/dialog/oauth` |

O Facebook pode não retornar um e-mail. Nesse caso, a API cria um placeholder email não entregável e mantém o subject estável do Facebook como identity key. Um provider email não verificado nunca é associado automaticamente a uma conta local existente.

## E-mail, senha e passkeys

- `POST /api/auth/register`: cria um usuário local.
- `POST /api/auth/login`: verifica o e-mail normalizado e o password hash bcrypt.
- `POST /api/auth/refresh`: rotaciona o refresh token.
- `POST /api/auth/passkeys/register/options` e `/verify`: registra uma passkey para um usuário autenticado.
- `POST /api/auth/passkeys/authenticate/options` e `/verify`: verifica a assertion e emite tokens.

O challenge WebAuthn é de uso único e expira após cinco minutos. User verification é obrigatório e origins de produção devem usar HTTPS.

## Ambiente da API

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

O callback dos providers é `https://api.example.com/api/auth/oauth/{provider}/callback`. O Web também publica Digital Asset Links e AASA em `/.well-known`; configure `MOBILE_ANDROID_PACKAGE_NAME`, `MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS` e `MOBILE_APPLE_APP_IDS`. O Mobile usa `APP_BASE_URL` e o scheme `fullstackstarter://auth/callback`. O Android host versionado já registra a callback activity, e o iOS habilita o associated domain `webcredentials` em `Runner.entitlements`.

A implementação principal está em `apps/api/src/auth/`, `apps/web/src/lib/auth/auth-client.ts` e `apps/mobile/lib/core/auth/providers.dart`. Aplique a migration Alembic que adiciona `oauth_identities` e `passkey_credentials` antes do deploy.
