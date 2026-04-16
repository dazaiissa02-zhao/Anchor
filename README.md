# Anchor Desktop

Anchor is a small macOS menu bar tool for staying with one task at a time while still preserving the thoughts that appear along the way.

## Why This Exists

Some work does not fail because the task is hard. It fails because attention keeps branching.

You start one thing, then a related thought appears. That thought creates another idea, a concern, a possible task, a thing to look up, a message to send, or a better version of the thing you are doing. Many of those thoughts are useful, but if you follow them immediately, the current task never gets deep enough to produce anything.

Anchor exists to protect the current task without throwing those thoughts away.

The core idea is simple:

- keep one current anchor visible
- define the next concrete action
- park stray thoughts immediately
- return to the action instead of processing the thought now
- review the parked thoughts after the focus block

It is not meant to be a full task manager, notes app, or productivity system. It is a small companion for the exact moment when attention wants to leave the current task.

## Product Intent

Anchor separates two actions that often get mixed together:

- capture the thought
- decide what to do with it

During a focus block, the user should not need to decide whether a new thought is important, urgent, actionable, or worth keeping. They only need a safe place to put it. Decision-making happens later, when the current block is finished.

The tool should help the user answer four questions at any moment:

- What am I doing now?
- What is the next concrete action?
- How long have I been doing this?
- Where can I put unrelated thoughts without following them?

The tone should be calm and non-judgmental. Abandoning an anchor is allowed. Parking many thoughts is allowed. The product's job is not to shame the user into focus, but to gently keep the present task from being displaced.

## Current Prototype

The current version is intentionally rough. The goal is not to look finished yet, but to keep the core interaction alive enough for real daily testing:

- name the one thing you are doing now
- name the next concrete action
- park stray thoughts without following them
- return to the current task
- review or extend the time block when the timer ends

The macOS menu bar star is the persistent entry point:

- `☆` idle
- `★` focusing
- `✦` reviewing

## Status

Alpha. Built through fast product iteration and still needs design, packaging, and code cleanup.

Known rough edges are tracked in [docs/ROADMAP.md](docs/ROADMAP.md).

## Current Interaction

- Menu bar star:
  - `☆` idle
  - `★` focusing
  - `✦` reviewing
- Main window:
  - current task
  - next action
  - remaining time
  - elapsed time
  - pause, park thought, finish, or abandon
- Thought drawer:
  - `Option + Command + J`
  - park a thought
  - view current-anchor thoughts and inbox thoughts
- Time-up checkpoint:
  - continue for 15 more minutes
  - complete review
  - abandon current anchor

## Build

Requirements:

- macOS
- Xcode command line tools
- Swift compiler available as `swiftc`

Build:

```bash
./build.sh
```

The app bundle is written to:

```text
dist/Anchor.app
```

Run:

```bash
open dist/Anchor.app
```

## Data

Local data is stored at:

```text
~/Library/Application Support/Anchor/anchor-data.json
```

The data file is intentionally not part of this repository.

## Repository Layout

```text
.
├── Info.plist
├── Sources/
│   ├── AppDelegate.swift
│   ├── AppDelegateActions.swift
│   ├── AppDelegateMenu.swift
│   ├── AppDelegateSession.swift
│   ├── CaptureWindowController.swift
│   ├── Constants.swift
│   ├── DataStore.swift
│   ├── HotKeyCenter.swift
│   ├── MainWindowController.swift
│   ├── Models.swift
│   ├── UIHelpers.swift
│   └── main.swift
├── build.sh
├── docs/
│   ├── PRODUCT.md
│   ├── TECHNICAL.md
│   └── ROADMAP.md
└── README.md
```

## Design Principle

Anchor should feel like a quiet companion, not another system to manage.

The product should stay small:

- the star wakes the tool
- the main window anchors the current task
- the thought drawer catches stray thoughts
- the checkpoint decides whether to continue, finish, or abandon

## License

MIT. See [LICENSE](LICENSE).
