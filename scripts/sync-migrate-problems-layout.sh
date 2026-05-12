#!/usr/bin/env bash
# Sync the canonical migrate-problems-layout.sh from packages/shared/lib/
# into every consumer plugin's lib/ copy (P170 / RFC-002 / ADR-031 / ADR-017).
#
# Each plugin is published as a self-contained npm bundle, so the
# per-plugin lib/ copy must exist at runtime — but the source of truth
# is packages/shared/lib/migrate-problems-layout.sh.
#
# Run this after editing packages/shared/lib/migrate-problems-layout.sh
# and before committing. The CI step `npm run check:migrate-problems-layout`
# fails the build if any copy has diverged.
#
# Usage:
#   bash scripts/sync-migrate-problems-layout.sh          # sync all copies
#   bash scripts/sync-migrate-problems-layout.sh --check  # exit non-zero if any copy differs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_SRC="$REPO_ROOT/packages/shared/lib/migrate-problems-layout.sh"

if [ ! -f "$SHARED_SRC" ]; then
  echo "ERROR: canonical source not found at $SHARED_SRC" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Consumer plugins that source this routine at skill Step 1.
# T7 ships with itil as the only consumer; future consumers (e.g. a
# retrospective skill that wants the same auto-migrate posture) get
# added here.
CONSUMERS=(itil)

DIVERGED=0
SYNCED=0
CREATED=0

for plugin in "${CONSUMERS[@]}"; do
  target_dir="$REPO_ROOT/packages/$plugin/lib"
  target="$target_dir/migrate-problems-layout.sh"

  if [ ! -f "$target" ]; then
    if [ "$MODE" = "check" ]; then
      echo "MISSING: $target" >&2
      DIVERGED=$((DIVERGED + 1))
    else
      mkdir -p "$target_dir"
      cp "$SHARED_SRC" "$target"
      chmod +x "$target"
      echo "CREATED: $target"
      CREATED=$((CREATED + 1))
    fi
    continue
  fi

  if ! cmp -s "$SHARED_SRC" "$target"; then
    if [ "$MODE" = "check" ]; then
      echo "DIVERGED: $target" >&2
      DIVERGED=$((DIVERGED + 1))
    else
      cp "$SHARED_SRC" "$target"
      chmod +x "$target"
      echo "SYNCED: $target"
      SYNCED=$((SYNCED + 1))
    fi
  fi
done

if [ "$MODE" = "check" ]; then
  if [ "$DIVERGED" -gt 0 ]; then
    echo "FAIL: $DIVERGED copy(s) diverged from canonical." >&2
    echo "Run: bash scripts/sync-migrate-problems-layout.sh" >&2
    exit 1
  fi
  echo "OK: all consumer copies match canonical"
  exit 0
fi

if [ "$SYNCED" -eq 0 ] && [ "$CREATED" -eq 0 ]; then
  echo "OK: all copies already in sync"
else
  echo "Synced $SYNCED, created $CREATED."
fi
