# Anchor Desktop

Anchor is a small macOS menu bar tool for staying with one task at a time.

It is intentionally rough right now. The current goal is not to look finished, but to keep the core interaction alive enough for real daily testing:

- name the one thing you are doing now
- name the next concrete action
- park stray thoughts without following them
- return to the current task
- review or extend the time block when the timer ends

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
│   ├── CaptureWindowController.swift
│   ├── MainWindowController.swift
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
