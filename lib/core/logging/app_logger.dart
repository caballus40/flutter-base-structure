import 'package:flutter/foundation.dart';

/// Vendor-agnostic logging. To add Sentry/Crashlytics, implement this
/// interface and swap it in `main.dart`; nothing else changes.
abstract interface class AppLogger {
  void debug(String message);
  void info(String message);
  void error(Object error, [StackTrace? stack, String? context]);
}

/// Console logger. `debug`/`info` are silent in release builds.
final class DebugLogger implements AppLogger {
  const DebugLogger();

  @override
  void debug(String message) {
    if (kDebugMode) debugPrint('[D] $message');
  }

  @override
  void info(String message) {
    if (kDebugMode) debugPrint('[I] $message');
  }

  @override
  void error(Object error, [StackTrace? stack, String? context]) {
    debugPrint('[E] ${context ?? 'error'}: $error');
    if (stack != null) debugPrint('$stack');
  }
}
