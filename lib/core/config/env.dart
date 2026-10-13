enum AppEnv { dev, stg, prod }

/// Compile-time configuration, loaded with
/// `--dart-define-from-file=env/<name>.json`. Never put secrets here.
abstract final class Env {
  static const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static final current = AppEnv.values.asNameMap()[_appEnv] ?? AppEnv.dev;

  static bool get isProd => current == AppEnv.prod;

  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://dev.api.example.com',
  );
}
