import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/auth_state.dart';

void main() {
  group('AuthState.toString — credential redaction', () {
    test('Authenticated.toString does not contain accessToken value', () {
      const state = AuthState.authenticated(
        accessToken: 'super_secret_access_token',
        refreshToken: 'super_secret_refresh_token',
      );

      final result = state.toString();

      expect(result, isNot(contains('super_secret_access_token')));
      expect(result, isNot(contains('super_secret_refresh_token')));
    });

    test('Authenticated.toString contains [REDACTED] sentinel', () {
      const state = AuthState.authenticated(
        accessToken: 'at',
        refreshToken: 'rt',
      );

      expect(state.toString(), contains('[REDACTED]'));
    });

    test('Unauthenticated.toString does not expose any sensitive data', () {
      const state = AuthState.unauthenticated();

      final result = state.toString();

      expect(result, equals('AuthState.unauthenticated()'));
    });
  });
}
