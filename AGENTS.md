# Development rules

- Keep the product small, calm, accessible, and supportive of ADHD users. Prefer clear next actions, forgiving flows, and reduced cognitive load.
- Preserve offline-first behavior. Local task data must remain usable without a network connection; synchronization and AI features are optional additions, never prerequisites for core task use.
- Treat task content and account data as private. Do not log, commit, or send personal data without a clear user-facing need and explicit consent. Keep credentials in platform secure storage; never hardcode credentials or commit signing keys, `.env` files, databases, exports, or backups.
- Do not add paid cloud services or separately billed OpenAI API access. Before any AI integration, verify that the documented ChatGPT sign-in and eligible subscription allowance support the intended inference use. Do not assume a ChatGPT web session or Codex credential is a supported third-party API.
- Use Flutter for Android and Windows. Keep platform-specific code isolated and maintain equivalent core behavior across both platforms.
- Use SQLite for private local persistence. Keep schema and data access behind a small storage boundary so UI code does not depend on platform details.
- Keep the app starter focused; do not implement broad product features without a task request.
- Add focused tests for changed behavior. Run `flutter analyze` and `flutter test` before submitting changes.
- Keep dependency changes necessary, reviewed, and reflected in `pubspec.lock`. Do not weaken TLS, package integrity, or test assertions.
- Never commit user task data, credentials, device identifiers, or other personal information.
