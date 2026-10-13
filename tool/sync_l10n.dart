// Pulls translations from a Google Sheet and writes lib/l10n/app_<locale>.arb.
//
// Sheet layout (first row is the header):
//   key | en | id | description
//   signIn | Sign in | Masuk | Login button label
// - Locale columns: any header like `en`, `id`, `pt_BR`.
// - `description` (optional) becomes @key metadata for translators.
// - Empty rows and rows whose key starts with `#` (section titles) are skipped.
//
// Usage:
//   dart run tool/sync_l10n.dart --sheet <SHEET_ID> [--gid <TAB_GID>]
//   dart run tool/sync_l10n.dart --csv path/to/export.csv
// The sheet ID can also come from the L10N_SHEET_ID env var. The sheet must be
// shared as "Anyone with the link can view".
import 'dart:convert';
import 'dart:io';

const _templateLocale = 'en';
const _outDir = 'lib/l10n';

final _localeHeader = RegExp(r'^[a-z]{2,3}(_[A-Z]{2})?$');
final _validKey = RegExp(r'^[a-z][a-zA-Z0-9]*$');
final _simplePlaceholder = RegExp(r'\{(\w+)\}');
final _icuMessage = RegExp(r'\{\w+\s*,\s*(plural|select)');

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final String csv;
  try {
    csv = switch (opts['csv']) {
      final String path => File(path).readAsStringSync(),
      _ => await _download(
        opts['sheet'] ?? Platform.environment['L10N_SHEET_ID'] ?? _fail(),
        opts['gid'] ?? '0',
      ),
    };
  } on Exception catch (e) {
    stderr.writeln('Could not load translations: $e');
    exitCode = 1;
    return;
  }

  final rows = _parseCsv(csv);
  if (rows.isEmpty) {
    stderr.writeln('Sheet is empty.');
    exitCode = 1;
    return;
  }

  final header = rows.first.map((h) => h.trim()).toList();
  final keyCol = header.indexOf('key');
  final descCol = header.indexOf('description');
  final locales = {
    for (var i = 0; i < header.length; i++)
      if (i != keyCol && i != descCol && _localeHeader.hasMatch(header[i]))
        header[i]: i,
  };
  if (keyCol == -1 || !locales.containsKey(_templateLocale)) {
    stderr.writeln(
      'Header must contain "key" and "$_templateLocale" columns. Got: $header',
    );
    exitCode = 1;
    return;
  }

  final errors = <String>[];
  final seen = <String>{};
  final arbs = {
    for (final l in locales.keys) l: <String, Object>{'@@locale': l},
  };

  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    String cell(int i) => i >= 0 && i < row.length ? row[i].trim() : '';
    final key = cell(keyCol);
    final line = r + 1;
    if (key.isEmpty || key.startsWith('#')) continue;

    if (!_validKey.hasMatch(key)) {
      errors.add('row $line: key "$key" must be lowerCamelCase');
      continue;
    }
    if (!seen.add(key)) {
      errors.add('row $line: duplicate key "$key"');
      continue;
    }

    for (final MapEntry(key: locale, value: col) in locales.entries) {
      final text = cell(col);
      if (text.isEmpty) {
        errors.add('row $line: "$key" missing "$locale" translation');
        continue;
      }
      arbs[locale]![key] = text;
    }

    final template = cell(locales[_templateLocale]!);
    final meta = <String, Object>{
      if (cell(descCol).isNotEmpty) 'description': cell(descCol),
      // ICU plural/select types are inferred by gen-l10n; declare simple ones.
      if (!_icuMessage.hasMatch(template) &&
          _simplePlaceholder.hasMatch(template))
        'placeholders': {
          for (final m in _simplePlaceholder.allMatches(template))
            m.group(1)!: <String, Object>{},
        },
    };
    if (meta.isNotEmpty) arbs[_templateLocale]!['@$key'] = meta;
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Sheet has ${errors.length} problem(s); no files written:');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exitCode = 1;
    return;
  }

  const encoder = JsonEncoder.withIndent('  ');
  for (final MapEntry(key: locale, value: arb) in arbs.entries) {
    File(
      '$_outDir/app_$locale.arb',
    ).writeAsStringSync('${encoder.convert(arb)}\n');
  }
  stdout.writeln(
    'Wrote ${seen.length} keys for ${locales.keys.join(', ')} to $_outDir/',
  );
}

Never _fail() => throw const FormatException(
  'Pass --sheet <ID>, set L10N_SHEET_ID, or use --csv <file>.',
);

Map<String, String> _parseArgs(List<String> args) => {
  for (var i = 0; i + 1 < args.length; i += 2)
    if (args[i].startsWith('--')) args[i].substring(2): args[i + 1],
};

Future<String> _download(String sheetId, String gid) async {
  final url = Uri.https('docs.google.com', '/spreadsheets/d/$sheetId/export', {
    'format': 'csv',
    'gid': gid,
  });
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode}. Is the sheet shared by link?',
        uri: url,
      );
    }
    return body;
  } finally {
    client.close();
  }
}

/// Minimal RFC 4180 parser: quoted fields, escaped quotes, newlines in cells.
List<List<String>> _parseCsv(String input) {
  final text = input.startsWith('﻿') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        inQuotes = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endField();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endField();
    rows.add(row);
  }
  return rows;
}
