#!/usr/bin/env bats

# Tests for architect-detect.sh (UserPromptSubmit) — verifies the injected
# scope exclusion text lists governance docs that the PreToolUse gate already
# exempts (P029). Without this, the LLM wastes time delegating to the
# architect for files the edit gate would allow anyway.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/architect-detect.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  mkdir -p docs/decisions
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

@test "detect: scope text mentions problem files exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docs/problems/"* ]] || [[ "$output" == *"problem tickets"* ]]
}

@test "detect: scope text mentions BRIEFING.md exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BRIEFING"* ]]
}

@test "detect: scope text mentions RISK-POLICY exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RISK-POLICY"* ]]
}

@test "detect: scope text mentions changeset exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"changeset"* ]]
}

@test "detect: scope text mentions memory files exemption (P029)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"memory"* ]] || [[ "$output" == *"MEMORY"* ]]
}
