#!/usr/bin/env bats

# Tests for architect verdict parsing from output text

@test "grep matches 'Architecture Review: PASS'" {
  output="Some preamble text\n\n**Architecture Review: PASS**\n\nNo conflicts."
  echo -e "$output" | grep -q "Architecture Review: PASS"
}

@test "grep matches 'ISSUES FOUND'" {
  output="**Architecture Review: ISSUES FOUND**\n\n1. [Decision Conflict]"
  echo -e "$output" | grep -q "ISSUES FOUND"
}

@test "grep does NOT match unrelated text" {
  output="The review is complete. Everything looks good."
  ! echo -e "$output" | grep -q "Architecture Review: PASS"
}

@test "subagent pattern matches wr-architect:agent" {
  SUBAGENT="wr-architect:agent"
  case "$SUBAGENT" in
    *architect*) true ;;
    *) false ;;
  esac
}
