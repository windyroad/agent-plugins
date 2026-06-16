#!/usr/bin/env bash
# Sync the canonical command-detect.sh from packages/shared/hooks/lib/
# into every packages/*/hooks/lib/ copy (P268 / P275 / ADR-017).
#
# Each package is published as a self-contained npm bundle, so the
# per-plugin hooks/lib/ copy must exist at runtime — but the source
# of truth is packages/shared/hooks/lib/command-detect.sh.
#
# Run this after editing packages/shared/hooks/lib/command-detect.sh
# and before committing. The CI step `npm run check:command-detect`
# fails the build if any copy has diverged.
#
# Usage:
#   bash scripts/sync-command-detect.sh          # sync all copies
#   bash scripts/sync-command-detect.sh --check  # exit non-zero if any copy differs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_SRC="$REPO_ROOT/packages/shared/hooks/lib/command-detect.sh"

if [ ! -f "$SHARED_SRC" ]; then
  echo "ERROR: canonical source not found at $SHARED_SRC" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Consumer plugins that source the command_invokes_git_commit helper
# from PreToolUse:Bash / PostToolUse:Bash hooks gating `git commit`
# invocations. Each gets a byte-identical copy at
# packages/<plugin>/hooks/lib/command-detect.sh.
#
# itil consumers (P268 / P272 / P273 / P274):
#   itil-readme-refresh-discipline.sh, itil-changeset-discipline.sh,
#   p057-staging-trap-detect.sh, itil-rfc-trailer-advisory.sh.
# retrospective consumers (P275): retrospective-readme-jtbd-currency.sh.
# architect consumers (P366): architect-readme-pairing-check.sh.
CONSUMERS=(itil retrospective architect)

DIVERGED=0
SYNCED=0
CREATED=0

for plugin in "${CONSUMERS[@]}"; do
  target_dir="$REPO_ROOT/packages/$plugin/hooks/lib"
  target="$target_dir/command-detect.sh"

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
    echo "ERROR: $DIVERGED copy(ies) of command-detect.sh have diverged or are missing." >&2
    echo "Run: bash scripts/sync-command-detect.sh" >&2
    exit 1
  fi
  echo "OK: all ${#CONSUMERS[@]} hooks/lib/command-detect.sh copies match packages/shared/hooks/lib/command-detect.sh"
else
  if [ "$SYNCED" -eq 0 ] && [ "$CREATED" -eq 0 ]; then
    echo "OK: all ${#CONSUMERS[@]} copies already in sync"
  else
    echo ""
    echo "Synced $SYNCED copy(ies); created $CREATED new copy(ies). Review with: git diff packages/*/hooks/lib/command-detect.sh"
  fi
fi
