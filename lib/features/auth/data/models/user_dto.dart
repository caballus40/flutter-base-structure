import 'package:base_app/features/auth/domain/user.dart';

/// JSON <-> domain mapping lives in the data layer; the domain stays pure.
abstract final class UserDto {
  static User fromJson(Map<String, dynamic> json) => User(
    id: '${json['id']}',
    name: json['name'] as String,
    email: json['email'] as String,
  );
}
