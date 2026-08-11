#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$TMPDIR"
  SESSION="parent-session"
  TARGET="/root/external-comms"
  KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  PIPELINE_REPO="$TMP/assessed"
  OTHER_REPO="$TMP/completion"
  git init -q "$PIPELINE_REPO"
  git init -q "$OTHER_REPO"
  printf 'assessed\n' > "$PIPELINE_REPO/state"
  printf 'completion\n' > "$OTHER_REPO/state"
  git -C "$PIPELINE_REPO" add state
  git -C "$OTHER_REPO" add state
  git -C "$PIPELINE_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
  git -C "$OTHER_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
}

teardown() {
  rm -rf "$TMP"
}

dispatch() {
  printf '%s' "$1" | "$HOOK_DIR/risk-scorer-dispatch.sh" post-tool
}

dispatch_subagent_stop() {
  printf '%s' "$1" | "$HOOK_DIR/risk-scorer-dispatch.sh" subagent-stop
}

spawn_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationspawn_agent","tool_input":{"agent_type":"%s"},"tool_response":"{\\"task_name\\":\\"%s\\"}"}' \
    "$SESSION" "$TMP" "${1:-wr-risk-scorer:external-comms}" "$TARGET"
}

current_spawn_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__spawn_agent","tool_input":{"agent_type":"%s"},"tool_response":{"agent_id":"%s"}}' \
    "$SESSION" "$TMP" "${1:-wr-risk-scorer:external-comms}" "$TARGET"
}

close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationinterrupt_agent","tool_input":{"target":"%s"},"tool_response":"{\\"previous_status\\":{\\"completed\\":\\"EXTERNAL_COMMS_RISK_VERDICT: PASS\\\\nEXTERNAL_COMMS_RISK_KEY: %s\\"}}"}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

current_close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"EXTERNAL_COMMS_RISK_VERDICT: PASS\\nEXTERNAL_COMMS_RISK_KEY: %s"}}}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

current_pipeline_wait_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__wait_agent","tool_input":{"targets":["%s"]},"tool_response":{"status":{"%s":{"completed":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}},"timed_out":false}}' \
    "$SESSION" "$OTHER_REPO" "$TARGET" "$TARGET" "$PIPELINE_REPO"
}

current_pipeline_close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}}}' \
    "$SESSION" "$OTHER_REPO" "$TARGET" "$PIPELINE_REPO"
}

current_empty_wait_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationwait_agent","tool_input":{"timeout_ms":3600000},"tool_response":"{\"message\":\"Wait completed.\",\"timed_out\":false}"}' \
    "$SESSION" "$TMP"
}

subagent_stop_input() {
  printf '{"hook_event_name":"SubagentStop","session_id":"%s","cwd":"%s","agent_id":"%s","agent_type":"wr-risk-scorer:external-comms","last_assistant_message":"EXTERNAL_COMMS_RISK_VERDICT: PASS\\nEXTERNAL_COMMS_RISK_KEY: %s"}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

@test "desktop SubagentStop marks completion before agent close" {
  dispatch "$(current_spawn_input)"
  dispatch_subagent_stop "$(subagent_stop_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
  [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' | wc -l | tr -d ' ')" = "1" ]

  dispatch "$(current_close_input)"
  [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' | wc -l | tr -d ' ')" = "1" ]
}

@test "Codex completion bridge marks the exact risk agent when it closes" {
  dispatch "$(spawn_input)"
  dispatch "$(close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
  run find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.claim' -print -quit
  [ -z "$output" ]
  run find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' -print -quit
  [ -n "$output" ]
}

@test "Codex completion bridge supports current agent ids and tool names" {
  dispatch "$(current_spawn_input)"
  dispatch "$(current_close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "current wait response stays inert until completed-agent close" {
  dispatch "$(spawn_input)"
  dispatch "$(current_empty_wait_input)"
  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]

  dispatch "$(close_input)"
  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "wait_agent completion refreshes a stale pipeline score exactly once" {
  rdir="$TMPDIR/claude-risk-$SESSION"
  mkdir -p "$rdir"
  printf '9' > "$rdir/commit"

  dispatch "$(current_spawn_input wr-risk-scorer:pipeline)"
  dispatch "$(current_pipeline_wait_input)"

  [ "$(cat "$rdir/commit")" = "4" ]
  [ "$(cat "$rdir/push")" = "4" ]
  [ "$(cat "$rdir/release")" = "4" ]
  expected="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && "$HOOK_DIR/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
  completion_hash="$(cd "$OTHER_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && "$HOOK_DIR/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
  [ "$(cat "$rdir/state-hash")" = "$expected" ]
  [ "$(cat "$rdir/state-hash")" != "$completion_hash" ]
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
  [ ! -e "$OTHER_REPO/.risk-reports" ]
  run grep -R "$PIPELINE_REPO" "$PIPELINE_REPO/.risk-reports"
  [ "$status" -ne 0 ]

  dispatch "$(current_pipeline_close_input)"
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
}

@test "pipeline completion rejects invalid assessed roots and remains retryable" {
  dispatch "$(current_spawn_input wr-risk-scorer:pipeline)"
  mkdir "$PIPELINE_REPO/subdir"

  for invalid_root in relative/path "$PIPELINE_REPO/subdir"; do
    invalid="$(current_pipeline_close_input | sed "s#RISK_CWD: $PIPELINE_REPO#RISK_CWD: $invalid_root#")"
    run dispatch "$invalid"
    [ "$status" -ne 0 ]
    [ ! -e "$TMPDIR/claude-risk-$SESSION/commit" ]
    [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*' ! -name '*.claim' ! -name '*.done' | wc -l | tr -d ' ')" = "1" ]
  done

  dispatch "$(current_pipeline_close_input)"
  [ "$(cat "$TMPDIR/claude-risk-$SESSION/commit")" = "4" ]
}

@test "a reused target cannot retain a stale risk-agent role" {
  dispatch "$(current_spawn_input)"
  dispatch "$(current_spawn_input default)"
  dispatch "$(current_close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "Codex completion bridge ignores a non-risk agent" {
  dispatch "$(spawn_input default)"
  dispatch "$(close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "Codex completion bridge ignores a close without a matching spawn" {
  dispatch "$(close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}
