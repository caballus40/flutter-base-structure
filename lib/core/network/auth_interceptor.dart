import 'package:base_app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum _Refresh { ok, rejected, unavailable }

/// Attaches the access token and transparently refreshes it on 401.
///
/// [QueuedInterceptor] handles errors one at a time, so when several requests
/// fail together only the first refreshes; the rest see the new token and
/// just retry.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required VoidCallback onUnauthorized,
  }) : _dio = dio,
       _tokens = tokenStorage,
       _onUnauthorized = onUnauthorized;

  static const refreshPath = '/auth/refresh';
  static const _header = 'Authorization';

  final Dio _dio;
  final TokenStorage _tokens;
  final VoidCallback _onUnauthorized;

  /// Interceptor-free client for refresh + retry. Retrying through [_dio]
  /// would deadlock: a second 401 would queue behind the one being handled.
  late final Dio _plain = Dio(_dio.options)
    ..httpClientAdapter = _dio.httpClientAdapter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.readAccess();
    if (token != null) options.headers[_header] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sent = request.headers[_header];
    // A 401 without a token (e.g. wrong password on login) is not a session issue.
    if (err.response?.statusCode != 401 || sent == null) {
      handler.next(err);
      return;
    }

    final current = await _tokens.readAccess();
    if (current == null) {
      // Session already ended by an earlier request in the queue.
      handler.next(err);
      return;
    }
    if (sent == 'Bearer $current') {
      switch (await _refresh()) {
        case (_Refresh.ok, _):
          break;
        case (_Refresh.rejected, _):
          await _tokens.clear();
          _onUnauthorized();
          handler.next(err);
          return;
        case (_Refresh.unavailable, final DioException? cause):
          // Offline/server down: keep the session, surface the real cause.
          handler.next(cause ?? err);
          return;
      }
    }
    await _retry(request, handler);
  }

  Future<(_Refresh, DioException?)> _refresh() async {
    final refreshToken = await _tokens.readRefresh();
    if (refreshToken == null) return (_Refresh.rejected, null);
    try {
      final res = await _plain.post<Object?>(
        refreshPath,
        data: {'refreshToken': refreshToken},
      );
      if (res.data case {
        'token': final String access,
        'refreshToken': final String refresh,
      }) {
        await _tokens.save(access: access, refresh: refresh);
        return (_Refresh.ok, null);
      }
      return (_Refresh.rejected, null);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final rejected = status >= 400 && status < 500;
      return (rejected ? _Refresh.rejected : _Refresh.unavailable, e);
    }
  }

  Future<void> _retry(
    RequestOptions request,
    ErrorInterceptorHandler handler,
  ) async {
    request.headers[_header] = 'Bearer ${await _tokens.readAccess()}';
    try {
      handler.resolve(await _plain.fetch<Object?>(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
