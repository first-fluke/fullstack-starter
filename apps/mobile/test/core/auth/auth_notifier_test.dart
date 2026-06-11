import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/providers.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/network/api/clients/authentication_service.dart';
import 'package:mobile/core/network/api/models/refresh_token_request.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthenticationService extends Mock
    implements AuthenticationService {}

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

  return (
    container: container,
    storage: storage,
    authService: authService,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(
      const RefreshTokenRequest(refreshToken: 'fallback'),
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
  });
}
