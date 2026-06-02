#!/usr/bin/env bash
# wr-architect — mark a decision/ADR's human-oversight: confirmed marker write
# as user-substance-confirmed (P348 / ADR-066 amendment 2026-06-02).
#
# Companion to the architect-oversight-marker-discipline.sh PreToolUse hook
# (also P348). SKILLs invoke this script AFTER an AskUserQuestion lands the
# user's substance-confirm answer for a specific ADR; the script writes the
# evidence marker that the hook reads to permit the subsequent Edit/Write
# that introduces `human-oversight: confirmed` into that ADR's frontmatter.
#
# Why the marker is required:
#   ADR-066 establishes that `human-oversight: confirmed` is a write-once-
#   permanent durable record. ADR-074 + P340 tighten the substance-confirm
#   semantics: the marker MAY ONLY land in response to a user answer that
#   selects a specific option. AFK iter subprocesses have no AskUserQuestion
#   access (ADR-013 Rule 6 fail-safe-defer territory), so they MUST NOT write
#   the `confirmed` value — they write `human-oversight: unconfirmed` instead,
#   which the drain (/wr-architect:review-decisions) later promotes. The hook
#   enforces the boundary structurally; this script is the evidence-write
#   side that legitimate substance-confirm flows use.
#
# Marker convention:
#   /tmp/oversight-confirmed-<sha256-of-path>-<session-id>
#   Written under EVERY recent candidate session SID per ADR-050 Option C
#   (concurrent orchestrator + subprocess sessions in the same project, the
#   per-machine runtime-sid marker is last-writer-wins). The PreToolUse hook
#   reads the SID from its stdin JSON; marking under every candidate
#   guarantees a matching marker exists whichever SID the hook reads.
#
# Usage:
#   wr-architect-mark-oversight-confirmed <artefact-path>
#     <artefact-path> — the ADR file path the user just substance-confirmed.
#                       The script computes sha256 of the absolute path.
#
# Exit codes:
#   0 — marker(s) written for at least one candidate SID, OR no candidate
#       SID was discoverable (cold-path: no announce markers yet). The
#       latter is a no-op so SKILL flows do not crash before any hook has
#       fired in the session.
#   2 — bad argument (missing or empty artefact-path).
#
# @adr ADR-066 (human-oversight marker)
# @adr ADR-049 (PATH shim grammar)
# @adr ADR-050 (multi-SID candidate enumeration)
# @adr ADR-013 (Rule 6 fail-safe-defer in non-interactive contexts)
# @problem P348 (iter subprocesses set human-oversight: confirmed without user event)

set -uo pipefail

ARTEFACT_PATH="${1:-}"

if [ -z "$ARTEFACT_PATH" ]; then
  echo "wr-architect-mark-oversight-confirmed: missing <artefact-path>" >&2
  exit 2
fi

# Normalize to absolute path so the hash is stable regardless of CWD.
# `cd $(dirname)` works whether the file exists or not (basename + abs dir).
abs_dir="$(cd "$(dirname "$ARTEFACT_PATH")" 2>/dev/null && pwd)" || abs_dir=""
if [ -n "$abs_dir" ]; then
  ABS_PATH="$abs_dir/$(basename "$ARTEFACT_PATH")"
else
  ABS_PATH="$ARTEFACT_PATH"
fi

# Path hash — use shasum/sha256sum portably (macOS ships shasum; Linux usually
# has both). First 16 hex chars are plenty for unique marker filenames.
if command -v sha256sum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | sha256sum | cut -d' ' -f1 | cut -c1-16)
elif command -v shasum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
else
  echo "wr-architect-mark-oversight-confirmed: no sha256 tool available" >&2
  exit 2
fi

MARKER_DIR="${SESSION_MARKER_DIR:-/tmp}"
WINDOW_MINS="${SESSION_CANDIDATE_WINDOW_MINS:-1440}"

# Candidate SID enumeration — recent announce markers across all systems
# within the mtime window. Mirrors get_candidate_session_ids in
# packages/itil/hooks/lib/session-id.sh; inlined here so this script is
# self-contained (no cross-plugin lib source — architect must not depend on
# itil-internal helpers per ADR-002 plugin packaging).
candidates=$(
  {
    # Env-var fast path. Not exported in agent contexts today, but if a
    # future Claude Code release adds it, this branch picks it up for free.
    if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
      echo "$CLAUDE_SESSION_ID"
    fi
    # Recent announce markers.
    find "$MARKER_DIR" -maxdepth 1 -name '*-announced-*' -mmin "-${WINDOW_MINS}" 2>/dev/null \
      | sed 's|.*/||; s/.*-announced-//'
  } | awk 'NF && !seen[$0]++'
)

# No candidate SID — cold path. Exit 0 so SKILL flows do not crash before any
# hook has fired this session. The subsequent Write deny will naturally
# surface the missing-marker case to the agent.
[ -n "$candidates" ] || exit 0

while IFS= read -r sid; do
  [ -n "$sid" ] || continue
  : > "$MARKER_DIR/oversight-confirmed-${PATH_HASH}-${sid}"
done <<< "$candidates"

exit 0
