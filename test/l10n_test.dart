import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String locale) {
  final json =
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('every English string has an Indonesian translation and vice versa', () {
    final en = _keys('en');
    final id = _keys('id');
    expect(en.difference(id), isEmpty, reason: 'missing in app_id.arb');
    expect(id.difference(en), isEmpty, reason: 'missing in app_en.arb');
  });
}
