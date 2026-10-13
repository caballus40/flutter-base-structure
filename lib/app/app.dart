import 'package:base_app/app/theme.dart';
import 'package:base_app/core/config/env.dart';
import 'package:base_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:base_app/features/items/domain/items_repository.dart';
import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({
    required this.authCubit,
    required this.itemsRepository,
    required this.router,
    super.key,
  });

  final AuthCubit authCubit;
  final ItemsRepository itemsRepository;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: itemsRepository,
      child: BlocProvider.value(
        value: authCubit,
        child: MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: router,
          // Follows the device language; falls back to the first (English).
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Non-prod builds wear a ribbon so testers know which backend they hit.
          builder: (context, child) => Env.isProd
              ? child!
              : Banner(
                  message: Env.current.name.toUpperCase(),
                  location: BannerLocation.bottomStart,
                  child: child,
                ),
        ),
      ),
    );
  }
}
