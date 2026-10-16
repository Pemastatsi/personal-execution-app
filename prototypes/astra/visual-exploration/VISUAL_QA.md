# Visual review

## Scope

Only the Focus and Roadmap presentations are explored. The existing current-milestone view follows the selected visual language because it shares Roadmap navigation. Home, Coach, and Recovery retain their original implementation. `model.dart`, `storage.dart`, and authentication code are unchanged.

## Inspection and refinement

Actual Flutter renders were exported and individually inspected in both themes. Initial findings led to these changes:

- **Precision:** five separate roadmap boxes made the layout feel like a generic card list. Replaced them with one continuous ruled ledger and a strong, inverted current-outcome row. The fixed primary action remains consistent with the Focus panel’s geometry.
- **Atmospheric:** the first Focus layout resembled Precision too closely. Moved the headline onto an open, centered stage, kept detailed instructions in one floating surface, and combined milestone context with the verified-progress arc below. The roadmap uses connected outcome stops and one raised current milestone.
- **Refined Minimalism:** retained the unboxed serif instruction and chapter layout, with readable sans-serif supporting instructions. Warmed dark-mode secondary text to stay consistent with the paper/charcoal direction.
- **Rendering:** Flutter test mode disables soft shadows by default. Enabled normal shadow painting for exports so the gallery reflects the implemented surfaces rather than hard-edged test shadows.
- **Accessibility:** refined the light Atmospheric secondary color after a conservative contrast calculation against the darkest gradient endpoint fell just below 4.5:1. Flexible labels and summary constraints accommodate enlarged text.

The next action, instruction and primary completion control are visible at default text size in all three Focus layouts. All five milestone titles are visible in the default Roadmap viewport. Supplementary roadmap guidance can require a short scroll. Large text intentionally scrolls rather than shrinking instructions; the primary action stays in the fixed footer.

## Validation

Flutter 3.47.7 in [GitHub Actions run 38864356146](https://github.com/Pemastatsi/personal-execution-app/actions/runs/38864356146):

- `flutter analyze`: no issues.
- `flutter test`: all 27 tests passed, including the original suite and six concept/theme interaction flows.
- Dedicated screenshot export: passed; twelve 780 × 1688 PNGs from the 390 × 844 logical viewport.
- Concept tests cover instruction detail, completion and Undo, evidence inspection, milestone navigation, explicit outcome verification, theme switching, entry to Coach/Recovery, and checkpoint retention.
- Android minimum-touch-target and labeled-target guidelines pass for the initial Focus controls in every concept/theme. Layout checks exercise both initial screens and resumed progress at 200% text scaling, including reachable primary actions.
- Gallery checked in Chromium with Playwright: all four view/theme combinations load three full-resolution images; enlargement, Escape dismissal, all-twelve links, and 390-pixel mobile width pass.

Conservative secondary-text contrast checks: Precision light 5.59:1 / dark 8.60:1; Atmospheric light 4.74:1 against the darkest light-gradient endpoint / dark 5.08:1 against the lightest instruction-surface endpoint; Editorial light 5.00:1 / dark 8.77:1. These are token-pair calculations, not a blanket accessibility certification.

The large-text pass caught header crowding in A and B. The decorative wordmark now yields horizontal space; instruction and control text continue to scale. A theme-transition mismatch on return to the existing Coach was also fixed by preserving compatible button text styles.

## Limits and review questions

- These are Flutter widget-renderer screenshots, not physical Android device or emulator captures. System bars, keyboard interaction in the new review entry point, TalkBack reading order, and real-device rendering/performance have not been manually tested.
- No participant study has established a five-second comprehension result or a preference among the concepts.
- Text at 200% can require scrolling for detail and milestone context. Long translated labels and right-to-left layouts are not validated.
- Instruction-detail choices use a compact menu, which saves visual space but adds a tap compared with the original three-button control.
- The review entry point uses in-memory sample state for fair comparisons; it does not promise persistence across process restarts. Existing production/prototype storage behavior is unchanged.
- AI responses, screenshot troubleshooting and tasks remain mocked. The supporting screens intentionally retain the earlier Astra appearance, so transitions are visually mixed until a direction is chosen.
- Motion is limited to existing transitions, Material feedback and progress changes. No custom celebratory animation or gamification was added.
