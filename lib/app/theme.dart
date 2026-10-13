import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF3B5BDB);

  static final light = ThemeData(colorSchemeSeed: _seed);
  static final dark = ThemeData(
    colorSchemeSeed: _seed,
    brightness: Brightness.dark,
  );
}
