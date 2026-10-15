# Design review and validation

The visual direction uses warm paper and violet surfaces, restrained green for verified outcomes, Newsreader for welcoming headings, and Manrope for action instructions. The Focus screen gives most of its area to one instruction. Navigation and progress provide context without presenting a backlog.

## Actual visual review

All five screens were rendered by Flutter at 390 × 844 logical pixels in both themes and inspected. The [gallery](screenshots/README.md) contains the exports. Review led to these refinements:

- Gave selected dark-theme tabs their own tinted surface.
- Corrected the coach send-arrow contrast in both themes.
- Bundled a monospace font so the fictional software screenshot renders faithfully.
- Made labels and utility actions wrap at larger text sizes.
- Moved transient feedback above primary controls and dismiss it when changing screens.
- Hid secondary coach context and attachment controls while typing, keeping the composer usable with a keyboard and large text.

The renders use Flutter's test engine with the actual bundled fonts. They are not emulator or physical-device screenshots.

## Accessibility measurements

Calculated WCAG contrast ratios for the actual palette:

| Text pairing | Light | Dark |
| --- | ---: | ---: |
| Main text / page | 13.70:1 | 15.54:1 |
| Secondary text / page | 5.23:1 | 8.60:1 |
| Primary button label / fill | 6.40:1 | 9.08:1 |
| Secondary text / tinted panel | 4.63:1 | 6.61:1 |

Interactive controls have at least 48 logical-pixel target heights. Automated tests cover target dimensions and labels, all five views at 100%, 150% and 200% text size, and the coach with a 300-pixel keyboard inset. Content can scroll; text scaling is not capped. Page/action transitions respect the platform's reduced-motion preference.

## Behaviour checked by the test suite

The tests cover resume → complete → help → mock screenshot → return, immediate task switching, saved checkpoints restored into a new model, theme changes, quick capture without replacing active work, milestone confirmation, Undo, and the two-week fixture. Micro-actions and AI responses cannot verify an outcome.

CI runs `flutter analyze`, `flutter test`, a separate screenshot export test, and `flutter build apk --debug`. Build and test results are attached to the [PR](https://github.com/Pemastatsi/personal-execution-app/pull/2). The production starter's separate CI is preserved.

## Remaining validation

No physical Android device, emulator, TalkBack session, or study with ADHD participants was used. Device SQLite lifecycle testing, Android system-bar/keyboard variations, and long-session usability remain untested. AI responses and screenshot interpretation are deliberately mocked. The two-week flow uses fictional dated sample state, not a longitudinal test.
