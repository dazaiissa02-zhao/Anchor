# Anchor Agent Handoff

This document gives any incoming agent the minimum product and implementation context needed to work on Anchor without re-deriving the current state from chat history.

## Product Snapshot

- Product name: Anchor Desktop
- Platform: macOS menu bar app
- Current stage: high-fidelity internal alpha
- Current goal: make the product feel calm, precise, and daily-usable before treating it as a public beta

Anchor is not a task manager. It is a small companion for protecting one current task while catching side thoughts without acting on them immediately.

## Core Product Model

- Current anchor: the one thing the user is staying with now
- Return note: an optional reminder for what to come back to
- Parked thought: a thought captured now and processed later
- Inbox: thoughts captured outside an active anchor
- Review / checkpoint: the moment when one anchor block ends and the user chooses to continue, complete, or change anchor

## Stage Assessment

Anchor is no longer a concept mock or static prototype.

It already supports a real end-to-end usage loop:

1. define an anchor
2. start a timed focus block
3. park stray thoughts without leaving the block
4. pause or resume if needed
5. review the block when time is up
6. continue, complete, or change anchor
7. revisit the day through review history

What it is not yet:

- not a polished public beta
- not packaged for release
- not visually finalized
- not fully tested

## What Is Implemented

- Main anchor planning view
- Active running state
- Pause and resume flow
- Review / checkpoint flow
- Configurable continuation durations
- Star-based menu bar entry
- Thought parking from the app and capture window
- Inbox page inside the main window
- Start anchor directly from inbox thoughts
- Delete confirmation for inbox thoughts
- Daily review page
- Past-date review via right-side calendar panel
- Local persistence in `~/Library/Application Support/Anchor/anchor-data.json`

## What Is Still Rough

- Visual refinement is incomplete
- The review experience still feels more mechanical than reflective
- Some hierarchy and spacing across surfaces still need cleanup
- Onboarding does not exist yet
- Privacy / data explanation is missing in-product
- Automated tests are missing
- Release packaging and versioning are missing

## Important Product Decisions

These decisions are active and should not be casually reverted:

- The product centers the current anchor, not a next-step productivity system.
- The interface should emphasize “what am I holding now,” not “what should I do after this.”
- “Star parking” should not visually compete with the current anchor.
- During active focus, thought parking should stay lightweight and usually collapsed by default.
- Avoid modal-on-modal interactions. Prefer page shifts, drawer-like expansion, or surface transitions.
- Inbox thoughts can directly become new anchors.
- Deleting inbox thoughts must require confirmation.
- The review page now uses a right-side calendar panel for past dates instead of a system date-picker strip.
- The product should stay emotionally quiet and non-judgmental.

## Visual Reference Files

Primary visual reference:

- `docs/design-sketch.html`

Secondary visual reference:

- `/Users/zhaozhao/Documents/codex/my-visualization-page/public/anchor-design-sketch.html`

Mechanism overview:

- `docs/anchor-mechanism-overview.html`

When there is a conflict between old rough UI and the sketch files, prefer the sketch direction over legacy implementation details.

## Files That Usually Matter

Product behavior and surfaces:

- `Sources/MainWindowController.swift`
- `Sources/AppDelegateActions.swift`
- `Sources/AppDelegateSession.swift`
- `Sources/AppDelegateMenu.swift`
- `Sources/CaptureWindowController.swift`

Visual system:

- `Sources/Constants.swift`
- `Sources/UIHelpers.swift`

Persistence and models:

- `Sources/DataStore.swift`
- `Sources/Models.swift`

## Working Rules For Future Agents

- Do not turn Anchor into a full task manager.
- Do not reintroduce loud default AppKit-looking controls if a calmer custom surface already exists.
- Do not make parked thoughts more visually prominent than the current anchor.
- Do not add nested popovers or nested modal flows unless there is no other option.
- Prefer precise, calm labels over productivity jargon.
- Preserve the warm paper / starlight visual direction unless explicitly changed by the user.

## Recommended Next Priorities

1. Visual cleanup across focus, review, inbox, and daily review
2. Better review experience and more natural output capture
3. Inbox processing flow beyond open-or-delete
4. State-transition tests
5. Onboarding and privacy explanation
