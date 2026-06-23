#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "agent instructions: drift guard passes" {
  run node "$REPO_ROOT/scripts/check-agent-instructions.mjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "agent instructions: Codex and Claude runtime terms are preserved" {
  run grep -n "AskUserQuestion" "$REPO_ROOT/CLAUDE.md"
  [ "$status" -eq 0 ]
  run grep -n "request_user_input" "$REPO_ROOT/AGENTS.md"
  [ "$status" -eq 0 ]
  run grep -n "Plan Mode" "$REPO_ROOT/AGENTS.md"
  [ "$status" -eq 0 ]
}
