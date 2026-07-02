#!/usr/bin/env bats
# Behavioural test for detect-unratified-stories-maps.sh (ADR-090 detector).
# Mirrors wr-architect detect-unoversighted.sh, but spans TWO artefact types
# with DIFFERENT marker encodings:
#   - stories: markdown YAML frontmatter `human-oversight: confirmed`
#   - story-maps: HTML `<meta name="human-oversight" content="confirmed">`
# Lists every artefact whose marker is missing or not `confirmed`. Always exit 0.
#
# @adr ADR-090 (drift-invalidated story-map/story human-oversight marker)
# @problem P404 (implement ADR-089 + ADR-090) — Phase 2

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/detect-unratified-stories-maps.sh"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/stories/accepted" "$TMPD/story-maps/draft"
  # stories (markdown frontmatter)
  printf -- '---\nstatus: accepted\nhuman-oversight: confirmed\n---\n# ok\n'   > "$TMPD/stories/accepted/STORY-1-ok.md"
  printf -- '---\nstatus: accepted\nhuman-oversight: unconfirmed\n---\n# no\n' > "$TMPD/stories/accepted/STORY-2-unconf.md"
  printf -- '---\nstatus: accepted\n---\n# nomarker\n'                          > "$TMPD/stories/accepted/STORY-3-none.md"
  # story-maps (HTML meta)
  printf -- '<meta name="human-oversight" content="confirmed">\n'   > "$TMPD/story-maps/draft/STORY-MAP-1-ok.html"
  printf -- '<meta name="human-oversight" content="unconfirmed">\n' > "$TMPD/story-maps/draft/STORY-MAP-2-unconf.html"
  printf -- '<h1>no meta</h1>\n'                                     > "$TMPD/story-maps/draft/STORY-MAP-3-none.html"
}
teardown() { rm -rf "$TMPD"; }

@test "detect: lists unconfirmed + unmarked, omits confirmed; exits 0" {
  run bash "$SCRIPT" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
  [[ "$output" == *"STORY-2-unconf.md"* ]]
  [[ "$output" == *"STORY-3-none.md"* ]]
  [[ "$output" == *"STORY-MAP-2-unconf.html"* ]]
  [[ "$output" == *"STORY-MAP-3-none.html"* ]]
  [[ "$output" != *"STORY-1-ok.md"* ]]
  [[ "$output" != *"STORY-MAP-1-ok.html"* ]]
}

@test "detect: all-confirmed set yields empty output, exit 0" {
  rm "$TMPD/stories/accepted/STORY-2-unconf.md" "$TMPD/stories/accepted/STORY-3-none.md" \
     "$TMPD/story-maps/draft/STORY-MAP-2-unconf.html" "$TMPD/story-maps/draft/STORY-MAP-3-none.html"
  run bash "$SCRIPT" "$TMPD/stories" "$TMPD/story-maps"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "detect: missing dirs are tolerated (exit 0, no crash)" {
  run bash "$SCRIPT" "$TMPD/nope-stories" "$TMPD/nope-maps"
  [ "$status" -eq 0 ]
}
