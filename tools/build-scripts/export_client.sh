#!/bin/bash
# Exports the Godot client using a named export preset defined in
# client/export_presets.cfg. That file does not exist yet (export
# presets/signing config are configured starting Phase 13 as part of
# the beta build pipeline) — this script fails fast with a clear
# message rather than silently doing nothing, so CI/devs know exactly
# why a build didn't happen.
#
# Usage: ./tools/build-scripts/export_client.sh <preset-name> <output-path>
# Example: ./tools/build-scripts/export_client.sh "Android" build/warzone.apk
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLIENT_DIR="$REPO_ROOT/client"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <preset-name> <output-path>" >&2
    exit 1
fi

PRESET_NAME="$1"
OUTPUT_PATH="$2"

if ! command -v godot4 >/dev/null 2>&1; then
    echo "ERROR: 'godot4' binary not found on PATH." >&2
    exit 1
fi

if [ ! -f "$CLIENT_DIR/export_presets.cfg" ]; then
    echo "ERROR: $CLIENT_DIR/export_presets.cfg does not exist yet." >&2
    echo "Export presets are configured in Phase 13 (Optimization) / Phase 15 (Closed Beta) build pipeline work." >&2
    exit 1
fi

godot4 --headless --path "$CLIENT_DIR" --export-release "$PRESET_NAME" "$OUTPUT_PATH"
echo "Exported '$PRESET_NAME' -> $OUTPUT_PATH"
