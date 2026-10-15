# Personal Execution App

An offline-first, ADHD-friendly personal task execution app for Android and Windows. This repository is an intentionally small Flutter development starter; it does not yet implement the full application or AI sign-in.

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
