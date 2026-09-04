# 認証

認証は FastAPI アプリケーションが一元管理します。ログイン方法にかかわらず、Web と Mobile には同じ自社 access/refresh token が発行されます。

## 対応する認証方法

- メールアドレスとパスワードによる登録・ログイン
- Google OAuth 2.0 Authorization Code + PKCE (`S256`)
- GitHub OAuth 2.0 Authorization Code + PKCE (`S256`)
- バージョンなしの Graph API エンドポイントを使用する Facebook Login
- WebAuthn パスキーの登録・認証

Provider client secret は API 環境だけに保存します。Web は認証サーバーを実行せず、provider access token も受け取りません。

## OAuth フロー

1. Client は許可された `redirect_uri` とアプリ内の `return_to` を指定し、`GET /api/auth/oauth/{provider}/authorize` を開きます。
2. API は一度だけ使える state transaction を作成します。Google と GitHub には PKCE `code_challenge` も送信します。
3. Provider は API の `GET /api/auth/oauth/{provider}/callback` に redirect します。
4. API は state を消費し、provider code を交換して `(provider, subject)` identity を解決します。その後、短時間だけ有効な一度限りの code を client に返します。
5. Client が `POST /api/auth/oauth/exchange` を呼ぶと、code が消費され、access/refresh token が返されます。

Native mobile client は authorize request に別の S256 PKCE challenge を追加し、最後の交換時に verifier を送信します。これにより custom scheme callback code はフローを開始したアプリだけが交換できます。

State の有効期間は 10 分、交換 code は 60 秒です。複数 replica の環境では Redis に保存します。認可が拒否された場合も state は消費されます。

| Provider | PKCE | Authorization endpoint |
| --- | --- | --- |
| Google | `S256` | `https://accounts.google.com/o/oauth2/v2/auth` |
| GitHub | `S256` | `https://github.com/login/oauth/authorize` |
| Facebook | なし | `https://www.facebook.com/dialog/oauth` |

Facebook がメールアドレスを返さない場合、API は配信不能な placeholder email を作成し、安定した Facebook subject を identity key として使用します。未検証の provider email を既存アカウントへ自動的に関連付けることはありません。

## メール、パスワード、パスキー

- `POST /api/auth/register`: ローカルユーザーを作成します。
- `POST /api/auth/login`: 正規化されたメールアドレスと bcrypt password hash を検証します。
- `POST /api/auth/refresh`: refresh token をローテーションします。
- `POST /api/auth/passkeys/register/options` と `/verify`: 認証済みユーザーにパスキーを登録します。
- `POST /api/auth/passkeys/authenticate/options` と `/verify`: assertion を検証し token を発行します。

WebAuthn challenge は一度だけ使用でき、5 分で失効します。User verification は必須で、本番 origin には HTTPS が必要です。

## API 環境変数

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

Provider callback は `https://api.example.com/api/auth/oauth/{provider}/callback` です。Web は `/.well-known` から Digital Asset Links と AASA も配信します。`MOBILE_ANDROID_PACKAGE_NAME`、`MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS`、`MOBILE_APPLE_APP_IDS` を設定してください。Mobile は `APP_BASE_URL` と `fullstackstarter://auth/callback` scheme を使用します。コミット済みの Android host には callback activity が登録され、iOS では `Runner.entitlements` に `webcredentials` associated domain が設定されています。

主な実装は `apps/api/src/auth/`、`apps/web/src/lib/auth/auth-client.ts`、`apps/mobile/lib/core/auth/providers.dart` にあります。デプロイ前に `oauth_identities` と `passkey_credentials` を追加する Alembic migration を適用してください。
