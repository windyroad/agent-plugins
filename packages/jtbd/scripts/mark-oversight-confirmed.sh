#!/usr/bin/env bash
# wr-jtbd — mark a JTBD/persona's human-oversight: confirmed marker write as
# user-substance-confirmed (P348 / ADR-110).
#
# JTBD-side sibling of packages/architect/scripts/mark-oversight-confirmed.sh.
# Companion to jtbd-oversight-marker-discipline.sh (also P348). SKILLs invoke
# this script AFTER an AskUserQuestion lands the user's substance-confirm
# answer for a specific job or persona; the script writes the evidence marker
# that the hook reads to permit the subsequent Edit/Write that introduces
# `human-oversight: confirmed` into that artefact's frontmatter.
#
# Why the marker is required:
#   ADR-068 mirrors ADR-066's `human-oversight: confirmed` marker contract on
#   the JTBD/persona surface. P348 captured iter subprocesses silently
#   writing the `confirmed` value without a user confirmation event,
#   contradicting JTBD-006's audit-trail outcome and JTBD-201/202's
#   auditability persona constraints. The hook enforces the boundary
#   structurally; this script is the evidence-write side that legitimate
#   substance-confirm flows use.
#
# AFK iter subprocesses with no AskUserQuestion access MUST write
# `human-oversight: unconfirmed` instead (the new enum value codified in
# ADR-110), which the drain
# (/wr-jtbd:confirm-jobs-and-personas) later promotes.
#
# Marker convention:
#   /tmp/oversight-confirmed-<sha256-of-path>-<session-id>
#   Shared marker namespace with the architect hook — both hooks consume the
#   same marker file shape. Written under EVERY recent candidate session SID
#   per ADR-050 Option C.
#
# Usage:
#   wr-jtbd-mark-oversight-confirmed <artefact-path>
#     <artefact-path> — the JTBD or persona file path the user just
#                       substance-confirmed.
#
# Exit codes:
#   0 — marker(s) written for at least one candidate SID, OR no candidate
#       SID was discoverable (cold path: no announce markers yet). The latter
#       writes no marker and prints a loud stderr diagnostic (P368) explaining
#       the downstream hook deny, then exits 0 so SKILL flows do not crash
#       before any hook has fired in the session.
#   2 — bad argument (missing or empty artefact-path).
#
# @adr ADR-068 (JTBD/persona human-oversight marker)
# @adr ADR-049 (PATH shim grammar)
# @adr ADR-050 (multi-SID candidate enumeration)
# @adr ADR-013 (Rule 6 fail-safe-defer in non-interactive contexts)
# @problem P348 (iter subprocesses set human-oversight: confirmed without user event)

set -uo pipefail

ARTEFACT_PATH="${1:-}"

if [ -z "$ARTEFACT_PATH" ]; then
  echo "wr-jtbd-mark-oversight-confirmed: missing <artefact-path>" >&2
  exit 2
fi

# Normalize to absolute path so the hash is stable regardless of CWD.
abs_dir="$(cd "$(dirname "$ARTEFACT_PATH")" 2>/dev/null && pwd)" || abs_dir=""
if [ -n "$abs_dir" ]; then
  ABS_PATH="$abs_dir/$(basename "$ARTEFACT_PATH")"
else
  ABS_PATH="$ARTEFACT_PATH"
fi

# Path hash — sha256, first 16 hex chars. Portable across macOS (shasum) and
# Linux (sha256sum / shasum).
if command -v sha256sum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | sha256sum | cut -d' ' -f1 | cut -c1-16)
elif command -v shasum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
else
  echo "wr-jtbd-mark-oversight-confirmed: no sha256 tool available" >&2
  exit 2
fi

MARKER_DIR="${SESSION_MARKER_DIR:-/tmp}"
WINDOW_MINS="${SESSION_CANDIDATE_WINDOW_MINS:-1440}"

# Candidate SID enumeration — recent announce markers across all systems
# within the mtime window. Inlined for plugin self-containment (no cross-
# plugin lib source — jtbd must not depend on architect-internal helpers
# per ADR-002 plugin packaging).
candidates=$(
  {
    if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
      echo "$CLAUDE_SESSION_ID"
    fi
    # `-L` follows the start-point symlink — on macOS MARKER_DIR defaults to /tmp,
    # a symlink to /private/tmp, which `find` would otherwise refuse to descend
    # (no-op on Linux where /tmp is a real dir). P380.
    find -L "$MARKER_DIR" -maxdepth 1 -name '*-announced-*' -mmin "-${WINDOW_MINS}" 2>/dev/null \
      | sed 's|.*/||; s/.*-announced-//'
  } | awk 'NF && !seen[$0]++'
)

# No candidate SID — cold path. Emit a loud stderr diagnostic (P368) and still
# exit 0. Exit 0 preserves the documented contract (do not crash SKILL flows
# before any announce marker has fired this session); the diagnostic replaces the
# prior SILENT no-op, which masqueraded as success and left the caller to hit the
# oversight-marker-discipline hook's deny with no idea why — the confusing loop
# P368 documents (the deny points back at this shim, which the caller already ran).
if [ -z "$candidates" ]; then
  {
    echo "wr-jtbd-mark-oversight-confirmed: no candidate session id discoverable"
    echo "  (CLAUDE_SESSION_ID empty and no *-announced-* markers in ${MARKER_DIR} within ${WINDOW_MINS}min)."
    echo "  NO oversight marker was written for: ${ABS_PATH}"
    echo "  The oversight-marker-discipline hook will DENY the 'human-oversight: confirmed' Edit"
    echo "  until a session announce marker exists. Start a fresh session, or point SESSION_MARKER_DIR"
    echo "  at a dir containing a *-announced-<sid> file, then re-run this shim (P368)."
  } >&2
  exit 0
fi

while IFS= read -r sid; do
  [ -n "$sid" ] || continue
  : > "$MARKER_DIR/oversight-confirmed-${PATH_HASH}-${sid}"
done <<< "$candidates"

exit 0
