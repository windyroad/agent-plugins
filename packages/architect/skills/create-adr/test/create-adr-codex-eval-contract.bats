#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  EVAL_DIR="$REPO_ROOT/packages/architect/skills/create-adr/eval"
}

@test "create-adr Codex promptfoo config sits beside Claude config" {
  [ -f "$EVAL_DIR/promptfooconfig.yaml" ]
  [ -f "$EVAL_DIR/promptfooconfig.codex.yaml" ]
  run grep -n "run-codex-skill-eval.sh" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
  run grep -n "grade-codex-rubric.sh" "$EVAL_DIR/promptfooconfig.codex.yaml"
  [ "$status" -eq 0 ]
}

@test "create-adr Codex eval runner uses codex exec and plugin marketplace" {
  run grep -n "codex plugin marketplace add" "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n "codex plugin add wr-architect@windyroad-local" "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n "codex exec" "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n -- "--ephemeral" "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n -- 'approval_policy="never"' "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
  run grep -n -- "--sandbox read-only" "$EVAL_DIR/run-codex-skill-eval.sh"
  [ "$status" -eq 0 ]
}
