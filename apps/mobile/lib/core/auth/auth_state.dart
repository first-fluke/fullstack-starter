import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// {@template auth_state}
/// Sealed union representing the authentication state of the application.
/// {@endtemplate}
@freezed
sealed class AuthState with _$AuthState {
  // Private constructor required to add custom members to a freezed class.
  const AuthState._();

  /// The user is authenticated and tokens are available.
  const factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
  }) = Authenticated;

  /// The user is not authenticated.
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// Returns a redacted string to prevent credentials leaking into logs or
  /// crash reports.
  @override
  String toString() {
    return switch (this) {
      Authenticated() => 'AuthState.authenticated(tokens: [REDACTED])',
      Unauthenticated() => 'AuthState.unauthenticated()',
    };
  }
}
