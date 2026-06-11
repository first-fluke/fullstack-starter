/// {@template app_env}
/// Application environment configuration.
/// {@endtemplate}
enum AppEnv {
  /// Development environment.
  dev,

  /// Staging environment.
  staging,

  /// Production environment.
  prod;

  /// The current application environment, resolved from the APP_ENV
  /// dart-define (defaults to `'dev'`).
  static AppEnv get current {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    return switch (env) {
      'staging' => AppEnv.staging,
      'prod' => AppEnv.prod,
      _ => AppEnv.dev,
    };
  }

  /// The base URL for this environment.
  ///
  /// Throws a [StateError] when [AppEnv.staging] or [AppEnv.prod] is active
  /// but the `APP_BASE_URL` dart-define is not provided (empty string).
  String get baseUrl => resolveBaseUrl(
    this,
    const String.fromEnvironment('APP_BASE_URL'),
  );
}

/// Resolves the base URL for [env] given the [defineValue] from the
/// `APP_BASE_URL` dart-define.
///
/// Extracted as a pure function so it can be tested without dart-define
/// overrides.
///
/// Throws a [StateError] for [AppEnv.staging] / [AppEnv.prod] when
/// [defineValue] is empty.
String resolveBaseUrl(AppEnv env, String defineValue) {
  return switch (env) {
    AppEnv.dev =>
      defineValue.isNotEmpty ? defineValue : 'http://localhost:8000',
    AppEnv.staging || AppEnv.prod =>
      defineValue.isNotEmpty
          ? defineValue
          : throw StateError(
              'APP_BASE_URL dart-define must be set for ${env.name} '
              'environment. Pass --dart-define=APP_BASE_URL=<url> '
              'when building.',
            ),
  };
}
