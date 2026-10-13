import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers Dio requests in-memory so tests exercise the real ApiClient.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final (int status, Object? body) Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
