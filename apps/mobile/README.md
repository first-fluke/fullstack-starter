# Mobile authentication setup

The Flutter app supports email/password, Google/GitHub/Facebook OAuth with an app-bound S256 PKCE exchange, and native Android/iOS passkeys.

## OAuth callback

The committed Android manifest registers `com.linusu.flutter_web_auth_2.CallbackActivity` for `fullstackstarter://auth/callback`. iOS uses `ASWebAuthenticationSession` for the same custom scheme without an extra URL type.

Add the callback URI to the API configuration:

```env
OAUTH_ALLOWED_MOBILE_REDIRECT_URIS=["fullstackstarter://auth/callback"]
```

## Native passkeys

Passkeys require a real HTTPS relying-party domain. Set the same hostname in the API and in `ios/Flutter/Auth.xcconfig`:

```env
WEBAUTHN_RP_ID=example.com
WEBAUTHN_ORIGINS=["https://example.com"]
```

```xcconfig
WEBAUTHN_RP_ID = example.com
```

### Android

Android Credential Manager requires API 28 or later. Add every debug, release, and Play App Signing SHA-256 certificate fingerprint to both the API and Web deployment environments:

```env
WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS=["AA:BB:..."]
MOBILE_ANDROID_PACKAGE_NAME=com.example.mobile
MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS=AA:BB:...
```

The API derives and permits the corresponding `android:apk-key-hash:` origins. The Web app serves Digital Asset Links at `/.well-known/assetlinks.json`.

### iOS

Select the application signing team and enable the Associated Domains capability for the App ID. `Runner.entitlements` already contains `webcredentials:$(WEBAUTHN_RP_ID)`. Configure the full application identifier on the Web deployment:

```env
MOBILE_APPLE_APP_IDS=ABCDE12345.com.example.mobile
```

The Web app serves AASA at `/.well-known/apple-app-site-association`.

## Runtime configuration

Staging and production require the API origin as a Dart define:

```sh
flutter run --dart-define=APP_ENV=staging --dart-define=APP_BASE_URL=https://api.example.com
```
