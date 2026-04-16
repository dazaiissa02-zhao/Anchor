# Roadmap

This roadmap is intentionally honest. Anchor is useful enough to test, but not yet good enough to call finished.

## Next

- Make the main window visually quieter and more polished.
- Improve the time-up checkpoint.
- Make parked thoughts easier to process after a block.
- Add a clear inbox flow.
- Improve notification copy and timing.
- Split `Sources/main.swift` into smaller files.
- Add basic tests for timing and state transitions.

## Product

- Start anchor from a parked inbox thought.
- Add configurable continuation durations.
- Add a simple daily summary.
- Add a way to archive or clear old inbox thoughts.
- Add onboarding for first launch.
- Add privacy and data location explanation inside the app.

## Design

- Create a real app icon and menu bar icon.
- Normalize typography across all windows.
- Improve spacing and visual rhythm.
- Make the thought drawer feel calmer.
- Improve empty states.
- Review dark mode behavior.

## Engineering

- Split the single Swift file into modules.
- Add model-level tests for:
  - start session
  - pause and resume
  - elapsed time
  - continue from review
  - abandon session
  - parked thoughts and inbox
- Add a Swift package or Xcode project.
- Add CI build checks.
- Add release packaging.
- Add versioning.

## Later

- Optional AI-assisted review.
- Optional cloud sync.
- Optional cross-device inbox.
- Optional desktop floating widget.
- Optional shortcuts integration.
