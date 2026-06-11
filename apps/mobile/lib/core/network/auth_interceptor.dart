import 'package:dio/dio.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';

/// {@template auth_interceptor}
/// A Dio interceptor that injects an Authorization Bearer token on every
/// request and handles transparent token refresh on 401 responses.
///
/// When a refresh call itself fails the logout callback is invoked, allowing
/// the caller to redirect to the login screen without coupling this class to
/// go_router internals.
/// {@endtemplate}
class AuthInterceptor extends QueuedInterceptorsWrapper {
  /// {@macro auth_interceptor}
  AuthInterceptor({
    required this.tokenStorage,
    required this.authService,
    required this.onLogout,
    this.retryDio,
  });

  /// The token storage used to read and persist tokens.
  final TokenStorage tokenStorage;

  /// The authentication service used to refresh tokens.
  final AuthenticationService authService;

  /// Called when a refresh attempt fails and the session must be ended.
  final void Function() onLogout;

  /// An optional plain Dio instance used to retry the original request after a
  /// successful token refresh.  When provided this instance must NOT carry an
  /// [AuthInterceptor] to avoid infinite refresh loops.  Falls back to
  /// constructing a minimal Dio from the failing request's options.
  final Dio? retryDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      await tokenStorage.clearTokens();
      onLogout();
      handler.next(err);
      return;
    }

    try {
      final tokenResponse = await authService.refreshTokenApiAuthRefreshPost(
        body: RefreshTokenRequest(refreshToken: refreshToken),
      );

      await tokenStorage.saveTokens(
        tokenResponse.accessToken,
        tokenResponse.refreshToken,
      );

      // Retry the original request with the new access token.
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${tokenResponse.accessToken}';

      final dio =
          retryDio ??
          Dio(
            BaseOptions(
              baseUrl: err.requestOptions.baseUrl,
              connectTimeout: err.requestOptions.connectTimeout,
              receiveTimeout: err.requestOptions.receiveTimeout,
            ),
          );
      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException {
      await tokenStorage.clearTokens();
      onLogout();
      handler.next(err);
    }
  }
}
