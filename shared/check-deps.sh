#!/bin/bash
# Shared dependency checker for windyroad-plugins marketplace.
# Called by each plugin's SessionStart hook with a list of required plugins.
#
# Usage: check-deps.sh <this-plugin-name> <required-plugin-1> [required-plugin-2] ...
#
# Checks if required sibling plugins are installed by looking for their
# .claude-plugin/plugin.json in the plugin cache. Outputs a warning to
# stderr (which surfaces as hook output) if any are missing.

set -euo pipefail

PLUGIN_NAME="${1:?Usage: check-deps.sh <plugin-name> <dep1> [dep2] ...}"
shift

MISSING=()

for DEP in "$@"; do
  # Check if the dependency plugin is installed by looking for its marker.
  # Installed plugins have their hooks loaded, so we check if the dep's
  # hooks are present in the session. Simplest check: look for the plugin
  # name in the installed plugins list.
  FOUND=false

  # Method 1: Check installed_plugins.json
  if [ -f "$HOME/.claude/plugins/installed_plugins.json" ]; then
    if python3 -c "
import json, sys
data = json.load(open('$HOME/.claude/plugins/installed_plugins.json'))
plugins = data.get('plugins', {})
for key in plugins:
    if key.startswith('${DEP}@'):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
      FOUND=true
    fi
  fi

  # Method 2: Check if plugin dir exists in cache
  if [ "$FOUND" = false ]; then
    for dir in "$HOME/.claude/plugins/cache/"*/"$DEP"/*/; do
      if [ -f "${dir}.claude-plugin/plugin.json" ] 2>/dev/null; then
        FOUND=true
        break
      fi
    done
  fi

  # Method 3: Check if loaded via --plugin-dir (plugin hooks would be active)
  # We can't easily check this, so we rely on methods 1 and 2.

  if [ "$FOUND" = false ]; then
    MISSING+=("$DEP")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "WARNING: Plugin '$PLUGIN_NAME' requires the following plugins that may not be installed:"
  for m in "${MISSING[@]}"; do
    echo "  - $m (install with: /plugin install $m@windyroad-plugins)"
  done
  echo ""
fi
