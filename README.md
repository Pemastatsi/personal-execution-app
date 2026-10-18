# Personal Execution App

An offline-first, ADHD-friendly personal task execution app for Android and Windows. This Flutter development starter now includes a **FocusFlow V2 Warm Minimal UI preview** with mock tasks, responsive dashboard and Focus Mode, manual step completion, and a light/dark theme toggle.

The preview is not connected to real task persistence or AI inference. Its sample data and in-session state reset when restarted. The existing SQLite storage boundary remains available for later integration.

## Design

Approved Figma project: https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB

See [the implementation handoff](docs/focusflow-v2-handoff.md) for screen links, semantic tokens, architectural boundaries, and remaining gaps.

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
