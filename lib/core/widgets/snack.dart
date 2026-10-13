import 'package:flutter/material.dart';

extension SnackX on BuildContext {
  void showSnack(String message) => ScaffoldMessenger.of(this)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
