#!/usr/bin/env bats

# Behavioural test for the read-only story-map query surface, and for the
# --json stdin mode on story-map-edit.
#
# Why these exist rather than an MCP server. The SDK cannot ship: marketplace
# install copies a directory and runs no `npm install`, and none of the cached
# plugin versions carries a node_modules. MCP tool schemas are also injected
# into every session of every adopter rather than progressively disclosed — a
# standing context cost against a surface with no measured traffic. And every
# gate in the suite matches `[ "$TOOL_NAME" = "Bash" ]`, so an MCP call would
# route around the enforcement layer. These shims solve the same two problems
# on the Bash path, where the gates still see the call.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-090 (drift-invalidated human-oversight marker)
# @adr ADR-103 (map is the approval surface)
# @adr ADR-052 (behavioural-tests default)

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  # The .sh wrapper, not the .mjs: it owns the oversight facts, computed from
  # the one shared hash definition in lib/story-oversight.sh.
  QUERY="$REPO_ROOT/packages/itil/scripts/story-map-query.sh"
  EDIT="$REPO_ROOT/packages/itil/scripts/story-map-edit.mjs"
  RENDER="$REPO_ROOT/packages/itil/scripts/render-story-map.mjs"
  MARK="$REPO_ROOT/packages/itil/scripts/mark-story-oversight-confirmed.sh"
  TMP="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP/docs/story-maps/draft" "$TMP/docs/stories/done"
  printf -- '---\nstatus: done\n---\n# STORY-950\n' > "$TMP/docs/stories/done/STORY-950-a.md"

  _map() {
    local id="$1" tasks="$2"
    {
      printf '<script id="story-map-data" type="application/json">\n'
      printf '{ "storyMapId": "%s", "title": "Map %s", "status": "draft",\n' "$id" "$id"
      printf '  "traces": { "problems": ["P900"], "jtbd": ["JTBD-900"], "rfcs": [], "adrs": [] },\n'
      printf '  "backbone": [ { "id": "a", "title": "A. Notice" }, { "id": "b", "title": "B. Decide" } ],\n'
      printf '  "releases": [ { "id": "live", "name": "Existing", "badge": "Live" } ],\n'
      printf '  "tasks": [ %s ] }\n' "$tasks"
      printf '</script>\n'
    } > "$TMP/docs/story-maps/draft/${id}-x.html"
    node "$RENDER" "$TMP/docs/story-maps/draft/${id}-x.html"
  }
  _map "STORY-MAP-940" '{ "activity": "a", "release": "live", "title": "T", "storyId": "STORY-950" }'
  _map "STORY-MAP-941" ''
}

@test "list returns every map with id, title, status and traces" {
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(d.map(m=>m.storyMapId).join(','));\""
  [ "$status" -eq 0 ]
  [ "$output" = "STORY-MAP-940,STORY-MAP-941" ]
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    const m=d.find(x=>x.storyMapId==='STORY-MAP-940');
    process.stdout.write([m.title,m.status,m.traces.problems[0]].join('|'));\""
  [ "$output" = "Map STORY-MAP-940|draft|P900" ]
}

@test "ratification comes from the shared oversight lib, not a local guess" {
  # If this computed its own boolean it could report ratified:true for a map the
  # ADR-090 drain considers drift-reopened — telling an agent it is safe to act
  # on substance no human approved, inverting the reason the field exists.
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(String(d.every(m=>m.ratified===false)));\""
  [ "$output" = "true" ]

  run env CLAUDE_SESSION_ID=test-session bash -c "cd '$TMP' && '$MARK' docs/story-maps/draft/STORY-MAP-940-x.html"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    const m=d.find(x=>x.storyMapId==='STORY-MAP-940');
    process.stdout.write(m.ratified+':'+m.reason);\""
  [ "$output" = "true:ratified" ]
}

@test "a ratified map that then drifts reports as unratified again, with a reason" {
  run env CLAUDE_SESSION_ID=test-session bash -c "cd '$TMP' && '$MARK' docs/story-maps/draft/STORY-MAP-940-x.html"
  [ "$status" -eq 0 ]
  # An ACTIVITY, not a band: ADR-103 put rows and cards outside the fingerprint,
  # so adding a band is scheduling and correctly drifts nothing. A new column is
  # a new step in the journey — substance, and the human's call.
  run bash -c "cd '$TMP' && node '$EDIT' docs/story-maps/draft/STORY-MAP-940-x.html add-activity --id z --title 'Z. New step'"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    const m=d.find(x=>x.storyMapId==='STORY-MAP-940');
    process.stdout.write(m.ratified+':'+m.reason);\""
  [ "$output" = "false:drift-reopened" ]
}

@test "the retired machine-acceptance axis is not reported" {
  # ADR-103 retired ADR-101, so there is no second acceptance basis to report.
  # A field that is always false reads as a live distinction that no longer
  # exists — worse than absent.
  run bash -c "cd '$TMP' && '$QUERY' list | grep -c 'afkAccepted' || true"
  [ "$output" = "0" ]
}

@test "get returns one map's backbone, bands and cards" {
  run bash -c "cd '$TMP' && '$QUERY' get STORY-MAP-940 | node -e \"
    const m=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write([m.backbone.length,m.releasesDetail.length,m.tasks.length].join(','));\""
  [ "$output" = "2,1,1" ]
}

@test "get on an unknown map fails rather than returning nothing" {
  run bash -c "cd '$TMP' && '$QUERY' get STORY-MAP-999"
  [ "$status" -ne 0 ]
  [[ "$output" == *"STORY-MAP-999"* ]]
}

@test "find-story reports which map holds a story and where it sits" {
  run bash -c "cd '$TMP' && '$QUERY' find-story STORY-950 | node -e \"
    const r=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(r.map(x=>x.storyMapId+':'+x.activity+':'+x.release).join('|'));\""
  [ "$output" = "STORY-MAP-940:a:live" ]
}

@test "find-story returns an empty list for a story on no map" {
  run bash -c "cd '$TMP' && '$QUERY' find-story STORY-999"
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "unratified lists only the maps needing ratification" {
  run env CLAUDE_SESSION_ID=test-session bash -c "cd '$TMP' && '$MARK' docs/story-maps/draft/STORY-MAP-940-x.html"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && '$QUERY' unratified | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(d.map(m=>m.storyMapId).join(','));\""
  [ "$output" = "STORY-MAP-941" ]
}

@test "the corpus glob matches the detector's, root and one level down" {
  # Two surfaces sharing one hash definition but disagreeing on WHICH maps exist
  # is the more confusing failure. This repo has hit that class before.
  printf '<script id="story-map-data" type="application/json">\n{ "storyMapId": "STORY-MAP-942", "title": "Root level", "backbone": [ { "id": "a", "title": "A" } ], "releases": [ { "id": "r1", "name": "N", "badge": "R1" } ] }\n</script>\n' > "$TMP/docs/story-maps/STORY-MAP-942-root.html"
  node "$RENDER" "$TMP/docs/story-maps/STORY-MAP-942-root.html"
  run bash -c "cd '$TMP' && '$QUERY' list | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(String(d.length));\""
  [ "$output" = "3" ]
}

@test "query is read-only: the corpus is byte-identical after every operation" {
  local before after
  before="$(cd "$TMP" && find docs -type f -exec shasum {} + | sort | shasum)"
  run bash -c "cd '$TMP' && '$QUERY' list >/dev/null && '$QUERY' get STORY-MAP-940 >/dev/null && '$QUERY' find-story STORY-950 >/dev/null && '$QUERY' unratified >/dev/null"
  [ "$status" -eq 0 ]
  after="$(cd "$TMP" && find docs -type f -exec shasum {} + | sort | shasum)"
  [ "$before" = "$after" ]
}

@test "an absent story-maps directory returns empty rather than erroring" {
  # The common adopter case: installed for problem management, no story maps.
  local bare="$TMP/bare"; mkdir -p "$bare"
  run bash -c "cd '$bare' && '$QUERY' list"
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "the maps directory can be overridden rather than hard-coded" {
  run bash -c "'$QUERY' list --maps-dir '$TMP/docs/story-maps' | node -e \"
    const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(String(d.length));\""
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "edit accepts an operation as JSON on stdin, so prose needs no escaping" {
  run bash -c "cd '$TMP' && printf '%s' '{\"op\":\"add-card\",\"story\":\"STORY-950\",\"activity\":\"b\",\"release\":\"live\",\"title\":\"He said \\\"go\\\" — then left\"}' | node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html --json -"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && '$QUERY' get STORY-MAP-941 | node -e \"
    const m=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(m.tasks[0].title);\""
  [ "$output" = 'He said "go" — then left' ]
}

@test "the stdin form produces byte-identical output to the flag form" {
  # The equivalence claim, asserted rather than trusted: a validation branch
  # added to one form only would drift silently otherwise.
  run bash -c "cd '$TMP' && node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html add-card --story STORY-950 --activity a --release live --title 'Same card' --value 'Value: same.'"
  [ "$status" -eq 0 ]
  cp "$TMP/docs/story-maps/draft/STORY-MAP-941-x.html" "$TMP/via-flags.html"

  run bash -c "cd '$TMP' && node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html remove-card --story STORY-950"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && printf '%s' '{\"op\":\"add-card\",\"story\":\"STORY-950\",\"activity\":\"a\",\"release\":\"live\",\"title\":\"Same card\",\"value\":\"Value: same.\"}' | node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html --json -"
  [ "$status" -eq 0 ]
  run diff -q "$TMP/via-flags.html" "$TMP/docs/story-maps/draft/STORY-MAP-941-x.html"
  [ "$status" -eq 0 ]
}

@test "the stdin form validates exactly as the flag form does" {
  run bash -c "cd '$TMP' && printf '%s' '{\"op\":\"add-card\",\"story\":\"STORY-950\",\"activity\":\"nonesuch\",\"release\":\"live\",\"title\":\"T\"}' | node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html --json -"
  [ "$status" -ne 0 ]
  [[ "$output" == *"nonesuch"* ]]
}

@test "malformed stdin JSON is rejected, not silently ignored" {
  run bash -c "cd '$TMP' && printf '%s' 'not json at all' | node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html --json -"
  [ "$status" -ne 0 ]
  [[ "$output" == *"JSON"* ]]
}

@test "a stdin object with no op is rejected" {
  run bash -c "cd '$TMP' && printf '%s' '{\"story\":\"STORY-950\"}' | node '$EDIT' docs/story-maps/draft/STORY-MAP-941-x.html --json -"
  [ "$status" -ne 0 ]
  [[ "$output" == *"op"* ]]
}

@test "a row's status is derived from its stories, not stored" {
  # Same reason storyStatus went: a stored value duplicates what the corpus
  # already knows, imposes a sync obligation, and drifts. A row is delivered
  # when its stories are, proposed when a problem or an RFC names it, and
  # unproposed when nothing has asked for it yet.
  mkdir -p "$TMP/docs/stories/done" "$TMP/docs/stories/draft"
  printf -- '---\nstatus: done\n---\n# STORY-960\n' > "$TMP/docs/stories/done/STORY-960-a.md"
  printf -- '---\nstatus: draft\n---\n# STORY-961\n' > "$TMP/docs/stories/draft/STORY-961-b.md"

  local map="$TMP/docs/story-maps/draft/STORY-MAP-945-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-945",
  "title": "Derived row status",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [
    { "id": "shipped", "name": "Shipped", "badge": "Live" },
    { "id": "named",   "name": "Named",   "badge": "R1", "rfc": "RFC-900" },
    { "id": "byprob",  "name": "By problem", "badge": "R1", "problems": ["P900"] },
    { "id": "nobody",  "name": "Nobody asked", "badge": "R2" }
  ],
  "tasks": [
    { "activity": "a", "release": "shipped", "title": "done one", "storyId": "STORY-960" },
    { "activity": "a", "release": "named",   "title": "draft one", "storyId": "STORY-961" }
  ]
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]

  run bash -c "cd '$TMP' && '$QUERY' get STORY-MAP-945 | node -e \"
    const m=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(m.releasesDetail.map(r=>r.id+'='+r.status).join(' '));\""
  [ "$output" = "shipped=delivered named=proposed byprob=proposed nobody=unproposed" ]
}

@test "a stored row status is ignored in favour of the derived one" {
  # Guards the migration: an island still carrying `status` must not win over
  # what the corpus actually says, or the duplicate survives in practice.
  local map="$TMP/docs/story-maps/draft/STORY-MAP-946-x.html"
  {
    printf '<script id="story-map-data" type="application/json">\n'
    cat <<'JSON'
{
  "storyMapId": "STORY-MAP-946",
  "title": "Stale stored status",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "r1", "name": "R", "badge": "R2", "status": "delivered" } ],
  "tasks": []
}
JSON
    printf '</script>\n'
  } > "$map"
  run node "$RENDER" "$map"
  [ "$status" -eq 0 ]
  run bash -c "cd '$TMP' && '$QUERY' get STORY-MAP-946 | node -e \"
    const m=JSON.parse(require('fs').readFileSync(0,'utf8'));
    process.stdout.write(m.releasesDetail[0].status);\""
  [ "$output" = "unproposed" ]
}
