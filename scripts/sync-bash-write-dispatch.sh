#!/usr/bin/env bash
# Keep the self-contained plugin copies of bash-write-dispatch.sh identical.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO_ROOT/packages/shared/hooks/lib/bash-write-dispatch.sh"
MODE="${1:-sync}"
CONSUMERS=(architect jtbd style-guide voice-tone tdd)
diverged=0

for plugin in "${CONSUMERS[@]}"; do
  target="$REPO_ROOT/packages/$plugin/hooks/bash-write-dispatch.sh"
  if [ "$MODE" = "--check" ]; then
    if ! cmp -s "$SOURCE" "$target"; then
      echo "DIVERGED: $target"
      diverged=$((diverged + 1))
    fi
  else
    cp "$SOURCE" "$target"
    chmod +x "$target"
  fi
done

if [ "$MODE" = "--check" ]; then
  [ "$diverged" -eq 0 ] || exit 1
  echo "OK: all ${#CONSUMERS[@]} bash-write-dispatch.sh copies match"
fi
