# ステートレストークン認証アーキテクチャ

[English](./AUTH.md) | [한국어](./AUTH.ko.md) | [简体中文](./AUTH.cn.md) | 日本語

## 概要

このテンプレートは、**ステートフルセッションベース認証**ではなく、**ステートレス JWT/JWE 認証システム**を実装しています。認証処理は完全にバックエンドで行われ、フロントエンドはトークンの保存と送信のみを担当します。

## アーキテクチャ

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant BetterAuth
    participant Backend
    participant API

    User->>BetterAuth: ソーシャルログイン (OAuth)
    BetterAuth->>Frontend: OAuth アクセストークン
    Frontend->>Backend: POST /api/auth/login (OAuth トークン)
    Backend->>Backend: OAuth トークン再検証 (Provider API)
    Backend->>Backend: ユーザー作成/更新 (DB)
    Backend->>Backend: JWE トークン発行 (access + refresh)
    Backend->>Frontend: JWE トークンを返す
    Frontend->>API: Authorization Header (access_token)
    API->>API: JWE トークン検証
    API->>User: 保護されたリソースを返す
```

## 主要コンポーネント

### 1. バックエンド (FastAPI - `apps/api/`)

**必須ファイル：**

- `src/lib/auth.py` - JWE トークン生成/検証、OAuth 検証
- `src/auth/router.py` - 認証エンドポイント
- `src/users/model.py` - ユーザー DB モデル
- `src/lib/dependencies.py` - 認証用の依存性注入

**主要関数：**

- `create_access_token(user_id)` - JWE アクセストークンを作成（1 時間の有効期限）
- `create_refresh_token(user_id)` - JWE リフレッシュトークンを作成（7 日間の有効期限）
- `decode_token(token)` - JWE トークンを検証してペイロードを抽出
- `verify_oauth_token(provider, token)` - OAuth トークンを再検証（Google/GitHub/Facebook）
- `get_current_user(request)` - Authorization ヘッダーからユーザーを抽出

**エンドポイント：**

- `POST /api/auth/login` - OAuth ログイン
- `POST /api/auth/refresh` - トークンをリフレッシュ
- `POST /api/auth/logout` - ログアウト

**セキュリティ：**

- JWE 暗号化 (A256GCM)
- アクセストークン：1 時間の有効期限
- リフレッシュトークン：7 日間の有効期限
- Authorization ヘッダーによる送信

### 2. フロントエンド (Next.js - `apps/web/`)

**必須ファイル：**

- `src/lib/auth.ts` - Better Auth サーバー設定（OAuth プロバイダー）
- `src/lib/auth-client.ts` - Better Auth クライアントとトークン交換ロジック
- `src/lib/api-client.ts` - トークン管理付き HTTP クライアント（インターセプター）
- `src/app/api/auth/[...all]/route.ts` - Better Auth ルートハンドラー

**主要操作/関数：**

- Better Auth OAuth ログイン (signIn.social)
- OAuth → バックエンド JWT 交換（自動化）
- Authorization ヘッダー自動注入
- 401 エラー時の自動トークンリフレッシュ
- ログアウト時のトークンクリーンアップ

**セキュリティ：**

- localStorage 保存（プレフィックス：`fullstack_`）
- JWE トークン（バックエンド発行）
- Authorization ヘッダー自動設定

## トークン管理

### アクセストークン

- **形式：** JWE (JSON Web Encryption)
- **アルゴリズム：** A256GCM (AES-256-GCM)
- **有効期限：** 1 時間
- **保存場所：** `localStorage.fullstack_access_token`
- **使用方法：** API リクエストの `Authorization: Bearer {token}` ヘッダー

### リフレッシュトークン

- **形式：** JWE
- **アルゴリズム：** A256GCM
- **有効期限：** 7 日間
- **保存場所：** `localStorage.fullstack_refresh_token`
- **使用方法：** 有効期限切れ時にアクセストークンを更新するために使用

## 認証フロー

### 1. ソーシャルログイン

```
ユーザー: "Google ログイン" をクリック
    ↓
フロントエンド: signIn.social("google")
    ↓
BetterAuth: OAuth リダイレクト
    ↓
BetterAuth: OAuth access 作成 (cookie)
    ↓
フロントエンド: OAuth アクセストークンを受信
    ↓
フロントエンド: exchangeOAuthForBackendJwt() を自動実行
    ↓
バックエンド: POST /api/auth/login { provider, access_token, email, name }
    ↓
バックエンド: OAuth トークン再検証 (Google API)
    ↓
バックエンド: ユーザー DB の検索/作成
    ↓
バックエンド: JWE トークン発行 (access: 1h, refresh: 7d)
    ↓
フロントエンド: JWE トークンを localStorage に保存
```

### 2. 保護された API リクエスト

```
フロントエンド: API リクエスト
    ↓
apiClient: access_token を Authorization ヘッダーに自動追加
    ↓
バックエンド: Authorization ヘッダー検証
    ↓
バックエンド: JWE トークンをデコード
    ↓
バックエンド: user_id を抽出
    ↓
バックエンド: DB でユーザーを検索
    ↓
API: 保護されたリソースを返す
```

### 3. トークンリフレッシュ（自動）

```
アクセストークンの有効期限切れ (1 時間)
    ↓
API リクエストで 401 エラー
    ↓
apiClient: refresh_token を自動使用
    ↓
バックエンド: POST /api/auth/refresh
    ↓
バックエンド: 新しい access_token を発行
    ↓
フロントエンド: localStorage を更新
    ↓
リクエストを自動再試行
```

### 4. ログアウト

```
ユーザー: "ログアウト" をクリック
    ↓
フロントエンド: signOut()
    ↓
フロントエンド: localStorage.clearTokens()
    ↓
フロントエンド: apiClient.post("/api/auth/logout")
    ↓
バックエンド: ログアウト処理（必要に応じてクライアントトークンを無効化）
```

## セキュリティ機能

### 1. JWE 暗号化

- **完全暗号化：** ペイロード全体を暗号化
- **アルゴリズム：** A256GCM (AES-256-GCM)
- **利点：** （標準 JWT (JWS) とは異なり）ペイロードが露出しない
- **認証タグ (authTag)：** 整合性と改竄検出を保証

### 2. ステートレス特性

- **サーバーセッションなし：** サーバー上にセッション状態を保存する必要がない
- **簡単なスケーリング：** 簡単なロードバランシング
- **スケールアウト：** サーバーの追加が容易

### 3. トークン有効期限戦略

- **アクセストークン：** 短い有効期限（1 時間）- セキュリティ最適化
- **リフレッシュトークン：** 長い有効期限（7 日間）- ユーザーコンビニエンス
- **自動リフレッシュ：** 有効期限切れ時に自動更新

## データベーススキーマ

### ユーザーテーブル

```python
class User(Base):
    id: UUID (PK)
    email: String (一意, インデックス付き)
    name: String (NULL 可)
    image: String (NULL 可)
    email_verified: Boolean (デフォルト: False)
    created_at: DateTime
    updated_at: DateTime
```

## 環境変数

### バックエンド (apps/api/.env)

```bash
# JWT/JWE (ステートレス認証)
JWT_SECRET=strong-secret-key-32-chars-or-more
JWE_SECRET_KEY=strong-encryption-key-32-chars-or-more

# データベース
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app

# Better Auth (OAuth のみ)
BETTER_AUTH_URL=http://localhost:3000
```

### フロントエンド (apps/web/.env)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# Better Auth
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=strong-secret-key-32-chars-or-more

# OAuth プロバイダー（オプション）
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
```

## API エンドポイント

### POST /api/auth/login

**目的：** OAuth トークンをバックエンド JWT に交換

**リクエストボディ：**

```json
{
  "provider": "google" | "github" | "facebook",
  "access_token": "<OAuth provider token>",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**レスポンス：**

```json
{
  "access_token": "<JWE encrypted access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/refresh

**目的：** リフレッシュトークンを使用して新しいアクセストークンを発行

**リクエストボディ：**

```json
{
  "refresh_token": "<JWE encrypted refresh token>"
}
```

**レスポンス：**

```json
{
  "access_token": "<JWE encrypted new access token>",
  "refresh_token": "<JWE encrypted refresh token>",
  "token_type": "bearer"
}
```

### POST /api/auth/logout

**目的：** クライアント側のトークンクリーンアップ

**レスポンス：** 204 No Content

## クライアント側トークン管理

### auth.ts

このファイルは Better Auth サーバー設定を処理します。

### auth-client.ts

Better Auth クライアントの初期化と、OAuth トークンをバックエンド JWE トークンに交換するロジックを処理します。

### api-client.ts

自動トークン注入とリフレッシュ用のインターセプターが設定された Axios インスタンス。

**主要関数：**

- `exchangeOAuthForBackendJwt()` - 自動 OAuth → バックエンド JWT 交換
- `setAccessToken()` - アクセストークンを保存
- `setRefreshToken()` - リフレッシュトークンを保存
- `clearTokens()` - すべてのトークンをクリア
- `hasBackendAccessToken()` - バックエンドトークンが存在するか確認

**自動機能：**

- Authorization ヘッダー自動注入（`apiClient` インターセプター経由）
- 401 エラー時の自動トークンリフレッシュ
- リトライキュー管理
- メモリ内トークン保存（Map + localStorage）

## OAuth プロバイダー

### サポートされているプロバイダー

| プロバイダー | クライアント ID 環境変数 | クライアントシークレット環境変数 | API エンドポイント |
|----------|------------------------------|-----------------------------------|--------------|
| Google | `GOOGLE_CLIENT_ID` | `GOOGLE_CLIENT_SECRET` | `https://www.googleapis.com/oauth2/v3/userinfo` |
| GitHub | `GITHUB_CLIENT_ID` | `GITHUB_CLIENT_SECRET` | `https://api.github.com/user` |
| Facebook | `FACEBOOK_CLIENT_ID` | `FACEBOOK_CLIENT_SECRET` | `https://graph.facebook.com/v19.0/me?fields=id,name,email,picture` |

## 主な利点

### 1. パフォーマンス向上

- Better Auth サーバー呼び出しの削減（~50-100ms の節約）
- バックエンド負荷の軽減

### 2. スケーラビリティ

- ステートレスサーバーによる簡単なスケーリング
- 簡単なロードバランシング

### 3. モバイルフレンドリー

- Authorization ヘッダー方式はモバイルに最適
- Cookie ベースの認証よりシンプル

### 4. セキュリティの強化

- JWE 暗号化によるデータ露出防止
- 短いアクセストークンの有効期限

## よくある質問

**Q: なぜ JWT の代わりに JWE を使用するのですか？**
A: JWE はペイロードが完全に暗号化されるため、より安全です。ペイロードの露出を防ぎ、整合性の確保に有利です。

**Q: なぜ OAuth トークンを再検証するのですか？**
A: OAuth プロバイダー API を通じてユーザー情報を再確認することで、セキュリティを強化します。トークン盗難時の攻撃を緩和するのに役立ちます。

**Q: なぜアクセストークンの有効期限が 1 時間なのですか？**
A: 短い有効期限はセキュリティに重要です。トークンが漏洩した場合の被害範囲を最小限に抑えます。リフレッシュトークン（7 日間）で更新できます。

## 参考

- [JWE (JSON Web Encryption) RFC 7516](https://datatracker.ietf.org/doc/html/rfc7516)
- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Better Auth Documentation](https://www.better-auth.com/docs)

**最終更新：** 2025-01-15
