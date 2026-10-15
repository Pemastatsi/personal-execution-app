# Personal Execution App — UI/UX Design Competition Brief
**Version:** 1.0 — October 15, 2026
**Purpose:** Independent design proposals only. Do not implement production functionality, modify production Flutter UI, or introduce API billing.

## Product vision
A calm, ADHD-friendly AI-guided personal execution companion for Android (primary) and synchronized Windows (secondary). Reduce overwhelm and time wasted researching, organizing, and planning. Make the next physical action immediately obvious and preserve momentum across interruptions. This is an execution product, **not** a traditional productivity dashboard.

## Intended user behavior (evidence from 37-question interview)
- Seeing a large task backlog causes overwhelm.
- Unknown multi-step processes stall work, particularly unfamiliar software.
- Research rabbit holes and overplanning interrupt execution.
- On launch: offer to **resume** an active unfinished task at the exact next action; otherwise offer just **2–3 user-selected tasks**.
- User sets task priorities. AI may suggest, but never reprioritizes, activates suggested tasks, modifies roadmap or marks milestones complete without approval.
- Complex projects: generate a concise high-level milestone roadmap, but plan concrete instructions only for the **current milestone**.
- AI guide: show **one instruction at a time**, adjustable detail (micro/normal/high-level), help interpret screenshots, diagnose and resolve blockers, direct but not patronizing tone.
- Progress must reflect **meaningful objective milestones**, not minutes spent, message counts, or micro-actions. AI recommends milestone completion; user confirms.
- Switch tasks instantly while saving last action, blocker, relevant context and what to do next.
- Show focus, current-milestone and full-roadmap views, switchable; focus is default.
- Full project history is retained privately; AI works from a concise rolling memory to support resumption.
- Idea Parking Lot: capture interesting future research without disrupting the task.
- Task suggestions: all require explicit user approval; show **2–3 at a time**, separately from committed work.
- Flexible notification schedule, daily cap, quiet hours, paused-reminder mode.
- Low-ceremony task capture using typing, voice where available, and screenshots/files.
- Minimal gamification: **no XP, fake points, streak guilt, flashy confetti, or cartoon overload**. Satisfaction comes from visible outcome progress and considerate feedback.
- Task domains for v1: complex technical/research projects; personal admin; quick postponed chores.
- AI offers advice only; user performs outside actions. No agent that clicks/sends on user's behalf.
- If embedded AI is unavailable, offline tasks and milestones still work; offer to continue in official ChatGPT, clearly noting manual return of context.
- No separately billed AI API; runtime feasibility is being tested separately. These design prototypes should have **mock data only**.

## Required comparable screens — Android first, 390 x 844 logical pixels
1. **Home / Resume**: one active work card (or 2–3 task choices) and clear primary CTA, compact progress; optional access to suggestions.
2. **Focus / Next action**: one actionable instruction, small milestone context, Completed / I'm Stuck / Ask AI / Switch Task; adjustable detail.
3. **AI coach / Screenshot troubleshooting**: conversation tied to task, prominent screenshot attachment, a brief answer containing a single next instruction, obvious Back to Focus.
4. **Milestone / Roadmap**: verified progress, outcomes completed and pending, ability to toggle milestone vs full roadmap without intimidating nested checklists.
5. **Switch task / Recovery**: preserve checkpoint and reopen exact next action. Can be sheet/modal tied to screen 1.
Optional: a two-to-three-item Suggestions Inbox and Idea Parking Lot, only if the five core screens are excellent.

## Sample MOCK tasks (do not use real private data)
- “Build a trading indicator” — 2 of 5 outcomes verified; current: “Compile the indicator without errors”; next instruction: “Open the editor and locate the error list.”
- “Send an application form” — current: “Find the required ID document.”
- “Replace a household light bulb” — quick task.

## Style requirements
Modern, polished, genuinely usable phone design. Excellent typography, generous but not wasteful spacing, clear information hierarchy, accessible contrast, generous touch targets, light and dark modes. Don't mimic ChatGPT or any existing task app wholesale. Attractive, but no complex dashboards, relentless stats, artificial gamification, or sprawl.

## Competition instructions
Each AI/tool independently propose a visually distinct, coherent concept using exactly the same product brief, screens, and sample data. Produce:
- 5 linked mobile screens (interactive/clickable where supported)
- 1 example of a return-after-two-weeks resumption flow
- light & dark theme samples
- brief explanation of core design decisions and potential usability risks
- screenshot exports or shareable link for comparison
**Do not add new product features**, backend code, AI keys, real user data, or billing. Each contender can choose its own visual direction without seeing the others.

## Evaluation rubric
- Next action understood in 5 seconds: 30%
- Minimum friction from opening to doing: 25%
- Easy blocker recovery & session return: 20%
- Visually calm, accessible, appealing: 15%
- Straightforward Flutter implementation: 10%

## Technical handoff
Winning design will guide Codex's implementation in Flutter; HTML/React/Figma exports are **design references, not production Flutter code**. Preserve the existing source repository; prototypes should be isolated from `lib/` production code or on separate branches. Keep security and API feasibility separate from UI exploration.
