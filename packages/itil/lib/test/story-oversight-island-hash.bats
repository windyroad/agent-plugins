#!/usr/bin/env bats

# Behavioural test for the ADR-102 amendment to ADR-090: a story map's
# ratification fingerprint is taken over its DATA ISLAND, not the whole file.
#
# Why this matters. Under ADR-090 the oversight marker is drift-invalidated
# against content. Under ADR-102 the rendered grid, the <style> block and the
# <meta> block are all generated from the island — so if the fingerprint covered
# the whole file, any template change would regenerate every map, drift every
# stored hash, and silently revoke human ratification across the corpus. That
# then blocks RFCs through check-rfc-stories-ratified. A presentation change
# must never revoke a substance approval.
#
# Stories (.md) and any map without an island keep whole-file hashing, so this
# is additive rather than a change to the story leg.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-090 (drift-invalidated human-oversight marker)
# @adr ADR-101 (AFK-accept carve-out — story-excluding map hash)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  # shellcheck source=/dev/null
  source "$REPO_ROOT/packages/itil/lib/story-oversight.sh"
  TMP="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP"
  MAP="$TMP/STORY-MAP-904-fixture.html"

  _island() {
    printf '<script id="story-map-data" type="application/json">\n'
    cat
    printf '\n</script>\n'
  }

  _write_map() {
    local styling="$1"
    {
      printf '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
      printf '<meta name="story-map-id" content="STORY-MAP-904">\n'
      printf '<meta name="human-oversight" content="unconfirmed">\n'
      printf '<style>body { color: %s; }</style>\n' "$styling"
      printf '</head>\n<body>\n'
      printf '<table class="map"><tr><td>rendered grid for %s</td></tr></table>\n' "$styling"
      cat <<'JSON' | _island
{ "storyMapId": "STORY-MAP-904", "title": "Fixture", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "live", "name": "Existing" } ] }
JSON
      printf '</body>\n</html>\n'
    } > "$MAP"
  }
}

@test "a presentation-only change leaves the map's fingerprint stable" {
  # This is the property that stops a restyle revoking every ratification.
  _write_map "#111111"
  local before
  before="$(oversight_content_hash "$MAP")"
  _write_map "#222222"
  local after
  after="$(oversight_content_hash "$MAP")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}

@test "a change to the map's data does drift the fingerprint" {
  # The marker must stay load-bearing for substance edits.
  _write_map "#111111"
  local before
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PY'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); t=p.read_text()
p.write_text(t.replace('"title": "Fixture"', '"title": "Fixture, amended"'))
PY
  local after
  after="$(oversight_content_hash "$MAP")"
  [ "$before" != "$after" ]
}

@test "an artefact with no data island still hashes whole-file" {
  # Stories are .md and legacy maps predate the island — neither must change.
  local story="$TMP/STORY-904-fixture.md"
  printf -- '---\nstatus: draft\n---\n\n# STORY-904\n\nBody.\n' > "$story"
  local before
  before="$(oversight_content_hash "$story")"
  printf -- '---\nstatus: draft\n---\n\n# STORY-904\n\nBody changed.\n' > "$story"
  local after
  after="$(oversight_content_hash "$story")"
  [ -n "$before" ]
  [ "$before" != "$after" ]
}

@test "excluding a story still works when the hash is scoped to the island" {
  # The ADR-101 carve-out excludes a story's CARD from the map hash, so that
  # capturing a story onto its map does not re-open the map's ratification.
  # In the rendered grid a card is `data-story-id="X"`; inside the island the
  # same story is a task entry with "storyId": "X". Island-scoping the hash
  # would silently no-op the exclusion if only the rendered form were matched —
  # which would make the carve-out unsatisfiable for every ADR-102 map.
  {
    printf '<!DOCTYPE html>\n<body>\n'
    cat <<'JSON' | _island
{
  "storyMapId": "STORY-MAP-905",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "live", "name": "Existing" } ],
  "tasks": [
    { "activity": "a", "release": "live", "title": "Kept", "storyId": "STORY-940" },
    { "activity": "a", "release": "live", "title": "Excluded", "storyId": "STORY-941" }
  ]
}
JSON
    printf '</body>\n</html>\n'
  } > "$MAP"

  local with_all without_941
  with_all="$(oversight_content_hash "$MAP")"
  without_941="$(oversight_content_hash_excluding_stories "$MAP" "STORY-941")"
  [ -n "$with_all" ]
  # Excluding a story that IS present must change the hash — otherwise the
  # exclusion did nothing and the carve-out is inert.
  [ "$with_all" != "$without_941" ]

  # And excluding a story that is absent must be a no-op relative to excluding
  # nothing, so the anchor is exact rather than a loose substring.
  local none absent
  none="$(oversight_content_hash_excluding_stories "$MAP")"
  absent="$(oversight_content_hash_excluding_stories "$MAP" "STORY-999")"
  [ "$none" = "$absent" ]
}

@test "the story-excluding map hash also scopes to the island" {
  # ADR-101's map leg must ride on the same basis, or a restyle breaks
  # AFK-accept eligibility for every map.
  _write_map "#111111"
  local before
  before="$(oversight_content_hash_excluding_stories "$MAP" "STORY-950")"
  _write_map "#333333"
  local after
  after="$(oversight_content_hash_excluding_stories "$MAP" "STORY-950")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}

@test "a single-line island does not over-capture to a later closing tag" {
  # Regression guard: a sed range never tests its end address on the start line,
  # so a compact one-line island would swallow everything up to the NEXT
  # </script> or EOF — silently widening the basis this scoping exists to narrow.
  local one="$TMP/oneline.html"
  {
    printf '<!DOCTYPE html>\n<body>\n'
    printf '<script id="story-map-data" type="application/json">{"storyMapId":"STORY-MAP-906"}</script>\n'
    printf '<p>presentation that must NOT be hashed</p>\n'
    printf '<script>var later = 1;</script>\n'
    printf '</body>\n</html>\n'
  } > "$one"

  local before after
  before="$(oversight_content_hash "$one")"
  # Change only the out-of-island presentation. The fingerprint must not move.
  python3 - "$one" <<'PYEOF'
import sys,pathlib
p=pathlib.Path(sys.argv[1]); t=p.read_text()
p.write_text(t.replace("presentation that must NOT be hashed","completely different presentation"))
PYEOF
  after="$(oversight_content_hash "$one")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}
