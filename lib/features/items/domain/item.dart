import 'package:equatable/equatable.dart';

final class Item extends Equatable {
  const Item({required this.id, required this.title, this.description = ''});

  final String id;
  final String title;
  final String description;

  @override
  List<Object?> get props => [id, title, description];
}
