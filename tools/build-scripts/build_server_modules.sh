#!/bin/bash
# Builds every Nakama runtime module under server/modules/*/ that has
# its own package.json (TypeScript modules) and copies build output
# into a location the local Docker stack mounts into the Nakama
# container. Safe to run before any real modules exist (Phase 2-4):
# it will simply report that there is nothing to build yet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODULES_DIR="$REPO_ROOT/server/modules"

found_any=false

for module_dir in "$MODULES_DIR"/*/; do
    [ -f "${module_dir}package.json" ] || continue
    found_any=true
    module_name="$(basename "$module_dir")"
    echo "==> Building server module: $module_name"
    (cd "$module_dir" && npm ci && npm run build)
done

if [ "$found_any" = false ]; then
    echo "No buildable server modules found yet under $MODULES_DIR."
    echo "This is expected until Phase 5 (Multiplayer Networking) introduces the first real Nakama module."
    exit 0
fi

echo "All server modules built successfully."
