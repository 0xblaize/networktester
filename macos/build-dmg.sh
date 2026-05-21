#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/macos/build"
APP_DIR="$BUILD_DIR/NetworkTester.app"
DMG_ROOT="$BUILD_DIR/dmg-root"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
DIST_DIR="$ROOT_DIR/dist"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$DIST_DIR"

swiftc "$ROOT_DIR/macos/NetworkTesterMac.swift" \
  -parse-as-library \
  -o "$MACOS_DIR/NetworkTester" \
  -framework SwiftUI \
  -framework Foundation \
  -framework AppKit

cp "$ROOT_DIR/macos/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/NetworkTester"

mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"

rm -f "$DIST_DIR/NetworkTester.dmg"
hdiutil create \
  -volname "NetworkTester" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DIST_DIR/NetworkTester.dmg"

echo "Built: $DIST_DIR/NetworkTester.dmg"
