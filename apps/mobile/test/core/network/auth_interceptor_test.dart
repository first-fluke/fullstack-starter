import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';
import 'package:mobile/core/network/api/models/token_response.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthenticationService extends Mock
    implements AuthenticationService {}

class _MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuthInterceptor _buildInterceptor({
  required _MockTokenStorage storage,
  required _MockAuthenticationService authService,
  required List<int> logoutCalls,
  Dio? retryDio,
}) {
  return AuthInterceptor(
    tokenStorage: storage,
    authService: authService,
    onLogout: () => logoutCalls.add(1),
    retryDio: retryDio,
  );
}

/// Drains the handler's internal future so the error completion produced by
/// `handler.next(err)` does not surface as an unhandled async error in the
/// test zone.
void _drain(ErrorInterceptorHandler handler) {
  unawaited(
    // Accessing the protected future is required to drain it in tests.
    // ignore: invalid_use_of_protected_member
    handler.future.then<void>((_) {}, onError: (_) {}),
  );
}

RequestOptions _opts({String path = '/test'}) {
  return RequestOptions(path: path, baseUrl: 'http://localhost');
}

DioException _dioError({
  required RequestOptions opts,
  int? statusCode,
}) {
  return DioException(
    requestOptions: opts,
    response: statusCode != null
        ? Response<dynamic>(requestOptions: opts, statusCode: statusCode)
        : null,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions());
    registerFallbackValue(
      const RefreshTokenRequest(refreshToken: 'fallback'),
    );
    registerFallbackValue(
      Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: 200,
      ),
    );
  });

  late _MockTokenStorage mockStorage;
  late _MockAuthenticationService mockAuthService;
  late List<int> logoutCalls;

  setUp(() {
    mockStorage = _MockTokenStorage();
    mockAuthService = _MockAuthenticationService();
    logoutCalls = [];
  });

  // -------------------------------------------------------------------------
  // onRequest – Bearer header injection
  // -------------------------------------------------------------------------
  group('onRequest', () {
    test('adds Authorization header when access token is present', () async {
      when(mockStorage.getAccessToken).thenAnswer((_) async => 'my_token');

      final interceptor = _buildInterceptor(
        storage: mockStorage,
        authService: mockAuthService,
        logoutCalls: logoutCalls,
      );

      final opts = _opts();
      final handler = RequestInterceptorHandler();
      await interceptor.onRequest(opts, handler);

      expect(opts.headers['Authorization'], equals('Bearer my_token'));
    });

    test('does not add Authorization header when no token is stored', () async {
      when(mockStorage.getAccessToken).thenAnswer((_) async => null);

      final interceptor = _buildInterceptor(
        storage: mockStorage,
        authService: mockAuthService,
        logoutCalls: logoutCalls,
      );

      final opts = _opts();
      final handler = RequestInterceptorHandler();
      await interceptor.onRequest(opts, handler);

      expect(opts.headers.containsKey('Authorization'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // onError – 401 → refresh → retry
  // -------------------------------------------------------------------------
  group('onError — 401 refresh', () {
    test('calls refresh and saves new tokens on successful refresh', () async {
      final mockRetryDio = _MockDio();
      final opts = _opts();

      when(mockStorage.getRefreshToken).thenAnswer((_) async => 'old_rt');
      when(
        () => mockAuthService.refreshTokenApiAuthRefreshPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'new_at',
          refreshToken: 'new_rt',
        ),
      );
      when(
        () => mockStorage.saveTokens('new_at', 'new_rt'),
      ).thenAnswer((_) async {});
      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer(
        (_) async => Response<dynamic>(requestOptions: opts, statusCode: 200),
      );

      final interceptor = _buildInterceptor(
        storage: mockStorage,
        authService: mockAuthService,
        logoutCalls: logoutCalls,
        retryDio: mockRetryDio,
      );

      final err = _dioError(opts: opts, statusCode: 401);
      final handler = ErrorInterceptorHandler();

      // onError completes only after handler.resolve has been invoked, so
      // awaiting it guarantees all side effects are done.
      await interceptor.onError(err, handler);

      verify(() => mockStorage.saveTokens('new_at', 'new_rt')).called(1);
      expect(logoutCalls, isEmpty);
    });

    test('clears tokens and calls onLogout when refresh throws', () async {
      when(mockStorage.getRefreshToken).thenAnswer((_) async => 'stale_rt');
      when(
        () => mockAuthService.refreshTokenApiAuthRefreshPost(
          body: any(named: 'body'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            statusCode: 401,
          ),
        ),
      );
      when(mockStorage.clearTokens).thenAnswer((_) async {});

      final interceptor = _buildInterceptor(
        storage: mockStorage,
        authService: mockAuthService,
        logoutCalls: logoutCalls,
      );

      final opts = _opts();
      final err = _dioError(opts: opts, statusCode: 401);
      final handler = ErrorInterceptorHandler();
      _drain(handler);

      await interceptor.onError(err, handler);

      verify(mockStorage.clearTokens).called(1);
      expect(logoutCalls, isNotEmpty);
    });

    test(
      'clears tokens and calls onLogout when no refresh token is stored',
      () async {
        when(mockStorage.getRefreshToken).thenAnswer((_) async => null);
        when(mockStorage.clearTokens).thenAnswer((_) async {});

        final interceptor = _buildInterceptor(
          storage: mockStorage,
          authService: mockAuthService,
          logoutCalls: logoutCalls,
        );

        final opts = _opts();
        final err = _dioError(opts: opts, statusCode: 401);
        final handler = ErrorInterceptorHandler();
        _drain(handler);

        await interceptor.onError(err, handler);

        verify(mockStorage.clearTokens).called(1);
        expect(logoutCalls, isNotEmpty);
      },
    );

    test('passes non-401 errors through without touching tokens', () async {
      final interceptor = _buildInterceptor(
        storage: mockStorage,
        authService: mockAuthService,
        logoutCalls: logoutCalls,
      );

      final opts = _opts();
      final err = _dioError(opts: opts, statusCode: 500);
      final handler = ErrorInterceptorHandler();
      _drain(handler);

      await interceptor.onError(err, handler);

      verifyNever(mockStorage.getRefreshToken);
      expect(logoutCalls, isEmpty);
    });
  });
}
