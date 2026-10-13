import 'package:base_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a localized MaterialApp.
  Future<void> pumpApp(
    Widget widget, {
    Locale locale = const Locale('en'),
  }) async {
    await pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
    await pump(); // let localizations load
  }
}
