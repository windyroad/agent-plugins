#!/usr/bin/env bats

# Behavioural test for packages/itil/scripts/render-story-map.mjs — the
# ADR-102 JSON-to-HTML story-map renderer. Runs the renderer against fixture
# JSON and asserts on the emitted HTML — NOT on SKILL.md prose (ADR-052 /
# P081 forbid structural tests on shipped prose).
#
# The defect this guards: the previously shipped skeleton emitted a vertical
# stack of <section class="backbone"> blocks with one heading each — no
# columns, no release dimension, no cells. All 13 corpus maps inherited it.
# A naive "output contains a <table>" assertion would NOT have caught it, so
# the load-bearing assertion here is CELL COUNT == activities x releases:
# that is what distinguishes a grid from a stack.
#
# Coverage:
# - backbone activities render as <th class="act" scope="col"> columns
# - release slices render as <th class="slice" scope="row"> rows
# - cell count equals activities x releases (grid, not stack)
# - a task renders in its declared cell and nowhere else
# - an activity/release pair with no tasks renders class="cell empty"
# - story-bearing cards emit data-story-id on a SINGLE line (story-oversight.sh
#   filtered whole lines; since ADR-103 cards are outside the basis entirely,
#   so this is kept for diff readability rather than hash correctness)
# - the <meta> trace block survives, including human-oversight/oversight-hash
# - no inline style="" on data-bearing elements (ADR-060 prohibition, retained)
# - re-rendering an unchanged source is byte-identical (idempotence)
# - regression guard: the old stacked shape is never emitted
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-060 (Phase 2 HTML encoding, amended by ADR-102)
# @adr ADR-103 (single-line cards — a readability convention since ADR-101 was retired)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  RENDER="$REPO_ROOT/packages/itil/scripts/render-story-map.mjs"
  IN_DOM="$REPO_ROOT/packages/itil/scripts/test/lib/render-in-dom.mjs"

  # The grid is rendered into the file, so it can be asserted either way. A
  # parsed DOM is still the right instrument for header association, cell count
  # and card placement — a grep cannot tell a `scope` from a substring. Nothing
  # is executed: see scripts/test/lib/render-in-dom.mjs.
  dom() { node "$IN_DOM" "$1" > "$TMP/dom.html"; printf '%s' "$TMP/dom.html"; }
  # jsdom serialises the whole table onto very few lines, so `grep -c` (which
  # counts matching LINES) under-reports. Count occurrences instead.
  domcount() { node "$IN_DOM" "$1" | grep -o "$2" | wc -l | tr -d ' '; }
  TMP="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP"

  OUT="$TMP/STORY-MAP-901-fixture.html"

  # A map is created by writing ONLY the data island and rendering it.
  # 3 activities x 2 releases = 6 cells. Two cells carry tasks; four are empty.
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-901",
  "title": "Fixture journey",
  "status": "draft",
  "persona": "developer",
  "reported": "2026-08-05",
  "decisionMakers": "Tom Howard",
  "humanOversight": "unconfirmed",
  "traces": {
    "jtbd": ["JTBD-901"]
  },
  "backbone": [
    { "id": "decide",  "title": "Decide it is ready", "note": "JTBD-901" },
    { "id": "assess",  "title": "Get it assessed",    "note": "" },
    { "id": "release", "title": "Release it",         "note": "" }
  ],
  "releases": [
    { "id": "live", "name": "Existing", "note": "shipped" },
    { "id": "r1",   "name": "Now",      "rfc": "RFC-901", "note": "being built" }
  ],
  "tasks": [
    {
      "activity": "assess",
      "release": "live",
      "title": "A score is taken before work leaves the machine",
      "storyId": "STORY-901",
      "jtbd": "JTBD-901",
      "ref": "STORY-901, P901"
    },
    {
      "activity": "release",
      "release": "r1",
      "title": "The release reports its own outcome",
      "storyId": "STORY-902",
      "jtbd": "JTBD-901",
      "ref": "STORY-902, P901"
    }
  ]
}
JSON
    printf '</script>\n'
  } > "$OUT"
}

@test "renders backbone activities as scope=col column headers" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<th class="act" scope="col"'
  [ "$output" -eq 3 ]
}

@test "renders release slices as scope=row row headers" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<th class="slice" scope="row"'
  [ "$output" -eq 2 ]
}

@test "emits a grid: cell count equals activities times releases" {
  # THE load-bearing assertion. The old stacked skeleton would fail this.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<td class="cell'
  [ "$output" -eq 6 ]
}

@test "places a task in its declared cell and nowhere else" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  # Count the rendered card, not the bare id — the id also appears in the data
  # island, which is the map's own source and legitimately mentions it.
  run domcount "$OUT" 'data-story-id="STORY-901"'
  [ "$output" -eq 1 ]
  # The row carrying the Live release must be the one holding STORY-901.
  run node -e '
    const h=require("fs").readFileSync(process.argv[1],"utf8");
    const rows=h.split("<tr").map(r=>r.split("</tr>")[0]).filter(r=>r.includes("scope=\"row\""));
    const live=rows.find(r=>r.includes("s-name\">Existing"));
    process.exit(live && live.includes("STORY-901") ? 0 : 1);
  ' "$(dom "$OUT")"
  [ "$status" -eq 0 ]
}

@test "renders an activity-release pair with no tasks as an empty cell" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" 'class="cell empty"'
  [ "$output" -eq 4 ]
  run domcount "$OUT" 'class="cell empty"><span class="vh">No stories for'
  [ "$output" -eq 4 ]
}

@test "each story's id sits on its own line in the island" {
  # Kept for diff readability (the ADR-101 whole-line filter that made it
  # load-bearing is retired — ADR-103). Cards are built in the
  # browser now, so what it must be able to drop is the island's storyId line —
  # which the pretty-printed serialisation guarantees, one key per line.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run bash -c "grep -c '\"storyId\": \"STORY-901\"' '$OUT'"
  [ "$output" -eq 1 ]
  # and that line carries only the key, so dropping it drops nothing else
  run bash -c "grep '\"storyId\": \"STORY-901\"' '$OUT' | tr -d ' ' "
  [ "$output" = '"storyId":"STORY-901",' ]
}

@test "preserves the meta trace block including oversight markers" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  for m in story-map-id status persona problems jtbd reported decision-makers human-oversight; do
    run grep -c "<meta name=\"$m\"" "$OUT"
    [ "$output" -ge 1 ]
  done
  # And no `adrs`: a map carries no decision trace (ADR-106). Asserted, not
  # left to a comment — absence is the whole claim.
  run bash -c "grep -c '<meta name=\"adrs\"' '$OUT' || true"
  [ "$output" -eq 0 ]
}

@test "emits no inline style attribute on data-bearing elements" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'data-story-id="[^"]*"[^>]*style="' "$OUT"
  [ "$output" -eq 0 ]
  run grep -c '<th class="slice"[^>]*style="' "$OUT"
  [ "$output" -eq 0 ]
}

@test "re-rendering an unchanged source is byte-identical" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  cp "$OUT" "$TMP/first.html"
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run diff -q "$TMP/first.html" "$OUT"
  [ "$status" -eq 0 ]
}

@test "never emits the old stacked shape" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<section class="backbone"' "$OUT"
  [ "$output" -eq 0 ]
  run grep -c 'data-rib=' "$OUT"
  [ "$output" -eq 0 ]
}

@test "a rendered map carries its own data, so there is no second file to diverge from" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<script id="story-map-data" type="application/json">' "$OUT"
  [ "$output" -eq 1 ]
  # The island must survive a render unchanged — it is the map's own source.
  run node -e '
    const fs=require("fs");
    const open=`<script id="story-map-data" type="application/json">`;
    const read=p=>{const h=fs.readFileSync(p,"utf8");const s=h.indexOf(open)+open.length,
      e=h.indexOf("</scr"+"ipt>",s);return h.slice(s,e).replace(/\u003c/g,"<");};
    const before=read(process.argv[1]);
    process.exit(JSON.parse(before).storyMapId==="STORY-MAP-901"?0:1);
  ' "$OUT"
  [ "$status" -eq 0 ]
}

@test "a file containing only the data island renders into a full map" {
  # This IS the creation path — there is no separate seed file or bootstrap mode.
  # $OUT is written by setup() as nothing but the island.
  run grep -c '<!DOCTYPE html>' "$OUT"
  [ "$output" -eq 0 ]
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<!DOCTYPE html>' "$OUT"
  [ "$output" -eq 1 ]
  run domcount "$OUT" '<th class="act" scope="col"'
  [ "$output" -eq 3 ]
  run domcount "$OUT" '<td class="cell'
  [ "$output" -eq 6 ]
}

@test "re-rendering in place is idempotent" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  cp "$OUT" "$TMP/pass1.html"
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run diff -q "$TMP/pass1.html" "$OUT"
  [ "$status" -eq 0 ]
}

@test "editing the data island changes the rendered grid" {
  # This is the property the single-file shape buys: the data IS the map, so
  # there is no way to edit one and leave the other stale.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<th class="slice" scope="row"'
  [ "$output" -eq 2 ]
  node -e '
    const fs=require("fs");const p=process.argv[1];
    let h=fs.readFileSync(p,"utf8");
    const open=`<script id="story-map-data" type="application/json">`;
    const s=h.indexOf(open)+open.length, e=h.indexOf("</scr"+"ipt>", s);
    const d=JSON.parse(h.slice(s,e).replace(/\\u003c/g,"<"));
    d.releases.push({id:"r2",name:"Later",badge:"R2",note:"deferred"});
    fs.writeFileSync(p, h.slice(0,s)+"\n"+JSON.stringify(d,null,2).replace(/</g,"\\u003c")+"\n  "+h.slice(e));
  ' "$OUT"
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<th class="slice" scope="row"'
  [ "$output" -eq 3 ]
  # The added band carries no tasks, so it renders as ONE spanning cell with a
  # visually-hidden statement rather than three silent empties.
  run domcount "$OUT" 'colspan="3"'
  [ "$output" -eq 1 ]
  run domcount "$OUT" 'No stories in this release band'
  [ "$output" -eq 1 ]
}

@test "a title containing a closing script tag cannot break out of the data island" {
  # JSON escapes the angle bracket, which is what the renderer emits on write.
  # The PARSED title is a literal closing script tag; the test is that it
  # survives a round trip without terminating the block or truncating the page.
  local nasty="$TMP/nasty.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-902",
  "title": "Break \u003c/script> out",
  "backbone": [ { "id": "a", "title": "A. Step" } ],
  "releases": [ { "id": "live", "name": "Existing", "badge": "Live" } ]
}
JSON
    printf '</script>\n'
  } > "$nasty"

  run node "$RENDER" "$nasty"
  [ "$status" -eq 0 ]
  # The title must not terminate the island early. If it had, the document
  # would be truncated and the closing tags would be missing.
  run grep -c '</html>' "$nasty"
  [ "$output" -eq 1 ]
  # Count the block itself, not the string — the fallback message names it too.
  run bash -c "grep -c '<script id=\"story-map-data\"' '$nasty'"
  [ "$output" -eq 1 ]
  # Round-trips: still parseable, and still draws a grid, after a second render.
  run node "$RENDER" "$nasty"
  [ "$status" -eq 0 ]
  run domcount "$nasty" '<th class="act" scope="col"'
  [ "$output" -eq 1 ]
}

@test "fails loudly on a hand-authored island holding a raw closing script tag" {
  # A raw </script> inside the block terminates it — in the renderer and in any
  # browser. Authors must escape it as <, exactly as the renderer does.
  # Failing loudly beats rendering a silently truncated map.
  local broken="$TMP/broken.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-903", "title": "raw </script> here",\n'
    printf '  "backbone": [], "releases": [] }\n'
    printf '</script>\n'
  } > "$broken"

  run node "$RENDER" "$broken"
  [ "$status" -ne 0 ]
}
@test "refuses an HTML file that carries no data island" {
  printf '<!DOCTYPE html>\n<html><body><p>not a map</p></body></html>\n' > "$TMP/bare.html"
  run node "$RENDER" "$TMP/bare.html"
  [ "$status" -ne 0 ]
  [[ "$output" == *"story-map-data"* ]]
}

@test "template ships in the published tarball and renders from an extracted copy" {
  # Guards the P151/P153/P219/P317 class: the renderer shipped but
  # packages/itil/templates/ was absent from package.json `files`, so the
  # template never reached an adopter and the first render failed with
  # "template not found". Source-repo dogfooding cannot catch this — the
  # template resolves fine relative to the script in a source checkout.
  # This test packs, extracts, and runs from OUTSIDE the repo.
  local sb="$BATS_TEST_TMPDIR/pack"
  mkdir -p "$sb"
  ( cd "$REPO_ROOT/packages/itil" && npm pack --pack-destination "$sb" >/dev/null 2>&1 )
  local tgz
  tgz="$(ls "$sb"/*.tgz | head -1)"
  [ -n "$tgz" ]
  ( cd "$sb" && tar xzf "$tgz" )

  [ -f "$sb/package/templates/story-map.html" ]
  # The shipped entrypoint must be executable in the tarball, not merely present
  # — a non-executable shim is an inert entrypoint that fails only for adopters.
  [ -x "$sb/package/bin/wr-itil-render-story-map" ]

  local work="$sb/adopter"
  mkdir -p "$work"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-001",
  "title": "Packaging smoke test",
  "status": "draft",
  "backbone": [ { "id": "a", "title": "A. Step" }, { "id": "b", "title": "B. Step" } ],
  "releases": [ { "id": "live", "name": "Existing", "badge": "Live" } ],
  "tasks": [ { "activity": "b", "release": "live", "title": "A thing", "storyId": "STORY-001" } ]
}
JSON
    printf '</script>\n'
  } > "$work/m.html"
  run env PATH="$sb/package/bin:$PATH" bash -c "cd '$work' && wr-itil-render-story-map m.html"
  [ "$status" -eq 0 ]
  # Outside a repo the grid is drawn client-side, so the file carries the data
  # and the links, not markup. What must ship is the shell AND the shared assets
  # it points at — without them an adopter's map renders blank.
  [ -f "$sb/package/templates/story-map.css" ]
  run grep -c 'story-map.css' "$work/m.html"
  [ "$output" -eq 1 ]
  run grep -c '"storyId": "STORY-001"' "$work/m.html"
  [ "$output" -eq 1 ]
}

@test "fails cleanly on a missing source file" {
  run node "$RENDER" "$TMP/does-not-exist.json" "$OUT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"does-not-exist.json"* ]]
}

@test "a wholly empty release band states itself once, not per cell" {
  # Guards the verbosity trade-off: a screen reader in browse mode gets silence
  # from an empty <td>, but per-cell text would bury a sparse map's few cards
  # under one identical announcement per empty cell.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" 'No stories in this release band'
  [ "$output" -eq 0 ]
}

@test "a row's badge class follows its DERIVED status, not an authored field" {
  # Two regressions in one assertion. The class was once keyed off list
  # position, so any two-row map drew both rows in the same colour and glyph.
  # It was then keyed off an authored `badge` (Live/R1/R2) — which duplicated
  # the RFC identity and collided with it: two different RFCs both reading "R1"
  # is what made rows and RFCs look like different things. Under ADR-103 a row
  # IS an RFC, so the visual channel follows derived status and the authored
  # badge is gone. An island still carrying one must not resurrect it.
  # A real docs/ layout: resolveStoryStatus walks up from the map, so a map
  # sitting loose in TMP would find no stories and every row would read
  # unproposed.
  local root="$TMP/repo"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\n---\n\n# STORY-970\n' > "$root/docs/stories/done/STORY-970-x.md"
  local m="$root/docs/story-maps/draft/STORY-MAP-946-badges.html"
  {
    printf '<!DOCTYPE html>\n<body>\n'
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-946",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [
    { "id": "shipped", "name": "Shipped",  "badge": "R2", "rfc": "RFC-899" },
    { "id": "asked",   "name": "Asked for", "rfc": "RFC-900" },
    { "id": "nobody",  "name": "Nobody asked" }
  ],
  "tasks": [ { "activity": "a", "release": "shipped", "title": "one", "storyId": "STORY-970" } ]
}
JSON
    printf '\n</script>\n</body>\n</html>\n'
  } > "$m"
  run node "$RENDER" "$m"
  [ "$status" -eq 0 ]
  # Its only story is done → b-live, DESPITE the authored "R2".
  run domcount "$m" 'class="badge b-live"'
  [ "$output" -ge 1 ]
  # named by an RFC → b-next
  run domcount "$m" 'class="badge b-next"'
  [ "$output" -ge 1 ]
  # Derived state is text, not only colour and an aria-hidden glyph.
  run grep -Fq '<span class="badge b-live"><span class="b-glyph" aria-hidden="true">✓</span>Delivered: RFC-899</span>' "$m"
  [ "$status" -eq 0 ]
  run grep -Fq '<span class="badge b-next"><span class="b-glyph" aria-hidden="true">→</span>Proposed: RFC-900</span>' "$m"
  [ "$status" -eq 0 ]
  # nothing has asked for it → a DEFECT, not a third resting state. It used to
  # render b-later/"Speculative", which named the problem comfortably enough
  # that a row could sit there untraced indefinitely.
  run domcount "$m" 'class="badge b-defect"'
  [ "$output" -ge 1 ]
}

@test "the badge glyph is real markup and hidden from assistive tech" {
  # Not CSS generated content: under forced-colors the badge backgrounds all
  # collapse to Canvas and the glyph is the only remaining differentiator.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<span class="b-glyph" aria-hidden="true">'
  [ "$output" -ge 2 ]
}

@test "emits a main landmark so page content is not outside every landmark" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run domcount "$OUT" '<main>'
  [ "$output" -eq 1 ]
}

@test "a ratification marker survives a re-render" {
  # The bug this guards: mark-story-oversight-confirmed wrote the marker into
  # the <meta> block, but under ADR-102 <meta> is GENERATED from the data
  # island. The next render regenerated it from an island that still said
  # unconfirmed, silently destroying a human ratification.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run env CLAUDE_SESSION_ID=test-session "$REPO_ROOT/packages/itil/scripts/mark-story-oversight-confirmed.sh" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<meta name="human-oversight" content="confirmed">' "$OUT"
  [ "$output" -eq 1 ]

  # Re-render. The marker must still be there.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<meta name="human-oversight" content="confirmed">' "$OUT"
  [ "$output" -eq 1 ]
  run grep -c '<meta name="oversight-hash"' "$OUT"
  [ "$output" -eq 1 ]
}

@test "a stored ratification hash validates against a fresh one" {
  # The subtle failure this guards: appending the marker as the LAST json key
  # gives the previously-last key a trailing comma. That is a punctuation-only
  # change on a line the marker filter does not exclude, so the stored hash
  # could never match a fresh computation and the map read as drifted forever.
  # shellcheck source=/dev/null
  source "$REPO_ROOT/packages/itil/lib/story-oversight.sh"
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run env CLAUDE_SESSION_ID=test-session "$REPO_ROOT/packages/itil/scripts/mark-story-oversight-confirmed.sh" "$OUT"
  [ "$status" -eq 0 ]
  local stored fresh
  stored="$(grep -o 'name="oversight-hash" content="[^"]*"' "$OUT" | sed 's/.*content="//;s/"//')"
  fresh="$(oversight_content_hash "$OUT")"
  [ -n "$stored" ]
  [ "$stored" = "$fresh" ]
}

@test "re-ratifying a map that already carries a marker stays valid" {
  # Guards the two-pass ordering: normalising the island can move a trailing
  # comma onto an unfiltered line, so the hash must be taken AFTER normalising,
  # not before. A map ratified twice is the case that exposes it.
  # shellcheck source=/dev/null
  source "$REPO_ROOT/packages/itil/lib/story-oversight.sh"
  local MARK="$REPO_ROOT/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run env CLAUDE_SESSION_ID=test-session "$MARK" "$OUT"
  [ "$status" -eq 0 ]
  # Second pass over an already-marked map.
  run env CLAUDE_SESSION_ID=test-session "$MARK" "$OUT"
  [ "$status" -eq 0 ]
  local stored
  stored="$(grep -o 'name="oversight-hash" content="[^"]*"' "$OUT" | sed 's/.*content="//;s/"//')"
  [ -n "$stored" ]
  [ "$stored" = "$(oversight_content_hash "$OUT")" ]
}

@test "story status is read from the story file, not stored on the card" {
  # The duplicate this removes: a card carrying storyStatus must be re-edited on
  # every story transition, which is a sync obligation, a proven drift class
  # (three of eight maps were wrong), and ratification churn — progress is not
  # substance, yet a stored status drifts the fingerprint.
  local root="$TMP/repo"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/accepted" "$root/docs/stories/done"
  printf -- '---\nstatus: accepted\n---\n# STORY-901\n' > "$root/docs/stories/accepted/STORY-901-a.md"
  printf -- '---\nstatus: done\n---\n# STORY-902\n' > "$root/docs/stories/done/STORY-902-b.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-908-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-908",
  "title": "Derived status",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "Now", "badge": "R1" } ],
  "tasks": [
    { "activity": "a", "release": "r1", "title": "One", "storyId": "STORY-901" },
    { "activity": "a", "release": "r1", "title": "Two", "storyId": "STORY-902" }
  ]
}
JSON
    printf '</script>\n'
  } > "$map"

  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  run domcount "$map" 'data-status="accepted"'
  [ "$output" -eq 1 ]
  run domcount "$map" 'data-status="done"'
  [ "$output" -eq 1 ]

  # Transition a story on disk. NO map edit. Re-render picks it up.
  rm "$root/docs/stories/accepted/STORY-901-a.md"
  printf -- '---\nstatus: in-progress\n---\n# STORY-901\n' > "$root/docs/stories/STORY-901-tmp.md"
  mkdir -p "$root/docs/stories/in-progress"
  mv "$root/docs/stories/STORY-901-tmp.md" "$root/docs/stories/in-progress/STORY-901-a.md"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  run domcount "$map" 'data-status="in-progress"'
  [ "$output" -eq 1 ]
}

@test "a card whose story cannot be resolved renders without a status" {
  # Rendering outside a repo — the published-tarball case — has no stories tree.
  # That must degrade to an absent attribute, never a crash or a stale guess.
  local lone="$TMP/lone.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-909",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "Now", "badge": "R1" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "Orphan", "storyId": "STORY-995" } ]
}
JSON
    printf '</script>\n'
  } > "$lone"
  run node "$RENDER" "$lone"
  [ "$status" -eq 0 ]
  run domcount "$lone" 'data-story-id="STORY-995"'
  [ "$output" -eq 1 ]
  run domcount "$lone" 'data-status='
  [ "$output" -eq 0 ]
}

@test "reverse-trace resolves a story through a client-rendered map" {
  # Round trip that proves the encoding change did not break the tier links:
  # before ADR-102 the map carried data-story-id in its markup; now the file
  # carries the island. update-story-references-section must find either.
  local root="$TMP/rt"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  local story="$root/docs/stories/draft/STORY-960-x.md"
  printf -- '---\nstatus: draft\n---\n\n# STORY-960: A story\n\nBody.\n' > "$story"
  local map="$root/docs/story-maps/draft/STORY-MAP-960-m.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-960",
  "title": "Round trip",
  "status": "draft",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "Now", "badge": "R1" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "T", "storyId": "STORY-960" } ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  # The script globs docs/** relative to the working directory, so it runs from
  # the fixture root the way it runs from a repo root.
  run bash -c "cd '$root' && '$REPO_ROOT/packages/itil/scripts/update-story-references-section.sh' 'docs/stories/draft/STORY-960-x.md' 'Story Maps'"
  [ "$status" -eq 0 ]
  run grep -c 'STORY-MAP-960' "$story"
  [ "$output" -ge 1 ]
}

@test "the reviewed accessibility properties are all emitted" {
  # The script's own header warns these must not be edited away, but the guard
  # set only covered about half of them. This closes the gap.
  #
  # `aria-label="Status legend"` was dropped from this set on 2026-08-07 with the
  # legend itself: it listed every row's badge, name and note, which is what the
  # grid's first column shows three lines below. A duplicate index is not an
  # accessibility feature. The glyphs need no key — each badge carries its own
  # text and the glyph is the redundant non-colour channel beside it.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  local d; d="$(dom "$OUT")"
  for needle in \
    'role="list"' \
    '<caption>' \
    'aria-label="Story map grid"' \
    'tabindex="0"' \
    'role="region"'
  do
    run bash -c "grep -c '$needle' '$d'"
    [ "$output" -ge 1 ] || { echo "missing: $needle"; return 1; }
  done
}

@test "an island that parses but carries no title leaves the static title intact" {
  # Worse than the script not running: a truthy-but-empty island would blank the
  # correct title and heading the shell already carries.
  local bare="$TMP/bare-title.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-970", "title": "Real title", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "badge": "R1" } ] }\n'
    printf '</script>\n'
  } > "$bare"
  run node "$RENDER" "$bare"
  [ "$status" -eq 0 ]
  # Strip the title/id from the island, keeping it valid JSON.
  python3 - "$bare" <<'PYEOF'
import sys,pathlib,json
p=pathlib.Path(sys.argv[1]); h=p.read_text()
O='<script id="story-map-data" type="application/json">'
s=h.index(O)+len(O); e=h.index('</script>',s)
d=json.loads(h[s:e].replace('\\u003c','<'))
d.pop('title',None); d.pop('storyMapId',None)
p.write_text(h[:s]+"\n"+json.dumps(d,indent=2).replace('<','\\u003c')+"\n  "+h[e:])
PYEOF
  run bash -c "grep -c '<h1 id=\"story-map-title\"></h1>' '$(dom "$bare")'"
  [ "$output" -eq 0 ]
  run bash -c "grep -c '<title></title>' '$(dom "$bare")'"
  [ "$output" -eq 0 ]
}

@test "traces render from the ids, and are absent when there are none" {
  # This replaced five paragraphs of hand-written `traceProse` on 2026-08-07.
  # Every one restated something already on the page or already in the island —
  # the persona is the island's own field and the lead's first sentence, the jobs
  # are glossed on the backbone columns, the problems are derived onto each row
  # so the authored copy drifted by construction, and "open questions" was a
  # changelog entry. Rendering the ids leaves no prose to keep in step.
  local notrace="$TMP/notrace.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-971", "title": "T", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N" } ] }\n'
    printf '</script>\n'
  } > "$notrace"
  run node "$RENDER" "$notrace"
  [ "$status" -eq 0 ]
  # A named landmark holding nothing is worse than no landmark.
  run grep -c 'story-map-traces' "$notrace"
  [ "$output" -eq 0 ]

  # With jobs, the ids render — and as links where they resolve.
  local withtrace="$TMP/withtrace.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-972", "title": "T", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N" } ], "traces": { "jtbd": ["JTBD-008"] } }\n'
    printf '</script>\n'
  } > "$withtrace"
  run node "$RENDER" "$withtrace"
  [ "$status" -eq 0 ]
  run grep -c 'story-map-traces' "$withtrace"
  [ "$output" -eq 1 ]
  run bash -c "grep -o 'JTBD-008' '$withtrace' | wc -l | tr -d ' '"
  [ "$output" -ge 2 ]
}

@test "the map carries no authoring instructions for its reader" {
  # The footer told the reader to edit the data block and re-render — guidance
  # for whoever maintains a map, printed on every map, telling a reader nothing
  # about the map. It belongs in the SKILL and the style guide.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'wr-itil-story-map-edit\|wr-itil-render-story-map' "$OUT"
  [ "$output" -eq 0 ]
  run grep -c '<footer' "$OUT"
  [ "$output" -eq 0 ]
}

@test "the map is readable with no script engine at all" {
  # The regression this closes: the grid was built client-side from the data
  # island, so the file itself carried no map. Open it anywhere that does not
  # run scripts — a phone's file preview, a sandboxed viewer, GitHub's HTML
  # rendering, print — and you got a fallback message instead of the map. A
  # document that needs a live script engine to be read is not a document.
  #
  # Asserted against the FILE's bytes, deliberately, not against a DOM: reading
  # it through jsdom would run whatever scripts are present and prove nothing.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]

  # The grid, the cards and the headers are all in the file as shipped.
  run bash -c "grep -o '<table class=\"map\"' '$OUT' | wc -l | tr -d ' '"
  [ "$output" -eq 1 ]
  run bash -c "grep -o 'class=\"task\"' '$OUT' | wc -l | tr -d ' '"
  [ "$output" -ge 2 ]
  run bash -c "grep -o 'scope=\"col\"' '$OUT' | wc -l | tr -d ' '"
  [ "$output" -ge 1 ]
  run bash -c "grep -o 'scope=\"row\"' '$OUT' | wc -l | tr -d ' '"
  [ "$output" -ge 1 ]

  # No executable script is left. Both remaining <script> elements are JSON
  # data islands, which a viewer that blocks scripts simply ignores.
  run bash -c "grep -o '<script[^>]*>' '$OUT' | grep -vc 'type=\"application/json\"' || true"
  [ "$output" -eq 0 ]

  # And no fallback message, because there is nothing left to fall back from.
  run grep -c 'has not been drawn' "$OUT"
  [ "$output" -eq 0 ]
}

@test "header accessible names carry word boundaries in the DOM" {
  # Without explicit text nodes the name concatenates — "LiveExistingshipped" —
  # relying on a display:block layout heuristic the accname spec does not mandate.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run bash -c "grep -o '<th class=\"slice\" scope=\"row\">.*</th>' '$(dom "$OUT")' | head -1"
  [[ "$output" == *'</span> <span class="s-name">'* ]]
}

@test "a row that closes problems is never labelled speculative" {
  # The bug: rowLabel branched only on `delivered`, so EVERY other row without an
  # RFC id fell through to "Speculative" — including rows tracing real problems.
  # STORY-MAP-003 rendered a row reading "→ Speculative … closes P160, P443",
  # contradicting itself on one line.
  local root="$TMP/repo"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  printf -- '---\nstatus: draft\nproblems: [P160]\n---\n\n# STORY-901\n' > "$root/docs/stories/draft/STORY-901-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-947-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-947",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "In flight" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "one", "storyId": "STORY-901" } ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local d; d="$(dom "$map")"
  # It closes P160, so it is proposed — not speculative.
  run bash -c "grep -c 'Speculative' '$d' || true"
  [ "$output" -eq 0 ]
  run bash -c "grep -c 'P160' '$d'"
  [ "$output" -ge 1 ]
}

@test "a row tracing nothing renders as a defect, not as a state" {
  # A story not linked to a problem is something to fix — document the problem
  # or link an existing one. Rendering it as a tidy third status normalises it.
  local root="$TMP/repo2"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  printf -- '---\nstatus: draft\n---\n\n# STORY-902\n' > "$root/docs/stories/draft/STORY-902-b.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-948-y.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-948",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "Nothing asked for this" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "one", "storyId": "STORY-902" } ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local d; d="$(dom "$map")"
  # Flagged as needing a trace, and visually distinct from a healthy row.
  run bash -c "grep -c 'b-defect' '$d'"
  [ "$output" -ge 1 ]
  run bash -c "grep -ci 'untraced' '$d'"
  [ "$output" -ge 1 ]
}

@test "a card with no story is refused, not rendered" {
  # "If the story doesn't exist, then it shouldn't even be in the map."
  # A card is a story's position in a journey. Without a story it is a sketch
  # wearing map vocabulary — which is what nine rows across maps 012 and 013
  # were, all of them rendering as a tidy status rather than as the defect they
  # are. The renderer refuses rather than drawing them.
  local root="$TMP/nostory"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"

  local map="$root/docs/story-maps/draft/STORY-MAP-949-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-949",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "R" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "a card with no story behind it" } ]
}
JSON
    printf '</script>\n'
  } > "$map"

  run node "$RENDER" "$map"
  [ "$status" -ne 0 ]
  # The message must name the card and both remedies, or the agent cannot act.
  echo "$output" | grep -q 'a card with no story behind it'
  echo "$output" | grep -qi 'capture'
  echo "$output" | grep -qi 'remove'
}

@test "a card naming a story that does not exist is refused too" {
  # A dangling storyId is the same defect wearing a reference.
  local root="$TMP/dangling"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  printf -- '---\nstatus: draft\nproblems: [P160]\n---\n\n# STORY-901\n' > "$root/docs/stories/draft/STORY-901-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-950-y.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-950",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "R" } ],
  "tasks": [
    { "activity": "a", "release": "r1", "title": "real", "storyId": "STORY-901" },
    { "activity": "a", "release": "r1", "title": "phantom", "storyId": "STORY-999" }
  ]
}
JSON
    printf '</script>\n'
  } > "$map"

  run node "$RENDER" "$map"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'STORY-999'
}

@test "outside a repository the rule does not fire" {
  # ADR-104: a map rendered from the published package resolves no stories at
  # all. Enforcing there would refuse every valid map for lacking a corpus that
  # was never present. The rule is about the map, not about the reader.
  local loose="$TMP/loose.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-951", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "R" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "x", "storyId": "STORY-901" } ] }\n'
    printf '</script>\n'
  } > "$loose"
  run node "$RENDER" "$loose"
  [ "$status" -eq 0 ]
}

@test "an authored problems or rfcs list in the island is ignored, not merged" {
  # A pre-migration island must not outvote the corpus (ADR-104). Asserted as
  # EQUALITY, not as absence of the authored value: with an empty derived union
  # "does not contain P999" passes for the wrong reason.
  local root="$TMP/ignore"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\nproblems: [P900]\n---\n# STORY-903\n' \
    > "$root/docs/stories/done/STORY-903-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-980-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-980",
  "title": "Authored loses",
  "traces": { "jtbd": ["JTBD-900"], "problems": ["P999"], "rfcs": ["RFC-999"] },
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "Now", "rfc": "RFC-900" } ],
  "tasks": [ { "activity": "a", "release": "r1", "title": "T", "storyId": "STORY-903" } ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local got
  got="$(grep -o 'name="problems" content="[^"]*"' "$map" | sed 's/.*content="//;s/"//')"
  [ "$got" = "P900" ] || { echo "problems meta was '$got', wanted the derived union P900"; return 1; }
  got="$(grep -o 'name="rfcs" content="[^"]*"' "$map" | sed 's/.*content="//;s/"//')"
  [ "$got" = "RFC-900" ] || { echo "rfcs meta was '$got', wanted the row identity RFC-900"; return 1; }
}

@test "a row carrying no rfc contributes nothing to the rfcs meta" {
  # A row legitimately has no RFC, in two spellings: an explicit null, and no key
  # at all. Unfiltered, the join yields ",RFC-900" or ",," — and content=",,"
  # satisfies the reverse-tracers' content="[^"]+" guard, so a map with no RFCs
  # stops looking like one.
  local map="$TMP/norfc.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-981", "title": "T", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "pre", "name": "P", "rfc": null }, { "id": "bare", "name": "B" }, { "id": "r1", "name": "N", "rfc": "RFC-900" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  local got
  got="$(grep -o 'name="rfcs" content="[^"]*"' "$map" | sed 's/.*content="//;s/"//')"
  [ "$got" = "RFC-900" ] || { echo "rfcs meta was '$got' — falsy rows leaked in"; return 1; }
}

@test "an authored decision trace is inert, not merely unrendered" {
  # A map carries no decision trace (ADR-106). "Unrendered" is not enough: while
  # the mentioned-scan stringified the whole traces object, an authored adrs
  # still resolved into derived.hrefs. The fixture MUST be able to resolve an
  # ADR, or this passes vacuously — resolveHref returns null with no
  # docs/decisions/ and every id looks inert whatever the scan does.
  local root="$TMP/inert"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/decisions"
  printf -- '# ADR-999: A resolvable decision\n' > "$root/docs/decisions/999-x.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-982-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-982", "title": "T", "traces": { "adrs": ["ADR-999"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  # No landmark: a named region holding nothing is worse than no region.
  run grep -c 'story-map-traces' "$map"
  [ "$output" -eq 0 ]
  # And no resolved href — this is the half that fails if the scan is widened back.
  run bash -c "grep -c 'ADR-999' '$map'"
  [ "$output" -eq 1 ] || { echo "ADR-999 appears $output times; it should survive only in the island"; return 1; }
}

@test "renaming a row's rfc does not drift the map's oversight fingerprint" {
  # Rows are scheduling, not substance (ADR-103), so they sit outside the basis.
  # This would break the moment a derived value were written back into traces
  # before the island is serialised.
  source "$REPO_ROOT/packages/itil/lib/story-oversight.sh"
  local map="$TMP/rowrename.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-983", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  local before; before="$(oversight_content_hash "$map")"
  [ -n "$before" ]

  sed -i.bak 's/RFC-900/RFC-901/' "$map" && rm -f "$map.bak"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  [ "$(oversight_content_hash "$map")" = "$before" ] \
    || { echo "renaming a row's RFC moved the fingerprint — scheduling leaked into the basis"; return 1; }
}

@test "a map is readable with no stylesheet, not just with no script engine" {
  # ADR-105 claims a map "degrades to unstyled-but-readable" when separated from
  # its shared stylesheet. It did not. The value clauses were <span>s whose only
  # separation was `.v-line { display: block }`, so with no CSS they ran together
  # as "mid-flowas a developerI want" — found by the maintainer opening a map on
  # a phone, where the relative stylesheet href resolves to nothing.
  #
  # Asserted on the text a no-CSS user agent produces: only DEFAULT-block
  # elements break the line, so this fails whenever separation is carried by the
  # stylesheet rather than by the markup.
  local root="$TMP/nocss"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\n---\n\n## User value\n\nIn order to read a map without its stylesheet, as a developer, I want the clauses to stay apart.\n' \
    > "$root/docs/stories/done/STORY-904-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-984-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-984", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "A card", "storyId": "STORY-904", "ref": "STORY-904" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local text
  text="$(node -e '
    const fs = require("fs");
    let h = fs.readFileSync(process.argv[1], "utf8");
    // What a user agent with no author stylesheet does: block-level elements
    // break the line, inline ones do not.
    h = h.replace(/<\/?(div|p|li|ul|ol|tr|td|th|table|section|article|header|footer|h[1-6]|caption)\b[^>]*>/gi, "\n");
    h = h.replace(/<[^>]+>/g, "");
    process.stdout.write(h.split("\n").map((l) => l.trim()).filter(Boolean).join("\n"));
  ' "$map")"

  # Each clause starts its own line. If separation is CSS-only they concatenate.
  echo "$text" | grep -q '^In order to read a map without its stylesheet' \
    || { echo "value clauses ran together without CSS:"; echo "$text" | head -20; return 1; }
  echo "$text" | grep -q '^as a developer' \
    || { echo "the 'as a' clause did not start its own line"; echo "$text" | head -20; return 1; }
  echo "$text" | grep -q '^I want the clauses to stay apart' \
    || { echo "the 'I want' clause did not start its own line"; echo "$text" | head -20; return 1; }
  echo "$text" | grep -q '^Traces:' \
    || { echo "the traces line did not start its own line"; echo "$text" | head -20; return 1; }
}

@test "no map in the corpus carries a decision trace, in either surface" {
  # A corpus assertion, not a fixture one. The renderer's behaviour was already
  # covered, and it stayed green while four real maps still published a
  # `Decisions:` group and an `adrs` meta — they refuse to render, so their
  # rendered halves were never regenerated. A green suite and a contradicting
  # corpus are compatible unless something looks at the corpus.
  #
  # Conjunction, deliberately: <meta> lives in <head>, so a traces-paragraph
  # assertion cannot see it, and neither clause subsumes the other.
  local maps root
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)/docs/story-maps"
  [ -d "$root" ] || skip "no story-map corpus in this checkout"
  maps="$(find "$root" -maxdepth 2 -name 'STORY-MAP-*.html' -print)"
  # Guard the search root: a glob that matches nothing asserts nothing, and
  # whether that passes is grep-implementation-dependent between here and CI.
  [ -n "$maps" ]

  local f bad=""
  while IFS= read -r f; do
    grep -q '<meta name="adrs"' "$f" && bad="$bad
  $(basename "$f") — carries an adrs meta"
    # The trace line carries the Jobs group and nothing else (ADR-106 removed
    # Decisions; the ADR-103 amendment removed RFCs, which restated the badges).
    grep -o '<strong>[A-Za-z]*:</strong>' "$f" | grep -qv '<strong>Jobs:</strong>' \
      && bad="$bad
  $(basename "$f") — carries a non-Jobs trace group"
  done <<< "$maps"
  [ -z "$bad" ] || { echo "maps publishing a decision trace:$bad"; return 1; }
}

@test "a row with no RFC is a defect unless every story in it is delivered" {
  # The exception (ADR-107) is work that shipped before the model existed, marked
  # `preRfc` on the row. Everything else without an identity is a defect — there
  # is no quiet band for work nobody has proposed. The companion test below
  # covers the half that matters most: delivery alone does not earn the
  # exception.
  local root="$TMP/norfcrule"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done" "$root/docs/stories/draft"
  printf -- '---\nstatus: done\n---\n# STORY-905\n'  > "$root/docs/stories/done/STORY-905-a.md"
  printf -- '---\nstatus: draft\n---\n# STORY-906\n' > "$root/docs/stories/draft/STORY-906-b.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-985-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-985",
  "title": "The one exception",
  "traces": { "jtbd": ["JTBD-900"] },
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [
    { "id": "shipped", "name": "Before the model", "preRfc": true },
    { "id": "open",    "name": "Not delivered, no identity" }
  ],
  "tasks": [
    { "activity": "a", "release": "shipped", "title": "Done one", "storyId": "STORY-905" },
    { "activity": "a", "release": "open",    "title": "Draft one", "storyId": "STORY-906" }
  ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local rows
  rows="$(node -e '
    const fs=require("fs"), h=fs.readFileSync(process.argv[1],"utf8");
    const O="<script id=\"story-map-status\" type=\"application/json\">";
    const i=h.indexOf(O)+O.length, j=h.indexOf("</script>", i);
    const d=JSON.parse(h.slice(i,j));
    process.stdout.write(Object.entries(d.rows).map(([k,v])=>k+"="+v).sort().join(" "));
  ' "$map")"
  [ "$rows" = "open=untraced shipped=delivered" ] \
    || { echo "row statuses were '$rows'; wanted shipped=delivered open=untraced"; return 1; }

  # And the defect is visible, not just classified.
  run bash -c "grep -c 'b-defect' '$map'"
  [ "$output" -ge 1 ]
}

@test "only a row explicitly marked pre-RFC may ship without an identity" {
  # The exception is CLOSED (ADR-107): it covers the rows holding work that
  # shipped before release rows carried RFC identities, and no new row joins it.
  # "All stories delivered" cannot be the test — every row meets that eventually,
  # which would make shipping unproposed work legitimate by finishing it. So a
  # historical row says so explicitly, and finishing a row earns nothing.
  local root="$TMP/closedexc"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\n---\n# STORY-907\n' > "$root/docs/stories/done/STORY-907-a.md"
  printf -- '---\nstatus: done\n---\n# STORY-908\n' > "$root/docs/stories/done/STORY-908-b.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-986-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-986",
  "title": "Closed exception",
  "traces": { "jtbd": ["JTBD-900"] },
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [
    { "id": "history", "name": "Before rows carried identities", "preRfc": true },
    { "id": "sneaked", "name": "Finished, but nobody proposed it" }
  ],
  "tasks": [
    { "activity": "a", "release": "history", "title": "Old one", "storyId": "STORY-907" },
    { "activity": "a", "release": "sneaked", "title": "New one", "storyId": "STORY-908" }
  ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local rows
  rows="$(node -e '
    const fs=require("fs"), h=fs.readFileSync(process.argv[1],"utf8");
    const O="<script id=\"story-map-status\" type=\"application/json\">";
    const i=h.indexOf(O)+O.length, j=h.indexOf("</script>", i);
    process.stdout.write(Object.entries(JSON.parse(h.slice(i,j)).rows)
      .map(([k,v])=>k+"="+v).sort().join(" "));
  ' "$map")"
  # Both rows are fully delivered. Only the marked one is legitimate.
  [ "$rows" = "history=delivered sneaked=untraced" ] \
    || { echo "row statuses were '$rows'; wanted history=delivered sneaked=untraced"; return 1; }
}

@test "a card shows its own lifecycle state, not only the row's" {
  # The defect this closes: every card carried a correct `data-status` and the
  # stylesheet had no rule referencing status at all, so a shipped story and one
  # nobody had started rendered identically. A row only reads delivered when
  # everything in it is done, so a single shipped story inside an in-flight row
  # was invisible — the maintainer reported the same story as live three times
  # and the map he was asked to approve looked the same every time.
  local root="$TMP/cardstatus"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done" "$root/docs/stories/in-progress" "$root/docs/stories/draft"
  printf -- '---\nstatus: done\n---\n# STORY-970\n'        > "$root/docs/stories/done/STORY-970-a.md"
  printf -- '---\nstatus: in-progress\n---\n# STORY-971\n' > "$root/docs/stories/in-progress/STORY-971-b.md"
  printf -- '---\nstatus: draft\n---\n# STORY-972\n'       > "$root/docs/stories/draft/STORY-972-c.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-987-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-987", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Shipped", "storyId": "STORY-970" }, { "activity": "a", "release": "r1", "title": "Building", "storyId": "STORY-971" }, { "activity": "a", "release": "r1", "title": "Not started", "storyId": "STORY-972" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  local d="$TMP/dom987.html"; node "$IN_DOM" "$map" > "$d"

  # Each state renders a marker carrying REAL TEXT — colour is never the sole
  # channel, and a screen reader gets the state from the accessible name.
  grep -q 'ts-done'  "$d" || { echo "no done marker"; return 1; }
  grep -q 'ts-prog'  "$d" || { echo "no in-progress marker"; return 1; }
  grep -q 'ts-draft' "$d" || { echo "no draft marker"; return 1; }
  grep -qi 'Done'    "$d" || { echo "the done marker carries no text"; return 1; }

  # Draft is present but quiet. Absence is reserved for a status that could not
  # be resolved — if draft rendered nothing, the two would be identical and this
  # very defect would be unverifiable by looking at a map.
  run bash -c "grep -o 'ts-draft' '$d' | wc -l | tr -d ' '"
  [ "$output" -eq 1 ]

  # And a card whose story does not resolve stays silent, so absence keeps
  # meaning "unresolved" rather than "draft".
  local nores="$TMP/nores.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-988", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ] }'
    printf '</script>\n'
  } > "$nores"
  run node "$RENDER" "$nores"
  [ "$status" -eq 0 ]
  run bash -c "grep -c 't-status' '$nores' || true"
  [ "$output" -eq 0 ]
}

@test "an archived story is refused among live rows, and allowed in a graveyard row" {
  # Archived means closed WITHOUT completion — scope shifted or superseded. A
  # card for one sitting among live work reads as abandoned capability: map 003
  # showed a live throttle marked Archived, because the card pointed at the
  # record of the deleted first implementation rather than at the story that
  # shipped the working one. Either it comes off the map, or it goes in a row
  # that says what it is.
  local root="$TMP/graveyard"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/archived" "$root/docs/stories/done"
  printf -- '---\nstatus: archived\n---\n# STORY-980\n' > "$root/docs/stories/archived/STORY-980-a.md"
  printf -- '---\nstatus: done\n---\n# STORY-981\n'     > "$root/docs/stories/done/STORY-981-b.md"

  # Among live rows: refused, and the message names both ways out.
  local bad="$root/docs/story-maps/draft/STORY-MAP-989-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-989", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Superseded", "storyId": "STORY-980" } ] }'
    printf '</script>\n'
  } > "$bad"
  run node "$RENDER" "$bad"
  [ "$status" -ne 0 ] || { echo "an archived story was drawn among live rows"; return 1; }
  [[ "$output" == *"STORY-980"* ]] || { echo "the refusal does not name the story"; return 1; }
  [[ "$output" == *"graveyard"* ]] || { echo "the refusal does not name the graveyard row as a way out"; return 1; }

  # In a graveyard row: allowed, and the row says what it holds.
  local ok="$root/docs/story-maps/draft/STORY-MAP-990-y.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-990", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" }, { "id": "old", "name": "Superseded along the way", "graveyard": true } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Live", "storyId": "STORY-981" }, { "activity": "a", "release": "old", "title": "Superseded", "storyId": "STORY-980" } ] }'
    printf '</script>\n'
  } > "$ok"
  run node "$RENDER" "$ok"
  [ "$status" -eq 0 ] || { echo "a graveyard row was refused: $output"; return 1; }

  local rows
  rows="$(node -e '
    const fs=require("fs"), h=fs.readFileSync(process.argv[1],"utf8");
    const O="<script id=\"story-map-status\" type=\"application/json\">";
    const i=h.indexOf(O)+O.length, j=h.indexOf("</script>", i);
    process.stdout.write(Object.entries(JSON.parse(h.slice(i,j)).rows).map(([k,v])=>k+"="+v).sort().join(" "));
  ' "$ok")"
  # A graveyard row is not delivered — nothing in it completed.
  [ "$rows" = "old=archived r1=delivered" ] \
    || { echo "row statuses were '$rows'; wanted old=archived r1=delivered"; return 1; }

  # And a live story may not hide in the graveyard. Built from scratch, NOT by
  # editing the rendered file above — the renderer pretty-prints the island, so
  # a sed against the authored one-line form matches nothing and the fixture
  # silently stays unmodified.
  local mixed="$root/docs/story-maps/draft/STORY-MAP-991-z.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-991", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "old", "name": "Superseded along the way", "graveyard": true } ], "tasks": [ { "activity": "a", "release": "old", "title": "Live", "storyId": "STORY-981" } ] }'
    printf '</script>\n'
  } > "$mixed"
  run node "$RENDER" "$mixed"
  [ "$status" -ne 0 ] || { echo "a live story was allowed in the graveyard row"; return 1; }
  [[ "$output" == *"STORY-981"* ]] || { echo "the refusal does not name the intruder"; return 1; }
}

@test "a story may span activities but not rows — it ships in one release" {
  # A story appearing in two columns is the grid working: one piece of work can
  # serve two steps of a journey. Two ROWS is a contradiction, because a row is
  # a release and a story ships once. This fired for real: repointing a card at
  # a story that already had one on the same map put it in both the pre-RFC row
  # and an RFC row, and the map was ratified before anyone noticed.
  local root="$TMP/spanrows"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\n---\n# STORY-995\n' > "$root/docs/stories/done/STORY-995-a.md"

  # Two activities, one row — allowed.
  local ok="$root/docs/story-maps/draft/STORY-MAP-995-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-995", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" }, { "id": "b", "title": "B" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "First step", "storyId": "STORY-995" }, { "activity": "b", "release": "r1", "title": "Second step", "storyId": "STORY-995" } ] }'
    printf '</script>\n'
  } > "$ok"
  run node "$RENDER" "$ok"
  [ "$status" -eq 0 ] || { echo "a story spanning two activities in one row was refused: $output"; return 1; }

  # Two rows — refused.
  local bad="$root/docs/story-maps/draft/STORY-MAP-996-y.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-996", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" }, { "id": "b", "title": "B" } ], "releases": [ { "id": "old", "name": "History", "preRfc": true }, { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "In the release", "storyId": "STORY-995" }, { "activity": "b", "release": "old", "title": "Also in history", "storyId": "STORY-995" } ] }'
    printf '</script>\n'
  } > "$bad"
  run node "$RENDER" "$bad"
  [ "$status" -ne 0 ] || { echo "a story was allowed to ship in two releases"; return 1; }
  [[ "$output" == *"STORY-995"* ]] || { echo "the refusal does not name the story"; return 1; }
}

@test "a card carries the value statement, not the prose the author put under it" {
  # The section was flattened with blank lines filtered out, so a second
  # paragraph glued itself onto the "I want" clause. On a phone STORY-052's
  # card ran to 169 words — the statement, then the evidence prose below it,
  # with no break. A story is free to explain itself under its value; the card
  # carries the statement and stops.
  local root="$TMP/valuepara"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  {
    printf -- '---\nstatus: draft\n---\n# STORY-994\n\n## User value (INVEST Valuable)\n\n'
    printf 'In order to keep the card readable, as a maintainer reading on a phone, I want the statement alone.\n\n'
    printf 'GLUEDPROSE. This paragraph explains the background and belongs off the card entirely.\n'
  } > "$root/docs/stories/draft/STORY-994-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-994-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-994", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Card", "storyId": "STORY-994" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ] || { echo "render failed: $output"; return 1; }

  grep -q 'the statement alone' "$map" || { echo "the card lost its value statement"; return 1; }
  ! grep -q 'GLUEDPROSE' "$map" || { echo "the paragraph below the value statement reached the card"; return 1; }
}

@test "a value statement the parser cannot split is refused, not quietly flattened" {
  # The fallback rendered an unsplittable statement as one undifferentiated
  # block — visually identical to a story written badly, on a map where every
  # other card showed three labelled clauses. STORY-060 hit it with "as whoever
  # picks the ticket up": correctly written, silently degraded, and the only
  # way anyone found out was reading the map on a phone.
  #
  # The renderer had already been here once. The recorded fix was to loosen the
  # pattern, which fixed fifteen stories and left the class open. Loosening
  # cannot close it; only refusing to render can, because the pattern will
  # always be narrower than the ways people write.
  local root="$TMP/rawvalue"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  {
    printf -- '---\nstatus: draft\n---\n# STORY-993\n\n## User value (INVEST Valuable)\n\n'
    printf 'This statement is not in the value-first shape at all.\n'
  } > "$root/docs/stories/draft/STORY-993-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-993-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-993", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Card", "storyId": "STORY-993" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -ne 0 ] || { echo "an unsplittable value statement rendered without complaint"; return 1; }
  [[ "$output" == *"STORY-993"* ]] || { echo "the refusal does not name the story: $output"; return 1; }
}

@test "a persona clause without an article still parses — the shape is the rule, not the wording" {
  # "as whoever picks the ticket up", "as maintainers", "as someone returning
  # to this". The house shape is value, who, want in that order; requiring the
  # who to open with a/an/the is a guess about wording that the corpus does not
  # respect.
  local root="$TMP/noarticle"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  {
    printf -- '---\nstatus: draft\n---\n# STORY-992\n\n## User value (INVEST Valuable)\n\n'
    printf 'In order to keep going, as whoever picks the ticket up, I want the evidence in hand.\n'
  } > "$root/docs/stories/draft/STORY-992-a.md"

  local map="$root/docs/story-maps/draft/STORY-MAP-992-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-992", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "rfc": "RFC-900" } ], "tasks": [ { "activity": "a", "release": "r1", "title": "Card", "storyId": "STORY-992" } ] }'
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ] || { echo "a value statement with no article on the persona was refused: $output"; return 1; }
  grep -q 'v-asa' "$map" || { echo "the persona clause did not reach its own line"; return 1; }
  grep -q 'whoever picks the ticket up' "$map" || { echo "the persona clause is missing"; return 1; }
}

@test "a map states what it is and what is being asked, before the grid" {
  # Whether a map was still a draft, and whether anyone had agreed it, lived
  # only in <meta> — which does not render. A reader opening the file got a
  # title and a grid and had to infer the rest. The corpus exercises only the
  # agreed branch, because every map in it is ratified, so the two unagreed
  # leads and the plural boundary are covered here.
  local root="$TMP/orient"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/draft"
  printf -- '---\nstatus: draft\n---\n# STORY-991\n' > "$root/docs/stories/draft/STORY-991-a.md"

  _orient_map() {  # $1 = file, $2 = extra island keys
    printf '<script id="story-map-data" type="application/json">\n' > "$1"
    printf '%s\n' "{ \"storyMapId\": \"STORY-MAP-991\", \"title\": \"T\", $2 \"traces\": { \"jtbd\": [\"JTBD-900\"] }, \"backbone\": [ { \"id\": \"a\", \"title\": \"A\" } ], \"releases\": [ { \"id\": \"r1\", \"name\": \"N\", \"rfc\": \"RFC-900\" } ], \"tasks\": [ { \"activity\": \"a\", \"release\": \"r1\", \"title\": \"Card\", \"storyId\": \"STORY-991\" } ] }" >> "$1"
    printf '</script>\n' >> "$1"
  }

  # Draft, unagreed: says so, and says what to do about it.
  local m="$root/docs/story-maps/draft/STORY-MAP-991-x.html"
  _orient_map "$m" '"status": "draft",'
  run node "$RENDER" "$m"
  [ "$status" -eq 0 ] || { echo "render failed: $output"; return 1; }
  grep -q 'Draft — not yet agreed' "$m" || { echo "a draft map does not say it is a draft"; return 1; }
  grep -q 'name the row that is wrong' "$m" || { echo "an unagreed map does not say what is being asked"; return 1; }
  # One release and one story must not read "1 releases, 1 stories".
  grep -q '1 release, 1 story,' "$m" || { echo "the singular boundary is wrong: $(grep -o '<p class="orient">[^<]*' "$m")"; return 1; }

  # Not a draft and still unagreed reads differently from a draft.
  _orient_map "$m" '"status": "proposed",'
  run node "$RENDER" "$m"
  grep -q 'Proposed — not yet agreed' "$m" || { echo "a proposed map is not distinguished from a draft"; return 1; }

  # Agreed: no ask, because there is nothing left to answer.
  _orient_map "$m" '"status": "draft", "humanOversight": "confirmed",'
  run node "$RENDER" "$m"
  grep -q '<strong>Agreed.</strong>' "$m" || { echo "a ratified map still reads as unagreed"; return 1; }
  ! grep -q 'name the row that is wrong' "$m" || { echo "a ratified map still asks to be ratified"; return 1; }
}
