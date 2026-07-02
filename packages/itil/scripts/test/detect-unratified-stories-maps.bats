#!/usr/bin/env bats
# Behavioural test for detect-unratified-stories-maps.sh (ADR-090 detector).
# DRIFT-AWARE via the shared lazy-fingerprint lib: an artefact counts as ratified
# only when it is `confirmed` AND its stored oversight-hash matches current
# content. Surfaces never-ratified, unconfirmed, and drift-reopened (confirmed
# then edited) cases; omits genuinely-ratified ones. Always exit 0.
#
# @adr ADR-090
# @problem P404 (Phase 2)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/detect-unratified-stories-maps.sh"
  MARK="${REPO_ROOT}/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/stories/accepted" "$TMPD/story-maps/draft"

  # Genuinely ratified (via the mark write-path) — should NOT be listed.
  printf -- '---\nstatus: accepted\n---\n# ok\n' > "$TMPD/stories/accepted/STORY-1-ok.md"
  bash "$MARK" "$TMPD/stories/accepted/STORY-1-ok.md"
  printf -- '<head></head>\n<h1>ok map</h1>\n' > "$TMPD/story-maps/draft/STORY-MAP-1-ok.html"
  bash "$MARK" "$TMPD/story-maps/draft/STORY-MAP-1-ok.html"

  # Unconfirmed + unmarked — listed.
  printf -- '---\nstatus: accepted\nhuman-oversight: unconfirmed\n---\n# no\n' > "$TMPD/stories/accepted/STORY-2-unconf.md"
  printf -- '---\nstatus: accepted\n---\n# nomarker\n'                          > "$TMPD/stories/accepted/STORY-3-none.md"

  # Drifted: ratified, then content edited afterward — listed.
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/stories/accepted/STORY-4-drift.md"
  bash "$MARK" "$TMPD/stories/accepted/STORY-4-drift.md"
  printf '\nAn edit made after ratification.\n' >> "$TMPD/stories/accepted/STORY-4-drift.md"

  # HTML map with no marker — listed.
  printf -- '<h1>no meta</h1>\n' > "$TMPD/story-maps/draft/STORY-MAP-3-none.html"
}
teardown() { rm -rf "$TMPD"; }

@test "detect: lists unconfirmed + unmarked + DRIFTED, omits genuinely-ratified; exit 0" {
  run bash "$SCRIPT" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
  [[ "$output" == *"STORY-2-unconf.md"* ]]
  [[ "$output" == *"STORY-3-none.md"* ]]
  [[ "$output" == *"STORY-4-drift.md"* ]]
  [[ "$output" == *"STORY-MAP-3-none.html"* ]]
  [[ "$output" != *"STORY-1-ok.md"* ]]
  [[ "$output" != *"STORY-MAP-1-ok.html"* ]]
}

@test "detect: all-ratified set yields empty output, exit 0" {
  rm "$TMPD/stories/accepted/STORY-2-unconf.md" "$TMPD/stories/accepted/STORY-3-none.md" \
     "$TMPD/stories/accepted/STORY-4-drift.md" "$TMPD/story-maps/draft/STORY-MAP-3-none.html"
  run bash "$SCRIPT" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "detect: missing dirs are tolerated (exit 0, no crash)" {
  run bash "$SCRIPT" "$TMPD/nope-stories" "$TMPD/nope-maps"
  [ "$status" -eq 0 ]
}
