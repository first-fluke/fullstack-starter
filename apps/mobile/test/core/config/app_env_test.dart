import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_env.dart';

void main() {
  group('resolveBaseUrl', () {
    group('dev environment', () {
      test('returns localhost default when define is empty', () {
        expect(
          resolveBaseUrl(AppEnv.dev, ''),
          equals('http://localhost:8000'),
        );
      });

      test('returns provided URL when define is non-empty', () {
        expect(
          resolveBaseUrl(AppEnv.dev, 'http://192.168.1.10:8000'),
          equals('http://192.168.1.10:8000'),
        );
      });
    });

    group('staging environment', () {
      test('returns provided URL when define is non-empty', () {
        expect(
          resolveBaseUrl(AppEnv.staging, 'https://staging.api.example.com'),
          equals('https://staging.api.example.com'),
        );
      });

      test('throws StateError when define is empty', () {
        expect(
          () => resolveBaseUrl(AppEnv.staging, ''),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('APP_BASE_URL dart-define must be set'),
            ),
          ),
        );
      });
    });

    group('prod environment', () {
      test('returns provided URL when define is non-empty', () {
        expect(
          resolveBaseUrl(AppEnv.prod, 'https://api.example.com'),
          equals('https://api.example.com'),
        );
      });

      test('throws StateError when define is empty', () {
        expect(
          () => resolveBaseUrl(AppEnv.prod, ''),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('APP_BASE_URL dart-define must be set'),
            ),
          ),
        );
      });
    });
  });
}
