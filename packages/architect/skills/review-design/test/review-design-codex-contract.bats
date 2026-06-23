#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL="$REPO_ROOT/packages/architect/skills/review-design/SKILL.md"
}

@test "review-design documents Claude and Codex architect invocation paths" {
  run grep -n "Claude Code invocation" "$SKILL"
  [ "$status" -eq 0 ]
  run grep -n "subagent_type: wr-architect:agent" "$SKILL"
  [ "$status" -eq 0 ]
  run grep -n "Codex invocation" "$SKILL"
  [ "$status" -eq 0 ]
  run grep -nE "^agent: wr-architect:agent$" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "review-design names generated Codex agent config" {
  run grep -n ".codex/agents/wr-architect.toml" "$SKILL"
  [ "$status" -eq 0 ]
}
