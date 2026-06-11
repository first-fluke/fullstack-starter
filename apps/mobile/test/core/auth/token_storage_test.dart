import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = _MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);
  });

  group('TokenStorage', () {
    group('saveTokens', () {
      test('writes access token and refresh token to secure storage', () async {
        when(
          () => mockStorage.write(key: 'access_token', value: 'at'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(key: 'refresh_token', value: 'rt'),
        ).thenAnswer((_) async {});

        await tokenStorage.saveTokens('at', 'rt');

        verify(
          () => mockStorage.write(key: 'access_token', value: 'at'),
        ).called(1);
        verify(
          () => mockStorage.write(key: 'refresh_token', value: 'rt'),
        ).called(1);
      });
    });

    group('getAccessToken', () {
      test('returns the stored access token', () async {
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => 'stored_at');

        final result = await tokenStorage.getAccessToken();

        expect(result, equals('stored_at'));
      });

      test('returns null when no token is stored', () async {
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => null);

        final result = await tokenStorage.getAccessToken();

        expect(result, isNull);
      });
    });

    group('getRefreshToken', () {
      test('returns the stored refresh token', () async {
        when(
          () => mockStorage.read(key: 'refresh_token'),
        ).thenAnswer((_) async => 'stored_rt');

        final result = await tokenStorage.getRefreshToken();

        expect(result, equals('stored_rt'));
      });
    });

    group('clearTokens', () {
      test('deletes both tokens from secure storage', () async {
        when(
          () => mockStorage.delete(key: 'access_token'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.delete(key: 'refresh_token'),
        ).thenAnswer((_) async {});

        await tokenStorage.clearTokens();

        verify(
          () => mockStorage.delete(key: 'access_token'),
        ).called(1);
        verify(
          () => mockStorage.delete(key: 'refresh_token'),
        ).called(1);
      });
    });
  });
}
