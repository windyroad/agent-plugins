#!/usr/bin/env bats

# Behavioural test for packages/itil/scripts/story-map-edit.mjs — the card-level
# editing surface for ADR-102 story maps.
#
# Why it exists. A map's data lives in a JSON island inside a ~500-line HTML
# file, with `<` escaped as <. Editing that with an exact-match string tool
# is fiddly enough that the agent which designed the format never once did it —
# every change during authoring went through a throwaway load-mutate-save
# script. That is the friction this command removes: an agent states the
# operation, and never opens the island.
#
# Each operation mutates the island and re-renders, so the rendered grid and the
# data can never disagree.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-095 (story-map membership enforced at capture — drives add-card)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  EDIT="$REPO_ROOT/packages/itil/scripts/story-map-edit.mjs"
  RENDER="$REPO_ROOT/packages/itil/scripts/render-story-map.mjs"
  IN_DOM="$REPO_ROOT/packages/itil/scripts/test/lib/render-in-dom.mjs"
  # The grid is drawn in the browser, so assertions about placement run the
  # shared script against a DOM. grep -c counts LINES, which under-reports on
  # jsdom's serialisation, so count occurrences.
  dom() { node "$IN_DOM" "$1" > "$TMP/dom.html"; printf '%s' "$TMP/dom.html"; }
  domcount() { node "$IN_DOM" "$1" | grep -o "$2" | wc -l | tr -d ' '; }
  TMP="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP/docs/story-maps/draft" "$TMP/docs/stories/draft"
  printf -- '---\nstatus: draft\n---\n# STORY-950\n' > "$TMP/docs/stories/draft/STORY-950-a.md"

  MAP="$TMP/docs/story-maps/draft/STORY-MAP-920-fixture.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-920",
  "title": "Fixture",
  "status": "draft",
  "backbone": [
    { "id": "notice", "title": "A. Notice" },
    { "id": "decide", "title": "B. Decide" }
  ],
  "releases": [
    { "id": "live", "name": "Existing", "badge": "Live" },
    { "id": "r1", "name": "Now", "badge": "R1" }
  ],
  "tasks": []
}
JSON
    printf '</script>\n'
  } > "$MAP"
  node "$RENDER" "$MAP"
}

@test "add-card places a story on the map without opening the island" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 \
    --title "A thing the persona can do" --value "Value: why it matters."
  [ "$status" -eq 0 ]
  run domcount "$MAP" 'data-story-id="STORY-950"'
  [ "$output" -eq 1 ]
  run domcount "$MAP" 'A thing the persona can do'
  [ "$output" -ge 1 ]
}

@test "add-card renders the card into the declared cell, not just the island" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity decide --release live --title "T"
  [ "$status" -eq 0 ]
  # The Live row must be the one holding it.
  run node -e '
    const h=require("fs").readFileSync(process.argv[1],"utf8");
    const rows=h.split("<tr").map(r=>r.split("</tr>")[0]).filter(r=>r.includes("scope=\"row\""));
    const live=rows.find(r=>r.includes("s-name\">Existing"));
    process.exit(live && live.includes("STORY-950") ? 0 : 1);
  ' "$(dom "$MAP")"
  [ "$status" -eq 0 ]
}

@test "add-card derives status from the story file" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -eq 0 ]
  run domcount "$MAP" 'data-status="draft"'
  [ "$output" -eq 1 ]
}

@test "add-card refuses an activity that is not on the backbone" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity nonesuch --release r1 --title "T"
  [ "$status" -ne 0 ]
  [[ "$output" == *"nonesuch"* ]]
  [[ "$output" == *"notice"* ]]
}

@test "add-card refuses a release band that does not exist" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r9 --title "T"
  [ "$status" -ne 0 ]
  [[ "$output" == *"r9"* ]]
}

@test "add-card refuses a duplicate story on the same map" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -eq 0 ]
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity decide --release r1 --title "T again"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already"* ]]
}

@test "move-card relocates a card and re-renders it in the new cell" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -eq 0 ]
  run node "$EDIT" "$MAP" move-card --story STORY-950 --activity decide --release live
  [ "$status" -eq 0 ]
  run node -e '
    const h=require("fs").readFileSync(process.argv[1],"utf8");
    const rows=h.split("<tr").map(r=>r.split("</tr>")[0]).filter(r=>r.includes("scope=\"row\""));
    const live=rows.find(r=>r.includes("s-name\">Existing"));
    const now=rows.find(r=>r.includes("s-name\">Now"));
    process.exit(live.includes("STORY-950") && !now.includes("STORY-950") ? 0 : 1);
  ' "$(dom "$MAP")"
  [ "$status" -eq 0 ]
}

@test "remove-card takes a card off the map" {
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -eq 0 ]
  run node "$EDIT" "$MAP" remove-card --story STORY-950
  [ "$status" -eq 0 ]
  run domcount "$MAP" 'data-story-id="STORY-950"'
  [ "$output" -eq 0 ]
}

@test "add-band appends a release row" {
  run node "$EDIT" "$MAP" add-band --id r2 --name "Later" --badge R2 --note "deferred"
  [ "$status" -eq 0 ]
  run domcount "$MAP" '<th class="slice" scope="row"'
  [ "$output" -eq 3 ]
  run domcount "$MAP" 'Later'
  [ "$output" -ge 1 ]
}

@test "add-activity appends a backbone column and every row grows a cell" {
  # A card first: a band with nothing in it collapses to one spanning cell, so
  # cell count only tracks the activity count once a band holds something.
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -eq 0 ]
  run domcount "$MAP" '<td class="cell'
  [ "$output" -eq 3 ]   # r1 row: 2 activities; live row: 1 spanning cell

  run node "$EDIT" "$MAP" add-activity --id verify --title "C. Verify"
  [ "$status" -eq 0 ]
  run domcount "$MAP" '<th class="act" scope="col"'
  [ "$output" -eq 3 ]
  # The populated row grew from 2 cells to 3 without anyone touching the HTML.
  run domcount "$MAP" '<td class="cell'
  [ "$output" -eq 4 ]
}

@test "a failed operation leaves the map untouched" {
  cp "$MAP" "$TMP/before.html"
  run node "$EDIT" "$MAP" add-card --story STORY-950 --activity nope --release r1 --title "T"
  [ "$status" -ne 0 ]
  run diff -q "$TMP/before.html" "$MAP"
  [ "$status" -eq 0 ]
}

@test "refuses a file that is not a story map" {
  printf '<html><body>no island</body></html>\n' > "$TMP/bare.html"
  run node "$EDIT" "$TMP/bare.html" add-card --story STORY-950 --activity notice --release r1 --title "T"
  [ "$status" -ne 0 ]
}

@test "editing a map preserves a row's pre-RFC marker" {
  # The exception is closed (ADR-107), so the marker only ever exists on rows
  # that already carry it. An edit that dropped it would silently turn history
  # into a defect, and there is no command to put it back — deliberately, since
  # a command to create a historical row would contradict the closed set.
  local root="$TMP/keepmark"
  mkdir -p "$root/docs/story-maps/draft" "$root/docs/stories/done"
  printf -- '---\nstatus: done\n---\n# STORY-991\n' > "$root/docs/stories/done/STORY-991-a.md"
  local map="$root/docs/story-maps/draft/STORY-MAP-991-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    printf '%s\n' '{ "storyMapId": "STORY-MAP-991", "title": "T", "traces": { "jtbd": ["JTBD-900"] }, "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "hist", "name": "History", "preRfc": true } ], "tasks": [ { "activity": "a", "release": "hist", "title": "one", "storyId": "STORY-991" } ] }'
    printf '</script>\n'
  } > "$map"
  run bash -c "cd '$root' && node '$RENDER' docs/story-maps/draft/STORY-MAP-991-x.html"
  [ "$status" -eq 0 ]

  run bash -c "cd '$root' && node '$EDIT' docs/story-maps/draft/STORY-MAP-991-x.html add-activity --id z --title 'Z. New step'"
  [ "$status" -eq 0 ]

  run bash -c "grep -c '\"preRfc\": true' '$map'"
  [ "$output" -eq 1 ] || { echo "the pre-RFC marker did not survive the edit"; return 1; }

  # And it still earns the exception rather than reading as a defect.
  run bash -c "grep -o '\"hist\": \"[a-z]*\"' '$map'"
  [ "$output" = '"hist": "delivered"' ] || { echo "derived status was $output, wanted delivered"; return 1; }
}
