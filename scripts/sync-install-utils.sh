#!/usr/bin/env bash
# Sync the canonical install-utils.mjs from packages/shared/ into every
# packages/*/lib/ copy. Each package is published as a self-contained
# npm bundle, so the lib/ copy must exist at runtime — but the source
# of truth is packages/shared/install-utils.mjs.
#
# Run this after editing packages/shared/install-utils.mjs and before
# committing. The `packages/shared/test/sync-install-utils.bats` test
# fails the build if any copy has diverged.
#
# Usage:
#   bash scripts/sync-install-utils.sh          # sync all copies
#   bash scripts/sync-install-utils.sh --check  # exit non-zero if any copy differs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_SRC="$REPO_ROOT/packages/shared/install-utils.mjs"

if [ ! -f "$SHARED_SRC" ]; then
  echo "ERROR: canonical source not found at $SHARED_SRC" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Enumerate target lib/ copies. Only packages that actually have a lib/
# install-utils.mjs file — we do not create new copies here.
mapfile -t TARGETS < <(find "$REPO_ROOT/packages" -maxdepth 3 -type f -path '*/lib/install-utils.mjs' | sort)

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No packages/*/lib/install-utils.mjs targets found." >&2
  exit 1
fi

DIVERGED=0
SYNCED=0

for target in "${TARGETS[@]}"; do
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
    echo "ERROR: $DIVERGED copy(ies) of install-utils.mjs have diverged from packages/shared/install-utils.mjs." >&2
    echo "Run: bash scripts/sync-install-utils.sh" >&2
    exit 1
  fi
  echo "OK: all ${#TARGETS[@]} lib/install-utils.mjs copies match packages/shared/install-utils.mjs"
else
  if [ "$SYNCED" -eq 0 ]; then
    echo "OK: all ${#TARGETS[@]} copies already in sync"
  else
    echo ""
    echo "Synced $SYNCED copy(ies). Review with: git diff packages/*/lib/install-utils.mjs"
  fi
fi
