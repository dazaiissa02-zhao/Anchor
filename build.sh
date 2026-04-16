#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/dist/Anchor.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS"
mkdir -p "$RESOURCES"
touch "$RESOURCES/.keep"
cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"

swiftc \
  -framework AppKit \
  -framework Carbon \
  -framework UserNotifications \
  "$ROOT/Sources/main.swift" \
  -o "$MACOS/Anchor"

chmod +x "$MACOS/Anchor"
echo "Built: $APP"
