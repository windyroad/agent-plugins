#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$TMPDIR"
  SESSION="parent-session"
  TARGET="/root/external-comms"
  KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
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
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__wait_agent","tool_input":{"targets":["%s"]},"tool_response":{"status":{"%s":{"completed":"RISK_SCORES: commit=4 push=4 release=4"}},"timed_out":false}}' \
    "$SESSION" "$TMP" "$TARGET" "$TARGET"
}

current_pipeline_close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"RISK_SCORES: commit=4 push=4 release=4"}}}' \
    "$SESSION" "$TMP" "$TARGET"
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
  [ "$(find "$TMP/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]

  dispatch "$(current_pipeline_close_input)"
  [ "$(find "$TMP/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
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
