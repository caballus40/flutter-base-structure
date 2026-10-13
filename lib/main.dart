import 'dart:async';
import 'dart:ui';

import 'package:base_app/app/app.dart';
import 'package:base_app/app/app_bloc_observer.dart';
import 'package:base_app/app/router.dart';
import 'package:base_app/core/config/env.dart';
import 'package:base_app/core/logging/app_logger.dart';
import 'package:base_app/core/network/api_client.dart';
import 'package:base_app/core/storage/token_storage.dart';
import 'package:base_app/features/auth/data/auth_repository_impl.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/items/data/items_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Swap DebugLogger for a crash-reporting AppLogger to ship errors.
  const logger = DebugLogger();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.error(details.exception, details.stack, 'Flutter');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error(error, stack, 'Uncaught');
    return true;
  };
  Bloc.observer = const AppBlocObserver(logger);

  // Composition root: every dependency is built here and injected via
  // constructors. No service locator.
  final tokens = TokenStorage();
  late final AuthCubit authCubit;
  final api = ApiClient(
    createDio(Env.baseUrl),
    tokenStorage: tokens,
    onUnauthorized: () => unawaited(authCubit.logout()),
    logger: logger,
  );
  authCubit = AuthCubit(AuthRepositoryImpl(api, tokens));
  unawaited(authCubit.restoreSession());

  runApp(
    App(
      authCubit: authCubit,
      itemsRepository: ItemsRepositoryImpl(api),
      router: createRouter(authCubit),
    ),
  );
}
