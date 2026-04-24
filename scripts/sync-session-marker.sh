#!/usr/bin/env bash
# Sync the canonical session-marker.sh from packages/shared/hooks/lib/
# into every packages/*/hooks/lib/ copy (P095 / ADR-038 / ADR-017).
#
# Each package is published as a self-contained npm bundle, so the
# per-plugin hooks/lib/ copy must exist at runtime — but the source
# of truth is packages/shared/hooks/lib/session-marker.sh.
#
# Run this after editing packages/shared/hooks/lib/session-marker.sh
# and before committing. The CI step `npm run check:session-marker`
# fails the build if any copy has diverged.
#
# Usage:
#   bash scripts/sync-session-marker.sh          # sync all copies
#   bash scripts/sync-session-marker.sh --check  # exit non-zero if any copy differs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_SRC="$REPO_ROOT/packages/shared/hooks/lib/session-marker.sh"

if [ ! -f "$SHARED_SRC" ]; then
  echo "ERROR: canonical source not found at $SHARED_SRC" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Consumer plugins that carry UserPromptSubmit hooks gated by the
# session-announcement marker. Each gets a byte-identical copy at
# packages/<plugin>/hooks/lib/session-marker.sh.
CONSUMERS=(architect jtbd tdd style-guide voice-tone itil)

DIVERGED=0
SYNCED=0
CREATED=0

for plugin in "${CONSUMERS[@]}"; do
  target_dir="$REPO_ROOT/packages/$plugin/hooks/lib"
  target="$target_dir/session-marker.sh"

  if [ ! -f "$target" ]; then
    if [ "$MODE" = "check" ]; then
      echo "MISSING: $target"
      DIVERGED=$((DIVERGED + 1))
      continue
    fi
    mkdir -p "$target_dir"
    cp "$SHARED_SRC" "$target"
    chmod +x "$target"
    echo "created:  ${target#$REPO_ROOT/}"
    CREATED=$((CREATED + 1))
    continue
  fi

  if ! diff -q "$SHARED_SRC" "$target" >/dev/null 2>&1; then
    if [ "$MODE" = "check" ]; then
      echo "DIVERGED: $target"
      DIVERGED=$((DIVERGED + 1))
    else
      cp "$SHARED_SRC" "$target"
      echo "synced:   ${target#$REPO_ROOT/}"
      SYNCED=$((SYNCED + 1))
    fi
  fi
done

if [ "$MODE" = "check" ]; then
  if [ "$DIVERGED" -gt 0 ]; then
    echo "" >&2
    echo "ERROR: $DIVERGED copy(ies) of session-marker.sh have diverged or are missing." >&2
    echo "Run: bash scripts/sync-session-marker.sh" >&2
    exit 1
  fi
  echo "OK: all ${#CONSUMERS[@]} hooks/lib/session-marker.sh copies match packages/shared/hooks/lib/session-marker.sh"
else
  if [ "$SYNCED" -eq 0 ] && [ "$CREATED" -eq 0 ]; then
    echo "OK: all ${#CONSUMERS[@]} copies already in sync"
  else
    echo ""
    echo "Synced $SYNCED copy(ies); created $CREATED new copy(ies). Review with: git diff packages/*/hooks/lib/session-marker.sh"
  fi
fi
