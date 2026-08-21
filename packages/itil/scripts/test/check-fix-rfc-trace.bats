#!/usr/bin/env bats

# @problem P314 — the fix-time propose-fix trace gate. Before fix work
# commences on a Known Error, the framework requires a fix vehicle tracing the
# problem. This script is the load-bearing PREDICATE half of that gate: it
# detects whether anything proposes a fix, and emits a directive on stdout when
# nothing does.
#
# @problem P508 — a fix proposal is a RELEASE ROW ON A STORY MAP, never a
# document. The predicate used to scan the RFC document directory alone and its
# directive told the caller to create a new document, which the current
# decision bars. It now answers from the union of both tiers, and its three
# refusal shapes are distinguishable by exit status.
#
# Behavioural per ADR-052: assert on the script's exit code + stdout directive
# given fixture corpora — not on script source content (no structural greps per
# P081).
#
# Every case passes BOTH a fixture rfcs-dir and a fixture maps-dir. Leaving the
# maps-dir to default would read this repository's own live corpus, making the
# suite order-dependent and its negative cases quietly untrue.
#
# Contract:
#   - <problem-file> whose basename is `<NNN>-<slug>.md` → PID = P<NNN>.
#   - Traced when a legacy RFC document's frontmatter `problems:` array
#     contains the exact PID (boundary-safe: P31 / P3140 must NOT match a P314
#     query), OR when a release row carrying an RFC identity holds a card whose
#     story names the PID.
#   - Traced            → exit 0, EMPTY stdout.
#   - Untraced, drawable→ exit 0, directive naming the row to draw + identity.
#   - A map cannot be read → exit 3, re-render directive (mechanical, no person).
#   - No story maps at all → exit 3, one-item-for-a-person directive.
#   - Missing problem file / no args → exit 2 (caller misuse), stderr usage.
#
# @adr ADR-119 (a fix proposal draws a release row, never a document)
# @adr ADR-103 (a release row is the RFC; the map is the approval surface)
# @adr ADR-071 (every fix goes through an RFC — unconditional, no carve-out)
# @adr ADR-060 (I1 load-bearing-from-the-start; I13 fix-proposal invariant)
# @adr ADR-052 (behavioural bats default)
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes — trace invariant)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — never stall/skip)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-fix-rfc-trace.sh"
  RENDER="$SCRIPTS_DIR/render-story-map.mjs"
  WORK="$(mktemp -d)"
  RFCS_DIR="$WORK/docs/rfcs"
  MAPS_DIR="$WORK/docs/story-maps"
  STORIES_DIR="$WORK/docs/stories/accepted"
  PROBLEMS_DIR="$WORK/docs/problems/known-error"
  mkdir -p "$RFCS_DIR" "$MAPS_DIR/draft" "$STORIES_DIR" "$PROBLEMS_DIR"
}

teardown() {
  rm -rf "$WORK"
}

# The default invocation under test: fixture corpora for BOTH tiers.
check() {
  run "$SCRIPT" "$1" "$RFCS_DIR" "$MAPS_DIR"
}

# Write an RFC document fixture whose frontmatter `problems:` array is verbatim.
write_rfc() {
  local id="$1" slug="$2" status="$3" problems="$4"
  cat > "$RFCS_DIR/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
problems: ${problems}
---

# RFC-${id}: ${slug}
EOF
}

# Write a problem fixture; returns the path on stdout.
write_problem() {
  local num="$1" slug="${2:-some-problem}"
  local f="$PROBLEMS_DIR/${num}-${slug}.md"
  cat > "$f" <<EOF
# Problem ${num}: ${slug}

**Status**: Known Error
EOF
  printf '%s' "$f"
}

# Draw a release row on a map, with one card whose story names the problem —
# the full row-to-card-to-story chain the row half reads through.
write_row() {
  local map="$1" rfc="$2" story="$3" pid="$4"
  cat > "$STORIES_DIR/${story}-a-fix.md" <<EOF
---
status: accepted
problems: [${pid}]
---
# ${story}
EOF
  cat > "$MAPS_DIR/draft/${map}-fixture.html" <<EOF
<script id="story-map-data" type="application/json">
{ "storyMapId": "${map}", "title": "Fixture", "status": "draft",
  "traces": { "jtbd": ["JTBD-900"] },
  "backbone": [ { "id": "a", "title": "A. Act" } ],
  "releases": [ { "id": "row", "name": "A row", "rfc": "${rfc}" } ],
  "tasks": [ { "activity": "a", "release": "row", "title": "T", "storyId": "${story}" } ] }
</script>
EOF
  ( cd "$WORK" && node "$RENDER" "docs/story-maps/draft/${map}-fixture.html" >/dev/null )
}

# A row with no cards, so nothing links it to any problem.
write_bare_map() {
  cat > "$MAPS_DIR/draft/$1-fixture.html" <<EOF
<script id="story-map-data" type="application/json">
{ "storyMapId": "$1", "title": "Bare", "status": "draft",
  "traces": { "jtbd": ["JTBD-900"] },
  "backbone": [ { "id": "a", "title": "A. Act" } ],
  "releases": [ { "id": "row", "name": "A row", "rfc": "RFC-900" } ], "tasks": [] }
</script>
EOF
  ( cd "$WORK" && node "$RENDER" "docs/story-maps/draft/$1-fixture.html" >/dev/null )
}

# ── Traced: the legacy document tier still answers ──────────────────────────

@test "legacy document trace (single-PID array) → exit 0, empty stdout" {
  write_rfc 005 some-fix accepted "[P314]"
  write_bare_map STORY-MAP-900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "legacy document trace (multi-PID array) → exit 0, empty stdout" {
  write_rfc 005 some-fix accepted "[P100, P314, P200]"
  write_bare_map STORY-MAP-900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exact match works for a zero-padded low PID (P080 ← [P080])" {
  write_rfc 005 padded-pid accepted "[P080]"
  write_bare_map STORY-MAP-900
  check "$(write_problem 080)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "PID boundary: P31 in a document does NOT satisfy a P314 query" {
  write_rfc 005 short-pid accepted "[P31]"
  write_bare_map STORY-MAP-900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

@test "PID boundary: P3140 in a document does NOT satisfy a P314 query" {
  write_rfc 005 long-pid accepted "[P3140]"
  write_bare_map STORY-MAP-900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P314"* ]]
}

# ── Traced: the release-row tier answers too ────────────────────────────────

@test "a release row proposing the fix reads as traced → exit 0, empty stdout" {
  write_row STORY-MAP-901 RFC-071 STORY-500 P508
  check "$(write_problem 508)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a row proposing a DIFFERENT problem does not satisfy this query" {
  write_row STORY-MAP-901 RFC-071 STORY-500 P463
  check "$(write_problem 508)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P508"* ]]
}

@test "an identified row with no card linking it to the problem is not a trace" {
  # The row-to-problem link is read through the cards' stories. A row drawn
  # without one is the floor violation, and reporting it as a trace would let
  # fix work begin against a row nothing connects to this problem.
  write_bare_map STORY-MAP-902
  check "$(write_problem 508)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-rfc-trace: P508"* ]]
}

# ── Untraced but drawable: exit 0 with the row directive ────────────────────

@test "drawable directive names the release row, not a new document" {
  write_bare_map STORY-MAP-900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release row"* ]]
  [[ "$output" == *"story map"* ]]
  # The retired instruction must be gone: nothing may tell a caller to mint a
  # standalone document for a fix proposal.
  [[ "$output" != *"capture-rfc"* ]]
  [[ "$output" != *"docs/rfcs"* ]]
}

@test "drawable directive carries an identity no document and no row holds" {
  write_rfc 059 a accepted "[P1]"
  write_row STORY-MAP-903 RFC-069 STORY-501 P900
  check "$(write_problem 314)"
  [ "$status" -eq 0 ]
  # Documents stop at 059, a row holds 069 — the union answers 070. Allocating
  # from the documents alone would have re-issued 060, which is the collision.
  [[ "$output" == *"RFC-070"* ]]
}

@test "drawable directive says the card's story must name the problem" {
  # Without this the caller draws a row that will not read as traced, and the
  # gate loops.
  write_bare_map STORY-MAP-900
  check "$(write_problem 508)"
  [[ "$output" == *"story file names P508"* ]]
}

# ── Refusals: exit 3 ───────────────────────────────────────────────────────

@test "a map edited but not re-rendered → exit 3, re-render directive" {
  # Fail-closed. Answering "no row proposes this" from a map that cannot say
  # would draw a duplicate row over one that may already exist.
  cat > "$MAPS_DIR/draft/STORY-MAP-904-fixture.html" <<'EOF'
<script id="story-map-data" type="application/json">
{ "storyMapId": "STORY-MAP-904", "title": "Never rendered",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "row", "name": "n", "rfc": "RFC-904" } ], "tasks": [] }
</script>
EOF
  check "$(write_problem 508)"
  [ "$status" -eq 3 ]
  [[ "$output" == *"re-render"* ]] || [[ "$output" == *"Re-render"* ]]
  [[ "$output" == *"STORY-MAP-904"* ]]
}

@test "the re-render refusal says nobody needs to be asked" {
  # A condition a renderer clears must not become a question for the maintainer.
  cat > "$MAPS_DIR/draft/STORY-MAP-904-fixture.html" <<'EOF'
<script id="story-map-data" type="application/json">
{ "storyMapId": "STORY-MAP-904", "title": "Never rendered",
  "backbone": [ { "id": "a", "title": "A" } ],
  "releases": [ { "id": "row", "name": "n", "rfc": "RFC-904" } ], "tasks": [] }
</script>
EOF
  check "$(write_problem 508)"
  [ "$status" -eq 3 ]
  [[ "$output" == *"mechanical"* ]]
}

@test "a repository with no story maps at all → exit 3, one item for a person" {
  rm -rf "$MAPS_DIR"
  check "$(write_problem 508)"
  [ "$status" -eq 3 ]
  [[ "$output" == *"no story maps"* ]]
  [[ "$output" == *"needs a person"* ]]
}

@test "the no-maps refusal tells the caller to carry on, not to stop" {
  # An adopter with no maps would otherwise see every Known Error refuse, which
  # reads as the loop mysteriously halting.
  rm -rf "$MAPS_DIR"
  check "$(write_problem 508)"
  [ "$status" -eq 3 ]
  [[ "$output" == *"next problem"* ]]
}

@test "an empty maps directory is drawable, not a no-maps refusal" {
  # A repo that has the directory but no maps yet is the same case as one whose
  # maps do not cover this journey: still a person's call. It is the ABSENT
  # corpus that this distinguishes, so assert the boundary rather than assume it.
  check "$(write_problem 508)"
  [ "$status" -eq 3 ]
  [[ "$output" == *"no story maps"* ]]
}

# ── Caller misuse ──────────────────────────────────────────────────────────

@test "missing problem file → exit 2, stderr usage" {
  run "$SCRIPT" "$PROBLEMS_DIR/999-nonexistent.md" "$RFCS_DIR" "$MAPS_DIR"
  [ "$status" -eq 2 ]
}

@test "no args → exit 2" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "maps-dir defaults when the third argument is omitted" {
  # Backwards compatibility for the two-argument call shape.
  write_rfc 005 x accepted "[P314]"
  run bash -c "cd '$WORK' && '$SCRIPT' '$(write_problem 314)' '$RFCS_DIR'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "rfcs-dir defaults when only the problem file is given" {
  mkdir -p "$WORK/docs/rfcs"
  cat > "$WORK/docs/rfcs/RFC-005-x.accepted.md" <<'EOF'
---
problems: [P314]
---
# RFC-005: x
EOF
  run bash -c "cd '$WORK' && '$SCRIPT' '$(write_problem 314)'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
