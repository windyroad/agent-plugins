#!/usr/bin/env bats
# Behavioural test for mark-story-oversight-confirmed.sh (ADR-090 ratify write-path).
# Writes `confirmed` + the content fingerprint into a story (md frontmatter) or a
# story-map (HTML meta). After marking, is_story_map_ratified is true; a later
# content edit drifts it back to not-ratified.
#
# @adr ADR-090
# @problem P404 (Phase 2)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/packages/itil/lib/story-oversight.sh"
  TMPD="$(mktemp -d)"
}
teardown() { rm -rf "$TMPD"; }

@test "mark: md story with no marker → ratified after mark" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/s.md"
  run bash "$SCRIPT" "$TMPD/s.md"; [ "$status" -eq 0 ]
  run is_story_map_ratified "$TMPD/s.md"; [ "$status" -eq 0 ]
}

@test "mark: md story with existing unconfirmed marker → confirmed + ratified" {
  printf -- '---\nstatus: accepted\nhuman-oversight: unconfirmed\n---\n# body\n' > "$TMPD/s.md"
  bash "$SCRIPT" "$TMPD/s.md"
  grep -qE '^human-oversight:[[:space:]]*confirmed' "$TMPD/s.md"
  run is_story_map_ratified "$TMPD/s.md"; [ "$status" -eq 0 ]
  # no duplicate marker line left behind
  [ "$(grep -cE '^human-oversight:' "$TMPD/s.md")" -eq 1 ]
}

@test "mark: idempotent — marking twice stays ratified, single marker" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/s.md"
  bash "$SCRIPT" "$TMPD/s.md"; bash "$SCRIPT" "$TMPD/s.md"
  run is_story_map_ratified "$TMPD/s.md"; [ "$status" -eq 0 ]
  [ "$(grep -cE '^oversight-hash:' "$TMPD/s.md")" -eq 1 ]
}

@test "mark: drift — mark then edit body → not ratified" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/s.md"
  bash "$SCRIPT" "$TMPD/s.md"
  printf -- '---\nstatus: accepted\nhuman-oversight: confirmed\n---\n# body EDITED\n' > "$TMPD/s.md"
  run is_story_map_ratified "$TMPD/s.md"; [ "$status" -ne 0 ]
}

@test "mark: HTML map → ratified after mark" {
  printf -- '<!doctype html>\n<head><title>map</title></head>\n<body><h1>map</h1></body>\n' > "$TMPD/m.html"
  run bash "$SCRIPT" "$TMPD/m.html"; [ "$status" -eq 0 ]
  grep -qE '<meta[^>]*name="human-oversight"[^>]*content="confirmed"' "$TMPD/m.html"
  run is_story_map_ratified "$TMPD/m.html"; [ "$status" -eq 0 ]
}
