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

Validation results and final render provenance are recorded here after the final CI pass.

## Limits and review questions

- These are Flutter widget-renderer screenshots, not physical Android device or emulator captures. System bars, keyboard interaction in the new review entry point, TalkBack reading order, and real-device rendering/performance have not been manually tested.
- No participant study has established a five-second comprehension result or a preference among the concepts.
- Text at 200% can require scrolling for detail and milestone context. Long translated labels and right-to-left layouts are not validated.
- Instruction-detail choices use a compact menu, which saves visual space but adds a tap compared with the original three-button control.
- The review entry point uses in-memory sample state for fair comparisons; it does not promise persistence across process restarts. Existing production/prototype storage behavior is unchanged.
- AI responses, screenshot troubleshooting and tasks remain mocked. The supporting screens intentionally retain the earlier Astra appearance, so transitions are visually mixed until a direction is chosen.
- Motion is limited to existing transitions, Material feedback and progress changes. No custom celebratory animation or gamification was added.
