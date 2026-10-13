import 'package:base_app/core/network/api_client.dart';
import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/data/models/item_dto.dart';
import 'package:base_app/features/items/domain/item.dart';
import 'package:base_app/features/items/domain/items_repository.dart';

final class ItemsRepositoryImpl implements ItemsRepository {
  ItemsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<Item>>> fetchPage({
    required int page,
    required int limit,
  }) => _api.get(
    '/items',
    query: {'page': page, 'limit': limit},
    parse: (data) => (data! as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ItemDto.fromJson)
        .toList(growable: false),
  );
}
