import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/providers.dart';

void main() {
  test('builds a backend OAuth authorization URL with the mobile callback', () {
    const challenge = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';
    final uri = buildOAuthAuthorizationUri(
      'https://api.example.com',
      OAuthProvider.google,
      codeChallenge: challenge,
    );

    expect(uri.path, '/api/auth/oauth/google/authorize');
    expect(
      uri.queryParameters['redirect_uri'],
      'fullstackstarter://auth/callback',
    );
    expect(uri.queryParameters['return_to'], '/');
    expect(uri.queryParameters['code_challenge'], challenge);
    expect(uri.queryParameters['code_challenge_method'], 'S256');
  });
}
