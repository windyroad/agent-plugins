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

# --- P474 / STORY-055: the extraction must not move a single hash --------------
#
# `oversight_content_hash` and `oversight_content_hash_excluding_stories` shared a
# verbatim grep|sed filter, which is why the P474 mirror had to be removed twice
# and why a third copy could have been missed. The filter is now extracted.
#
# The extraction boundary is the whole risk. The two functions' INPUT paths are
# NOT equivalent and must stay that way: one passes the file to grep directly,
# the other round-trips through $(cat) — which strips all trailing newlines —
# then printf '%s\n' re-adds exactly one. So trailing blank lines are preserved
# by the first and collapsed by the second. Extract the filter only; unify the
# input paths "for symmetry" and the hash silently changes for any artefact with
# anomalous trailing whitespace, un-ratifying every stored fingerprint at once.
#
# `_ref_*` below are VERBATIM copies of the pre-extraction implementation. They
# exist to be compared against, so do NOT refactor them to call the new helper —
# that would make the equivalence assertions circular and worthless.

_ref_hash() {
  grep -vE '^(human-oversight|oversight-hash|oversight-basis|status):|<meta[^>]*name="(human-oversight|oversight-hash|oversight-basis|status)"' "$1" \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g' \
    | shasum -a 256 | awk '{print $1}'
}

_ref_hash_excluding() {
  local f="$1"; shift
  local filtered id
  filtered="$(cat "$f")"
  for id in "$@"; do
    [ -n "$id" ] || continue
    filtered="$(printf '%s\n' "$filtered" | grep -vF "data-story-id=\"${id}\"" || true)"
  done
  printf '%s\n' "$filtered" \
    | grep -vE '^(human-oversight|oversight-hash|oversight-basis|status):|<meta[^>]*name="(human-oversight|oversight-hash|oversight-basis|status)"' \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g' \
    | shasum -a 256 | awk '{print $1}'
}

@test "extraction: byte-identical to the frozen reference across edge shapes" {
  # No final newline.
  printf -- '---\nstatus: draft\n---\nbody' > "$TMPD/a"
  # Multiple trailing blank lines — the shape the input-path divergence hinges on.
  printf -- '---\nstatus: draft\n---\nbody\n\n\n\n' > "$TMPD/b"
  # CRLF.
  printf -- '---\r\nstatus: draft\r\n---\r\nbody\r\n' > "$TMPD/c"
  # Empty file.
  : > "$TMPD/d"
  # A criterion tick and a data-status, both normalised.
  printf -- '- [x] done\n<a data-status="done">x</a>\n' > "$TMPD/e"
  # Every excluded key present, in both encodings.
  printf -- 'human-oversight: confirmed\noversight-hash: deadbeef\noversight-basis: pure-decomposition\nstatus: accepted\n<meta name="status" content="draft">\nbody\n' > "$TMPD/f"
  # Only a newline.
  printf '\n' > "$TMPD/g"

  for n in a b c d e f g; do
    [ "$(oversight_content_hash "$TMPD/$n")" = "$(_ref_hash "$TMPD/$n")" ] || {
      echo "oversight_content_hash diverged on fixture $n"; false
    }
  done
}

@test "extraction: map variant byte-identical, including the id-exclusion loop" {
  printf -- '<meta name="status" content="draft">\n<a data-story-id="STORY-05">short</a>\n<a data-story-id="STORY-054">long</a>\n<a class="slice" data-status="done">s</a>\nbody\n\n\n' \
    > "$TMPD/m.html"
  # Zero ids, one id, and the prefix-collision pair — STORY-05 must not strip
  # STORY-054's card, which is what the closing-quote anchor buys.
  [ "$(oversight_content_hash_excluding_stories "$TMPD/m.html")" = "$(_ref_hash_excluding "$TMPD/m.html")" ]
  [ "$(oversight_content_hash_excluding_stories "$TMPD/m.html" STORY-054)" = "$(_ref_hash_excluding "$TMPD/m.html" STORY-054)" ]
  [ "$(oversight_content_hash_excluding_stories "$TMPD/m.html" STORY-05)" = "$(_ref_hash_excluding "$TMPD/m.html" STORY-05)" ]
  [ "$(oversight_content_hash_excluding_stories "$TMPD/m.html" STORY-05 STORY-054)" = "$(_ref_hash_excluding "$TMPD/m.html" STORY-05 STORY-054)" ]
  # And the divergence itself is preserved rather than accidentally unified.
  [ "$(oversight_content_hash_excluding_stories "$TMPD/m.html")" != "$(oversight_content_hash "$TMPD/m.html")" ]
}

# Golden hashes are pinned over FIXTURES, never over live artefacts. Pinning to
# the corpus would redden this suite on every later legitimate artefact edit —
# ADR-052's refactor-blocking failure mode. Their job is to catch the frozen
# reference itself rotting, which the equivalence cases above cannot.
@test "extraction: pinned golden hashes over a canonical fixture" {
  printf -- '---\nstatus: draft\nhuman-oversight: confirmed\n---\n\n# STORY-900: canonical\n\n**Reported**: 2026-07-30\n\n- [ ] a criterion\n' \
    > "$TMPD/golden.md"
  [ "$(oversight_content_hash "$TMPD/golden.md")" = "1a18f2501f7092b64316a1566795e64860f90893c2b4d0d36cd9a783ada21414" ]
}

@test "extraction: the excluded-key accessor agrees with the operative pattern both ways" {
  local keys; keys="$(oversight_excluded_keys)"
  [ -n "$keys" ]
  # Every accessor key appears as an alternation branch in the operative filter.
  for k in $keys; do
    grep -qF -- "$k" "$LIB" || { echo "accessor key '$k' absent from the lib pattern"; false; }
  done
  # And every branch in the operative pattern appears in the accessor — the
  # direction that catches a key ADDED to the regex but not to the accessor,
  # which would leave the corpus lint blind to it.
  local branch
  for branch in $(grep -oE '\^\(([a-z-]+\|)+[a-z-]+\):' "$LIB" | head -1 | tr -d '^():' | tr '|' ' '); do
    printf '%s\n' "$keys" | grep -qx -- "$branch" || {
      echo "pattern branch '$branch' missing from oversight_excluded_keys()"; false
    }
  done
}
