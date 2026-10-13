import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/domain/item.dart';
import 'package:base_app/features/items/domain/items_repository.dart';
import 'package:base_app/features/items/presentation/cubit/items_cubit.dart';
import 'package:base_app/features/items/presentation/cubit/items_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItemsRepository extends Mock implements ItemsRepository {}

List<Item> _page(int start, int count) => [
  for (var i = start; i < start + count; i++) Item(id: '$i', title: 'Item $i'),
];

void main() {
  late _MockItemsRepository repo;
  const failure = Failure(FailureType.network);
  const size = ItemsCubit.pageSize;

  setUp(() => repo = _MockItemsRepository());

  void stubPage(int page, Result<List<Item>> result) => when(
    () => repo.fetchPage(page: page, limit: size),
  ).thenAnswer((_) async => result);

  final fullPage = _page(0, size);

  blocTest<ItemsCubit, ItemsState>(
    'load success',
    setUp: () => stubPage(1, Ok(fullPage)),
    build: () => ItemsCubit(repo),
    act: (c) => c.load(),
    expect: () => [
      const ItemsState(status: ItemsStatus.loading),
      ItemsState(status: ItemsStatus.success, items: fullPage, page: 1),
    ],
  );

  blocTest<ItemsCubit, ItemsState>(
    'load failure with no data shows failure status',
    setUp: () => stubPage(1, const Err(failure)),
    build: () => ItemsCubit(repo),
    act: (c) => c.load(),
    expect: () => [
      const ItemsState(status: ItemsStatus.loading),
      const ItemsState(status: ItemsStatus.failure, failure: failure),
    ],
  );

  blocTest<ItemsCubit, ItemsState>(
    'refresh failure keeps existing items',
    setUp: () => stubPage(1, const Err(failure)),
    build: () => ItemsCubit(repo),
    seed: () =>
        ItemsState(status: ItemsStatus.success, items: fullPage, page: 1),
    act: (c) => c.load(),
    expect: () => [
      ItemsState(
        status: ItemsStatus.success,
        items: fullPage,
        page: 1,
        failure: failure,
      ),
    ],
  );

  blocTest<ItemsCubit, ItemsState>(
    'loadMore appends and detects last page',
    setUp: () => stubPage(2, Ok(_page(size, 5))),
    build: () => ItemsCubit(repo),
    seed: () =>
        ItemsState(status: ItemsStatus.success, items: fullPage, page: 1),
    act: (c) => c.loadMore(),
    expect: () => [
      ItemsState(
        status: ItemsStatus.success,
        items: fullPage,
        page: 1,
        isLoadingMore: true,
      ),
      ItemsState(
        status: ItemsStatus.success,
        items: _page(0, size + 5),
        page: 2,
        hasMore: false,
      ),
    ],
  );

  blocTest<ItemsCubit, ItemsState>(
    'loadMore is ignored when no more pages',
    build: () => ItemsCubit(repo),
    seed: () => ItemsState(
      status: ItemsStatus.success,
      items: fullPage,
      hasMore: false,
    ),
    act: (c) => c.loadMore(),
    expect: () => <ItemsState>[],
    verify: (_) => verifyNever(
      () => repo.fetchPage(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ),
  );
}
