#!/usr/bin/env bats
# Behavioural test for detect-unratified-stories-maps.sh (ADR-090 detector).
# DRIFT-AWARE via the shared lazy-fingerprint lib: a MAP counts as ratified only
# when it is `confirmed` AND its stored oversight-hash matches current content.
# Surfaces never-ratified, unconfirmed, and drift-reopened (confirmed then
# edited) maps; omits genuinely-ratified ones. Always exit 0.
#
# ADR-103: a STORY carries no marker of its own. It is approved when every map in
# its `story-maps:` field is ratified, so the story leg is tested through maps.
#
# @adr ADR-090  @adr ADR-103
# @problem P404 (Phase 2)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/detect-unratified-stories-maps.sh"
  MARK="${REPO_ROOT}/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/stories/accepted" "$TMPD/story-maps/draft"

  # A ratified map, and a story sitting on it — neither should be listed.
  printf -- '<head></head>\n<h1>ok map</h1>\n' > "$TMPD/story-maps/draft/STORY-MAP-1-ok.html"
  bash "$MARK" "$TMPD/story-maps/draft/STORY-MAP-1-ok.html"
  printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-1]\n---\n# ok\n' > "$TMPD/stories/accepted/STORY-1-ok.md"

  # A story naming an UNRATIFIED map, and one naming no map at all — listed.
  printf -- '---\nstatus: accepted\nstory-maps: [STORY-MAP-3]\n---\n# no\n' > "$TMPD/stories/accepted/STORY-2-unconf.md"
  printf -- '---\nstatus: accepted\n---\n# nomarker\n'                       > "$TMPD/stories/accepted/STORY-3-none.md"

  # A leftover story-level marker must NOT approve anything (ADR-103) — listed.
  printf -- '---\nstatus: accepted\nhuman-oversight: confirmed\nstory-maps: [STORY-MAP-3]\n---\n# stale\n' \
    > "$TMPD/stories/accepted/STORY-4-drift.md"

  # HTML map with no marker — listed.
  printf -- '<h1>no meta</h1>\n' > "$TMPD/story-maps/draft/STORY-MAP-3-none.html"
}
teardown() { rm -rf "$TMPD"; }

@test "detect: lists stories on unratified maps and unratified maps; omits approved; exit 0" {
  run bash "$SCRIPT" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
  [[ "$output" == *"STORY-2-unconf.md"* ]]
  [[ "$output" == *"STORY-3-none.md"* ]]
  [[ "$output" == *"STORY-4-drift.md"* ]]
  [[ "$output" == *"STORY-MAP-3-none.html"* ]]
  [[ "$output" != *"STORY-1-ok.md"* ]]
  [[ "$output" != *"STORY-MAP-1-ok.html"* ]]
}

@test "detect: fully-approved set yields empty output, exit 0" {
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
