# 인증

인증의 소유자는 FastAPI 애플리케이션입니다. 로그인 수단이 달라도 Web과 Mobile은 동일한 자체 access/refresh token을 발급받습니다.

## 지원 방식

- 이메일/비밀번호 회원가입 및 로그인
- Google OAuth 2.0 Authorization Code + PKCE (`S256`)
- GitHub OAuth 2.0 Authorization Code + PKCE (`S256`)
- 버전 없는 Graph API 엔드포인트를 사용하는 Facebook Login
- WebAuthn 패스키 등록 및 로그인

Provider client secret은 API 환경에만 둡니다. Web은 별도 인증 서버를 실행하지 않으며 provider access token도 전달받지 않습니다.

## OAuth 흐름

1. Client가 허용된 `redirect_uri`와 앱 내부 경로인 `return_to`를 담아 `GET /api/auth/oauth/{provider}/authorize`를 엽니다.
2. API가 일회용 state transaction을 생성합니다. Google과 GitHub에는 PKCE `code_challenge`도 전달합니다.
3. Provider가 API의 `GET /api/auth/oauth/{provider}/callback`으로 redirect합니다.
4. API가 state를 소비하고 provider code를 교환한 뒤 `(provider, subject)` identity를 확인합니다. 이후 client에 짧은 수명의 일회용 code를 전달합니다.
5. Client가 `POST /api/auth/oauth/exchange`를 호출하면 code가 소비되고 자체 access/refresh token이 발급됩니다.

Native mobile client는 authorize 요청에 별도의 S256 PKCE challenge를 추가하고 최종 교환 시 verifier를 제출합니다. 따라서 custom scheme callback code는 흐름을 시작한 앱에서만 교환할 수 있습니다.

OAuth state의 수명은 10분, client 교환 code의 수명은 60초입니다. 다중 replica 배포에서는 Redis에 저장합니다. 사용자가 동의를 거절한 경우에도 state를 먼저 소비한 뒤 client로 오류를 반환합니다.

### Provider별 동작

| Provider | PKCE | Authorization endpoint |
| --- | --- | --- |
| Google | `S256` | `https://accounts.google.com/o/oauth2/v2/auth` |
| GitHub | `S256` | `https://github.com/login/oauth/authorize` |
| Facebook | 사용 안 함 | `https://www.facebook.com/dialog/oauth` |

Facebook은 이메일을 반환하지 않을 수 있습니다. 이때 API는 전송 불가능한 placeholder email을 만들고 안정적인 Facebook subject를 identity key로 사용합니다. 검증되지 않은 provider email을 기존 local account에 자동 연결하지 않습니다.

## 이메일과 비밀번호

- `POST /api/auth/register`: local user를 만들고 token을 반환합니다.
- `POST /api/auth/login`: 정규화된 email과 bcrypt password hash를 검증합니다.
- `POST /api/auth/refresh`: refresh token을 원자적으로 교체합니다.
- `POST /api/auth/logout`: 현재 access/refresh token을 폐기합니다.
- `GET /api/auth/me`: 인증된 user를 반환합니다.

## 패스키

패스키는 WebAuthn을 사용하며 동일한 user record에 연결됩니다.

- `POST /api/auth/passkeys/register/options`: access token이 필요합니다.
- `POST /api/auth/passkeys/register/verify`: 등록 ceremony를 소비하고 public-key credential을 저장합니다.
- `POST /api/auth/passkeys/authenticate/options`: email을 기준으로 인증을 시작합니다.
- `POST /api/auth/passkeys/authenticate/verify`: assertion을 검증하고 signature counter를 갱신한 뒤 token을 반환합니다.

Challenge는 한 번만 사용할 수 있고 5분 후 만료됩니다. User verification은 필수입니다. Relying-party ID와 origin을 정확히 지정해야 하며 운영 WebAuthn origin은 HTTPS여야 합니다.

## API 환경변수

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

Provider callback URL은 다음과 같습니다.

```text
https://api.example.com/api/auth/oauth/google/callback
https://api.example.com/api/auth/oauth/github/callback
https://api.example.com/api/auth/oauth/facebook/callback
```

Web은 `/.well-known`에서 Digital Asset Links와 AASA도 제공합니다. `MOBILE_ANDROID_PACKAGE_NAME`, `MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS`, `MOBILE_APPLE_APP_IDS`를 설정합니다. Mobile은 `APP_BASE_URL`과 등록된 `fullstackstarter://auth/callback` scheme을 사용합니다. 커밋된 Android host에는 `com.linusu.flutter_web_auth_2.CallbackActivity`가 등록되어 있고, iOS는 `Runner.entitlements`에서 `webcredentials` associated domain을 활성화합니다.

## 주요 구현 파일

- `apps/api/src/auth/oauth_service.py`: state, PKCE, provider 교환, identity 확인
- `apps/api/src/auth/passkey_service.py`: WebAuthn ceremony
- `apps/api/src/auth/ephemeral_store.py`: Redis 기반 일회용 transaction
- `apps/api/src/auth/repository.py`: identity 및 passkey 영속화
- `apps/api/src/auth/router.py`: 공개 인증 API
- `apps/web/src/lib/auth/auth-client.ts`: browser 로그인 및 WebAuthn helper
- `apps/mobile/lib/core/auth/providers.dart`: mobile OAuth system session 및 native passkey 연동

새 API를 배포하기 전에 `oauth_identities`와 `passkey_credentials`를 추가하는 Alembic migration을 적용해야 합니다.
