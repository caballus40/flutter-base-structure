import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the session tokens securely and caches them in memory so the
/// auth interceptor doesn't hit the platform channel on every request.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  String? _access;
  String? _refresh;
  bool _loaded = false;

  Future<String?> readAccess() async {
    await _load();
    return _access;
  }

  Future<String?> readRefresh() async {
    await _load();
    return _refresh;
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    _loaded = true;
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }

  Future<void> _load() async {
    if (_loaded) return;
    _access = await _storage.read(key: _accessKey);
    _refresh = await _storage.read(key: _refreshKey);
    _loaded = true;
  }
}
