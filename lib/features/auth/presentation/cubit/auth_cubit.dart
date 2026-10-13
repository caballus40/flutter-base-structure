import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/auth/domain/auth_repository.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide session state. The router redirects based on this; screens never
/// navigate manually after login/logout.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    final user = await _repository.restoreSession();
    if (isClosed) return;
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await _repository.login(email: email, password: password);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => Authenticated(value),
      Err(:final failure) => Unauthenticated(failure),
    });
  }

  Future<void> logout() async {
    await _repository.logout();
    if (!isClosed) emit(const Unauthenticated());
  }
}
