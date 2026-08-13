#!/usr/bin/env bats
# Behavioural test for mark-story-oversight-confirmed.sh (ADR-090 ratify write-path).
# Writes `confirmed` + the content fingerprint into a story MAP. After marking,
# is_story_map_ratified is true; a later substance edit drifts it back.
#
# ADR-103: a STORY is never marked — its approval is its map's — so the script
# refuses one rather than writing a second approval surface.
#
# @adr ADR-090  @adr ADR-103
# @problem P404 (Phase 2)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/packages/itil/lib/story-oversight.sh"
  TMPD="$(mktemp -d)"
}
teardown() { rm -rf "$TMPD"; }

@test "mark: refuses a story — approval is the map's, not the story's (ADR-103)" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/s.md"
  run bash "$SCRIPT" "$TMPD/s.md"
  [ "$status" -eq 2 ]
  # The refusal must name the remedy, or the caller has nowhere to go.
  echo "$output" | grep -q 'story-maps'
  # And it must not have written anything.
  ! grep -q 'human-oversight' "$TMPD/s.md"
}

@test "mark: refuses regardless of where the story lives" {
  # Keyed on the artefact, not a `docs/stories/` path substring — an adopter
  # with a different layout must get the same answer.
  mkdir -p "$TMPD/some/other/place"
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/some/other/place/s.md"
  run bash "$SCRIPT" "$TMPD/some/other/place/s.md"
  [ "$status" -eq 2 ]
}

@test "mark: HTML map → ratified after mark" {
  printf -- '<!doctype html>\n<head><title>map</title></head>\n<body><h1>map</h1></body>\n' > "$TMPD/m.html"
  run bash "$SCRIPT" "$TMPD/m.html"; [ "$status" -eq 0 ]
  grep -qE '<meta[^>]*name="human-oversight"[^>]*content="confirmed"' "$TMPD/m.html"
  run is_story_map_ratified "$TMPD/m.html"; [ "$status" -eq 0 ]
}
