import 'package:base_app/core/logging/app_logger.dart';
import 'package:base_app/core/network/auth_interceptor.dart';
import 'package:base_app/core/result/result.dart';
import 'package:base_app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createDio(String baseUrl) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  ),
);

/// Single gateway to the backend. Every exception is converted to a [Failure]
/// here, so no layer above ever sees a [DioException].
class ApiClient {
  ApiClient(
    this._dio, {
    required TokenStorage tokenStorage,
    required VoidCallback onUnauthorized,
    required AppLogger logger,
  }) : _logger = logger {
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        tokenStorage: tokenStorage,
        onUnauthorized: onUnauthorized,
      ),
    );
    if (kDebugMode) {
      // Headers stay out of logs: they carry the bearer token.
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          logPrint: (o) => logger.debug('$o'),
        ),
      );
    }
  }

  final Dio _dio;
  final AppLogger _logger;

  Future<Result<T>> get<T>(
    String path, {
    required T Function(Object? data) parse,
    Map<String, Object?>? query,
  }) => _send(() => _dio.get<Object?>(path, queryParameters: query), parse);

  Future<Result<T>> post<T>(
    String path, {
    required T Function(Object? data) parse,
    Object? body,
  }) => _send(() => _dio.post<Object?>(path, data: body), parse);

  Future<Result<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? data) parse,
  ) async {
    try {
      final response = await request();
      return Ok(parse(response.data));
    } on DioException catch (e) {
      return Err(_toFailure(e));
    } on Object catch (e, st) {
      // Parsing errors (TypeError, FormatException) from unexpected payloads.
      _logger.error(e, st, 'ApiClient parse');
      return const Err(Failure(FailureType.unknown));
    }
  }

  static Failure _toFailure(DioException e) {
    final serverMessage = switch (e.response?.data) {
      {'message': final String m} => m,
      _ => null,
    };
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const Failure(FailureType.network),
      DioExceptionType.badResponse => Failure(switch (e.response?.statusCode ??
          0) {
        401 || 403 => FailureType.unauthorized,
        >= 500 => FailureType.server,
        _ => FailureType.badRequest,
      }, serverMessage),
      _ => const Failure(FailureType.unknown),
    };
  }
}
