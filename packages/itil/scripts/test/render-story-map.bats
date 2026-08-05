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
#   filters whole lines; a multi-line card breaks the ADR-101 carve-out)
# - the <meta> trace block survives, including human-oversight/oversight-hash
# - no inline style="" on data-bearing elements (ADR-060 prohibition, retained)
# - re-rendering an unchanged source is byte-identical (idempotence)
# - regression guard: the old stacked shape is never emitted
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-060 (Phase 2 HTML encoding, amended by ADR-102)
# @adr ADR-101 (AFK-accept carve-out — single-line card constraint)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  RENDER="$REPO_ROOT/packages/itil/scripts/render-story-map.mjs"
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
  run grep -c '<th class="act" scope="col"' "$OUT"
  [ "$output" -eq 3 ]
}

@test "renders release slices as scope=row row headers" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<th class="slice" scope="row"' "$OUT"
  [ "$output" -eq 2 ]
}

@test "emits a grid: cell count equals activities times releases" {
  # THE load-bearing assertion. The old stacked skeleton would fail this.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -oc '<td class="cell' "$OUT"
  [ "$output" -eq 6 ]
}

@test "places a task in its declared cell and nowhere else" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  # Count the rendered card, not the bare id — the id also appears in the data
  # island, which is the map's own source and legitimately mentions it.
  run grep -c 'data-story-id="STORY-901"' "$OUT"
  [ "$output" -eq 1 ]
  # The row carrying the Live release must be the one holding STORY-901.
  run node -e '
    const h=require("fs").readFileSync(process.argv[1],"utf8");
    const rows=h.split("<tr").filter(r=>r.includes("scope=\"row\""));
    const live=rows.find(r=>r.includes(">Live<")||r.includes("Live<"));
    process.exit(live && live.includes("STORY-901") ? 0 : 1);
  ' "$OUT"
  [ "$status" -eq 0 ]
}

@test "renders an activity-release pair with no tasks as an empty cell" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'class="cell empty"' "$OUT"
  [ "$output" -eq 4 ]
}

@test "emits each story-bearing card on a single line" {
  # story-oversight.sh filters whole lines; a multi-line card silently breaks
  # the ADR-101 AFK-accept carve-out.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'data-story-id="STORY-901"' "$OUT"
  [ "$output" -eq 1 ]
  # The whole card — title through closing tag — must sit on that one line.
  run node -e '
    const fs=require("fs");
    const line=fs.readFileSync(process.argv[1],"utf8").split("\n")
      .find(l=>l.includes("data-story-id=\"STORY-901\""));
    if(!line) process.exit(1);
    process.exit(line.includes("A score is taken") && line.trimEnd().endsWith("</li>") ? 0 : 1);
  ' "$OUT"
  [ "$status" -eq 0 ]
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
  run grep -c '<th class="act" scope="col"' "$OUT"
  [ "$output" -eq 3 ]
  run grep -oc '<td class="cell' "$OUT"
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
  run grep -c '<th class="slice" scope="row"' "$OUT"
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
  run grep -c '<th class="slice" scope="row"' "$OUT"
  [ "$output" -eq 3 ]
  # The added band carries no tasks, so it renders as ONE spanning cell with a
  # visually-hidden statement rather than three silent empties.
  run grep -c '<td class="cell empty" colspan="3">' "$OUT"
  [ "$output" -eq 1 ]
  run grep -c 'No stories in this release band' "$OUT"
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
  # Exactly one closing script tag: the island's own. Two would mean the title
  # broke out and truncated the document.
  run grep -oc '</scr'"ipt>" "$nasty"
  [ "$output" -eq 1 ]
  run grep -c '</html>' "$nasty"
  [ "$output" -eq 1 ]
  # Round-trips: still parseable and still a grid after a second render.
  run node "$RENDER" "$nasty"
  [ "$status" -eq 0 ]
  run grep -c '<th class="act" scope="col"' "$nasty"
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
  run grep -c 'class="act" scope="col"' "$work/m.html"
  [ "$output" -eq 2 ]
  run grep -c 'data-story-id="STORY-001"' "$work/m.html"
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
  run grep -c 'No stories in this release band' "$OUT"
  [ "$output" -eq 0 ]
}

@test "each release band gets its own badge class" {
  # Regression: badge class was keyed off list position, so any two-band map
  # rendered both bands in the same colour and glyph.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c 'class="badge b-live"' "$OUT"
  [ "$output" -ge 1 ]
  run grep -c 'class="badge b-next"' "$OUT"
  [ "$output" -ge 1 ]
}

@test "the badge glyph is real markup and hidden from assistive tech" {
  # Not CSS generated content: under forced-colors the badge backgrounds all
  # collapse to Canvas and the glyph is the only remaining differentiator.
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<span class="b-glyph" aria-hidden="true">' "$OUT"
  [ "$output" -ge 2 ]
}

@test "emits a main landmark so page content is not outside every landmark" {
  run node "$RENDER" "$OUT"
  [ "$status" -eq 0 ]
  run grep -c '<main>' "$OUT"
  [ "$output" -eq 1 ]
}
