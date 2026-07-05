#!/usr/bin/env bash
# Sync the canonical quota-pace-throttle.sh from packages/shared/hooks/ into every
# consumer plugin (ADR-017 / RFC-036 / ADR-088).
#
# Each consumer plugin is published as a self-contained npm bundle, so the
# per-plugin copy must exist at runtime — but the source of truth is
# packages/shared/hooks/quota-pace-throttle.sh.
#
# Run this after editing the canonical and before committing. The CI step
# `npm run check:quota-pace-throttle` fails the build if any copy has diverged.
#
# Usage:
#   bash scripts/sync-quota-pace-throttle.sh          # sync all copies
#   bash scripts/sync-quota-pace-throttle.sh --check  # exit non-zero if any copy differs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED_HOOK="$REPO_ROOT/packages/shared/hooks/quota-pace-throttle.sh"

if [ ! -f "$SHARED_HOOK" ]; then
  echo "ERROR: canonical hook not found at $SHARED_HOOK" >&2
  exit 1
fi

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
fi

# Consumer plugins that ship the quota-pace throttle. Each already has a
# UserPromptSubmit array in its hooks.json (RFC-046). connect,
# retrospective, c4, wardley, agent-plugins are deferred — tracked as an
# explicit RFC-036 task, not silently dropped.
CONSUMERS=(architect itil jtbd tdd risk-scorer style-guide voice-tone)

DIVERGED=0
SYNCED=0
CREATED=0

sync_or_check() {
  local plugin="$1"
  local dst="$REPO_ROOT/packages/$plugin/hooks/quota-pace-throttle.sh"

  if [ ! -f "$dst" ]; then
    if [ "$MODE" = "check" ]; then
      echo "MISSING: $dst"
      DIVERGED=$((DIVERGED + 1))
      return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$SHARED_HOOK" "$dst"
    chmod +x "$dst"
    echo "created:  ${dst#$REPO_ROOT/}"
    CREATED=$((CREATED + 1))
    return
  fi

  if ! diff -q "$SHARED_HOOK" "$dst" >/dev/null 2>&1; then
    if [ "$MODE" = "check" ]; then
      echo "DIVERGED: $dst"
      DIVERGED=$((DIVERGED + 1))
    else
      cp "$SHARED_HOOK" "$dst"
      chmod +x "$dst"
      echo "synced:   ${dst#$REPO_ROOT/}"
      SYNCED=$((SYNCED + 1))
    fi
  fi
}

for plugin in "${CONSUMERS[@]}"; do
  sync_or_check "$plugin"
done

if [ "$MODE" = "check" ]; then
  if [ "$DIVERGED" -gt 0 ]; then
    echo "" >&2
    echo "ERROR: $DIVERGED copy(ies) of quota-pace-throttle.sh have diverged or are missing." >&2
    echo "Run: bash scripts/sync-quota-pace-throttle.sh" >&2
    exit 1
  fi
  echo "OK: all ${#CONSUMERS[@]} quota-pace-throttle.sh copies match the canonical source"
else
  if [ "$SYNCED" -eq 0 ] && [ "$CREATED" -eq 0 ]; then
    echo "OK: all copies already in sync"
  else
    echo ""
    echo "Synced $SYNCED file(s); created $CREATED new file(s). Review with: git diff packages/*/hooks/quota-pace-throttle.sh"
  fi
fi
