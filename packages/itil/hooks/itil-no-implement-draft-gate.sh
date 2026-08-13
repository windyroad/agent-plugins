#!/bin/bash
# wr-itil — PreToolUse:Bash gate (ADR-096 / P404). A story in `draft` is NEVER
# implementable. Blocks a `git commit` whose `Refs: STORY-NNN` trailer names a
# story still in docs/stories/draft/ — implementation requires `accepted` (where
# the INVEST + RFC-trace gates + ADR-090 ratification fire). Capture commits are
# exempt (they CREATE the draft story). Bootstrap-exempt commits bypass
# (ADR-060 A4). Degrades to a no-op on abnormal paths — characterised, not
# authorised; see the header note below.
#
# This is the enforcement locus the architect named as the ONLY one that catches
# the exact P404 bypass — a direct implementing commit against a draft story,
# whether from the orchestrator or by hand.
#
# It ALSO enforces the ADR-090 ratification ADR-096 names but never implemented
# (P465): a commit against an `accepted`/`in-progress` story is blocked unless
# that story is ratified. This half is UNCONDITIONAL — a pure tightening, no
# config, no opt-in — because putting an ADR-090-mandated check behind a flag
# would be the decision conflict. Under ADR-103 the approval surface is the story
# MAP: a story carries no oversight marker of its own, and is approved when every
# map in its `story-maps:` field is ratified.
#
# Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1.
#
# @adr ADR-096 (no-implement-while-draft) ADR-060 (lifecycle)
#      ADR-095 (sibling capture-time gates) ADR-052 (bats)
#      ADR-090 (drift-invalidated ratification) ADR-103 (map is the approval surface)
# @problem P404 P465 P456
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh" 2>/dev/null || exit 0
# Degrades to a no-op on a missing lib. NOT authorised by any in-force decision:
# ADR-013 (Structured user interaction for governance-skill decisions) Rule 6
# governs a skill that cannot reach AskUserQuestion, and its Continue clause
# reads "Do NOT silently fail-soft-skip". This posture is CHARACTERISED, not
# endorsed — see "the gate degrades to a no-op when its predicate lib is
# missing" in hooks/test/. Both source guards are terminal and both precede
# every check, so a missing lib — either one — degrades to no gate at all.
# Open question queued at P369.
# shellcheck source=../lib/story-oversight.sh
source "$SCRIPT_DIR/../lib/story-oversight.sh" 2>/dev/null || exit 0

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

  # ADR-090 ratification at the implementation locus (P465). ADR-096's Decision
  # Outcome claims no unratified story can ever be implemented; nothing enforced
  # it until here. Scoped to accepted/in-progress — done/archived stories are
  # past implementation and are not gated.
  shopt -s nullglob
  livefiles=(./docs/stories/accepted/${id}-*.md ./docs/stories/in-progress/${id}-*.md)
  shopt -u nullglob
  [ ${#livefiles[@]} -gt 0 ] || continue
  story="${livefiles[0]}"

  # ADR-103: a story's approval is its story MAP's. The story itself carries no
  # oversight marker, so there is one question to ask and one place to fix it.
  if ! story_is_approved "$story"; then
    deny "BLOCKED (ADR-103 / ADR-096 / P465): this commit references ${id}, but ${id} is not approved. A story is approved by its story map: every map in its \`story-maps:\` field must be ratified, and ${id} either names no map or names one that is unratified or has drifted since it was ratified. Ratify the map via /wr-itil:manage-story-map <MAP-ID> ratify, then re-commit. Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1."
  fi
done <<< "$STORIES"

exit 0
