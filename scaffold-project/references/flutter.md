# Flutter

Read after the user picked Flutter (step 1 of `SKILL.md`). An application: the branch policy is the
application variant.

Dart requires a package's code in `lib/` and resolves `package:` imports only from inside the package,
so the shared shape is met with **two packages**: the app is the Flutter project in `src/`, and
`tests/` is a test-only package that depends on it by path — the same way a .NET test project
references the project it tests.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **package
name** in snake_case (`order_portal`).

| Question | Default |
|---|---|
| "Organization, in reverse-domain form? (e.g. `com.acme` — it becomes the Android / iOS bundle id prefix)" | none — ask; never `com.example` |
| "Platforms? (android, ios, web, windows, macos, linux)" | android, ios, web |

## Generate

```bash
flutter create --empty --org <org> --project-name <package_name> --description "<description>" --platforms <list> src
```

`--empty` skips the counter demo. The project lands in `src/`: `src/lib/`, `src/pubspec.yaml`, the
platform folders, `src/.gitignore` and `src/analysis_options.yaml`.

## Shape

- Delete `src/README.md` (the root README replaces it) and `src/test/` if present — tests live in
  `tests/`. Keep `src/.gitignore` where it is: its paths are relative to the Flutter project.
- Set `version: 0.1.0+1` in `src/pubspec.yaml`.
- `--empty` generates a root widget, `MainApp`, whose body is `Text('Hello World!')`. Keep `MainApp`
  and replace the text with the project's display name (`order_app` → "Order App") — the minimal
  entry point stays, the greeting goes.
- **The test package** — `tests/pubspec.yaml`:

  ```yaml
  name: <package_name>_tests
  publish_to: none
  environment:
    sdk: <the same constraint as src/pubspec.yaml>
  dependencies:
    flutter:
      sdk: flutter
    <package_name>:
      path: ../src
  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: <the same constraint as src/pubspec.yaml>
  flutter:
    uses-material-design: true      # matches the app's; without it every `flutter test` warns
  ```

  `tests/analysis_options.yaml` — written in full, or `flutter pub get` rewrites it during
  verification:

  ```yaml
  include: package:flutter_lints/flutter.yaml

  analyzer:
    exclude: [build/**]
  ```

  Test files go in `tests/unit/` and `tests/widget/`.
- **One smoke test,** `tests/widget/app_test.dart`: pump `MainApp`
  (`import 'package:<package_name>/main.dart';`) and expect the display name on screen. It proves
  the path dependency, `flutter_test` and the widget tree resolve; the first real test replaces it.
- Device-level integration tests (`integration_test/`) need the app's platform runners and so stay in
  `src/integration_test/` when they are added — say so in CONTRIBUTING.
- Root `.gitignore`: `tests/.dart_tool/`, `tests/build/`, `tests/pubspec.lock`, then the shared block.

## README fill-ins

- **Requirements:** `- Flutter <version from flutter --version> or later`, and the platforms.
- **Usage:** `cd src && flutter run` (with `-d chrome` for the web), and `flutter build <platform>`
  for a release build.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- [Flutter](https://docs.flutter.dev/get-started/install) <version> or later`,
  plus the platform toolchains (Android Studio, Xcode) for the chosen platforms.
- **Build:** `cd src && flutter pub get && flutter analyze && flutter build web` (or the platform at
  hand).
- **Testing:**

  ````markdown
  Tests live in the `tests/` package, which depends on the app in `src/` by path. Unit tests go in `tests/unit/`,
  widget tests in `tests/widget/`; device-level integration tests, which need the app's platform runners, go in
  `src/integration_test/`. Every test is named with the Given / When / Then pattern
  (`given some condition, when some action, then some output`).

  ```bash
  cd tests
  flutter pub get
  flutter test unit widget
  ```
  ````

## Verify

```bash
cd src && flutter pub get && flutter analyze
cd ../tests && flutter pub get && flutter analyze && flutter test unit widget
```

and one platform build — `cd src && flutter build web` when web is a platform. The test run must
report **1 passed**. `tests/unit/` holds only a `.gitkeep` until the first unit test; the command still
passes.
