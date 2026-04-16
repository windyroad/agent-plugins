#!/usr/bin/env bats

# Tests for jtbd-eval.sh (UserPromptSubmit) — verifies the injected scope
# exclusion text lists governance docs that the PreToolUse gate already
# exempts (P029). Without this, the LLM wastes time delegating to the
# jtbd-lead for files the edit gate would allow anyway.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-eval.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

@test "eval: scope text mentions problem files exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docs/problems/"* ]] || [[ "$output" == *"problem tickets"* ]]
}

@test "eval: scope text mentions BRIEFING.md exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BRIEFING"* ]]
}

@test "eval: scope text mentions RISK-POLICY exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RISK-POLICY"* ]]
}
