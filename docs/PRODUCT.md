# Product Notes

## Problem

The user often starts one task, then quickly branches into related thoughts, follow-up ideas, concerns, and side quests. Those thoughts may be useful, but following them immediately breaks depth and makes the day feel unproductive.

Anchor exists to separate two actions:

- capture the thought
- decide what to do with it later

## Target Behavior

The tool should help the user stay with the current task without shaming or over-controlling them.

The user should always know:

- what am I doing now
- what is the next action
- how long have I been doing it
- how much time remains
- where can I put unrelated thoughts

## Core Objects

### Anchor

An anchor is the current focused task.

It has:

- task title
- next action
- duration
- start time
- active status
- parked thoughts
- optional review output

### Parked Thought

A parked thought is a thought captured without acting on it immediately.

It may belong to:

- the current anchor
- the inbox, if no anchor is running

### Inbox

The inbox stores thoughts captured when there is no active anchor.

It should not become a task manager. It is a temporary holding area.

## Current Flow

1. Start an anchor with a task, next action, and time block.
2. During the block, park stray thoughts with the thought drawer.
3. The app reminds the user to return to the next action.
4. When time is up, the app shows a checkpoint.
5. The user chooses one of:
   - continue 15 minutes
   - complete review
   - abandon the anchor

## Product Principles

- Keep the main window focused on one thing.
- Do not make parked thoughts visually compete with the current anchor.
- Avoid adding task-manager complexity too early.
- Prefer explicit actions over vague buttons.
- Allow abandonment as a valid outcome.
- Keep the tone calm and non-judgmental.

## Known Product Problems

- The visual design is still early and not emotionally polished enough.
- Review and thought processing are too mechanical.
- There is no clean way to convert inbox thoughts into future anchors.
- The app has no onboarding.
- The app does not explain what data it stores.
- Notifications need better copy and timing.
- The menu, main window, and thought drawer need more consistent hierarchy.
