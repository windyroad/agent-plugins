#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL="$REPO_ROOT/packages/architect/skills/review-design/SKILL.md"
  CREATE_SKILL="$REPO_ROOT/packages/architect/skills/create-adr/SKILL.md"
  REVIEW_SKILL="$REPO_ROOT/packages/architect/skills/review-decisions/SKILL.md"
  AGENT="$REPO_ROOT/packages/architect/agents/agent.md"
}

@test "ratified ADR guidance permits supersession but not amendment" {
  run grep -F "Draft a new ADR that supersedes the ratified decision" "$SKILL"
  [ "$status" -eq 0 ]
  run grep -F "a confirmed ADR is immutable" "$CREATE_SKILL"
  [ "$status" -eq 0 ]
  run grep -F "do not clear its marker or edit its body" "$REVIEW_SKILL"
  [ "$status" -eq 0 ]
  run grep -F "Do not edit the old decision's frontmatter or body" "$AGENT"
  [ "$status" -eq 0 ]
  run grep -F 'Updated with "Superseded by" note' "$AGENT"
  [ "$status" -ne 0 ]
  run grep -F "new or amended ADR" "$SKILL"
  [ "$status" -ne 0 ]
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
