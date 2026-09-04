import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/config/app_env.dart';
import 'package:mobile/core/network/api/api_client.dart' as generated;
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/email_login_request.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';
import 'package:mobile/core/network/api/models/token_response.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

// Re-export tokenStorageProvider so callers can import from one place.
export 'token_storage.dart' show tokenStorageProvider;

/// OAuth providers supported by the backend PKCE broker.
enum OAuthProvider {
  /// Google OpenID Connect.
  google,

  /// GitHub OAuth.
  github,

  /// Facebook Login.
  facebook,
}

const _oauthCallbackUri = 'fullstackstarter://auth/callback';

/// Native platform authenticator used for WebAuthn ceremonies.
final passkeyAuthenticatorProvider = Provider<PasskeyAuthenticator>(
  (ref) => PasskeyAuthenticator(),
  name: 'passkeyAuthenticatorProvider',
);

({String ceremonyId, Map<String, dynamic> publicKey}) _parsePasskeyOptions(
  Map<String, Object?>? data,
) {
  final ceremonyId = data?['ceremony_id'];
  final publicKey = data?['public_key'];
  if (ceremonyId is! String || publicKey is! Map) {
    throw const FormatException('Passkey options response is malformed');
  }
  return (
    ceremonyId: ceremonyId,
    publicKey: Map<String, dynamic>.from(publicKey),
  );
}

/// Builds the backend URL that starts an OAuth Authorization Code + PKCE flow.
Uri buildOAuthAuthorizationUri(
  String baseUrl,
  OAuthProvider provider, {
  required String codeChallenge,
}) {
  return Uri.parse(
    '$baseUrl/api/auth/oauth/${provider.name}/authorize',
  ).replace(
    queryParameters: {
      'redirect_uri': _oauthCallbackUri,
      'return_to': '/',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    },
  );
}

/// Provides the Dio instance shared by the generated [generated.ApiClient].
///
/// Adds [AuthInterceptor] so every request automatically carries a Bearer
/// token and handles transparent refresh on 401 responses.  When refresh
/// fails the [AuthInterceptor] calls [TokenStorage.clearTokens] and invokes
/// the `onLogout` callback — wired here to [authStateProvider]'s logout()
/// so the notifier stays decoupled from go_router internals.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  // A plain Dio (no AuthInterceptor) dedicated to the refresh call so that
  // a 401 on /auth/refresh does not loop back into this interceptor.
  final plainDio = Dio(
    BaseOptions(
      baseUrl: AppEnv.current.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final plainAuthService = AuthenticationService(plainDio);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.current.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final authInterceptor = AuthInterceptor(
    tokenStorage: tokenStorage,
    authService: plainAuthService,
    onLogout: () {
      // Notify the auth notifier so the router redirect fires.
      ref.read(authStateProvider.notifier).forceUnauthenticated();
    },
    retryDio: plainDio,
  );

  dio.interceptors.add(authInterceptor);
  return dio;
}, name: 'authenticatedDioProvider');

/// Provider for the generated [generated.ApiClient] with auth support.
final apiClientProvider = Provider<generated.ApiClient>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return generated.ApiClient(dio, baseUrl: AppEnv.current.baseUrl);
}, name: 'apiClientProvider');

/// Provider for [AuthenticationService] using the authenticated client.
final authServiceProvider = Provider<AuthenticationService>((ref) {
  final client = ref.watch(apiClientProvider);
  return client.authentication;
}, name: 'authServiceProvider');

/// {@template auth_notifier}
/// AsyncNotifier that manages the authentication lifecycle.
/// {@endtemplate}
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.watch(tokenStorageProvider);
    final accessToken = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();

    if (accessToken != null && refreshToken != null) {
      return AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return const AuthState.unauthenticated();
  }

  /// Saves tokens and transitions to [Authenticated].
  Future<void> login({
    required String accessToken,
    required String refreshToken,
  }) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.saveTokens(accessToken, refreshToken);
    state = AsyncData(
      AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  /// Opens the system authentication session and exchanges its one-time code.
  Future<void> loginWithOAuth(OAuthProvider provider) async {
    state = const AsyncLoading();
    try {
      final secureRandom = Random.secure();
      final verifierBytes = List<int>.generate(
        64,
        (_) => secureRandom.nextInt(256),
      );
      final codeVerifier = base64Url.encode(verifierBytes).replaceAll('=', '');
      final codeChallenge = base64Url
          .encode(sha256.convert(utf8.encode(codeVerifier)).bytes)
          .replaceAll('=', '');
      final authorizationUri = buildOAuthAuthorizationUri(
        AppEnv.current.baseUrl,
        provider,
        codeChallenge: codeChallenge,
      );
      final callback = await FlutterWebAuth2.authenticate(
        url: authorizationUri.toString(),
        callbackUrlScheme: 'fullstackstarter',
      );
      final code = Uri.parse(callback).queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw StateError('OAuth callback did not include an exchange code');
      }
      final response = await ref
          .read(authenticatedDioProvider)
          .post<Map<String, Object?>>(
            '/api/auth/oauth/exchange',
            data: {'code': code, 'code_verifier': codeVerifier},
          );
      final data = response.data;
      if (data == null) throw StateError('OAuth exchange returned no tokens');
      final tokens = TokenResponse.fromJson(data);
      await login(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Verifies an email/password pair and stores the returned tokens.
  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final tokens = await ref
          .read(authServiceProvider)
          .loginApiAuthLoginPost(
            body: EmailLoginRequest(email: email, password: password),
          );
      await login(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Creates a passkey for the currently authenticated account.
  Future<void> registerPasskey() async {
    final authenticatedState = state;
    state = const AsyncLoading();
    try {
      final dio = ref.read(authenticatedDioProvider);
      final optionsResponse = await dio.post<Map<String, Object?>>(
        '/api/auth/passkeys/register/options',
      );
      final options = _parsePasskeyOptions(optionsResponse.data);
      final credential = await ref
          .read(passkeyAuthenticatorProvider)
          .register(RegisterRequestType.fromJson(options.publicKey));
      await dio.post<void>(
        '/api/auth/passkeys/register/verify',
        data: {
          'ceremony_id': options.ceremonyId,
          'credential': credential.toJson(),
        },
      );
      state = authenticatedState;
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Signs in using a native passkey associated with [email].
  Future<void> loginWithPasskey(String email) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(authenticatedDioProvider);
      final optionsResponse = await dio.post<Map<String, Object?>>(
        '/api/auth/passkeys/authenticate/options',
        data: {'email': email},
      );
      final options = _parsePasskeyOptions(optionsResponse.data);
      final credential = await ref
          .read(passkeyAuthenticatorProvider)
          .authenticate(AuthenticateRequestType.fromJson(options.publicKey));
      final verifyResponse = await dio.post<Map<String, Object?>>(
        '/api/auth/passkeys/authenticate/verify',
        data: {
          'ceremony_id': options.ceremonyId,
          'credential': credential.toJson(),
        },
      );
      final data = verifyResponse.data;
      if (data == null) {
        throw const FormatException('Passkey verification returned no tokens');
      }
      final tokens = TokenResponse.fromJson(data);
      await login(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Clears tokens and transitions to [Unauthenticated].
  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        final authService = ref.read(authServiceProvider);
        await authService.logoutApiAuthLogoutPost(
          body: RefreshTokenRequest(refreshToken: refreshToken),
        );
      }
    } on Exception {
      // Best-effort server-side logout; always clear local tokens.
    }
    await storage.clearTokens();
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// Immediately marks the session as unauthenticated without a server call.
  ///
  /// Called by [AuthInterceptor] when a token refresh fails.
  void forceUnauthenticated() {
    state = const AsyncData(AuthState.unauthenticated());
  }
}

/// Provider for the authentication state.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
