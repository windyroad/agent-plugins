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
contract="$(cat "$skill")"
scenario="${1:?expected scenario}"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
# Additional exec-provider arguments contain test metadata, including rubrics.
# Only the scenario may reach the subject; future interview replies stay separate.
common=(--tools "" --disable-slash-commands --setting-sources "" --strict-mcp-config --mcp-config '{"mcpServers":{}}')
if jq -e 'type == "object" and (.turns | type == "array") and (.turns | length > 0) and all(.turns[]; type == "string")' <<< "$scenario" >/dev/null 2>&1; then
  session="$(node -p 'require("node:crypto").randomUUID()')"
  first=true
  while IFS= read -r encoded; do
    turn="$(jq -r . <<< "$encoded")"
    if $first; then
      response="$(claude -p "${common[@]}" --session-id "$session" --append-system-prompt "$contract" "$turn" </dev/null)"
      first=false
    else
      response="$(claude -p "${common[@]}" --resume "$session" "$turn" </dev/null)"
    fi
    jq -cn --arg user "$turn" --arg assistant "$response" '{user:$user,assistant:$assistant}' >> "$scratch/transcript.jsonl"
  done < <(jq -c '.turns[]' <<< "$scenario")
  jq -s . "$scratch/transcript.jsonl"
else
  claude -p "${common[@]}" --append-system-prompt "$contract" "$scenario"
fi
