import 'dart:async';

import 'package:base_app/core/widgets/loading_view.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:base_app/features/auth/presentation/login_page.dart';
import 'package:base_app/features/items/domain/items_repository.dart';
import 'package:base_app/features/items/presentation/cubit/items_cubit.dart';
import 'package:base_app/features/items/presentation/items_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const items = '/';
}

/// Navigation is a function of auth state: the router re-evaluates [redirect]
/// whenever [AuthCubit] emits.
GoRouter createRouter(AuthCubit auth) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: _StreamListenable(auth.stream),
  redirect: (_, state) {
    final loc = state.matchedLocation;
    return switch (auth.state) {
      AuthInitial() => loc == Routes.splash ? null : Routes.splash,
      Authenticated() =>
        (loc == Routes.login || loc == Routes.splash) ? Routes.items : null,
      AuthLoading() ||
      Unauthenticated() => loc == Routes.login ? null : Routes.login,
    };
  },
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, _) => const Scaffold(body: LoadingView()),
    ),
    GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
    GoRoute(
      path: Routes.items,
      // Cubit is scoped to the route: created on enter, closed on leave.
      builder: (_, _) => BlocProvider(
        create: (context) =>
            ItemsCubit(context.read<ItemsRepository>())..load(),
        child: ItemsPage(onLogout: auth.logout),
      ),
    ),
  ],
);

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
