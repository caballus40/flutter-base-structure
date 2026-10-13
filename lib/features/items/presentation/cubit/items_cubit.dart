import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/domain/items_repository.dart';
import 'package:base_app/features/items/presentation/cubit/items_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemsCubit extends Cubit<ItemsState> {
  ItemsCubit(this._repository) : super(const ItemsState());

  static const pageSize = 20;

  final ItemsRepository _repository;

  /// Loads the first page. Also used for pull-to-refresh: existing items stay
  /// on screen while refreshing, and a failed refresh keeps them.
  Future<void> load() async {
    if (state.items.isEmpty) emit(state.copyWith(status: ItemsStatus.loading));
    final result = await _repository.fetchPage(page: 1, limit: pageSize);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          ItemsState(
            status: ItemsStatus.success,
            items: value,
            page: 1,
            hasMore: value.length == pageSize,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            status: state.items.isEmpty
                ? ItemsStatus.failure
                : ItemsStatus.success,
            failure: failure,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status != ItemsStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    final result = await _repository.fetchPage(
      page: state.page + 1,
      limit: pageSize,
    );
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            items: [...state.items, ...value],
            page: state.page + 1,
            hasMore: value.length == pageSize,
            isLoadingMore: false,
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(isLoadingMore: false, failure: failure));
    }
  }
}
