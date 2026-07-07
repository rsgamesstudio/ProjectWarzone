#!/bin/bash
# Runs the GUT (Godot Unit Test) suite headlessly against the client
# project and exits non-zero on any test failure, so it can gate CI.
#
# Usage: ./tools/build-scripts/run_gdscript_tests.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLIENT_DIR="$REPO_ROOT/client"

if ! command -v godot4 >/dev/null 2>&1 && ! command -v godot >/dev/null 2>&1; then
    echo "ERROR: neither 'godot4' nor 'godot' binary found on PATH." >&2
    exit 1
fi

GODOT_BIN="$(command -v godot4 || command -v godot)"

echo "==> Running GUT test suite via $GODOT_BIN"
"$GODOT_BIN" --headless --path "$CLIENT_DIR" \
    -s addons/gut/gut_cmdln.gd \
    -gconfig=.gutconfig.json

echo "All GDScript tests passed."
