#!/usr/bin/env bats
# Behavioural fixtures for /wr-itil:capture-story-map (P170 Phase 2 Slice 3 — ADR-060).
#
# Mirrors capture-story-behavioural.bats with story-map-tier adjustments
# (HTML encoding, I3 + I4 invariants instead of I6 + I9, no optional
# --rfc / --story-map flags).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/capture-story-map/SKILL.md"
  HELPER_PROBLEM="${REPO_ROOT}/packages/itil/scripts/update-problem-references-section.sh"
  HELPER_JTBD="${REPO_ROOT}/packages/itil/scripts/update-jtbd-references-section.sh"

  TMPROOT=$(mktemp -d)
  ORIG_DIR="$PWD"
  cd "$TMPROOT"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPROOT"
}

@test "capture-story-map: SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "capture-story-map: SKILL.md frontmatter declares wr-itil:capture-story-map name" {
  run grep -E '^name: wr-itil:capture-story-map$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-story-map: SKILL.md names I3 trace-to-problem invariant" {
  run grep -E 'I3 hard-block|I3.*trace-to-problem' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-story-map: SKILL.md names I4 trace-to-JTBD invariant" {
  run grep -E 'I4 hard-block|I4.*trace-to-JTBD' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-story-map: next-ID formula computes 001 for empty story-maps directory" {
  mkdir -p docs/story-maps/draft
  local_max=$(ls docs/story-maps/*/STORY-MAP-*.html 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
  next=$(printf '%03d' $(( 10#${local_max:-0} + 1 )))
  [ "$next" = "001" ]
}

@test "capture-story-map: next-ID formula computes 003 when STORY-MAP-002 exists locally" {
  mkdir -p docs/story-maps/draft docs/story-maps/in-progress
  touch docs/story-maps/draft/STORY-MAP-002-foo.html
  touch docs/story-maps/in-progress/STORY-MAP-001-bar.html
  local_max=$(ls docs/story-maps/*/STORY-MAP-*.html 2>/dev/null | sed 's|.*/STORY-MAP-||;s|-.*||' | grep -oE '^[0-9]+' | sort -n | tail -1)
  next=$(printf '%03d' $(( 10#${local_max:-0} + 1 )))
  [ "$next" = "003" ]
}

@test "capture-story-map: update-problem-references-section.sh accepts 'Story Maps' section name" {
  mkdir -p docs/problems/known-error docs/story-maps/draft
  cat > docs/problems/known-error/170-test.md <<'EOF'
# P170: Test

## Story Maps

(empty)
EOF
  run bash "$HELPER_PROBLEM" docs/problems/known-error/170-test.md "Story Maps"
  [[ "$output" != *"unknown section-name"* ]]
}

@test "capture-story-map: update-jtbd-references-section.sh accepts 'Story Maps' section name" {
  mkdir -p docs/jtbd/solo-developer docs/story-maps/draft
  cat > docs/jtbd/solo-developer/JTBD-008-test.proposed.md <<'EOF'
# JTBD-008: Test

## Story Maps

(empty)
EOF
  run bash "$HELPER_JTBD" docs/jtbd/solo-developer/JTBD-008-test.proposed.md "Story Maps"
  [[ "$output" != *"unknown section-name"* ]]
}

@test "capture-story-map: SKILL.md prescribes HTML encoding per ADR-060 amendment 2026-05-12" {
  run grep -E 'HTML5|<!DOCTYPE html>|encoding amendment 2026-05-12' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-story-map: SKILL.md prescribes draft/ landing subdir" {
  run grep -E 'docs/story-maps/draft/STORY-MAP' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "capture-story-map: SKILL.md prohibits inline style on data-bearing elements per STYLE-GUIDE.md" {
  run grep -iE 'NO inline.*style.*data-bearing|prohibited inline.*style' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
