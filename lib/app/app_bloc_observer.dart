import 'package:base_app/core/logging/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Routes every Bloc/Cubit error to the logger, and state changes in debug.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver(this._logger);

  final AppLogger _logger;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _logger.debug('${bloc.runtimeType}: ${change.nextState}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(error, stackTrace, '${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
