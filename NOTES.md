# Engineering Notes

The rules this codebase follows. If a change breaks one, either fix the change or update this file with the reason.

## Principal points

1. **Feature-first, layered inside each feature.**
   `features/<name>/{domain,data,presentation}`. Code shared by two or more features goes in `core/`. A feature never imports another feature's internals. When features need each other, the app layer connects them (e.g. `ItemsPage(onLogout: …)` is wired in `app/router.dart`).

2. **Dependency rule: `presentation → domain ← data`.**
   `domain/` is plain Dart: entities plus abstract repositories. It has no Flutter, no Dio and no JSON. `data/` implements the repositories, and `presentation/` uses only the abstractions.

3. **Add only the dependencies you need.** Each package has to earn its place:
   | Package | Why |
   |---|---|
   | `flutter_bloc` | State management + scoped DI (`RepositoryProvider`/`BlocProvider`) |
   | `equatable` | Value equality for states/entities without codegen |
   | `dio` | Interceptors, timeouts, cancellation |
   | `go_router` | Declarative routing + auth redirect |
   | `flutter_secure_storage` | Token in Keychain/Keystore, never SharedPreferences |
   | `flutter_localizations` + `intl` | Official i18n (`gen-l10n`), type-safe strings |

   Deliberately **not** used: `get_it` (constructor injection is enough), `freezed`/`json_serializable` (Dart 3 sealed classes and small hand-written mappers are enough at this size), `dartz`/`fpdart` (a 20-line `Result` does the job).

4. **Errors are values.** Repositories return `Result<T>` (`Ok` or `Err(Failure)`). `ApiClient._send` is the only place exceptions are caught and mapped, so a `DioException` or parse error never reaches the UI. Because `switch` over a sealed type must be exhaustive, the compiler makes you handle failures.

5. **Cubit by default.** Use a `Bloc` only when you need event transformers (debounce search, drop duplicate taps).

6. **Choose the state shape on purpose:**
   - **Mutually exclusive states** (auth): use a `sealed class` hierarchy, since impossible states can't be represented.
   - **Accumulating states** (paginated list): use one immutable class with a `status` enum and `copyWith`, so data survives across loading/error.

7. **Guard against emitting after `close`.** After every `await` in a cubit, check `if (isClosed) return;` before you `emit`.

8. **Navigation follows state.** The router redirects based on `AuthCubit` state, and screens never call `go('/login')` after login or logout. This removes a whole class of back-stack bugs.

9. **Scope state to where it's used.** `AuthCubit` is app-wide. `ItemsCubit` is created in its route's builder, so it is disposed automatically when you leave the route.

10. **Keep rebuilds small.** Use `const` constructors everywhere you can. Use `BlocSelector` or `buildWhen` to rebuild only what changes (the login button rebuilds alone). Use `BlocConsumer`/`listenWhen` for one-off effects (snackbars). Use `ValueKey` on list items.

11. **Use one composition root.** All wiring happens in `main.dart`. Swapping an implementation (mock API, cache layer) is a one-line change there.

12. **One build, many environments.** `env/{dev,stg,prod}.json` are passed with `--dart-define-from-file`, and `Env` reads them at compile time. There's no flavor package and no runtime config file. Non-prod builds show a ribbon. Secrets never go in these files; CI injects them.

13. **Keep lints strict.** `analysis_options.yaml` turns on `strict-casts`, `strict-inference`, `strict-raw-types`, package-only imports, `unawaited_futures` and more. The rule is **0 analyzer issues**, and `unawaited(...)` marks fire-and-forget calls explicitly.

14. **Test behaviour, not pixels.**
   - Cubits are tested with `bloc_test` and `mocktail`.
   - Repositories and `AuthInterceptor` are tested against a real `ApiClient` with an in-memory `FakeAdapter`.
   - Pages are tested with `MockCubit`, using `tester.pumpApp(...)` so they render localized: one test per UI state, plus the effects (snackbar, callback).
   - There are no golden tests; they are brittle across platforms and fonts.
   - CI (`.github/workflows/ci.yml`) enforces formatting, 0 analyzer issues, green tests and ARB files that match the sheet.

15. **Every user-facing string comes from l10n, and the Google Sheet is the source of truth.** Use `context.l10n.key`. Translators edit the sheet, and `tool/sync_l10n.dart` regenerates the ARB files. Never hand-edit the ARBs: the next sync overwrites them. `core/` holds no UI text; `Failure.localized(l10n)` turns error types into messages.

16. **Sessions refresh themselves.** `AuthInterceptor` (a `QueuedInterceptor`) attaches the token and handles 401s as follows:
   - **Refresh once.** On the first 401 it refreshes the token. Concurrent 401s then see the new token and just retry.
   - **Refresh and retry go through a separate interceptor-free Dio.** Retrying through the main client would deadlock the queue.
   - **A 4xx from the refresh call ends the session.** The interceptor calls `onUnauthorized` and the router goes to login.
   - **A network or 5xx failure keeps the session.** The request fails with the real cause, so going offline never signs the user out.

17. **Every error goes to one logger.** `AppLogger` is a three-method interface. `FlutterError.onError`, `PlatformDispatcher.onError`, `AppBlocObserver` and `ApiClient` all report to it. A crash reporter is one new implementation swapped in `main.dart`. Never log headers or bodies that carry credentials (`LogInterceptor` has `requestHeader: false`).

18. **Don't add speculative layers.** There are no `UseCase` classes that wrap a single repository call, and no separate `RemoteDataSource` until a second source (cache, DB) exists. Add a layer when it removes complexity, not before.

## Structure

```
lib/
  main.dart                 composition root + global error hooks
  app/                      App widget (env ribbon), router (auth redirect), theme, AppBlocObserver
  core/
    config/env.dart         AppEnv + compile-time values from env/*.json
    logging/app_logger.dart AppLogger interface + DebugLogger
    network/api_client.dart Dio wrapper, error → Failure mapping
    network/auth_interceptor.dart  token attach + single-flight refresh
    result/result.dart      Result<T>, Failure
    storage/token_storage.dart
    widgets/                LoadingView, MessageView, showSnack
  l10n/                     app_en.arb, app_id.arb, l10n.dart (context.l10n, Failure.localized)
  features/
    auth/   domain · data · presentation (AuthCubit, LoginPage)
    items/  domain · data · presentation (ItemsCubit, ItemsPage, ItemTile)
env/                        dev.json, stg.json, prod.json
tool/
  sync_l10n.dart            Google Sheet → ARB files
  l10n_seed.csv             starter rows to import into the sheet
test/
  helpers/                  fake_adapter, fakes (MemoryTokenStorage, SilentLogger), pump_app
  core/network/             auth_interceptor_test
  features/...              cubit, repository and page tests
.github/workflows/ci.yml
```

## Adding a feature (checklist)

1. `domain/`: entity (`Equatable`) + `abstract interface class XRepository` returning `Result<T>`.
2. `data/`: `models/x_dto.dart` (`fromJson` → entity) + `XRepositoryImpl(ApiClient)`.
3. `presentation/`: `XCubit` + state, page, and small widgets in `widgets/`. Add the feature's strings to the Google Sheet, then run the sync.
4. Build the repository in `main.dart` and expose it with `RepositoryProvider` in `App`.
5. Add a `GoRoute` that creates the cubit in `BlocProvider(create: …)`.
6. Write cubit tests and a page test per UI state. If parsing is non-trivial, write repository tests too.
7. `dart format`, `flutter analyze` and `flutter test` must all be clean. CI checks them.

## Backend contract assumed by the skeleton

| Endpoint | Request | Response |
|---|---|---|
| `POST /auth/login` | `{email, password}` | `{token, refreshToken, user: {id, name, email}}` |
| `POST /auth/refresh` | `{refreshToken}` | `{token, refreshToken}`. A 4xx ends the session |
| `GET /auth/me` | Bearer token | `{id, name, email}` |
| `GET /items?page&limit` | Bearer token | `[{id, title, description?}]` |
| any error | — | optional `{message}`, which is shown to the user |

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=env/dev.json
flutter build apk --release --dart-define-from-file=env/prod.json --obfuscate --split-debug-info=build/symbols
```

## i18n

- Languages: English (`en`, the template and fallback) and Indonesian (`id`). The app follows the device language.
- **The Google Sheet is the source of truth.** It has columns `key | en | id | description`. Keys are lowerCamelCase. A row whose key starts with `#` is a section title and is skipped. Placeholders use `{name}`, and ICU plural/select messages work too.
- **Sync:** `dart run tool/sync_l10n.dart --sheet <SHEET_ID>`, or set `L10N_SHEET_ID`. Add `--gid <id>` if the strings are not on the first tab. To sync from a CSV file instead, use `--csv file.csv`. Then `flutter pub get` regenerates `AppLocalizations`.
- **Validation:** if any key is invalid or duplicated, or any translation is missing, the sync writes **nothing** and lists the bad rows.
- **Commit the generated ARBs.** Builds and CI then stay offline and reproducible, and the diff shows exactly what translators changed.
- **Sharing:** the sheet must be shared as "Anyone with the link can view". If it has to stay private, export it as CSV and use `--csv`, or switch the script to use a service account.
- **Setup:** to create the sheet the first time, import `tool/l10n_seed.csv` (File → Import) into a new Google Sheet. It contains every current key.
- iOS: add `<key>CFBundleLocalizations</key><array><string>en</string><string>id</string></array>` to `ios/Runner/Info.plist`. Without it, iOS won't report Indonesian to the app.
