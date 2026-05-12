#!/usr/bin/env bats
# Behavioural contract fixtures for /wr-itil:list-story-maps (P170 Phase 2 Slice 6).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/list-story-maps/SKILL.md"
}

@test "list-story-maps: SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "list-story-maps: SKILL.md frontmatter declares wr-itil:list-story-maps name" {
  run grep -E '^name: wr-itil:list-story-maps$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "list-story-maps: SKILL.md allowed-tools does NOT include Write or Edit (read-only contract)" {
  run grep '^allowed-tools:' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Write"* ]]
  [[ "$output" != *"Edit"* ]]
}

@test "list-story-maps: SKILL.md names all 5 lifecycle state subdirectories" {
  for state in draft accepted in-progress completed archived; do
    run grep -E "docs/story-maps/${state}|${state}/" "$SKILL_FILE"
    [ "$status" -eq 0 ]
  done
}

@test "list-story-maps: SKILL.md does NOT render a WSJF column (I5 invariant)" {
  # Story-maps are planning artefacts, not work items — no WSJF per ADR-060 line 145.
  run grep -E '^\| WSJF\b|\| WSJF \|' "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "list-story-maps: SKILL.md names <meta> block parse target per ADR-060 lines 381-435" {
  run grep -E '<meta name=|xmllint.*meta' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "list-story-maps: SKILL.md uses git log cache-freshness pattern per P031" {
  run grep -E 'git log -1 --format=%H -- docs/story-maps/README\.md' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
