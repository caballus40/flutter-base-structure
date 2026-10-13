import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/auth/domain/auth_repository.dart';
import 'package:base_app/features/auth/domain/user.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  const user = User(id: '1', name: 'Ada', email: 'ada@x.io');
  const failure = Failure(FailureType.unauthorized, 'Wrong password');

  setUp(() => repo = _MockAuthRepository());

  void stubLogin(Result<User> result) => when(
    () => repo.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  blocTest<AuthCubit, AuthState>(
    'restoreSession emits Authenticated when a user exists',
    setUp: () => when(repo.restoreSession).thenAnswer((_) async => user),
    build: () => AuthCubit(repo),
    act: (c) => c.restoreSession(),
    expect: () => [const Authenticated(user)],
  );

  blocTest<AuthCubit, AuthState>(
    'restoreSession emits Unauthenticated when no session',
    setUp: () => when(repo.restoreSession).thenAnswer((_) async => null),
    build: () => AuthCubit(repo),
    act: (c) => c.restoreSession(),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthCubit, AuthState>(
    'login success emits [Loading, Authenticated]',
    setUp: () => stubLogin(const Ok(user)),
    build: () => AuthCubit(repo),
    act: (c) => c.login('ada@x.io', 'pw'),
    expect: () => [const AuthLoading(), const Authenticated(user)],
  );

  blocTest<AuthCubit, AuthState>(
    'login failure emits [Loading, Unauthenticated(failure)]',
    setUp: () => stubLogin(const Err(failure)),
    build: () => AuthCubit(repo),
    act: (c) => c.login('ada@x.io', 'bad'),
    expect: () => [const AuthLoading(), const Unauthenticated(failure)],
  );

  blocTest<AuthCubit, AuthState>(
    'logout clears session',
    setUp: () => when(repo.logout).thenAnswer((_) async {}),
    build: () => AuthCubit(repo),
    seed: () => const Authenticated(user),
    act: (c) => c.logout(),
    expect: () => [const Unauthenticated()],
    verify: (_) => verify(repo.logout).called(1),
  );
}
