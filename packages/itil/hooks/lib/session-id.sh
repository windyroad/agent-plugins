#!/bin/bash
# P124: agent-side session-ID discovery helper.
#
# `get_current_session_id` returns the canonical Claude Code session UUID
# for the current invocation, used by /wr-itil:manage-problem Step 2
# substep 7 to write the create-gate marker (`/tmp/manage-problem-grep-${SID}`)
# under the same SID the manage-problem-enforce-create.sh hook reads from
# its stdin JSON payload.
#
# Why this helper exists:
#   The agent's process does NOT export CLAUDE_SESSION_ID. The hook side
#   reads session_id from its stdin JSON payload (per the Claude Code
#   PreToolUse contract); the agent side has no equivalent surface, so
#   /wr-itil:manage-problem Step 2's prior fallback `${CLAUDE_SESSION_ID:-default}`
#   wrote the marker under "default" while the hook checked the real UUID.
#   Marker mismatch -> Write deny -> agent had to scrape an existing
#   announce marker filename ad-hoc to recover. P124.
#
# Discovery strategy (announce markers preferred over reviewed markers):
#   /tmp/${SYSTEM}-announced-${SESSION_ID} markers are write-once-per-session
#   per ADR-038 and are emitted on the FIRST UserPromptSubmit of every
#   session by every active plugin (architect, jtbd, tdd, style-guide,
#   voice-tone, itil-assistant-gate, itil-correction-detect). They have
#   no mtime sliding (unlike `-reviewed-` gate markers, which `touch`-refresh
#   on every gate check per ADR-009 sliding TTL + P111 subprocess refresh),
#   so the announce-marker UUID is the most reliable per-session signal
#   reachable from agent-side code without an env var.
#
# Why itil-local instead of packages/shared (cf. ADR-017):
#   The discovery direction is the OPPOSITE of ADR-038's announce helper —
#   ADR-038's session-marker.sh WRITES announce markers from hook side;
#   this helper READS them from agent side. Only manage-problem SKILL.md
#   needs agent-side discovery today (Step 2 substep 7), so the helper
#   is itil-local with read-only fallbacks across other plugins' marker
#   filenames (no write coupling, no sync obligation). If a second skill
#   adopts agent-side SID discovery, promote to packages/shared/ at that
#   point per ADR-017 shared-code-sync. Mirrors create-gate.sh's "Why a
#   separate helper from lib/review-gate.sh" precedent.
#
# Empty SESSION_ID fallback:
#   No env-var + no markers -> echo nothing, return 1. Callers MUST check
#   the return code; a marker-write under an empty SID would land at
#   /tmp/manage-problem-grep- which the hook never matches. Fail-closed.
#
# References:
#   ADR-038 — progressive disclosure / session-marker pattern (announce
#             markers, /tmp/${SYSTEM}-announced-${SESSION_ID} convention).
#   ADR-009 — gate marker lifecycle (covers /tmp marker conventions).
#   ADR-017 — shared-code-sync (consulted; itil-local is the right home today).
#   P119    — create-gate hook this discovery helper feeds.
#   P124    — this helper.
#
# Test override: SESSION_MARKER_DIR (defaults to /tmp) lets bats run
# under a sandboxed marker directory without polluting real session
# state in /tmp.

# Returns the canonical session UUID for the current invocation.
# Echoes the UUID on stdout. Exit 0 if discovered, 1 if not.
#
# Usage:
#   source packages/itil/hooks/lib/session-id.sh
#   sid=$(get_current_session_id) || { echo "no SID available" >&2; exit 1; }
get_current_session_id() {
  # Env-var fast path. CLAUDE_SESSION_ID is not exported in agent
  # contexts today, but if a future Claude Code release adds it,
  # this branch picks it up for free.
  if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    echo "$CLAUDE_SESSION_ID"
    return 0
  fi

  local marker_dir="${SESSION_MARKER_DIR:-/tmp}"

  # Marker-system priority order. Architect first because architect-
  # enforce-edit.sh fires on virtually every project edit and so its
  # announce marker is the most reliably present early in any session
  # touching this repo. JTBD second for the same reason on this project.
  # The remaining systems give graceful degradation if the higher-
  # priority hooks haven't yet announced (rare — UserPromptSubmit
  # announces fire on prompt 1).
  local systems=(
    architect
    jtbd
    tdd
    itil-assistant-gate
    itil-correction-detect
    style-guide
    voice-tone
  )

  local system marker
  for system in "${systems[@]}"; do
    # Glob expansion: nullglob avoids the literal-pattern-on-no-match
    # pitfall. Subshell isolates the shopt change.
    marker=$(
      shopt -s nullglob
      set -- "${marker_dir}/${system}-announced-"*
      [ "$#" -gt 0 ] && printf '%s\n' "$1"
    )
    if [ -n "$marker" ]; then
      # Strip the prefix to recover the trailing UUID.
      basename "$marker" | sed "s/^${system}-announced-//"
      return 0
    fi
  done

  return 1
}
