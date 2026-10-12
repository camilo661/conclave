#!/bin/bash
# Runs the unit tests.
# The standalone Command Line Tools do not put the Swift Testing macro plugin
# on the compiler's search path, so it is added here when present.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"

FLAGS=()
if [[ -d "$PLUGINS" ]]; then
    FLAGS=(-Xswiftc -plugin-path -Xswiftc "$PLUGINS")
fi

swift test --package-path "$ROOT" "${FLAGS[@]}" "$@"
