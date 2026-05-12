#!/usr/bin/env bats

# P170 / Phase 2 Slice 2b — sanity bats for the 3 sibling helpers
# (update-rfc-references-section.sh, update-jtbd-references-section.sh,
# update-story-references-section.sh). Behavioural coverage of the
# polymorphism is asserted by the comprehensive Slice 2a bats fixture
# at update-problem-references-section.bats; this fixture asserts
# existence + executable + arg-validation + structural no-branching
# guard for the 3 siblings, deferring full behavioural coverage to
# follow-on slice when the siblings are wired into consumer skills.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  RFC_HELPER="$REPO_ROOT/packages/itil/scripts/update-rfc-references-section.sh"
  JTBD_HELPER="$REPO_ROOT/packages/itil/scripts/update-jtbd-references-section.sh"
  STORY_HELPER="$REPO_ROOT/packages/itil/scripts/update-story-references-section.sh"
}

@test "rfc-helper: exists and is executable" {
  [ -x "$RFC_HELPER" ]
}

@test "rfc-helper: requires rfc-file arg" {
  run bash "$RFC_HELPER"
  [ "$status" -ne 0 ]
}

@test "rfc-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$RFC_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "rfc-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$RFC_HELPER"
}

@test "jtbd-helper: exists and is executable" {
  [ -x "$JTBD_HELPER" ]
}

@test "jtbd-helper: requires jtbd-file arg" {
  run bash "$JTBD_HELPER"
  [ "$status" -ne 0 ]
}

@test "jtbd-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$JTBD_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "jtbd-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$JTBD_HELPER"
}

@test "story-helper: exists and is executable" {
  [ -x "$STORY_HELPER" ]
}

@test "story-helper: requires story-file arg" {
  run bash "$STORY_HELPER"
  [ "$status" -ne 0 ]
}

@test "story-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$STORY_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "story-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$STORY_HELPER"
}
