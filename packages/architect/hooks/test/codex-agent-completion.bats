#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  export CLAUDE_PROJECT_DIR="$TMP/project"
  mkdir -p "$TMPDIR" "$CLAUDE_PROJECT_DIR/docs/decisions"
  SESSION="architect-codex-$$"
  TARGET="agent-target"
  MARKER="/tmp/architect-reviewed-$SESSION"
  HASH="$MARKER.hash"
  PLAN="/tmp/architect-plan-reviewed-$SESSION"
  rm -f "$MARKER" "$HASH" "$PLAN"
}

teardown() {
  rm -f "$MARKER" "$HASH" "$PLAN"
  rm -rf "$TMP"
}

dispatch() {
  printf '%s' "$1" | node "$HOOK_DIR/codex-agent-completion.mjs"
}

spawn() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__spawn_agent","tool_input":{"agent_type":"%s"},"tool_response":{"agent_id":"%s"}}' "$SESSION" "$CLAUDE_PROJECT_DIR" "$1" "$TARGET"
}

close() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"%s"}}}' "$SESSION" "$CLAUDE_PROJECT_DIR" "$TARGET" "$1"
}

@test "matched Codex architect PASS creates review markers" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ -f "$MARKER" ]
  [ -f "$HASH" ]
  [ -f "$PLAN" ]
}

@test "issues and malformed output fail closed" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close '**Architecture Review: ISSUES FOUND**')"
  [ ! -e "$MARKER" ]
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close 'review complete')"
  [ ! -e "$MARKER" ]
}

@test "unmatched close and non-architect target do not unlock" {
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
  dispatch "$(spawn default)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
}

@test "reused target clears stale architect identity" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(spawn default)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
}
