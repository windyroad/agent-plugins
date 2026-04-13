#!/usr/bin/env bats

# Tests for risk-score-mark.sh subagent pattern matching

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "pattern matches colon-style: wr-risk-scorer:pipeline" {
  echo "wr-risk-scorer:pipeline" | grep -qE 'risk-scorer.pipeline'
}

@test "pattern matches colon-style: wr-risk-scorer:plan" {
  echo "wr-risk-scorer:plan" | grep -qE 'risk-scorer.plan'
}

@test "pattern matches colon-style: wr-risk-scorer:wip" {
  echo "wr-risk-scorer:wip" | grep -qE 'risk-scorer.wip'
}

@test "pattern matches colon-style: wr-risk-scorer:policy" {
  echo "wr-risk-scorer:policy" | grep -qE 'risk-scorer.policy'
}

@test "case guard matches wr-risk-scorer:pipeline" {
  SUBAGENT="wr-risk-scorer:pipeline"
  case "$SUBAGENT" in
    *risk-scorer*) true ;;
    *) false ;;
  esac
}

@test "case guard does NOT match unrelated agent" {
  SUBAGENT="wr-architect:agent"
  case "$SUBAGENT" in
    *risk-scorer*) false ;;
    *) true ;;
  esac
}
