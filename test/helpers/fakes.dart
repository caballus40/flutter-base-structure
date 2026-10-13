import 'package:base_app/core/logging/app_logger.dart';
import 'package:base_app/core/storage/token_storage.dart';

/// In-memory tokens so tests can observe saves and clears.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async => access = refresh = null;
}

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void error(Object error, [StackTrace? stack, String? context]) {}
}
