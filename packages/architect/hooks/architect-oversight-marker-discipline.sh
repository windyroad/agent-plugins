#!/usr/bin/env bash
# architect-oversight-marker-discipline.sh — PreToolUse:Edit|Write hook
# (P348 / ADR-066 amendment 2026-06-02). Denies Edit/Write operations that
# introduce `human-oversight: confirmed` into a docs/decisions/ ADR's
# frontmatter unless a session-scoped evidence marker proves the user has
# substance-confirmed THAT specific ADR via AskUserQuestion.
#
# P348 captured AFK iter subprocesses silently writing `human-oversight:
# confirmed` without any user confirmation event — contradicting ADR-066's
# write-once-permanent-on-substance-confirm contract and JTBD-006's audit-
# trail outcome. This hook is the structural guard. The discipline-prose
# already in /wr-architect:create-adr (substance-confirm at Step 5,
# P340-tightened by ADR-066 Amendment 2026-05-31) is the SKILL-level
# expression; this hook elevates it to a structurally enforced boundary
# AFK iter subprocesses cannot bypass.
#
# Allow paths (exit 0 silently per ADR-045 Pattern 1):
#   - tool_name not Edit|Write
#   - file outside the project root (P004)
#   - file not under docs/decisions/
#   - file not a `.md` (README, changelogs, etc.)
#   - the Edit/Write does NOT introduce the literal frontmatter line
#     `human-oversight: confirmed` (e.g. introduces `unconfirmed` or
#     `rejected-pending-supersede`, leaves the marker untouched, etc.)
#   - the session-scoped marker `/tmp/oversight-confirmed-<sha>-<sid>`
#     exists for THIS specific ADR path under THIS session ID
#
# Deny path (PreToolUse deny JSON, hook exit 0):
#   - all of: docs/decisions/*.md, the change introduces
#     `human-oversight: confirmed`, AND no matching marker for this ADR
#     under this session
#
# Recovery (mechanical per ADR-013 Rule 1):
#   The SKILL flow that hosts the substance-confirm AskUserQuestion calls
#   `wr-architect-mark-oversight-confirmed <adr-path>` immediately after
#   the user's answer lands. The next Edit/Write of that ADR is then
#   allowed. AFK iter subprocesses MUST instead write
#   `human-oversight: unconfirmed` (new enum value per ADR-066 amendment
#   2026-06-02), which the drain (/wr-architect:review-decisions) later
#   promotes interactively.
#
# Resolution (ADR-049 amended): PATH-shim grammar — the SKILL invokes
# `wr-architect-mark-oversight-confirmed`, which resolves through the
# highest-version-wins shim wrapper.
#
# @adr ADR-066 (human-oversight marker — write-once-permanent contract)
# @adr ADR-068 (sibling JTBD/persona contract)
# @adr ADR-049 (PATH shim resolution for invocation)
# @adr ADR-050 (multi-SID candidate enumeration for marker write)
# @adr ADR-045 (Pattern 1 silent-on-pass PreToolUse)
# @adr ADR-013 (Rule 6 fail-safe-defer in non-interactive contexts)
# @problem P348 (iter subprocesses set human-oversight: confirmed without user event)

set -uo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL_NAME=""
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""

# Tool gate: only Edit and Write.
case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

# Missing inputs — allow (fail-open is acceptable here because the
# architect-enforce-edit gate is the outer perimeter that catches missing
# session_id with fail-closed deny; this discipline is a refinement).
[ -n "$FILE_PATH" ] || exit 0
[ -n "$SESSION_ID" ] || exit 0

# P004: only gate files inside the project root.
case "$FILE_PATH" in
  /*)
    case "$FILE_PATH" in
      "$PWD"/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

# Scope: only docs/decisions/<NNN>-*.md and per-state subdir layouts.
case "$FILE_PATH" in
  */docs/decisions/*.md|docs/decisions/*.md) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")
# Skip README + non-ADR auxiliary files.
case "$BASENAME" in
  README.md) exit 0 ;;
esac

# Extract the candidate new-content. For Write, that's the full
# `tool_input.content`. For Edit, that's `tool_input.new_string`.
case "$TOOL_NAME" in
  Write)
    NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null) || NEW_CONTENT=""
    OLD_CONTENT=""
    if [ -f "$FILE_PATH" ]; then
      OLD_CONTENT=$(cat "$FILE_PATH" 2>/dev/null) || OLD_CONTENT=""
    fi
    ;;
  Edit)
    NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null) || NEW_CONTENT=""
    OLD_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null) || OLD_CONTENT=""
    ;;
esac

# Does the new content introduce `human-oversight: confirmed`?
# Token-cheap grep — single literal line, case-insensitive, tolerant of
# trailing whitespace (mirroring detect-unoversighted.sh's match grammar).
MARKER_RE='^[[:space:]]*human-oversight:[[:space:]]*confirmed[[:space:]]*$'

if ! echo "$NEW_CONTENT" | grep -qiE "$MARKER_RE"; then
  exit 0  # new content does not contain the confirmed marker → allow
fi

# If the OLD content already had the marker, this Edit/Write is not
# INTRODUCING it (could be reformatting or a no-op on this line). Allow.
if [ -n "$OLD_CONTENT" ] && echo "$OLD_CONTENT" | grep -qiE "$MARKER_RE"; then
  exit 0
fi

# Now we know: the change INTRODUCES `human-oversight: confirmed`. Require
# the session-scoped evidence marker for THIS ADR's absolute path.
abs_dir=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd) || abs_dir=""
if [ -n "$abs_dir" ]; then
  ABS_PATH="$abs_dir/$(basename "$FILE_PATH")"
else
  ABS_PATH="$FILE_PATH"
fi

if command -v sha256sum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | sha256sum | cut -d' ' -f1 | cut -c1-16)
elif command -v shasum >/dev/null 2>&1; then
  PATH_HASH=$(printf '%s' "$ABS_PATH" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
else
  # No hashing tool available — fail-open. Unrealistic on macOS/Linux but
  # do not block the user over an environment edge case.
  exit 0
fi

MARKER_DIR="${SESSION_MARKER_DIR:-/tmp}"
MARKER="$MARKER_DIR/oversight-confirmed-${PATH_HASH}-${SESSION_ID}"

if [ -f "$MARKER" ]; then
  exit 0  # evidence present → allow
fi

# Deny.
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: '${BASENAME}' is about to receive 'human-oversight: confirmed' but no substance-confirm evidence marker exists for this ADR in this session (P348 / ADR-066). The marker '/tmp/oversight-confirmed-<sha>-<sid>' is written by 'wr-architect-mark-oversight-confirmed <adr-path>' immediately after an AskUserQuestion lands the user's substance-confirm answer. If you are an AFK iter subprocess without AskUserQuestion access, write 'human-oversight: unconfirmed' instead — the drain (/wr-architect:review-decisions) will promote it interactively. To recover this Edit/Write: surface the substance-confirm AskUserQuestion to the user, call wr-architect-mark-oversight-confirmed with this ADR's path, then retry."
  }
}
EOF
exit 0
