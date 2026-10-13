<div align="center">

# 🚀 Flutter Base

**A lean starting point for Flutter apps: clean feature-first structure, Bloc/Cubit, and translations managed in Google Sheets.**

[![Flutter](https://img.shields.io/badge/Flutter-3.32%2B-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8%2B-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![State](https://img.shields.io/badge/state-flutter__bloc-blue?style=flat-square)](https://bloclibrary.dev)
[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](.github/workflows/ci.yml)
[![i18n](https://img.shields.io/badge/i18n-EN%20%C2%B7%20ID-green?style=flat-square)](#-localization)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

[Engineering Notes](NOTES.md) · [Quick Start](#-quick-start) · [Localization](#-localization)

</div>

---

## ✨ Features

- ⚡ **Lean**: five runtime packages, no code generation except the official l10n.
- 🧱 **Clean structure**: each feature has its own `domain / data / presentation`, and features stay independent of each other.
- 🛡️ **Safe errors**: repositories return a `Result` instead of throwing, so network and parsing errors can't crash the UI.
- 🔒 **Secure session**: tokens are kept in Keychain/Keystore. An expired token is refreshed silently, with one refresh even when several requests fail at once, and routing redirects automatically on login and logout.
- 📜 **Pagination built in**: infinite scroll, pull-to-refresh, and loading, empty and error states.
- 🌐 **EN + ID**: translators edit a Google Sheet, and one command syncs it into type-safe strings.
- 🌍 **Environments**: `env/dev|stg|prod.json` with no extra packages. Non-prod builds show a ribbon.
- 🪵 **Logging hook**: one `AppLogger` interface receives every Flutter, platform and Bloc error. Plug in Sentry or Crashlytics in one place.
- ✅ **Tested + CI**: unit, interceptor and widget tests. GitHub Actions checks formatting, analysis, tests and translation drift.

## 🏁 Start a new app from this base

1. Copy the folder and rename the package: replace `base_app` in `pubspec.yaml` and in every `package:base_app/` import.
2. Set your own org ID (for example `com.yourcompany`) in the `flutter create` command below.
3. Change `appTitle` in the translation sheet and `_seed` in `lib/app/theme.dart`.
4. Set the real URLs in `env/*.json` and replace `OWNER/REPO` in the CI badge.
5. Replace the example `items` feature with your own features, keeping `auth` if you need it.

## 📦 Installation

Requires Flutter 3.32+ (Dart 3.8+).

```bash
# First time only: generate the android/ and ios/ folders (existing files are kept)
flutter create --org com.example --project-name base_app --platforms android,ios .
rm test/widget_test.dart   # template counter test, not used here

flutter pub get
```

For iOS, add the supported languages to `ios/Runner/Info.plist` so the device language is detected:

```xml
<key>CFBundleLocalizations</key>
<array><string>en</string><string>id</string></array>
```

## 🚀 Quick Start

```bash
flutter run --dart-define-from-file=env/dev.json
```

The app opens on the splash screen and restores any saved session. Without one, it goes to Login; after you sign in, it goes to Items.

## 📖 Usage

### Common commands

```bash
flutter analyze   # must report 0 issues
flutter test      # unit, interceptor, widget and l10n tests
dart format $(git ls-files '*.dart')   # CI fails on unformatted code
flutter build apk --release --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols
```

### Configuration

Each environment is a JSON file passed with `--dart-define-from-file`. These files hold URLs and flags only, never secrets. For personal overrides, use `env/*.local.json`, which git ignores.

| Key        | Values              | Default                       | Description                        |
| ---------- | ------------------- | ----------------------------- | ---------------------------------- |
| `APP_ENV`  | `dev`, `stg`, `prod` | `dev`                         | Non-prod builds show a ribbon      |
| `BASE_URL` | URL                 | `https://dev.api.example.com` | Backend API base URL               |

### Backend contract

| Endpoint                | Request              | Response                          |
| ----------------------- | -------------------- | --------------------------------- |
| `POST /auth/login`      | `{email, password}`  | `{token, refreshToken, user: {id, name, email}}` |
| `POST /auth/refresh`    | `{refreshToken}`     | `{token, refreshToken}` (4xx = session over) |
| `GET /auth/me`          | Bearer token         | `{id, name, email}`               |
| `GET /items?page&limit` | Bearer token         | `[{id, title, description?}]`     |
| any error               | —                    | optional `{message}`, shown to the user |

### Project structure

```
lib/
  main.dart        composition root (all dependencies wired here)
  app/             App widget, router with auth redirect, theme
  core/            ApiClient + AuthInterceptor, Result/Failure, AppLogger,
                   token storage, shared widgets
  features/
    auth/          domain · data · presentation
    items/         domain · data · presentation
  l10n/            ARB files (generated from the sheet) + context.l10n
env/               dev.json, stg.json, prod.json
tool/              sync_l10n.dart, l10n_seed.csv
test/              unit, interceptor, widget and l10n tests
.github/workflows/ ci.yml
```

The full architecture rules and the checklist for adding a feature are in **[NOTES.md](NOTES.md)**.

## 🌐 Localization

Translations live in a **Google Sheet**, which is the source of truth:

| key    | en      | id    | description        |
| ------ | ------- | ----- | ------------------ |
| signIn | Sign in | Masuk | Login button label |

```bash
dart run tool/sync_l10n.dart --sheet <SHEET_ID>   # or set L10N_SHEET_ID
flutter pub get                                   # regenerates AppLocalizations
```

| Option    | Description                                          |
| --------- | ---------------------------------------------------- |
| `--sheet` | Google Sheet ID (the sheet must be shared as "Anyone with the link can view") |
| `--gid`   | Tab ID, if the strings are not on the first tab (default `0`) |
| `--csv`   | Read a local CSV export instead of downloading the sheet |

- The sync **writes nothing** if any key is invalid or duplicated, or any translation is missing. It lists the rows to fix.
- Commit the generated `lib/l10n/app_*.arb` files. Don't edit them by hand.
- To create the sheet the first time, import `tool/l10n_seed.csv`.
- In code, use `context.l10n.signIn`.

## 🗺️ Roadmap

- [x] Clean architecture skeleton (auth + paginated list)
- [x] EN / ID localization synced from Google Sheets
- [x] Unit tests for cubits and repositories
- [x] Environments (dev / stg / prod)
- [x] Silent token refresh
- [x] Logger and crash-reporting hook
- [x] CI pipeline (format, analyze, test, l10n drift)
- [x] Widget tests

## 🤝 Contributing

1. Follow the rules and the "Adding a feature" checklist in [NOTES.md](NOTES.md).
2. Add new strings to the Google Sheet, then run the sync.
3. Formatting, `flutter analyze` and `flutter test` must all pass before you open a PR. CI checks them.

## 📄 License

MIT License © 2026 caballus40. See [LICENSE](LICENSE).
