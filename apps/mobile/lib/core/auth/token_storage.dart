import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key used to store the access token.
const _kAccessTokenKey = 'access_token';

/// Key used to store the refresh token.
const _kRefreshTokenKey = 'refresh_token';

/// {@template token_storage}
/// Secure storage for authentication tokens.
/// {@endtemplate}
class TokenStorage {
  /// {@macro token_storage}
  const TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Saves both tokens to secure storage.
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: _kAccessTokenKey, value: accessToken),
      _storage.write(key: _kRefreshTokenKey, value: refreshToken),
    ]);
  }

  /// Returns the stored access token, or null if not present.
  Future<String?> getAccessToken() => _storage.read(key: _kAccessTokenKey);

  /// Returns the stored refresh token, or null if not present.
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshTokenKey);

  /// Clears both tokens from secure storage.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessTokenKey),
      _storage.delete(key: _kRefreshTokenKey),
    ]);
  }
}

/// Riverpod provider for [TokenStorage].
final tokenStorageProvider = Provider<TokenStorage>(
  (_) => const TokenStorage(),
  name: 'tokenStorageProvider',
);
