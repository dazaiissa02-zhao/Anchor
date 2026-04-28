# Next Agent

This file is the short-lived handoff for the next Anchor session.

Update it whenever:

- the current chat window is getting full
- work is being paused and resumed later
- a different agent will take over

Keep it brief and operational. If something belongs here permanently, move it into `AGENT_HANDOFF.md` or `STATUS.md`.

## Last Updated

- Date: 2026-04-28
- By: Codex

## Current Branch

- `main`

## Current Reality

- GitHub `main` should be treated as the latest shared source of truth for Anchor.
- The local backup branch `backup/pre-sync-20260427` has already been removed.
- The latest design-sketch visual direction has been added to `docs/design-sketch.html`.
- The next cleanup goal is not product behavior yet, but smoother agent-to-agent continuity.

## What Was Just Finished

- Confirmed that `anchor-desktop` is the active latest product line.
- Verified the app still builds successfully with `./build.sh`.
- Cleaned old local branch clutter.
- Added this short-form handoff workflow so future sessions do not depend on old chat windows.

## What Is In Progress

- Project context is now split into:
  - `docs/AGENT_HANDOFF.md` for durable context
  - `docs/STATUS.md` for current product assessment
  - `docs/NEXT_AGENT.md` for short-lived execution state

## Recommended Next Action

- Keep using this file whenever a session is about to roll over.
- For the next product task, start by checking whether the user wants:
  - visual refinement
  - review UX improvements
  - inbox flow improvements
  - tests / release hygiene

## Known Sharp Edges

- Do not assume old chat windows contain unique truth. If it matters, write it into the repo.
- If local git networking to GitHub fails again, verify remote state through the GitHub connector before making repo-level decisions.
- `docs/design-sketch.html` is now an important visual reference and should not drift casually.

## Handoff Checklist

- Update this file
- Update `STATUS.md` if product state changed
- Update `AGENT_HANDOFF.md` if durable rules changed
- Commit
- Push or otherwise sync remote state
