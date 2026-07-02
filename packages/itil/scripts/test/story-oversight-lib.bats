#!/usr/bin/env bats
# Behavioural test for lib/story-oversight.sh — ADR-090 lazy-fingerprint helpers.
# The hash EXCLUDES the marker lines (so writing the marker is idempotent), and
# "ratified" = confirmed marker AND stored hash matches current content. Any
# content edit drifts the hash → not ratified (ADR-090 drift-invalidation).
#
# @adr ADR-090
# @problem P404 (Phase 2)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  LIB="${REPO_ROOT}/packages/itil/lib/story-oversight.sh"
  TMPD="$(mktemp -d)"
  # shellcheck source=/dev/null
  source "$LIB"
}
teardown() { rm -rf "$TMPD"; }

@test "oversight_content_hash: identical content → identical hash" {
  printf '# body\nline two\n' > "$TMPD/a"; printf '# body\nline two\n' > "$TMPD/b"
  [ "$(oversight_content_hash "$TMPD/a")" = "$(oversight_content_hash "$TMPD/b")" ]
}

@test "oversight_content_hash: adding/changing the marker lines does NOT change the hash" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/f"
  before="$(oversight_content_hash "$TMPD/f")"
  printf -- '---\nstatus: accepted\nhuman-oversight: confirmed\noversight-hash: %064d\n---\n# body\n' 0 > "$TMPD/f"
  [ "$before" = "$(oversight_content_hash "$TMPD/f")" ]
}

@test "oversight_content_hash: a real content edit DOES change the hash" {
  printf '# body\n' > "$TMPD/f"; before="$(oversight_content_hash "$TMPD/f")"
  printf '# body EDITED\n' > "$TMPD/f"
  [ "$before" != "$(oversight_content_hash "$TMPD/f")" ]
}

@test "oversight_content_hash: ticking an acceptance-criterion checkbox does NOT drift (lifecycle progress)" {
  printf -- '---\nstatus: accepted\n---\n- [ ] a criterion\n' > "$TMPD/f"; before="$(oversight_content_hash "$TMPD/f")"
  printf -- '---\nstatus: accepted\n---\n- [x] a criterion\n' > "$TMPD/f"
  [ "$before" = "$(oversight_content_hash "$TMPD/f")" ]
}

@test "oversight_content_hash: advancing frontmatter status: does NOT drift (lifecycle)" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/f"; before="$(oversight_content_hash "$TMPD/f")"
  printf -- '---\nstatus: done\n---\n# body\n' > "$TMPD/f"
  [ "$before" = "$(oversight_content_hash "$TMPD/f")" ]
}

@test "oversight_content_hash: changing criterion TEXT DOES drift (substance)" {
  printf -- '---\nstatus: accepted\n---\n- [ ] original\n' > "$TMPD/f"; before="$(oversight_content_hash "$TMPD/f")"
  printf -- '---\nstatus: accepted\n---\n- [ ] a DIFFERENT criterion\n' > "$TMPD/f"
  [ "$before" != "$(oversight_content_hash "$TMPD/f")" ]
}

@test "oversight_content_hash: advancing slice data-status does NOT drift (HTML map lifecycle)" {
  printf '<a class="slice" data-story-id="STORY-1" data-status="draft">x</a>\n' > "$TMPD/m.html"; before="$(oversight_content_hash "$TMPD/m.html")"
  printf '<a class="slice" data-story-id="STORY-1" data-status="done">x</a>\n' > "$TMPD/m.html"
  [ "$before" = "$(oversight_content_hash "$TMPD/m.html")" ]
}

@test "is_story_map_ratified: confirmed + matching hash → ratified (md)" {
  printf -- '---\nstatus: accepted\n---\n# body\n' > "$TMPD/f"
  h="$(oversight_content_hash "$TMPD/f")"
  printf -- '---\nstatus: accepted\nhuman-oversight: confirmed\noversight-hash: %s\n---\n# body\n' "$h" > "$TMPD/f"
  run is_story_map_ratified "$TMPD/f"; [ "$status" -eq 0 ]
}

@test "is_story_map_ratified: confirmed but STALE hash (drifted) → not ratified" {
  printf -- '---\nhuman-oversight: confirmed\noversight-hash: %064d\n---\n# body EDITED AFTER RATIFY\n' 1 > "$TMPD/f"
  run is_story_map_ratified "$TMPD/f"; [ "$status" -ne 0 ]
}

@test "is_story_map_ratified: confirmed with NO hash (legacy hand-ratified) → not ratified" {
  printf -- '---\nhuman-oversight: confirmed\n---\n# body\n' > "$TMPD/f"
  run is_story_map_ratified "$TMPD/f"; [ "$status" -ne 0 ]
}

@test "is_story_map_ratified: unconfirmed → not ratified" {
  printf -- '---\nhuman-oversight: unconfirmed\n---\n# body\n' > "$TMPD/f"
  run is_story_map_ratified "$TMPD/f"; [ "$status" -ne 0 ]
}

@test "is_story_map_ratified: HTML map confirmed + matching hash → ratified" {
  printf '<h1>map</h1>\n' > "$TMPD/m.html"
  h="$(oversight_content_hash "$TMPD/m.html")"
  printf '<meta name="human-oversight" content="confirmed">\n<meta name="oversight-hash" content="%s">\n<h1>map</h1>\n' "$h" > "$TMPD/m.html"
  run is_story_map_ratified "$TMPD/m.html"; [ "$status" -eq 0 ]
}
