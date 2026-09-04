import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/providers.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthenticationService extends Mock
    implements AuthenticationService {}

class _MockDio extends Mock implements Dio {}

class _MockPasskeyAuthenticator extends Mock implements PasskeyAuthenticator {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [ProviderContainer] with the token storage and auth service
/// overridden by mocks, and returns both the container and the mocks.
({
  ProviderContainer container,
  _MockTokenStorage storage,
  _MockAuthenticationService authService,
})
_buildContainer() {
  final storage = _MockTokenStorage();
  final authService = _MockAuthenticationService();

  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authServiceProvider.overrideWithValue(authService),
    ],
  );

  return (container: container, storage: storage, authService: authService);
}

({
  ProviderContainer container,
  _MockTokenStorage storage,
  _MockDio dio,
  _MockPasskeyAuthenticator passkeys,
})
_buildPasskeyContainer() {
  final storage = _MockTokenStorage();
  final dio = _MockDio();
  final passkeys = _MockPasskeyAuthenticator();
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authenticatedDioProvider.overrideWithValue(dio),
      passkeyAuthenticatorProvider.overrideWithValue(passkeys),
    ],
  );
  return (
    container: container,
    storage: storage,
    dio: dio,
    passkeys: passkeys,
  );
}

Map<String, Object?> _registrationOptions() => {
  'ceremony_id': 'registration-ceremony-id-000000000000',
  'public_key': <String, dynamic>{
    'challenge': 'AQID',
    'rp': {'id': 'example.com', 'name': 'Fullstack Starter'},
    'user': {
      'id': 'dXNlcg',
      'name': 'user@example.com',
      'displayName': 'User',
    },
    'excludeCredentials': <Object?>[],
    'pubKeyCredParams': [
      {'type': 'public-key', 'alg': -7},
    ],
    'authenticatorSelection': {
      'requireResidentKey': false,
      'residentKey': 'preferred',
      'userVerification': 'required',
    },
    'attestation': 'none',
  },
};

Map<String, Object?> _authenticationOptions() => {
  'ceremony_id': 'authentication-ceremony-id-0000000000',
  'public_key': <String, dynamic>{
    'challenge': 'AQID',
    'rpId': 'example.com',
    'allowCredentials': [
      {'type': 'public-key', 'id': 'Y3JlZA', 'transports': <String>[]},
    ],
    'userVerification': 'required',
  },
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(const RefreshTokenRequest(refreshToken: 'fallback'));
    registerFallbackValue(
      RegisterRequestType.fromJson(
        _registrationOptions()['public_key']! as Map<String, dynamic>,
      ),
    );
    registerFallbackValue(
      AuthenticateRequestType.fromJson(
        _authenticationOptions()['public_key']! as Map<String, dynamic>,
      ),
    );
  });

  group('AuthNotifier', () {
    group('build — session restoration', () {
      test(
        'restores Authenticated state when tokens exist in storage',
        () async {
          final (:container, :storage, authService: _) = _buildContainer();
          addTearDown(container.dispose);

          when(storage.getAccessToken).thenAnswer((_) async => 'at');
          when(storage.getRefreshToken).thenAnswer((_) async => 'rt');

          final state = await container.read(authStateProvider.future);

          expect(state, isA<Authenticated>());
          final auth = state as Authenticated;
          expect(auth.accessToken, equals('at'));
          expect(auth.refreshToken, equals('rt'));
        },
      );

      test('resolves to Unauthenticated when no tokens are stored', () async {
        final (:container, :storage, authService: _) = _buildContainer();
        addTearDown(container.dispose);

        when(storage.getAccessToken).thenAnswer((_) async => null);
        when(storage.getRefreshToken).thenAnswer((_) async => null);

        final state = await container.read(authStateProvider.future);

        expect(state, isA<Unauthenticated>());
      });
    });

    group('login', () {
      test('saves tokens and transitions to Authenticated', () async {
        final (:container, :storage, authService: _) = _buildContainer();
        addTearDown(container.dispose);

        // Initial state: unauthenticated.
        when(storage.getAccessToken).thenAnswer((_) async => null);
        when(storage.getRefreshToken).thenAnswer((_) async => null);
        when(
          () => storage.saveTokens('new_at', 'new_rt'),
        ).thenAnswer((_) async {});

        // Await build.
        await container.read(authStateProvider.future);

        // Perform login.
        await container
            .read(authStateProvider.notifier)
            .login(accessToken: 'new_at', refreshToken: 'new_rt');

        verify(() => storage.saveTokens('new_at', 'new_rt')).called(1);

        final state = container.read(authStateProvider).value;
        expect(state, isA<Authenticated>());
        final auth = state! as Authenticated;
        expect(auth.accessToken, equals('new_at'));
      });
    });

    group('logout', () {
      test('clears tokens and transitions to Unauthenticated', () async {
        final (:container, :storage, :authService) = _buildContainer();
        addTearDown(container.dispose);

        // Initial state: authenticated.
        when(storage.getAccessToken).thenAnswer((_) async => 'at');
        when(storage.getRefreshToken).thenAnswer((_) async => 'rt');
        when(
          () => authService.logoutApiAuthLogoutPost(body: any(named: 'body')),
        ).thenAnswer((_) async {});
        when(storage.clearTokens).thenAnswer((_) async {});

        await container.read(authStateProvider.future);

        await container.read(authStateProvider.notifier).logout();

        verify(storage.clearTokens).called(1);

        final state = container.read(authStateProvider).value;
        expect(state, isA<Unauthenticated>());
      });

      test('clears tokens even when server logout call throws', () async {
        final (:container, :storage, :authService) = _buildContainer();
        addTearDown(container.dispose);

        when(storage.getAccessToken).thenAnswer((_) async => 'at');
        when(storage.getRefreshToken).thenAnswer((_) async => 'rt');
        when(
          () => authService.logoutApiAuthLogoutPost(body: any(named: 'body')),
        ).thenThrow(Exception('network error'));
        when(storage.clearTokens).thenAnswer((_) async {});

        await container.read(authStateProvider.future);

        await container.read(authStateProvider.notifier).logout();

        verify(storage.clearTokens).called(1);
        final state = container.read(authStateProvider).value;
        expect(state, isA<Unauthenticated>());
      });
    });

    group('passkeys', () {
      test(
        'registers a native passkey for the authenticated account',
        () async {
          final (:container, :storage, :dio, :passkeys) =
              _buildPasskeyContainer();
          addTearDown(container.dispose);

          when(storage.getAccessToken).thenAnswer((_) async => 'at');
          when(storage.getRefreshToken).thenAnswer((_) async => 'rt');
          when(
            () => dio.post<Map<String, Object?>>(
              '/api/auth/passkeys/register/options',
            ),
          ).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(),
              data: _registrationOptions(),
            ),
          );
          when(() => passkeys.register(any())).thenAnswer(
            (_) async => const RegisterResponseType(
              id: 'credential-id',
              rawId: 'credential-id',
              clientDataJSON: 'client-data',
              attestationObject: 'attestation',
              transports: ['internal'],
            ),
          );
          when(
            () => dio.post<void>(
              '/api/auth/passkeys/register/verify',
              data: any(named: 'data'),
            ),
          ).thenAnswer(
            (_) async => Response<void>(requestOptions: RequestOptions()),
          );

          await container.read(authStateProvider.future);
          await container.read(authStateProvider.notifier).registerPasskey();

          verify(() => passkeys.register(any())).called(1);
          verify(
            () => dio.post<void>(
              '/api/auth/passkeys/register/verify',
              data: any(named: 'data'),
            ),
          ).called(1);
          expect(container.read(authStateProvider).value, isA<Authenticated>());
        },
      );

      test('authenticates with a native passkey and stores tokens', () async {
        final (:container, :storage, :dio, :passkeys) =
            _buildPasskeyContainer();
        addTearDown(container.dispose);

        when(storage.getAccessToken).thenAnswer((_) async => null);
        when(storage.getRefreshToken).thenAnswer((_) async => null);
        when(
          () => storage.saveTokens('passkey-at', 'passkey-rt'),
        ).thenAnswer((_) async {});
        when(
          () => dio.post<Map<String, Object?>>(
            '/api/auth/passkeys/authenticate/options',
            data: {'email': 'user@example.com'},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: _authenticationOptions(),
          ),
        );
        when(() => passkeys.authenticate(any())).thenAnswer(
          (_) async => const AuthenticateResponseType(
            id: 'credential-id',
            rawId: 'credential-id',
            clientDataJSON: 'client-data',
            authenticatorData: 'authenticator-data',
            signature: 'signature',
            userHandle: 'user-handle',
          ),
        );
        when(
          () => dio.post<Map<String, Object?>>(
            '/api/auth/passkeys/authenticate/verify',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'access_token': 'passkey-at',
              'refresh_token': 'passkey-rt',
              'token_type': 'bearer',
            },
          ),
        );

        await container.read(authStateProvider.future);
        await container
            .read(authStateProvider.notifier)
            .loginWithPasskey('user@example.com');

        verify(() => passkeys.authenticate(any())).called(1);
        verify(() => storage.saveTokens('passkey-at', 'passkey-rt')).called(1);
        expect(container.read(authStateProvider).value, isA<Authenticated>());
      });
    });
  });
}
