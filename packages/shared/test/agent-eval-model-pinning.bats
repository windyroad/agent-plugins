#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  TMP="$(mktemp -d)"
  BIN="$TMP/bin"
  CLAUDE_LOG="$TMP/claude.log"
  NPM_LOG="$TMP/npm.log"
  mkdir -p "$BIN"

  cat > "$BIN/claude" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CLAUDE_LOG"
if [[ " $* " == *" --output-format stream-json "* ]]; then
  printf '%s\n' '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"text","text":"JTBD Review: PASS"}]}}'
elif [[ "${FAKE_CLAUDE_GRADER:-0}" == 1 ]]; then
  printf '%s\n' '{"pass":true,"score":1,"reason":"ok"}'
else
  printf '%s\n' 'RISK_SCORES: commit=1 push=1 release=1'
fi
SH
  chmod +x "$BIN/claude"

  cat > "$BIN/npm" <<'SH'
#!/usr/bin/env bash
printf 'agent=%s grader=%s argv=%s\n' \
  "${AGENT_EVAL_MODEL:-}" "${AGENT_EVAL_GRADER_MODEL:-}" "$*" > "$NPM_LOG"
SH
  chmod +x "$BIN/npm"
}

teardown() {
  rm -rf "$TMP"
}

@test "Claude agent evals invoke Sonnet 5" {
  runners=(
    packages/shared/agents/eval/run-claude-eval.sh
    packages/architect/agents/eval/run-agent-eval.sh
    packages/jtbd/agents/eval/run-agent-eval.sh
    packages/risk-scorer/agents/eval/run-agent-eval.sh
    packages/style-guide/agents/eval/run-agent-eval.sh
    packages/tdd/agents/eval/run-agent-eval.sh
    packages/voice-tone/agents/eval/run-agent-eval.sh
  )

  for runner in "${runners[@]}"; do
    : > "$CLAUDE_LOG"
    run env -u AGENT_EVAL_MODEL PATH="$BIN:$PATH" CLAUDE_LOG="$CLAUDE_LOG" \
      "$REPO_ROOT/$runner" 'AGENT: pipeline'
    [ "$status" -eq 0 ]
    run grep -F -- '--model claude-sonnet-5' "$CLAUDE_LOG"
    [ "$status" -eq 0 ]
  done
}

@test "Claude rubric graders invoke Opus 5.5" {
  graders=(
    packages/architect/agents/eval/grade-llm-rubric.sh
    packages/risk-scorer/agents/eval/grade-llm-rubric.sh
    packages/style-guide/agents/eval/grade-llm-rubric.sh
    packages/tdd/agents/eval/grade-llm-rubric.sh
    packages/voice-tone/agents/eval/grade-llm-rubric.sh
  )

  for grader in "${graders[@]}"; do
    : > "$CLAUDE_LOG"
    run env -u AGENT_EVAL_GRADER_MODEL PATH="$BIN:$PATH" \
      CLAUDE_LOG="$CLAUDE_LOG" FAKE_CLAUDE_GRADER=1 \
      "$REPO_ROOT/$grader" 'Return a passing grade.'
    [ "$status" -eq 0 ]
    run grep -F -- '--model claude-opus-5-5' "$CLAUDE_LOG"
    [ "$status" -eq 0 ]
  done
}

@test "CI probes Sonnet 5 and delegates both pinned model roles" {
  run env PATH="$BIN:$PATH" CLAUDE_LOG="$CLAUDE_LOG" NPM_LOG="$NPM_LOG" \
    "$REPO_ROOT/scripts/run-agent-evals-ci.sh"

  [ "$status" -eq 0 ]
  run grep -F -- '--model claude-sonnet-5 Reply exactly: available' "$CLAUDE_LOG"
  [ "$status" -eq 0 ]
  run grep -F 'agent=claude-sonnet-5 grader=claude-opus-5-5 argv=run eval:agents' "$NPM_LOG"
  [ "$status" -eq 0 ]
}
