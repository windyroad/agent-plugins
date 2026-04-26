#!/bin/bash
# P125: PreToolUse:Bash hook — denies `git commit` invocations that
# would land in the P057 staging-trap shape (rename + post-rename
# Edit without re-stage).
#
# Detection delegates to `lib/staging-detect.sh::detect_p057_trap`.
# When the helper returns 1, this hook emits PreToolUse deny JSON
# with the trap'd path inline and the literal `git add <path>`
# recovery command, satisfying ADR-013 Rule 1's "deny redirects to
# a recovery path" contract via the mechanical-recovery shape (no
# skill wrapper required — re-staging a file is a single command).
#
# Allow paths (exit 0 without deny):
#   - tool_name != "Bash"          (only Bash invocations are gated)
#   - command does not contain     `git commit` substring (non-commit
#                                  Bash bypasses entirely)
#   - working tree clean of trap  (helper returns 0)
#   - outside a git work tree     (helper fails-open)
#   - parse failure on stdin      (mirrors create-gate.sh fail-open)
#
# References:
#   ADR-005 — plugin testing strategy (hook bats live under hooks/test/).
#   ADR-009 — gate marker lifecycle (this hook deliberately does NOT
#             use markers; detection is per-invocation deterministic).
#   ADR-013 Rule 1 — deny redirects with mechanical recovery.
#   ADR-038 — progressive disclosure / deny-message terseness budget.
#   P057    — original staging-trap ticket; this hook is the
#             enforcement layer the documentation alone didn't provide.
#   P119    — sibling create-gate hook (PreToolUse:Write + lib/create-gate.sh).
#   P125    — this hook.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/staging-detect.sh
source "$SCRIPT_DIR/lib/staging-detect.sh"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only gate Bash. Non-Bash tools bypass entirely.
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only fire on `git commit` invocations. Substring match catches
# common shapes (`git commit -m`, `git commit --amend`, leading
# `cd && git commit`, etc.) without over-matching unrelated bash.
case "$COMMAND" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Run detection. Helper echoes trap'd path on stdout when detected;
# returns 1 in that case. Returns 0 (allow) on no-trap or fail-open
# (non-git tree, parse error).
TRAPPED_PATH=$(detect_p057_trap 2>/dev/null) && exit 0

# Trap detected — emit deny with terse recovery.
# Voice-tone draft target ~245 bytes; ADR-038 progressive-disclosure
# budget. Keeps the rule cite (P057), the trap'd file path, and the
# literal recovery command inline.
REASON="BLOCKED: P057 staging-trap. Renamed file has unstaged post-rename edits: ${TRAPPED_PATH}. Run \`git add ${TRAPPED_PATH}\` then retry commit. Otherwise rename lands without the edit; edit drifts into next commit (audit-trail break)."

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "${REASON}"
  }
}
EOF
exit 0
