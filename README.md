# Personal Execution App

An offline-first Flutter starter for Android and Windows. Stage 2 adds an
**isolated ChatGPT authentication proof of concept**, without integrating AI into
task data or building the full application. Actual Plus-account authentication,
device compatibility and subscription inference remain unverified.

See [Stage 2 status and device test instructions](docs/stage2-status.md) for
eligibility, registration, billing controls and verification limits. This PR
proposes the MIT license; main's licensing remains pending until owner review.

## Development

Use Flutter 3.47.7 (Dart >=3.12), Android SDK/JDK 17, or Visual Studio on Windows.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

SQLite task storage stays local. Credentials use platform secure storage.
Conversations and screenshot attachments stay in memory and go to OpenAI only
when explicitly sent. Android backup and recents capture are disabled.

## Download the Android proof of concept

Open this PR's successful **Flutter CI** run in GitHub Actions. Download the
`personal-execution-stage2-android-debug-<run number>` artifact and extract
`app-debug.apk`. Artifacts expire after seven days. No signing secret is needed.

Sign in with ChatGPT, then open **Manage usage**. Keep app credit use off and save
this app's usage limit **below 100%** before confirming the settings and sending.
The app cannot inspect these external settings. If they cannot be verified, keep
Send disabled. No API keys, credit purchases or paid fallback are configured.

Passing fixture tests or installing the APK does not prove live subscription
inference. Follow the physical-device acceptance procedure before claiming it.
