#!/bin/bash
# Plugin-staleness surfacer — UserPromptSubmit hook (ADR-088 / RFC-036 / P045 / P375).
#
# Every turn, compare THIS session's running plugin version (inferred from the
# hook's own script path in the plugin cache) against the highest version
# installed on disk for the same plugin key. When the session is behind, emit
# ONE advisory line telling the user to restart to pick up the newer code.
#
# Network-free (own version from script path vs highest semver cache dir),
# warn-only (never installs or restarts — P343 restart-required means an
# auto-refresh can't help THIS session anyway), fails quiet on any error
# (fail-open), silent when the session is current, and emits at most once per
# newly-detected version (a version-keyed extension of ADR-038's per-session
# announcement marker) so it costs ~0 tokens on unchanged turns.
#
# Each plugin ships its own copy and emits its own line independently — no
# cross-plugin coordination (eliminates the P260 shared-marker race).
#
# Canonical source: packages/shared/hooks/staleness-check.sh. Synced to each
# consumer plugin by scripts/sync-staleness-check.sh (ADR-017); CI
# `npm run check:staleness-check` fails on drift.

# Fail-open: any unexpected error → silent success, never block a turn.
set +e

# AFK-launched sessions suppress the advisory: the orchestrator handles cache
# refresh (work-problems Step 6.5) and an AFK subprocess cannot restart itself,
# so the line would be pure noise. Reuses the established AFK-suppress marker.
[ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" = "1" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || exit 0
[ -n "$SCRIPT_DIR" ] || exit 0

# Installed layout: <cache>/windyroad/<key>/<version>/hooks/staleness-check.sh
# → version = basename(dirname(SCRIPT_DIR)); key = basename(dirname(dirname)).
VERSION_DIR="$(dirname "$SCRIPT_DIR")"        # <cache>/windyroad/<key>/<version>
SELF_VERSION="$(basename "$VERSION_DIR")"
KEY_DIR="$(dirname "$VERSION_DIR")"           # <cache>/windyroad/<key>
KEY="$(basename "$KEY_DIR")"

# Not running from the versioned plugin cache (e.g. source-repo dogfooding at
# packages/shared/hooks) → own version isn't strict semver → silent.
case "$SELF_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) : ;;
  *) exit 0 ;;
esac

# Highest strict-semver cache dir for this key. The semver filter drops
# SHA-named git-source residual dirs that would otherwise win `sort -V` (the
# recurring cache-refresh trap — see /install-updates / feedback memory).
HIGHEST="$(ls "$KEY_DIR" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
[ -n "$HIGHEST" ] || exit 0

# Session is current, or somehow ahead of the highest installed → silent.
[ "$SELF_VERSION" = "$HIGHEST" ] && exit 0
[ "$(printf '%s\n%s\n' "$SELF_VERSION" "$HIGHEST" | sort -V | tail -1)" = "$HIGHEST" ] || exit 0

# Emit once per (session, key, detected-version): a version-keyed extension of
# ADR-038's /tmp/${SYSTEM}-announced-${SESSION_ID} marker. A newer version
# detected mid-session yields a new marker key → re-emitted once. Empty
# SESSION_ID (test/manual) → no marker written, no dedup.
SESSION_ID="$(cat 2>/dev/null | jq -r '.session_id // empty' 2>/dev/null)"
if [ -n "$SESSION_ID" ]; then
  MARKER="/tmp/wr-staleness-announced-${SESSION_ID}-${KEY}-${HIGHEST}"
  [ -f "$MARKER" ] && exit 0
  : > "$MARKER" 2>/dev/null
fi

echo "${KEY}: this session is on ${SELF_VERSION}, ${HIGHEST} installed — restart to pick it up"
exit 0
