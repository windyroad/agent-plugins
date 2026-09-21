#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$TMPDIR" "$BATS_TEST_TMPDIR/packs"
}

teardown() {
  rm -f /tmp/{style-guide,voice-tone}-{reviewed,plan-reviewed}-bats-p402-*-"$$"{,.hash,-other,-other.hash,-child,-child.hash}
  rm -f /tmp/{style-guide,voice-tone,jtbd}-{reviewed,plan-reviewed}-bats-p539-*-"$$"{,.hash}
  rm -f /tmp/architect-{reviewed,plan-reviewed}-bats-p539-architect-"$$"{,.hash}
  rm -f /tmp/architect-{reviewed,plan-reviewed}-bats-p539-architect-relative-"$$"{,.hash}
  rm -f /tmp/jtbd-{reviewed,plan-reviewed}-bats-p539-jtbd-stop-"$$"{,.hash}
  rm -f /tmp/jtbd-{reviewed,plan-reviewed}-bats-p539-jtbd-ambiguous-"$$"{,.hash}
  rm -f /tmp/jtbd-verdict
}

pack_plugin() {
  local package="$1" version tarball extracted
  version="$(jq -r .version "$REPO_ROOT/packages/$package/package.json")"
  npm pack "$REPO_ROOT/packages/$package" --pack-destination "$BATS_TEST_TMPDIR/packs" >/dev/null
  tarball="$BATS_TEST_TMPDIR/packs/windyroad-$package-$version.tgz"
  extracted="$BATS_TEST_TMPDIR/$package"
  mkdir -p "$extracted"
  tar -xzf "$tarball" -C "$extracted"
  printf '%s\n' "$extracted/package"
}

send_event() {
  local helper="$1" payload="$2"
  printf '%s' "$payload" | node "$helper"
}

send_configured_event() {
  local package="$1" event="$2" payload="$3" command
  while IFS= read -r command; do
    printf '%s' "$payload" | PLUGIN_ROOT="$package" bash -c "$command"
  done < <(jq -r --arg event "$event" '.hooks[$event][-1].hooks[].command' "$package/hooks-codex/hooks.json")
}

marker_time() {
  node -e 'console.log(require("node:fs").statSync(process.argv[1]).mtimeMs)' "$1"
}

spawn_payload() {
  jq -cn --arg session "$1" --arg cwd "$2" --arg role "$3" --arg target "$4" \
    '{session_id:$session,cwd:$cwd,tool_name:"spawn_agent",tool_input:{agent_type:$role,message:"review"},tool_response:{task_name:$target}}'
}

close_payload() {
  jq -cn --arg session "$1" --arg cwd "$2" --arg target "$3" --arg output "$4" \
    '{session_id:$session,cwd:$cwd,tool_name:"interrupt_agent",tool_input:{target:$target},tool_response:{previous_status:{completed:$output}}}'
}

wait_payload() {
  jq -cn --arg session "$1" --arg cwd "$2" --arg target "$3" --arg output "$4" \
    '{session_id:$session,cwd:$cwd,tool_name:"wait_agent",tool_input:{},tool_response:{status:{($target):{completed:$output}}}}'
}

stop_payload() {
  jq -cn --arg session "$1" --arg cwd "$2" --arg role "$3" --arg target "$4" --arg output "$5" \
    '{session_id:$session,cwd:$cwd,hook_event_name:"SubagentStop",agent_type:$role,agent_id:$target,last_assistant_message:$output}'
}

native_array_spawn_payload() {
  local response
  response="$(jq -cn --arg target "$4" '{task_name:$target}')"
  jq -cn --arg session "$1" --arg cwd "$2" --arg role "$3" --arg response "$response" \
    '{session_id:$session,cwd:$cwd,tool_name:"collaboration.spawn_agent",tool_input:{agent_type:$role,message:"review"},tool_response:[{type:"input_text",text:$response}]}'
}

native_array_close_payload() {
  local response
  response="$(jq -cn --arg output "$4" '{previous_status:{completed:$output}}')"
  jq -cn --arg session "$1" --arg cwd "$2" --arg target "$3" --arg response "$response" \
    '{session_id:$session,cwd:$cwd,tool_name:"collaboration.interrupt_agent",tool_input:{target:$target},tool_response:[{type:"input_text",text:$response}]}'
}

@test "packed reviewers share the current dotted collaboration and input_text completion transport" {
  local package root role verdict session target marker

  for package in style-guide voice-tone jtbd; do
    root="$(pack_plugin "$package")"
    case "$package" in
      style-guide)
        role="wr-style-guide:agent"; verdict='**Style Guide Review: PASS**'; marker="/tmp/style-guide-reviewed-bats-p539-$package-$$" ;;
      voice-tone)
        role="wr-voice-tone:agent"; verdict='**Voice & Tone Review: PASS**'; marker="/tmp/voice-tone-reviewed-bats-p539-$package-$$" ;;
      jtbd)
        role="wr-jtbd:agent"; verdict='**JTBD Review: PASS**'; marker="/tmp/jtbd-reviewed-bats-p539-$package-$$" ;;
    esac
    session="bats-p539-$package-$$"
    target="/root/p539-$package"

    [ -f "$root/hooks-codex/codex-agent-completion.mjs" ]
    jq -e '.hooks.PostToolUse[] | select(.matcher | contains("collaboration.spawn_agent"))' "$root/hooks-codex/hooks.json"
    send_event "$root/hooks-codex/codex-agent-completion.mjs" \
      "$(native_array_spawn_payload "$session" "$REPO_ROOT" "$role" "$target")"
    [ "$package" != jtbd ] || printf 'PASS\n' > /tmp/jtbd-verdict
    send_event "$root/hooks-codex/codex-agent-completion.mjs" \
      "$(native_array_close_payload "$session" "$REPO_ROOT" "$target" "$verdict")"
    [ -e "$marker" ]
  done
}

@test "packed architect consumes the shared current native completion decoder" {
  local root helper session target marker
  root="$(pack_plugin architect)"
  helper="$root/hooks/codex-agent-completion.mjs"
  session="bats-p539-architect-$$"
  target="/root/p539-architect"
  marker="/tmp/architect-reviewed-$session"

  [ -f "$root/hooks/lib/codex-completion-input.mjs" ]
  send_event "$helper" \
    "$(native_array_spawn_payload "$session" "$REPO_ROOT" 'wr-architect:agent' "$target")"
  send_event "$helper" \
    "$(native_array_close_payload "$session" "$REPO_ROOT" "$target" '**Architecture Review: PASS**')"
  [ -e "$marker" ]
}

@test "packed architect matches a relative completion target to its canonical spawn target" {
  local root session marker
  root="$(pack_plugin architect)"
  session="bats-p539-architect-relative-$$"
  marker="/tmp/architect-reviewed-$session"
  send_event "$root/hooks/codex-agent-completion.mjs" \
    "$(spawn_payload "$session" "$REPO_ROOT" 'wr-architect:agent' '/root/review')"
  send_event "$root/hooks/codex-agent-completion.mjs" \
    "$(close_payload "$session" "$REPO_ROOT" 'review' '**Architecture Review: PASS**')"
  [ -f "$marker" ]
}

@test "opaque JTBD stop fails closed, then a bound completion admits the next edit" {
  local root session marker
  root="$(pack_plugin jtbd)"
  session="bats-p539-jtbd-stop-$$"
  marker="/tmp/jtbd-reviewed-$session"
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(spawn_payload "$session" "$REPO_ROOT" 'wr-jtbd:agent' '/root/review')"
  printf 'PASS\n' > /tmp/jtbd-verdict
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(stop_payload "$session" "$REPO_ROOT" 'wr-jtbd:agent' 'opaque-agent-id' '**JTBD Review: PASS**')"
  [ ! -e "$marker" ]
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(close_payload "$session" "$REPO_ROOT" 'review' '**JTBD Review: PASS**')"
  [ -f "$marker" ]
  [ -f "$marker.hash" ]
  local gate_input
  gate_input="$(jq -cn --arg session "$session" --arg path "$REPO_ROOT/scripts/sync-codex-plugin-surfaces.mjs" \
    '{session_id:$session,tool_name:"Edit",tool_input:{file_path:$path}}')"
  run bash -c 'printf "%s" "$1" | "$2/hooks/jtbd-enforce-edit.sh"' _ "$gate_input" "$root"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "opaque JTBD completion does not choose among two pending reviewers" {
  local root session marker
  root="$(pack_plugin jtbd)"
  session="bats-p539-jtbd-ambiguous-$$"
  marker="/tmp/jtbd-reviewed-$session"
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(spawn_payload "$session" "$REPO_ROOT" 'wr-jtbd:agent' '/root/first')"
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(spawn_payload "$session" "$REPO_ROOT" 'wr-jtbd:agent' '/root/second')"
  printf 'PASS\n' > /tmp/jtbd-verdict
  send_event "$root/hooks-codex/codex-agent-completion.mjs" \
    "$(stop_payload "$session" "$REPO_ROOT" 'wr-jtbd:agent' 'opaque-agent-id' '**JTBD Review: PASS**')"
  [ ! -e "$marker" ]
  [ -f /tmp/jtbd-verdict ]
}

@test "packed style-guide transports only genuine bound native completions" {
  local root helper role target session marker state before other
  root="$(pack_plugin style-guide)"
  helper="$root/hooks-codex/codex-agent-completion.mjs"
  role="wr-style-guide:agent"
  target="/root/p402-style"
  session="bats-p402-style-$$"
  marker="/tmp/style-guide-reviewed-$session"

  [ -f "$helper" ]
  jq -e '.hooks.PostToolUse[] | select(.matcher | contains("wait_agent"))' "$root/hooks-codex/hooks.json"
  jq -e '.hooks.SubagentStop[] | select(.matcher == "^wr-style-guide:agent$")' "$root/hooks-codex/hooks.json"

  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target")"
  [ ! -e "$marker" ]
  send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target" '**Style Guide Review: PASS**')"
  [ -e "$marker" ]

  before="$(marker_time "$marker")"
  sleep 1
  send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target" '**Style Guide Review: PASS**')"
  [ "$(marker_time "$marker")" = "$before" ]

  session="bats-p402-style-fail-$$"
  marker="/tmp/style-guide-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-fail")"
  send_event "$helper" "$(wait_payload "$session" "$REPO_ROOT" "$target-fail" '**Style Guide Review: VIOLATIONS FOUND**')"
  [ ! -e "$marker" ]

  session="bats-p402-style-stale-$$"
  marker="/tmp/style-guide-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-stale")"
  state="$(find "$TMPDIR/claude-risk-$session" -type f -name 'codex-review-*' ! -name '*.claim' ! -name '*.done' -print -quit)"
  touch -t 200001010000 "$state"
  send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target-stale" '**Style Guide Review: PASS**')"
  [ ! -e "$marker" ]
  jq -e '.reason == "stale-registration"' "$TMPDIR/codex-review-completion-diagnostic.json"

  other="$BATS_TEST_TMPDIR/other-checkout"
  git init -q "$other"
  session="bats-p402-style-checkout-$$"
  marker="/tmp/style-guide-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-checkout")"
  send_event "$helper" "$(close_payload "$session" "$other" "$target-checkout" '**Style Guide Review: PASS**')"
  [ ! -e "$marker" ]
  jq -e '.reason == "checkout-mismatch"' "$TMPDIR/codex-review-completion-diagnostic.json"
}

@test "both packed packages preserve reviewer identity and reject changed or expired policy reviews" {
  local style voice fixture policy session marker payload state ttl n
  style="$(pack_plugin style-guide)"
  voice="$(pack_plugin voice-tone)"
  fixture="$BATS_TEST_TMPDIR/checkout"
  mkdir -p "$fixture/docs"
  git init -q "$fixture"
  cp "$REPO_ROOT/docs/STYLE-GUIDE.md" "$REPO_ROOT/docs/VOICE-AND-TONE.md" "$fixture/docs/"
  policy="$fixture/docs/STYLE-GUIDE.md"

  session="bats-p402-composed-$$"
  payload="$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  send_configured_event "$style" PostToolUse "$payload"
  send_configured_event "$voice" PostToolUse "$payload"
  payload="$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
  send_configured_event "$style" PostToolUse "$payload"
  send_configured_event "$voice" PostToolUse "$payload"
  [ -f "/tmp/style-guide-reviewed-$session" ]
  [ ! -e "/tmp/voice-tone-reviewed-$session" ]

  session="bats-p402-composed-voice-$$"
  payload="$(spawn_payload "$session" "$fixture" 'wr-voice-tone:agent' '/root/review')"
  send_configured_event "$voice" PostToolUse "$payload"
  send_configured_event "$style" PostToolUse "$payload"
  payload="$(close_payload "$session" "$fixture" 'review' '**Voice & Tone Review: PASS**')"
  send_configured_event "$voice" PostToolUse "$payload"
  send_configured_event "$style" PostToolUse "$payload"
  [ -f "/tmp/voice-tone-reviewed-$session" ]
  [ ! -e "/tmp/style-guide-reviewed-$session" ]

  session="bats-p402-drift-$$"
  send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  printf '\nAll buttons must now use a different theme.\n' >> "$policy"
  send_configured_event "$style" PostToolUse "$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
  [ ! -e "/tmp/style-guide-reviewed-$session" ]
  jq -e '.reason == "policy-changed"' "$TMPDIR/codex-review-completion-diagnostic.json"

  session="bats-p402-whitespace-$$"
  send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  printf '\n\n' >> "$policy"
  send_configured_event "$style" PostToolUse "$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
  [ -f "/tmp/style-guide-reviewed-$session" ]

  session="bats-p402-distinct-parent-$$"
  send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  send_configured_event "$style" SubagentStop "$(stop_payload "$session-child" "$fixture" 'wr-style-guide:agent' '/root/review' '**Style Guide Review: PASS**')"
  [ ! -e "/tmp/style-guide-reviewed-$session" ]
  [ ! -e "/tmp/style-guide-reviewed-$session-child" ]
  jq -e '.reason == "missing-parent-registration"' "$TMPDIR/codex-review-completion-diagnostic.json"

  session="bats-p402-expired-$$"
  send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  state="$(find "$TMPDIR/claude-risk-$session" -type f -name 'codex-review-*' -print -quit)"
  node -e 'require("node:fs").utimesSync(process.argv[1], new Date(Date.now()-10000), new Date(Date.now()-10000))' "$state"
  REVIEW_TTL=1 send_configured_event "$style" PostToolUse "$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
  [ ! -e "/tmp/style-guide-reviewed-$session" ]
  jq -e '.reason == "stale-registration"' "$TMPDIR/codex-review-completion-diagnostic.json"

  session="bats-p402-future-$$"
  send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
  state="$(find "$TMPDIR/claude-risk-$session" -type f -name 'codex-review-*' -print -quit)"
  node -e 'require("node:fs").utimesSync(process.argv[1], new Date(Date.now()+60000), new Date(Date.now()+60000))' "$state"
  send_configured_event "$style" PostToolUse "$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
  [ ! -e "/tmp/style-guide-reviewed-$session" ]
  jq -e '.reason == "invalid-registration-age"' "$TMPDIR/codex-review-completion-diagnostic.json"

  n=0
  for ttl in 0 -1 NaN Infinity 1oops; do
    n=$((n+1))
    session="bats-p402-invalid-ttl-$n-$$"
    REVIEW_TTL="$ttl" send_configured_event "$style" PostToolUse "$(spawn_payload "$session" "$fixture" 'wr-style-guide:agent' '/root/review')"
    REVIEW_TTL="$ttl" send_configured_event "$style" PostToolUse "$(close_payload "$session" "$fixture" 'review' '**Style Guide Review: PASS**')"
    [ ! -e "/tmp/style-guide-reviewed-$session" ]
    jq -e '.reason == "invalid-review-ttl"' "$TMPDIR/codex-review-completion-diagnostic.json"
  done
}

@test "packed voice-tone handles wait and SubagentStop without widening reviewer scope" {
  local root helper role target session marker writer state
  root="$(pack_plugin voice-tone)"
  helper="$root/hooks-codex/codex-agent-completion.mjs"
  role="wr-voice-tone:agent"
  target="/root/p402-voice"

  [ -f "$helper" ]
  jq -e '.hooks.SubagentStop[] | select(.matcher == "^wr-voice-tone:agent$")' "$root/hooks-codex/hooks.json"

  session="bats-p402-voice-wait-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-wait")"
  send_event "$helper" "$(wait_payload "$session" "$REPO_ROOT" "$target-wait" '**Voice & Tone Review: PASS**')"
  [ -e "$marker" ]

  session="bats-p402-voice-stop-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-stop")"
  send_event "$helper" "$(stop_payload "$session" "$REPO_ROOT" "$role" "$target-stop" '**Voice & Tone Review: PASS**')"
  [ -e "$marker" ]

  session="bats-p402-voice-narrative-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-narrative")"
  send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target-narrative" 'The review passed with no issues.')"
  [ ! -e "$marker" ]

  session="bats-p402-voice-empty-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-empty")"
  send_event "$helper" "$(jq -cn --arg session "$session" --arg cwd "$REPO_ROOT" '{session_id:$session,cwd:$cwd,tool_name:"wait_agent",tool_response:{message:"Wait timed out."}}')"
  send_event "$helper" "$(jq -cn --arg session "$session" --arg cwd "$REPO_ROOT" --arg target "$target-empty" '{session_id:$session,cwd:$cwd,tool_name:"interrupt_agent",tool_input:{target:$target},tool_response:{previous_status:"running"}}')"
  [ ! -e "$marker" ]

  session="bats-p402-voice-external-$$"
  key="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  marker="$TMPDIR/claude-risk-$session/external-comms-voice-tone-reviewed-$key"
  send_configured_event "$root" PostToolUse "$(spawn_payload "$session" "$REPO_ROOT" 'wr-voice-tone:external-comms' "$target-external")"
  send_configured_event "$root" PostToolUse "$(close_payload "$session" "$REPO_ROOT" "$target-external" "EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS
EXTERNAL_COMMS_VOICE_TONE_KEY: $key")"
  [ -e "$marker" ]

  session="bats-p402-voice-unrelated-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_configured_event "$root" PostToolUse "$(spawn_payload "$session" "$REPO_ROOT" 'wr-voice-tone:unknown' "$target-unrelated")"
  send_configured_event "$root" PostToolUse "$(close_payload "$session" "$REPO_ROOT" "$target-unrelated" '**Voice & Tone Review: PASS**')"
  [ ! -e "$marker" ]

  session="bats-p402-voice-parent-$$"
  marker="/tmp/voice-tone-reviewed-$session-other"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-parent")"
  send_event "$helper" "$(close_payload "$session-other" "$REPO_ROOT" "$target-parent" '**Voice & Tone Review: PASS**')"
  [ ! -e "$marker" ]
  jq -e '.reason == "missing-parent-registration"' "$TMPDIR/codex-review-completion-diagnostic.json"

  session="bats-p402-voice-writer-$$"
  marker="/tmp/voice-tone-reviewed-$session"
  send_event "$helper" "$(spawn_payload "$session" "$REPO_ROOT" "$role" "$target-writer")"
  writer="$root/hooks/voice-tone-mark-reviewed.sh"
  chmod -x "$writer"
  run send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target-writer" '**Voice & Tone Review: PASS**')"
  [ "$status" -ne 0 ]
  [ ! -e "$marker" ]
  chmod +x "$writer"
  send_event "$helper" "$(close_payload "$session" "$REPO_ROOT" "$target-writer" '**Voice & Tone Review: PASS**')"
  [ -e "$marker" ]
}
