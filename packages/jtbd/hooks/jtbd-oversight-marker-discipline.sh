#!/usr/bin/env bash
# jtbd-oversight-marker-discipline.sh — PreToolUse:Edit|Write hook
# (P348 / ADR-068 amendment 2026-06-02). JTBD-side sibling of
# architect-oversight-marker-discipline.sh. Denies Edit/Write operations
# that introduce `human-oversight: confirmed` into a docs/jtbd/ artefact's
# (persona.md or JTBD-NNN-*.md) frontmatter unless a session-scoped
# evidence marker proves the user has substance-confirmed THAT specific
# artefact via AskUserQuestion.
#
# P348 captured AFK iter subprocesses silently writing `human-oversight:
# confirmed` without any user confirmation event. ADR-068 mirrors ADR-066's
# marker contract on the JTBD/persona surface, and JTBD-006's audit-trail
# outcome + JTBD-201/202's auditability constraints depend on the marker
# being honest. This hook is the structural guard.
#
# Allow paths (exit 0 silently per ADR-045 Pattern 1):
#   - tool_name not Edit|Write
#   - file outside the project root (P004)
#   - file not under docs/jtbd/
#   - file not a `.md` (README, etc.)
#   - basename README.md
#   - the Edit/Write does NOT introduce `human-oversight: confirmed`
#   - the session-scoped marker `/tmp/oversight-confirmed-<sha>-<sid>`
#     exists for THIS specific JTBD/persona path under THIS session
#
# Deny path (PreToolUse deny JSON, hook exit 0):
#   - all of: docs/jtbd/**/*.md, the change introduces
#     `human-oversight: confirmed`, AND no matching marker for this
#     artefact under this session
#
# Recovery (mechanical per ADR-013 Rule 1):
#   The SKILL flow that hosts the substance-confirm AskUserQuestion calls
#   `wr-jtbd-mark-oversight-confirmed <jtbd-or-persona-path>` immediately
#   after the user's answer lands. AFK iter subprocesses MUST instead write
#   `human-oversight: unconfirmed` (new enum value per ADR-068 amendment
#   2026-06-02), which the drain (/wr-jtbd:confirm-jobs-and-personas)
#   later promotes interactively.
#
# @adr ADR-068 (JTBD/persona human-oversight marker)
# @adr ADR-066 (parent contract — architect surface)
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

case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

[ -n "$FILE_PATH" ] || exit 0
[ -n "$SESSION_ID" ] || exit 0

case "$FILE_PATH" in
  /*)
    case "$FILE_PATH" in
      "$PWD"/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

# Scope: docs/jtbd/**/*.md. Personas live at docs/jtbd/<persona>/persona.md;
# jobs live at docs/jtbd/<persona>/JTBD-NNN-*.md. Both are valid targets.
case "$FILE_PATH" in
  */docs/jtbd/*.md|docs/jtbd/*.md) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  README.md) exit 0 ;;
esac

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

MARKER_RE='^[[:space:]]*human-oversight:[[:space:]]*confirmed[[:space:]]*$'

if ! echo "$NEW_CONTENT" | grep -qiE "$MARKER_RE"; then
  exit 0
fi

if [ -n "$OLD_CONTENT" ] && echo "$OLD_CONTENT" | grep -qiE "$MARKER_RE"; then
  exit 0
fi

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
  exit 0
fi

MARKER_DIR="${SESSION_MARKER_DIR:-/tmp}"
MARKER="$MARKER_DIR/oversight-confirmed-${PATH_HASH}-${SESSION_ID}"

if [ -f "$MARKER" ]; then
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: '${BASENAME}' is about to receive 'human-oversight: confirmed' but no substance-confirm evidence marker exists for this JTBD/persona in this session (P348 / ADR-068). The marker '/tmp/oversight-confirmed-<sha>-<sid>' is written by 'wr-jtbd-mark-oversight-confirmed <artefact-path>' immediately after an AskUserQuestion lands the user's substance-confirm answer. If you are an AFK iter subprocess without AskUserQuestion access, write 'human-oversight: unconfirmed' instead — the drain (/wr-jtbd:confirm-jobs-and-personas) will promote it interactively. To recover this Edit/Write: surface the substance-confirm AskUserQuestion to the user, call wr-jtbd-mark-oversight-confirmed with this artefact's path, then retry."
  }
}
EOF
exit 0
