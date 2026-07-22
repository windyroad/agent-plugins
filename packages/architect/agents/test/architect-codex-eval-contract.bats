#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  EVAL_DIR="$REPO_ROOT/packages/architect/agents/eval"
}

@test "architect Codex agent eval covers required verdict classes" {
  [ -f "$EVAL_DIR/promptfooconfig.codex.yaml" ]
  run grep -n "PASS" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
  run grep -n "ISSUES FOUND" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
  run grep -n "NEEDS DIRECTION" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
  run grep -n "Unratified Dependency" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
}

@test "architect Codex agent eval runner uses packed install and exact custom agent" {
  run grep -n 'npm pack' "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n 'windyroad-architect --runtime codex --scope user' "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n "codex exec" "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n 'agents/wr-architect-agent.toml' "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n 'wr-architect:agent' "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n 'git -C "$TMP_REPO" init' "$EVAL_DIR/run-codex-agent-eval.sh"
  [ "$status" -eq 0 ]
}
