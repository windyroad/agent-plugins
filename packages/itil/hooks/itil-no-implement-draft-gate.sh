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
# It ALSO enforces the ADR-090 ratification ADR-096 names but never implemented
# (P465): a commit against an `accepted`/`in-progress` story is blocked unless
# that story is ratified. This half is UNCONDITIONAL — a pure tightening, no
# config, no opt-in — because putting an ADR-090-mandated check behind a flag
# would be the decision conflict. Where the marker was machine-written under the
# ADR-101 pure-decomposition carve-out, the gate additionally re-asserts the
# story-LOCAL structure of that carve-out. It never re-evaluates the carve-out's
# shared-artefact conditions: those are accept-time only, because unrelated churn
# on a shared story map must not block an unrelated story (that is P456's shape).
#
# Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1.
#
# @adr ADR-096 (no-implement-while-draft) ADR-060 (lifecycle) ADR-013 (Rule 6)
#      ADR-095 (sibling capture-time gates) ADR-052 (bats)
#      ADR-090 (drift-invalidated ratification) ADR-101 (AFK carve-out)
# @problem P404 P465 P456
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh" 2>/dev/null || exit 0
# Fail-open per ADR-013 Rule 6. A missing story-oversight lib degrades to the
# draft-only gate; a missing command-detect lib (sourced above with the same
# guard) exits before the draft check too, so that path degrades to no gate at
# all. Both fail in the safe direction — never blocking every commit.
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

  if ! is_story_map_ratified "$story"; then
    deny "BLOCKED (ADR-090 / ADR-096 / P465): this commit references ${id}, but ${id} is not ratified — it carries no confirmed human-oversight marker, or its content has drifted since it was ratified. ADR-096 requires ratification before any implementation. Ratify it via /wr-itil:manage-story ${id} ratify, then re-commit. Bypass: BYPASS_NO_IMPLEMENT_DRAFT=1."
  fi

  # ADR-101 belt-and-braces. The load-bearing catch for a post-accept edit is
  # the hash above (both `afk-accept:` and `## Decomposition basis` sit inside
  # it). This adds a specific, actionable deny reason instead of a generic drift
  # deny, on a story-local structure no shared-artefact churn can invalidate.
  if oversight_is_pure_decomposition "$story"; then
    oversight_declares_pure_decomposition "$story" || deny \
      "BLOCKED (ADR-101): ${id} carries a machine-written pure-decomposition marker but no longer declares \`afk-accept: pure-decomposition\`. Re-accept it, or ratify it as a human via /wr-itil:manage-story ${id} ratify."
    crit=$(awk '/^##[[:space:]]+Acceptance criteria/{i=1;next} i&&/^##[[:space:]]/{exit} i' "$story" | grep -cE '^- \[[ xX]\]')
    basis=$(awk '/^##[[:space:]]+Decomposition basis/{i=1;next} i&&/^##[[:space:]]/{exit} i' "$story" | grep -cE '^- ')
    if [ "$crit" -eq 0 ] || [ "$basis" -ne "$crit" ]; then
      deny "BLOCKED (ADR-101): ${id} was AFK-accepted as pure decomposition, but its \`## Decomposition basis\` (${basis} entries) no longer matches its acceptance criteria (${crit}). Every criterion must name the already-confirmed clause it decomposes. Re-run /wr-itil:manage-story ${id} accepted, or ratify it as a human."
    fi
  fi
done <<< "$STORIES"

exit 0
