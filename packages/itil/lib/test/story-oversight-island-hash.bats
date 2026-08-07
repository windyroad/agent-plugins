#!/usr/bin/env bats

# Behavioural test for the ratification fingerprint over a story map.
#
# Two decisions shape what this asserts:
#
# ADR-102 scoped the hash to the map's data island rather than the whole file,
# so restyling the shared template cannot revoke a human approval.
#
# ADR-103 narrowed it further, to SUBSTANCE only — the map's identity and prose,
# its traces, and its backbone. Releases and the cards in them are scheduling: a
# human approves a journey and its steps, not the order work is drawn in. That
# narrowing is what retires the ADR-101 carve-out, which existed solely because
# capturing a story onto its map used to drift the map's own fingerprint.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-103 (a release row is the RFC; the map is the approval surface)
# @adr ADR-090 (drift-invalidated human-oversight marker)
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
      # Pretty-printed, one key per line — what JSON.stringify(d, null, 2) emits.
      cat <<'JSON' | _island
{
  "storyMapId": "STORY-MAP-904",
  "title": "Fixture",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "live", "name": "Existing" } ],
  "tasks": []
}
JSON
      printf '</body>\n</html>\n'
    } > "$MAP"
  }
}

@test "a presentation-only change leaves the map's fingerprint stable" {
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  _write_map "#222222"
  after="$(oversight_content_hash "$MAP")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}

@test "an artefact with no data island still hashes whole-file" {
  # Stories are .md and pre-ADR-102 maps have no island — neither must change.
  local story="$TMP/STORY-904-fixture.md"
  printf -- '---\nstatus: draft\n---\n\n# STORY-904\n\nBody.\n' > "$story"
  local before after
  before="$(oversight_content_hash "$story")"
  printf -- '---\nstatus: draft\n---\n\n# STORY-904\n\nBody changed.\n' > "$story"
  after="$(oversight_content_hash "$story")"
  [ -n "$before" ]
  [ "$before" != "$after" ]
}

@test "adding a row does not reopen a map's ratification" {
  # Drawing a release is scheduling, not substance.
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PYEOF'
import sys, pathlib, json
p = pathlib.Path(sys.argv[1]); h = p.read_text()
O = '<script id="story-map-data" type="application/json">'
s = h.index(O) + len(O); e = h.index('</script>', s)
d = json.loads(h[s:e].replace('\\u003c', '<'))
d.setdefault("releases", []).append({"id": "r9", "name": "Later", "badge": "R2"})
p.write_text(h[:s] + "\n" + json.dumps(d, indent=2) + "\n  " + h[e:])
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}

@test "adding a story to a row does not reopen a map's ratification" {
  # The exact drift ADR-101's carve-out was invented to work around.
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PYEOF'
import sys, pathlib, json
p = pathlib.Path(sys.argv[1]); h = p.read_text()
O = '<script id="story-map-data" type="application/json">'
s = h.index(O) + len(O); e = h.index('</script>', s)
d = json.loads(h[s:e].replace('\\u003c', '<'))
d.setdefault("tasks", []).append(
    {"activity": "a", "release": "live", "title": "New card", "storyId": "STORY-970"})
p.write_text(h[:s] + "\n" + json.dumps(d, indent=2) + "\n  " + h[e:])
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ "$before" = "$after" ]
}

@test "adding an activity column DOES reopen ratification" {
  # A new column is a new step in the journey — the human's call.
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PYEOF'
import sys, pathlib, json
p = pathlib.Path(sys.argv[1]); h = p.read_text()
O = '<script id="story-map-data" type="application/json">'
s = h.index(O) + len(O); e = h.index('</script>', s)
d = json.loads(h[s:e].replace('\\u003c', '<'))
d["backbone"].append({"id": "z", "title": "Z. New step"})
p.write_text(h[:s] + "\n" + json.dumps(d, indent=2) + "\n  " + h[e:])
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ "$before" != "$after" ]
}

@test "changing the map's own prose DOES reopen ratification" {
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PYEOF'
import sys, pathlib, json
p = pathlib.Path(sys.argv[1]); h = p.read_text()
O = '<script id="story-map-data" type="application/json">'
s = h.index(O) + len(O); e = h.index('</script>', s)
d = json.loads(h[s:e].replace('\\u003c', '<'))
d["title"] = "A different journey entirely"
p.write_text(h[:s] + "\n" + json.dumps(d, indent=2) + "\n  " + h[e:])
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ "$before" != "$after" ]
}

@test "writing the ratification marker into the island does not change the hash" {
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" "$before" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
t = t.replace('"storyMapId": "STORY-MAP-904"',
              '"humanOversight": "confirmed",\n  "oversightHash": "%s",\n'
              '  "storyMapId": "STORY-MAP-904"' % sys.argv[2])
p.write_text(t)
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ "$before" = "$after" ]
}

@test "the island's lifecycle status is excluded like its meta twin" {
  _write_map "#111111"
  local before after
  before="$(oversight_content_hash "$MAP")"
  python3 - "$MAP" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(t.replace('"storyMapId"', '"status": "accepted",\n  "storyMapId"'))
PYEOF
  after="$(oversight_content_hash "$MAP")"
  [ "$before" = "$after" ]
}

@test "a single-line island does not over-capture to a later closing tag" {
  # A sed range never tests its end address on the start line, so a compact
  # one-line island would swallow everything up to the NEXT </script> or EOF.
  local one="$TMP/oneline.html"
  {
    printf '<!DOCTYPE html>\n<body>\n'
    printf '<script id="story-map-data" type="application/json">{"storyMapId":"STORY-MAP-906","title":"T","backbone":[],"releases":[]}</script>\n'
    printf '<p>presentation that must NOT be hashed</p>\n'
    printf '<script>var later = 1;</script>\n'
    printf '</body>\n</html>\n'
  } > "$one"
  local before after
  before="$(oversight_content_hash "$one")"
  python3 - "$one" <<'PYEOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(t.replace("presentation that must NOT be hashed", "completely different"))
PYEOF
  after="$(oversight_content_hash "$one")"
  [ -n "$before" ]
  [ "$before" = "$after" ]
}
