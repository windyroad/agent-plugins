#!/usr/bin/env bats
# Behavioural test for check-rfc-stories-ratified.sh (ADR-090 — an RFC may
# reference only RATIFIED stories). For each STORY-NNN in the RFC's stories:
# frontmatter, the predicate resolves the story file and verifies
# human-oversight: confirmed. Composes with check-rfc-has-stories (ADR-089):
# has-stories checks >=1 exists; this checks each listed one is ratified.
#
# @adr ADR-090 (story maps and stories carry a drift-invalidated human-oversight marker)
# @problem P404 (implement ADR-089 + ADR-090) — Phase 2

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/check-rfc-stories-ratified.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/stories/accepted"
}
teardown() { rm -rf "$TMPD"; }

mkstory() { # $1=id $2=oversight-value(or "none")
  local f="$TMPD/stories/accepted/$1-x.md"
  { echo "---"; echo "status: accepted"; echo "story-id: x"
    [ "$2" != "none" ] && echo "human-oversight: $2"
    echo "---"; echo "# $1"; } > "$f"
}
mkrfc() { printf -- '---\nstatus: proposed\nstories: [%s]\n---\n# rfc\n' "$1" > "$TMPD/RFC.proposed.md"; }

@test "check-rfc-stories-ratified: empty stories: [] passes vacuously (exit 0)" {
  printf -- '---\nstatus: proposed\nstories: []\n---\n# rfc\n' > "$TMPD/RFC.proposed.md"
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -eq 0 ]
}

@test "check-rfc-stories-ratified: a confirmed story is ACCEPTED (exit 0)" {
  mkstory STORY-020 confirmed
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -eq 0 ]
}

@test "check-rfc-stories-ratified: an unconfirmed story is REJECTED (exit non-zero)" {
  mkstory STORY-020 unconfirmed
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-020"* ]]
}

@test "check-rfc-stories-ratified: a story with NO oversight marker is REJECTED" {
  mkstory STORY-020 none
  mkrfc STORY-020
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-020"* ]]
}

@test "check-rfc-stories-ratified: a missing story file is REJECTED" {
  mkrfc STORY-099
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-099"* ]]
}

@test "check-rfc-stories-ratified: mixed — one confirmed one unconfirmed is REJECTED" {
  mkstory STORY-020 confirmed
  mkstory STORY-021 unconfirmed
  mkrfc "STORY-020, STORY-021"
  run bash "$SCRIPT" "$TMPD/RFC.proposed.md" "$TMPD/stories"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-021"* ]]
}
