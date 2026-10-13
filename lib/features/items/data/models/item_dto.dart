import 'package:base_app/features/items/domain/item.dart';

abstract final class ItemDto {
  static Item fromJson(Map<String, dynamic> json) => Item(
    id: '${json['id']}',
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
  );
}
