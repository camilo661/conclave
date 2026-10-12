#!/bin/bash
# Builds Conclave.app into ./dist from the Swift package.
# Usage: Scripts/build_app.sh [--run]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Conclave.app"
WORK="$ROOT/.build/app-assets"

# Universal binary: the same app runs on Apple Silicon and Intel Macs.
ARCHS=(--arch arm64 --arch x86_64)

echo "==> Compiling"
swift build -c release --package-path "$ROOT" "${ARCHS[@]}"
BIN_DIR="$(swift build -c release --package-path "$ROOT" "${ARCHS[@]}" --show-bin-path)"

echo "==> Rendering icon"
rm -rf "$WORK"
mkdir -p "$WORK"
swift "$ROOT/Scripts/make_icon.swift" "$ROOT/Resources/Brand/logo.jpg" "$WORK/AppIcon.iconset"
iconutil --convert icns "$WORK/AppIcon.iconset" --output "$WORK/AppIcon.icns"

echo "==> Assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Conclave" "$APP/Contents/MacOS/Conclave"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$WORK/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$WORK/AppIcon.iconset/icon_512x512.png" "$APP/Contents/Resources/logo.png"
cp -R "$ROOT/Resources/es.lproj" "$APP/Contents/Resources/es.lproj"

echo "==> Signing (sandbox + hardened runtime)"
codesign --force --options runtime \
    --entitlements "$ROOT/Resources/Conclave.entitlements" \
    --sign - "$APP"

echo "==> Built $APP"
if [[ "${1:-}" == "--run" ]]; then
    open "$APP"
fi
