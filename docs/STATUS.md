# Anchor Status

Last updated: 2026-04-26

## Current Stage

High-fidelity internal alpha.

Anchor is already usable for real daily self-testing, but it is not yet ready to be treated as a public beta.

## Current Product Position

Anchor is a macOS menu bar tool for holding one current task while safely parking unrelated thoughts.

It should remain:

- small
- calm
- non-judgmental
- centered on the current anchor

It should not drift into a full task manager.

## What Is Working Now

- Start an anchor from the main window
- Set an anchor duration
- Run, pause, and resume a focus block
- Park thoughts during a block
- Open a separate star-parking capture window
- Review a finished block
- Continue a block with multiple duration choices
- Write review output
- Change / abandon the current anchor
- View inbox thoughts
- Start a new anchor directly from inbox thoughts
- Delete inbox thoughts with confirmation
- Review the current day
- Switch to past recorded days using the right-side calendar

## What Still Needs Work

- Final visual polish and consistency
- Better empty states and spacing rhythm
- More graceful review UX
- Better inbox processing depth
- Onboarding
- Privacy / data explanation
- Automated tests
- Release packaging / versioning

## Current Design Source Of Truth

Primary:

- `docs/design-sketch.html`

Secondary:

- `/Users/zhaozhao/Documents/codex/my-visualization-page/public/anchor-design-sketch.html`

Support:

- `docs/anchor-mechanism-overview.html`

## Active UX Decisions

- Current anchor is the primary focus.
- Return note is optional.
- Thought parking should stay lightweight.
- Running state should not expose a large thought editor by default.
- Inbox thoughts can directly become anchors.
- Past-date review uses a right-side calendar panel.

## Current Biggest Risks

- The implementation can work, but some surfaces still feel prototype-like.
- The codebase has moved faster than its tests and docs.
- README and product notes still contain some outdated statements compared with the current implementation.

## Recommended Next Moves

1. Do one full visual pass on the major surfaces.
2. Align docs with the current product reality.
3. Add state-flow tests for session lifecycle.
4. Improve inbox and review depth.
5. Prepare the app for a cleaner internal release cycle.
