# Technical Notes

## Stack

- macOS native desktop app
- Swift
- AppKit
- Menu bar app via `NSStatusItem`
- Local JSON persistence
- Built with `swiftc` through `build.sh`

There is no package manager or Xcode project yet.

## Entry Point

All app code currently lives in:

```text
Sources/main.swift
```

This is acceptable for the prototype, but it should be split once the behavior stabilizes.

Suggested future modules:

- `AppDelegate`
- `DataStore`
- `Models`
- `MainWindowController`
- `CaptureWindowController`
- `ReviewCheckpoint`
- `ReminderEngine`
- `UIComponents`

## Persistence

Data is stored as JSON:

```text
~/Library/Application Support/Anchor/anchor-data.json
```

The current model is:

- `AnchorState`
- `FocusSession`
- `CapturedThought`
- `AnchorTask`

The JSON encoder uses pretty printing and sorted keys to make local debugging easier.

## Timing Logic

The app keeps a repeating 1-second timer.

On each tick:

- update status icon
- rebuild menu
- update visible countdown and elapsed time
- check whether the current anchor has reached zero
- trigger reminders if needed

Elapsed time excludes paused time.

When a session enters review, elapsed time is calculated from `endedAt`, so review time does not inflate the session duration.

## Reminder Logic

Current reminder types:

- midpoint reminder
- fixed 5-minute reminder
- thought spike reminder after 3 thoughts within 5 minutes
- time-up notification

Reminder copy and timing should be revisited after more real usage.

## Build

```bash
./build.sh
```

The script creates:

```text
dist/Anchor.app
```

It also places a placeholder file in `Contents/Resources` so ad-hoc signing behaves consistently.

## Current Technical Debt

- `Sources/main.swift` is too large.
- UI helpers are mixed with product logic.
- Review, reminders, and persistence need clearer boundaries.
- There are no automated tests.
- There is no release packaging or update flow.
- The app is ad-hoc signed only.
- Accessibility has not been reviewed.
- Keyboard handling is minimal.
