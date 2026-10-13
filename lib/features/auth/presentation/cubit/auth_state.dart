import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/auth/domain/user.dart';
import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Session not resolved yet (app start).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated([this.failure]);

  /// Set when a login attempt failed.
  final Failure? failure;

  @override
  List<Object?> get props => [failure];
}
