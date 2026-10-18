# FocusFlow V2 — Warm Minimal Flutter handoff

**Figma file:** https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB

| Approved screen | Figma node |
| --- | --- |
| Light dashboard | [16:19](https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB?node-id=16-19) |
| Dark dashboard | [16:131](https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB?node-id=16-131) |
| Light Focus Mode | [17:25](https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB?node-id=17-25) |
| Dark Focus Mode | [17:92](https://www.figma.com/design/zAwMOYl4KoiXNuGJfW75NB?node-id=17-92) |

## Design decisions

- Keep Figma as the visual design reference; use Flutter as the native Android/Windows implementation.
- Warm Minimal semantic tokens: ivory `#F7F6F2`, dark charcoal `#171918`, muted bronze `#87704F` (light) / `#BFA582` (dark), off-white surfaces and warm neutral borders.
- Match screen hierarchy: compact navigation on desktop, task-first hero, subdued secondary projects, single-action Focus Mode, right-hand completion criteria.
- On Android, use a compact header and touch-safe bottom navigation instead of squeezing the desktop three-column layout.
- The mock uses the system Flutter typeface rather than embedding Geist. Figma uses Geist; confirm licensing and add a properly licensed font asset in a later typography pass.
- Theme change is session-only. Data is static mock data; changes and notes are session-only and not connected to TaskStore.
- The focus step's next action is illustrative. Marking a step complete changes the local preview only, not actual task milestone state.
- AI assistant recommendations are display-only. No external requests, AI API key, credentials or sensitive task content.

## Files

- `lib/ui/focusflow_palette.dart` — approved theme colors and Material theme setup
- `lib/ui/demo_task.dart` — non-sensitive mock scenarios from the original design brief
- `lib/ui/focusflow_shell.dart` — responsive Today, Focus and Projects views
- `lib/main.dart` — app entry point with theme switch
- `test/widget_test.dart` — UI smoke tests

## Review and acceptance

Run `flutter pub get`, `flutter analyze`, and `flutter test`; then compare Android 390×844 and a Windows desktop window to the Figma frames. Build via `flutter build apk --debug` and `flutter build windows --debug` on the appropriate toolchains. Validate contrast, overflow and touch targets on devices.

**Not yet implemented:** actual SQLite task history in UI, permanent resumption checkpoints, AI screenshot troubleshooting, roadmap screens, notification controls, full accessibility audit, pixel-perfect Geist typography, and AI sign-in. None of these are implied by this PR.

The project remains offline-first: existing `lib/storage/task_store.dart` and database tests are preserved.
