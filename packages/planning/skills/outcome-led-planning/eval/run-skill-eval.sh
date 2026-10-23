#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
surface="${1:?expected source or codex}"
shift
case "$surface" in
  source) skill="$HERE/../SKILL.md" ;;
  codex) skill="$HERE/../../../skills-codex/outcome-led-planning/SKILL.md" ;;
  *) echo 'Expected source or codex skill surface.' >&2; exit 2 ;;
esac
scenario="${1:?expected scenario}"
entry=outcome-led-planning
if jq -e 'type == "object" and has("skill")' <<< "$scenario" >/dev/null 2>&1; then
  entry="$(jq -r .skill <<< "$scenario")"
fi
case "$entry" in
  outcome-led-planning|contribute|setup-github-tracking) ;;
  *) echo 'Expected outcome-led-planning, contribute or setup-github-tracking skill envelope.' >&2; exit 2 ;;
esac
if [ "${PLANNING_EVAL_RUNTIME:-claude}" = codex ]; then
  exec python3 "$HERE/codex-eval.py" subject "${1:?expected scenario}" "$skill"
fi
[ "${PLANNING_EVAL_RUNTIME:-claude}" = claude ] || { echo 'Expected explicit claude or codex runtime.' >&2; exit 2; }
contract='This is a tabletop evaluation. No tools, including independent reviewer tools, are available. Respond only as the assistant to the current user turn; do not invent or role-play other actors’ replies, decisions or review verdicts. Describe proposed external actions rather than executing tools or emitting a tool call. Ask any required question or confirmation directly in the current reply, then wait for the next user turn. Distinguish supplied observations from proposed actions and required checks. Do not turn omitted scenario information into observations about files or saved records; describe the inspection needed to establish it; mentioning a check does not establish that it passed.'
contract+=$'\n\n'
contract+="$(cat "$HERE/fixture-context.txt")"
references="$(dirname "$skill")/references"
[ "$entry" = outcome-led-planning ] || skill="$(dirname "$skill")/../$entry/SKILL.md"
contract+=$'\n\n'
contract+="$(cat "$skill")"
contract+=$'\n\n'
contract+="$(cat "$references/project-tracking.md")"
if [ "$entry" = outcome-led-planning ]; then
  contract+=$'\n\n'
  contract+="$(cat "$references/planning-details.md")"
elif [ "$entry" = contribute ]; then
  contract+=$'\n\n'
  contract+="$(awk '
    /^## / {
      selected = ($0 == "## Independent increment acceptance" || $0 == "## New integrations")
      if ($0 == "## Independent increment acceptance") acceptance = 1
      if ($0 == "## New integrations") integrations = 1
    }
    selected { print }
    END {
      if (!acceptance) { print "Missing independent increment acceptance section" > "/dev/stderr"; exit 2 }
      if (!integrations) { print "Missing new integrations section" > "/dev/stderr"; exit 2 }
    }
  ' "$references/planning-details.md")"
fi
if [ "$entry" = setup-github-tracking ] && ! jq -e 'type == "object" and .tracking == "local"' <<< "$scenario" >/dev/null 2>&1; then
  contract+=$'\n\n'
  contract+="$(awk '
    BEGIN { selected = 1 }
    /^## / {
      selected = ($0 == "## Establish one shared plan" || $0 == "## Apply real issue tracking")
      if ($0 == "## Establish one shared plan") shared = 1
      if ($0 == "## Apply real issue tracking") issues = 1
    }
    selected { print }
    END { if (!shared || !issues) { print "Missing required GitHub setup protocol section" > "/dev/stderr"; exit 2 } }
  ' "$references/github-coordination.md")"
fi
# Only an explicit selected-mode envelope loads the conditional reference.
# Provider metadata/rubrics and future turns never select or reach the subject.
if [ "$entry" != setup-github-tracking ] && jq -e 'type == "object" and .tracking == "github"' <<< "$scenario" >/dev/null 2>&1; then
  contract+=$'\n\n'
  contract+="$(cat "$(dirname "$skill")/../setup-github-tracking/SKILL.md")"
  contract+=$'\n\n'
  contract+="$(cat "$references/github-coordination.md")"
  contract+=$'\n\n'
  contract+="$(cat "$references/github-project-checkpoint.md")"
fi
if jq -e 'type == "object" and (.tracking == "github" or .tracking == "local")' <<< "$scenario" >/dev/null 2>&1; then
  contract+=$'\n\nScenario tracking backend: '
  contract+="$(jq -r .tracking <<< "$scenario")."
fi
if jq -e 'type == "object" and (.prompt | type == "string")' <<< "$scenario" >/dev/null 2>&1; then
  scenario="$(jq -r .prompt <<< "$scenario")"
fi
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
# Additional exec-provider arguments contain test metadata, including rubrics.
# Only the scenario may reach the subject; future interview replies stay separate.
common=(--model "${AGENT_EVAL_MODEL:-claude-sonnet-5}" --safe-mode --tools "" --disable-slash-commands --setting-sources "" --strict-mcp-config --mcp-config '{"mcpServers":{}}')
if jq -e 'type == "object" and (.turns | type == "array") and (.turns | length > 0) and all(.turns[]; type == "string")' <<< "$scenario" >/dev/null 2>&1; then
  session="$(node -p 'require("node:crypto").randomUUID()')"
  first=true
  while IFS= read -r encoded; do
    turn="$(jq -r . <<< "$encoded")"
    if $first; then
      response="$(claude -p "${common[@]}" --session-id "$session" --system-prompt "$contract" -- "$turn" </dev/null)"
      first=false
    else
      response="$(claude -p "${common[@]}" --resume "$session" -- "$turn" </dev/null)"
    fi
    jq -cn --arg user "$turn" --arg assistant "$response" '{user:$user,assistant:$assistant}' >> "$scratch/transcript.jsonl"
  done < <(jq -c '.turns[]' <<< "$scenario")
  jq -s . "$scratch/transcript.jsonl"
else
  claude -p "${common[@]}" --system-prompt "$contract" -- "$scenario"
fi
