#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  export CLAUDE_PROJECT_DIR="$TMP/project"
  mkdir -p "$TMPDIR" "$CLAUDE_PROJECT_DIR/docs/decisions"
  git init -q "$CLAUDE_PROJECT_DIR"
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

stop() {
  printf '{"session_id":"architect-child-%s","cwd":"%s","hook_event_name":"SubagentStop","agent_type":"wr-architect:agent","agent_id":"%s","last_assistant_message":"%s"}' "$$" "$CLAUDE_PROJECT_DIR" "$TARGET" "$1"
}

prompt() {
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"UserPromptSubmit"}' "$SESSION" "$CLAUDE_PROJECT_DIR"
}

guarded_edit() {
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"src/example.js"}}' "$SESSION" "$CLAUDE_PROJECT_DIR"
}

@test "matched Codex architect PASS creates review markers" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(close '**Architecture Review: PASS**')"
  [ -f "$MARKER" ]
  [ -f "$HASH" ]
  [ -f "$PLAN" ]
}

@test "background Codex architect PASS is imported only by its parent" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '**Architecture Review: PASS**')"
  [ ! -e "$MARKER" ]
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]
  [ -f "$HASH" ]
  [ -f "$PLAN" ]
}

@test "background architect accepts the canonical H2 PASS and rejects conflicting verdicts" {
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '## Architecture Review: PASS')"
  dispatch "$(guarded_edit)"
  [ -f "$MARKER" ]

  rm -f "$MARKER" "$HASH" "$PLAN"
  dispatch "$(spawn wr-architect:agent)"
  dispatch "$(stop '**Architecture Review: PASS**\n**Architecture Review: ISSUES FOUND**')"
  dispatch "$(guarded_edit)"
  [ ! -e "$MARKER" ]
}

@test "expired architect registrations do not make a current background review ambiguous" {
  dispatch "$(spawn wr-architect:agent)"
  live="$(find "$TMPDIR/codex-review-transport" -name 'registration-*.json' -print -quit)"
  stale="$TMPDIR/codex-review-transport/registration-$(printf 'a%.0s' {1..64}).json"
  jq '.parentSession = "expired-parent" | .createdAt = 0' "$live" > "$stale"

  dispatch "$(stop '**Architecture Review: PASS**')"
  dispatch "$(guarded_edit)"

  [ ! -e "$stale" ]
  [ -f "$MARKER" ]
}

@test "architect transport failures fail open without creating authorization" {
  blocker="$TMPDIR/codex-review-transport"
  printf 'not a directory\n' > "$blocker"

  run dispatch "$(spawn wr-architect:agent)"

  [ "$status" -eq 0 ]
  [ ! -e "$MARKER" ]
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
