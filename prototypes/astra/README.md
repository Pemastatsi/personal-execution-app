# Astra — Personal Execution concept

A Flutter Android prototype based on the full [competition brief](../../docs/ui-ux-design-competition-brief.md). All task content is fictional. This package is independent of the production `lib/` and the authentication feasibility work.

Astra puts the next physical action ahead of the plan. Warm paper, quiet violet, editorial Newsreader headings and legible Manrope instructions create a calm, recognisable identity. A five-segment outcome path communicates earned progress. There are no timers, streaks, points, or generated priorities.

See the [five-screen light/dark gallery](screenshots/README.md), [visual QA notes](VISUAL_QA.md), and [implementation PR](https://github.com/Pemastatsi/personal-execution-app/pull/2).

## Try the experience

1. Open Home and tap **Resume focus**. The editor instruction is already selected.
2. Complete an action, change instruction detail, or tap **I’m stuck**.
3. In the coach, attach the fictional compiler screenshot. The response identifies one next instruction. **Back to focus** restores the same action.
4. Switch to the application form, then back to the indicator. The action, blocker, detail setting and conversation remain intact.
5. Before resuming the initial sample, open **Where was I?** to see the two-week recovery. The date is seeded 14 days before first launch; it updates only when work resumes.
6. Finish the compiler actions. Progress stays at 2/5 until you confirm that the compiler reports zero errors. The next milestone then becomes available.
7. Tap the moon/sun on Home to change theme. Capture a task without replacing your current focus.

The default dataset includes the three tasks specified in the brief. With no active task, Home shows up to three choices. Task row arrows switch immediately; the history icon previews context before switching.

## Run and validate

Use Flutter 3.47.7 and Java 17 or newer. From this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
flutter test test/render_test.dart --dart-define=EXPORT_SCREENSHOTS=true
```

The `Astra concept · APK and visual QA` GitHub Actions workflow runs analysis and tests, renders all five screens in both themes at 390 × 844 logical pixels (2× PNG export), then builds and uploads `astra-android-debug`. Download and unzip that artifact to install `app-debug.apk`. Artifacts expire after 30 days; rerun the workflow to refresh them. The Android application ID is `dev.personalexecution.astra`, so it can coexist with the production starter.

## Implementation and boundaries

- `model.dart`: local sample state, current-milestone action plans, explicit verification, contextual mock responses, and checkpoint serialization.
- `storage.dart`: a small storage boundary. Android uses its own SQLite database, with Android backup disabled. Other platforms use an in-memory demonstration store.
- `design.dart`: shared colours, typography, controls and outcome visualisations. Fonts are bundled, OFL licensed, and work offline.
- `screens.dart`, `coach.dart`: the five views, with native Android back handling, scrollable content, and reduced-motion support.
- Tests exercise task recovery, restart serialization, milestone approval, capture, theme changes, screenshot troubleshooting and text scaling. Render exports come from Flutter's test renderer, not a physical Android device.

## Scope and usability limitations

- AI is deterministic and local. It does not inspect real images or run outside actions. Screenshot troubleshooting uses a clearly labelled fictional MetaEditor image; no files leave the device.
- No account, backend, paid API, authentication changes, notifications, voice capture, live ChatGPT handoff or Windows synchronisation is included.
- Newly captured tasks get a generic first-step prompt. They do not receive a genuinely AI-generated plan.
- Initial verified evidence is fictional sample data, and later verification is user attestation, not an external check.
- The two-week interval is a fixture, not a longitudinal user study. There has been no usability study with ADHD participants.
- Physical-device testing and TalkBack review must be reported separately from widget/render tests. SQLite lifecycle behaviour on a physical device needs further testing.

The prototype deliberately keeps those boundaries visible while making all five core flows interactive.
