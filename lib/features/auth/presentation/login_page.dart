import 'dart:async';

import 'package:base_app/core/widgets/snack.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<AuthCubit>().login(_email.text.trim(), _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state case Unauthenticated(:final failure?)) {
          context.showSnack(failure.localized(l10n));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.signIn,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(labelText: l10n.email),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => (v == null || !v.contains('@'))
                            ? l10n.emailInvalid
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(labelText: l10n.password),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.passwordRequired
                            : null,
                      ),
                      const SizedBox(height: 24),
                      // Rebuilds only the button, only when loading flips.
                      BlocSelector<AuthCubit, AuthState, bool>(
                        selector: (state) => state is AuthLoading,
                        builder: (_, loading) => FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.signIn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
