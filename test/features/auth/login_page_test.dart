import 'package:base_app/core/result/result.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:base_app/features/auth/presentation/login_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockAuthCubit cubit;

  setUp(() {
    cubit = _MockAuthCubit();
    when(() => cubit.state).thenReturn(const Unauthenticated());
    when(() => cubit.login(any(), any())).thenAnswer((_) async {});
  });

  Widget subject() =>
      BlocProvider<AuthCubit>.value(value: cubit, child: const LoginPage());

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('shows validation errors and does not submit', (tester) async {
    await tester.pumpApp(subject());

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    verifyNever(() => cubit.login(any(), any()));
  });

  testWidgets('submits trimmed email and password', (tester) async {
    await tester.pumpApp(subject());

    await tester.enterText(field('Email'), '  ada@x.io ');
    await tester.enterText(field('Password'), 'secret');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => cubit.login('ada@x.io', 'secret')).called(1);
  });

  testWidgets('loading disables the button and shows a spinner', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const AuthLoading());
    await tester.pumpApp(subject());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('failed login shows a localized snackbar', (tester) async {
    whenListen(
      cubit,
      Stream.fromIterable([
        const AuthLoading(),
        const Unauthenticated(Failure(FailureType.network)),
      ]),
      initialState: const Unauthenticated(),
    );
    await tester.pumpApp(subject());
    await tester.pump();

    expect(find.text('No connection. Check your network.'), findsOneWidget);
  });

  testWidgets('renders in Indonesian', (tester) async {
    await tester.pumpApp(subject(), locale: const Locale('id'));

    expect(find.text('Masuk'), findsNWidgets(2)); // title + button
    expect(field('Kata sandi'), findsOneWidget);
  });
}
