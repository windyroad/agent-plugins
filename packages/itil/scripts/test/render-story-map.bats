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

  # The grid is built in the browser under ADR-102, so assertions about header
  # association, cell count and card placement must run the shared script
  # against a DOM. Asserting on the file's bytes would only check the island.
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
    "problems": ["P901"],
    "rfcs": [],
    "jtbd": ["JTBD-901"],
    "adrs": ["ADR-102"]
  },
  "lead": "A fixture map used only by the renderer's behavioural test.",
  "backbone": [
    { "id": "decide",  "title": "Decide it is ready", "note": "JTBD-901" },
    { "id": "assess",  "title": "Get it assessed",    "note": "" },
    { "id": "release", "title": "Release it",         "note": "" }
  ],
  "releases": [
    { "id": "live", "name": "Existing", "badge": "Live", "note": "shipped" },
    { "id": "r1",   "name": "Now",      "badge": "R1",   "note": "being built" }
  ],
  "tasks": [
    {
      "activity": "assess",
      "release": "live",
      "title": "A score is taken before work leaves the machine",
      "value": "Value: the assessment is not optional in practice.",
      "storyId": "STORY-901",
      "rfc": "RFC-901",
      "jtbd": "JTBD-901",
      "storyStatus": "draft",
      "ref": "STORY-901, P901"
    },
    {
      "activity": "release",
      "release": "r1",
      "title": "The release reports its own outcome",
      "value": "Value: I stop polling CI.",
      "storyId": "STORY-902",
      "rfc": "",
      "jtbd": "JTBD-901",
      "storyStatus": "draft",
      "ref": "STORY-902, P901"
    }
  ],
  "traceProse": {
    "persona": "Fixture persona prose.",
    "jobs": "Fixture jobs prose.",
    "problems": "Fixture problems prose.",
    "decisions": "Fixture decisions prose."
  }
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
  for m in story-map-id status persona problems jtbd adrs reported decision-makers human-oversight; do
    run grep -c "<meta name=\"$m\"" "$OUT"
    [ "$output" -ge 1 ]
  done
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
  [ -f "$sb/package/templates/story-map.js" ]
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
    { "id": "shipped", "name": "Shipped",  "badge": "R2" },
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
  # delivered (its only story is done) → b-live, DESPITE the authored "R2".
  run domcount "$m" 'class="badge b-live"'
  [ "$output" -ge 1 ]
  # named by an RFC → b-next
  run domcount "$m" 'class="badge b-next"'
  [ "$output" -ge 1 ]
  # nothing has asked for it → b-later
  run domcount "$m" 'class="badge b-later"'
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
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  local d; d="$(dom "$OUT")"
  for needle in \
    'role="list"' \
    '<caption>' \
    'aria-label="Story map grid"' \
    'tabindex="0"' \
    'role="region"' \
    'aria-label="Status legend"'
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

@test "the trace section stays hidden until it has content" {
  # A named landmark holding nothing, under a visible heading, is worse than no
  # landmark — and axe's empty-heading rule will not catch it.
  local notrace="$TMP/notrace.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '{ "storyMapId": "STORY-MAP-971", "title": "T", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "badge": "R1" } ] }\n'
    printf '</script>\n'
  } > "$notrace"
  run node "$RENDER" "$notrace"
  [ "$status" -eq 0 ]
  run bash -c "grep -c 'id=\"story-map-trace-section\" aria-labelledby=\"trace-h\" hidden' '$(dom "$notrace")'"
  [ "$output" -eq 1 ]
  # And it IS revealed when there is prose to show.
  run bash -c "grep -c 'hidden' '$(dom "$OUT")'"
  [ "$output" -eq 0 ]
}

@test "a map whose script never runs says so instead of looking complete" {
  # Silent total content loss was the highest-value failure to close: the page
  # kept its heading and lead, so it looked finished while 17 stories were gone.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'has not been drawn' "$OUT"
  [ "$output" -eq 1 ]
  # Once the script runs, the message is cleared.
  run bash -c "grep -c 'has not been drawn' '$(dom "$OUT")'"
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
