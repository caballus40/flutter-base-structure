import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/auth/domain/user.dart';

abstract interface class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  /// Returns the signed-in user from a stored token, or null if there is none.
  Future<User?> restoreSession();

  Future<void> logout();
}
