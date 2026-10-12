#!/bin/bash
# Packages Conclave as a portable app: one self-contained bundle with no
# installer and no dependencies, delivered as a disk image and a zip archive
# that can be copied to any Mac or carried on a USB drive.
# Usage: Scripts/package.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/Conclave.app"

"$ROOT/Scripts/build_app.sh"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")"
DMG="$DIST/Conclave-$VERSION.dmg"
ZIP="$DIST/Conclave-$VERSION.zip"

echo "==> Verifying bundle"
codesign --verify --deep --strict "$APP"
echo "    architectures: $(lipo -archs "$APP/Contents/MacOS/Conclave")"

echo "==> Creating disk image"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/Conclave.app"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG"
hdiutil create -quiet -volname "Conclave" -srcfolder "$STAGING" -fs HFS+ -format UDZO "$DMG"

echo "==> Creating zip archive"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Portable packages ready"
ls -lh "$DMG" "$ZIP" | awk '{ print "    " $5 "  " $9 }'
