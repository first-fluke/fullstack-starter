import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/config/app_env.dart';
import 'package:mobile/core/network/api/api_client.dart' as generated;
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';
import 'package:mobile/core/network/auth_interceptor.dart';

// Re-export tokenStorageProvider so callers can import from one place.
export 'token_storage.dart' show tokenStorageProvider;

/// Provides the Dio instance shared by the generated [generated.ApiClient].
///
/// Adds [AuthInterceptor] so every request automatically carries a Bearer
/// token and handles transparent refresh on 401 responses.  When refresh
/// fails the [AuthInterceptor] calls [TokenStorage.clearTokens] and invokes
/// the `onLogout` callback — wired here to [authStateProvider]'s logout()
/// so the notifier stays decoupled from go_router internals.
final _authenticatedDioProvider = Provider<Dio>((ref) {
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
  final dio = ref.watch(_authenticatedDioProvider);
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
