#!/bin/bash
# wr-itil — PreToolUse:Bash gate (ADR-096 / P404). A story in `draft` is NEVER
# implementable. Blocks a `git commit` whose `Refs: STORY-NNN` trailer names a
# story still in docs/stories/draft/ — implementation requires `accepted` (where
# the INVEST + RFC-trace gates + ADR-090 ratification fire). Capture commits are
# exempt (they CREATE the draft story). Bootstrap-exempt commits bypass
# (ADR-060 A4). Fail-open on every abnormal path (ADR-013 Rule 6).
#
# This is the enforcement locus the architect named as the ONLY one that catches
# the exact P404 bypass — a direct implementing commit against a draft story,
# whether from the orchestrator or by hand.
#
# Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1.
#
# @adr ADR-096 (no-implement-while-draft) ADR-060 (lifecycle) ADR-013 (Rule 6)
#      ADR-095 (sibling capture-time gates) ADR-052 (bats)
# @problem P404
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh" 2>/dev/null || exit 0

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_name',''))
except: print('')" 2>/dev/null || echo "")
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_input',{}).get('command',''))
except: print('')" 2>/dev/null || echo "")
command_invokes_git_commit "$COMMAND" || exit 0
[ "${BYPASS_NO_IMPLEMENT_DRAFT:-}" = "1" ] && exit 0

# Capture commits create the draft story — exempt. Bootstrap migrations bypass.
case "$COMMAND" in
  *"capture STORY-"*) exit 0 ;;
  *"bootstrap-exempt"*) exit 0 ;;
esac

# Extract `Refs: STORY-NNN` trailers from the command text (present literally
# regardless of -m / heredoc form).
STORIES=$(printf '%s' "$COMMAND" | grep -oE 'Refs:[[:space:]]*STORY-[0-9]{3}' | grep -oE 'STORY-[0-9]{3}' | sort -u)
[ -n "$STORIES" ] || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -d "./docs/stories" ] || exit 0

deny() {
  cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$1"
  }
}
JSON
  exit 0
}

while IFS= read -r id; do
  [ -n "$id" ] || continue
  shopt -s nullglob; draftfiles=(./docs/stories/draft/${id}-*.md); shopt -u nullglob
  if [ ${#draftfiles[@]} -gt 0 ]; then
    deny "BLOCKED (ADR-096 / P404): this commit references ${id} via a Refs: trailer, but ${id} is still in draft. A draft story cannot be implemented — accept it first via /wr-itil:manage-story ${id} accepted (it runs the INVEST + RFC-trace gates + ratification), then re-commit. Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1."
  fi
done <<< "$STORIES"

exit 0
