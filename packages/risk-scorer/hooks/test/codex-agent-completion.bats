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

@test "Codex completion bridge marks the exact risk agent when it closes" {
  dispatch "$(spawn_input)"
  dispatch "$(close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
  run find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*' -print -quit
  [ -z "$output" ]
}

@test "Codex completion bridge supports current agent ids and tool names" {
  dispatch "$(current_spawn_input)"
  dispatch "$(current_close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
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
