import 'package:base_app/core/network/api_client.dart';
import 'package:base_app/core/network/auth_interceptor.dart';
import 'package:base_app/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/fakes.dart';

void main() {
  late MemoryTokenStorage tokens;
  late int refreshCalls;
  late int unauthorizedCalls;

  setUp(() {
    tokens = MemoryTokenStorage(access: 'old', refresh: 'r1');
    refreshCalls = 0;
    unauthorizedCalls = 0;
  });

  /// Protected endpoints accept only `Bearer new`; [onRefresh] answers refresh.
  ApiClient build((int, Object?) Function() onRefresh) {
    final dio = createDio('https://test.local')
      ..httpClientAdapter = FakeAdapter((o) {
        if (o.path == AuthInterceptor.refreshPath) {
          refreshCalls++;
          return onRefresh();
        }
        return o.headers['Authorization'] == 'Bearer new'
            ? (200, {'ok': true})
            : (401, null);
      });
    return ApiClient(
      dio,
      tokenStorage: tokens,
      onUnauthorized: () => unauthorizedCalls++,
      logger: const SilentLogger(),
    );
  }

  Future<Result<Object?>> call(ApiClient api) =>
      api.get('/protected', parse: (d) => d);

  (int, Object?) refreshOk() => (200, {'token': 'new', 'refreshToken': 'r2'});

  test('expired token is refreshed and the request retried', () async {
    final result = await call(build(refreshOk));

    expect(result, isA<Ok<Object?>>());
    expect(refreshCalls, 1);
    expect((tokens.access, tokens.refresh), ('new', 'r2'));
    expect(unauthorizedCalls, 0);
  });

  test('concurrent 401s trigger a single refresh', () async {
    final api = build(refreshOk);

    final results = await Future.wait([call(api), call(api), call(api)]);

    expect(results, everyElement(isA<Ok<Object?>>()));
    expect(refreshCalls, 1);
  });

  test('rejected refresh clears the session and signs out once', () async {
    final result = await call(build(() => (401, null)));

    expect((result as Err<Object?>).failure.type, FailureType.unauthorized);
    expect((tokens.access, tokens.refresh), (null, null));
    expect(unauthorizedCalls, 1);
  });

  test('unreachable refresh keeps the session', () async {
    final result = await call(build(() => (503, null)));

    expect((result as Err<Object?>).failure.type, FailureType.server);
    expect(tokens.access, 'old');
    expect(unauthorizedCalls, 0);
  });

  test('401 without a token (bad login) does not refresh', () async {
    tokens = MemoryTokenStorage();
    final result = await call(build(refreshOk));

    expect((result as Err<Object?>).failure.type, FailureType.unauthorized);
    expect(refreshCalls, 0);
    expect(unauthorizedCalls, 0);
  });

  test('ignores unrelated errors', () async {
    final dio = createDio('https://test.local')
      ..httpClientAdapter = FakeAdapter((_) => (404, {'message': 'Nope'}));
    final api = ApiClient(
      dio,
      tokenStorage: tokens,
      onUnauthorized: () => unauthorizedCalls++,
      logger: const SilentLogger(),
    );

    final result = await call(api);

    expect(
      (result as Err<Object?>).failure,
      const Failure(FailureType.badRequest, 'Nope'),
    );
    expect(refreshCalls, 0);
  });
}
