#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  EVAL_HOOK="$REPO_ROOT/packages/voice-tone/hooks/voice-tone-eval.sh"
  STOP_HOOK="$REPO_ROOT/packages/voice-tone/hooks/assistant-voice-tone-stop.sh"

  WORKDIR="$(mktemp -d)"
  mkdir -p "$WORKDIR/docs"
  SID="assistant-vt-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/assistant-voice-tone-announced-${SID}"
  rm -f "/tmp/assistant-voice-tone-announced-${SID}.hash"
  rm -rf "$WORKDIR"
}

run_eval_hook() {
  (cd "$WORKDIR" && printf '{"session_id":"%s"}' "$SID" | bash "$EVAL_HOOK")
}

run_stop_hook() {
  local active="$1"
  (cd "$WORKDIR" && printf '{"session_id":"%s","stop_hook_active":%s,"last_assistant_message":"Done."}' "$SID" "$active" | bash "$STOP_HOOK")
}

@test "assistant voice guide absent: UserPromptSubmit is silent" {
  run run_eval_hook
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "assistant voice guide present: first prompt injects complete prose guide" {
  echo "Use ISO 24495-1:2023 plain language." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"

  run run_eval_hook

  [ "$status" -eq 0 ]
  [[ "$output" == *"ASSISTANT VOICE AND TONE GUIDE ACTIVE"* ]]
  [[ "$output" == *"Use ISO 24495-1:2023 plain language."* ]]
  [[ "$output" == *"alignment, not as a certification claim"* ]]
}

@test "assistant voice guide unchanged: second prompt is silent" {
  echo "Use short, concrete sentences." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"
  run_eval_hook >/dev/null

  run run_eval_hook

  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "assistant voice guide changed: prompt reinjects guide" {
  echo "Use short, concrete sentences." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"
  run_eval_hook >/dev/null
  echo "Use short, concrete sentences. Prefer active voice." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"

  run run_eval_hook

  [ "$status" -eq 0 ]
  [[ "$output" == *"Prefer active voice."* ]]
}

@test "assistant voice Stop absent guide: silent" {
  run run_stop_hook false
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "assistant voice Stop present guide: requires one unmistakably guided complete replacement" {
  echo "Use plain language." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"

  run run_stop_hook false

  [ "$status" -eq 0 ]
  [ "$(jq -r '.decision' <<<"$output")" = "block" ]
  reason="$(jq -r '.reason' <<<"$output")"
  [[ "$reason" == *"rewrite your previous response as one complete final response"* ]]
  [[ "$reason" == *"make the voice requested by the guide unmistakable"* ]]
  [[ "$reason" == *"Always emit the complete replacement response"* ]]
  [[ "$reason" == *"Never return an empty response, a verdict, or review commentary"* ]]
}

@test "assistant voice Stop retry guard: active stop hook is silent" {
  echo "Use plain language." > "$WORKDIR/docs/ASSISTANT-VOICE-AND-TONE.md"

  run run_stop_hook true

  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "Codex projection keeps UserPromptSubmit and Stop commands runnable" {
  run node "$REPO_ROOT/scripts/sync-codex-plugin-surfaces.mjs" voice-tone --build
  [ "$status" -eq 0 ]

  projected="$REPO_ROOT/packages/voice-tone/hooks-codex/hooks.json"
  [ "$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' "$projected")" = '${PLUGIN_ROOT}/hooks/voice-tone-eval.sh' ]
  [ "$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].additionalContextLimit' "$projected")" -eq 0 ]
  [ "$(jq -r '.hooks.Stop[0].hooks[0].command' "$projected")" = '${PLUGIN_ROOT}/hooks/assistant-voice-tone-stop.sh' ]
  ! grep -q 'CLAUDE_PLUGIN_ROOT' "$projected"

  node "$REPO_ROOT/scripts/sync-codex-plugin-surfaces.mjs" voice-tone --clean
}
