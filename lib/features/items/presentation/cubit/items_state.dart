import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/domain/item.dart';
import 'package:equatable/equatable.dart';

enum ItemsStatus { initial, loading, success, failure }

/// A paginated list accumulates data across states, so it uses one immutable
/// class + status instead of a sealed hierarchy.
final class ItemsState extends Equatable {
  const ItemsState({
    this.status = ItemsStatus.initial,
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
  });

  final ItemsStatus status;
  final List<Item> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Last error. Cleared by any [copyWith] that doesn't pass it.
  final Failure? failure;

  ItemsState copyWith({
    ItemsStatus? status,
    List<Item>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
  }) => ItemsState(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasMore,
    isLoadingMore,
    failure,
  ];
}
