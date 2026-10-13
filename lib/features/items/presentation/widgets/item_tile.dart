import 'package:base_app/features/items/domain/item.dart';
import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(item.title),
    subtitle: item.description.isEmpty
        ? null
        : Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}
