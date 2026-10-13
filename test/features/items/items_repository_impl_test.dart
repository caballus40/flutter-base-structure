import 'package:base_app/core/network/api_client.dart';
import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/data/items_repository_impl.dart';
import 'package:base_app/features/items/domain/item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/fakes.dart';

void main() {
  late MemoryTokenStorage tokens;
  late int unauthorizedCalls;

  setUp(() {
    tokens = MemoryTokenStorage(access: 'token');
    unauthorizedCalls = 0;
  });

  ItemsRepositoryImpl build((int, Object?) Function(String path) respond) {
    final dio = createDio('https://test.local')
      ..httpClientAdapter = FakeAdapter((o) => respond(o.path));
    return ItemsRepositoryImpl(
      ApiClient(
        dio,
        tokenStorage: tokens,
        onUnauthorized: () => unauthorizedCalls++,
        logger: const SilentLogger(),
      ),
    );
  }

  test('parses a page of items', () async {
    final repo = build(
      (_) => (
        200,
        [
          {'id': 1, 'title': 'A', 'description': 'first'},
          {'id': '2', 'title': 'B'},
        ],
      ),
    );

    final result = await repo.fetchPage(page: 1, limit: 20);

    expect(result, isA<Ok<List<Item>>>());
    expect((result as Ok<List<Item>>).value, const [
      Item(id: '1', title: 'A', description: 'first'),
      Item(id: '2', title: 'B'),
    ]);
  });

  test('maps 5xx to server failure', () async {
    final result = await build(
      (_) => (500, null),
    ).fetchPage(page: 1, limit: 20);
    expect((result as Err<List<Item>>).failure.type, FailureType.server);
  });

  test('uses server message on 4xx', () async {
    final result = await build(
      (_) => (422, {'message': 'Bad page'}),
    ).fetchPage(page: 1, limit: 20);
    expect(
      (result as Err<List<Item>>).failure,
      const Failure(FailureType.badRequest, 'Bad page'),
    );
  });

  test('malformed payload becomes unknown failure, not a crash', () async {
    final result = await build(
      (_) => (200, {'not': 'a list'}),
    ).fetchPage(page: 1, limit: 20);
    expect((result as Err<List<Item>>).failure.type, FailureType.unknown);
  });

  test('401 on authenticated request triggers onUnauthorized', () async {
    final result = await build(
      (_) => (401, null),
    ).fetchPage(page: 1, limit: 20);
    expect((result as Err<List<Item>>).failure.type, FailureType.unauthorized);
    expect(unauthorizedCalls, 1);
  });
}
