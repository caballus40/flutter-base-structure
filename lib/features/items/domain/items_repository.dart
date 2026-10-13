import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/items/domain/item.dart';

abstract interface class ItemsRepository {
  Future<Result<List<Item>>> fetchPage({required int page, required int limit});
}
