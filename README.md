# Personal Execution App

An offline-first, ADHD-friendly personal task execution app for Android and Windows. Stage 2 provides a connection prototype with AI disabled pending confirmation that this private app is eligible for ChatGPT plan usage. It does not yet implement AI sign-in, inference, or the full task manager. See [Stage 2 status](docs/stage2-status.md) for scope and blockers.

## Requirements

- Flutter 3.47.7 (Dart SDK supplied by Flutter)
- Android SDK and Java 17+ for Android builds
- Windows with Visual Studio C++ desktop workload for Windows builds

## Develop and validate

From the repository root:

```sh
flutter pub get
flutter analyze
flutter test
```

Build Android with `flutter build apk --debug` on a runner with Android SDK tools. Build Windows with `flutter build windows --debug` on Windows with Visual Studio installed.

SQLite dependencies include `sqflite` for Android and `sqflite_common_ffi` for Windows desktop. `flutter_secure_storage` provides platform secure storage for future credentials. Keep task records local by default; do not add a remote database or separately billed inference API. Verify the supported ChatGPT sign-in and subscription inference flow as a separate feasibility task before designing an integration.

## Download an Android test build

Open a successful **Flutter CI** run from the pull request or GitHub Actions.
Download the **personal-execution-stage2-android-debug-<run number>** artifact and
extract `app-debug.apk`. Artifacts expire after seven days; rerun the workflow
when needed. The debug build shows the eligibility blocker and does not connect
to ChatGPT or consume inference allowance.
