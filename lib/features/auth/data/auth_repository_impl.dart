import 'package:base_app/core/network/api_client.dart';
import 'package:base_app/core/result/result.dart';
import 'package:base_app/core/storage/token_storage.dart';
import 'package:base_app/features/auth/data/models/user_dto.dart';
import 'package:base_app/features/auth/domain/auth_repository.dart';
import 'package:base_app/features/auth/domain/user.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      parse: (data) {
        final json = data! as Map<String, dynamic>;
        return (
          token: json['token'] as String,
          refreshToken: json['refreshToken'] as String,
          user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        );
      },
    );
    switch (result) {
      case Ok(:final value):
        await _tokens.save(access: value.token, refresh: value.refreshToken);
        return Ok(value.user);
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<User?> restoreSession() async {
    if (await _tokens.readAccess() == null) return null;
    final result = await _api.get(
      '/auth/me',
      parse: (data) => UserDto.fromJson(data! as Map<String, dynamic>),
    );
    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        if (failure.type == FailureType.unauthorized) await _tokens.clear();
        return null;
    }
  }

  @override
  Future<void> logout() => _tokens.clear();
}
