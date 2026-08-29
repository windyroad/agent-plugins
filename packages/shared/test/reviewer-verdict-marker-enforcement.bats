#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

teardown() {
  rm -f /tmp/style-guide-verdict /tmp/voice-tone-verdict
  rm -f /tmp/{style-guide,voice-tone}-{reviewed,plan-reviewed}-"bats-p469-$$"*
}

@test "style and voice hooks trust canonical output, not legacy verdict files" {
  for fixture in \
    "style-guide|$REPO_ROOT/packages/style-guide/hooks/style-guide-mark-reviewed.sh|wr-style-guide:agent|Style Guide Review" \
    "voice-tone|$REPO_ROOT/packages/voice-tone/hooks/voice-tone-mark-reviewed.sh|wr-voice-tone:agent|Voice & Tone Review"; do
    IFS='|' read -r gate hook subagent heading <<< "$fixture"
    session="bats-p469-$$"
    marker="/tmp/${gate}-reviewed-${session}"
    plan_marker="/tmp/${gate}-plan-reviewed-${session}"
    legacy_verdict="/tmp/${gate}-verdict"
    rm -f "$marker" "$marker.hash" "$plan_marker"

    printf 'PASS' > "$legacy_verdict"
    jq -n \
      --arg session "$session" \
      --arg subagent "$subagent" \
      --arg output "**${heading}: VIOLATIONS FOUND**" \
      '{session_id: $session, tool_name: "Agent", tool_input: {subagent_type: $subagent}, tool_response: {content: [{type: "text", text: $output}]}}' \
      | "$hook"
    [ ! -e "$marker" ]
    [ ! -e "$marker.hash" ]
    [ ! -e "$plan_marker" ]

    jq -n \
      --arg session "$session" \
      --arg subagent "$subagent" \
      --arg output "**${heading}: PASS**" \
      '{session_id: $session, tool_name: "Agent", tool_input: {subagent_type: $subagent}, tool_response: {content: [{type: "text", text: $output}]}}' \
      | "$hook"
    [ -e "$marker" ]
    [ -e "$marker.hash" ]
    [ -e "$plan_marker" ]
  done
}
