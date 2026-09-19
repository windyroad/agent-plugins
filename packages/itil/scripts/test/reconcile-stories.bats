#!/usr/bin/env bats
# Behavioural fixtures for reconcile-stories.sh + bin shim + skill
# (P170 Phase 2 Slice 9 — ADR-060 amendment 2026-05-10 line 270 +
# reconcile-rfcs.sh / reconcile-readme.sh sibling).
#
# Per ADR-052: behavioural tests on observable script outputs. The
# load-bearing surfaces under test are:
#   1. Script existence + executable + valid Bash.
#   2. README parse error (exit 2) on missing README or missing
#      Story Rankings header.
#   3. Clean run (exit 0) on a fresh stories directory + empty README.
#   4. Drift detection (exit 1) when README claims a story that isn't
#      on filesystem in the right lifecycle state.
#   5. STALE detection when filesystem has a story not listed in
#      either Story Rankings (active) or Done section.
#   6. Bin shim resolves to the script.
#   7. SKILL.md presence + canonical name + read-only contract.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/reconcile-stories.sh"
  BIN_SHIM="${REPO_ROOT}/packages/itil/bin/wr-itil-reconcile-stories"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/reconcile-stories/SKILL.md"

  TMPROOT=$(mktemp -d)
  ORIG_DIR="$PWD"
  cd "$TMPROOT"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPROOT"
}

# ---------------------------------------------------------------------------
# Surface 1: Script + bin shim existence
# ---------------------------------------------------------------------------

@test "reconcile-stories: script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "reconcile-stories: bin shim exists, is executable, and exec's the script" {
  [ -f "$BIN_SHIM" ]
  [ -x "$BIN_SHIM" ]
  run grep -E 'exec.*scripts/reconcile-stories\.sh' "$BIN_SHIM"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 2: Parse errors (exit 2)
# ---------------------------------------------------------------------------

@test "reconcile-stories: exits 2 when README is missing" {
  mkdir -p docs/stories
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 2 ]
  [[ "$output" == *"PARSE_ERROR"* ]] || [[ "$stderr" == *"PARSE_ERROR"* ]]
}

@test "reconcile-stories: exits 2 when README missing Story Rankings header" {
  mkdir -p docs/stories
  echo "# Stories" > docs/stories/README.md
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# Surface 3: Clean run (exit 0)
# ---------------------------------------------------------------------------

@test "reconcile-stories: exits 0 on empty stories dir with empty README tables" {
  mkdir -p docs/stories/draft docs/stories/accepted docs/stories/in-progress docs/stories/done docs/stories/archived
  cat > docs/stories/README.md <<'EOF'
# Story Backlog

## Story Rankings

| ID | Title | Status |
|----|-------|--------|

## Done

| ID | Title | Done |
|----|-------|------|
EOF
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 4: Drift detection on filesystem vs README mismatch (exit 1)
# ---------------------------------------------------------------------------

@test "reconcile-stories: detects STALE when filesystem has a draft story not in README" {
  mkdir -p docs/stories/draft docs/stories/done
  touch docs/stories/draft/STORY-007-foo.md
  cat > docs/stories/README.md <<'EOF'
# Story Backlog

## Story Rankings

| ID | Title | Status |
|----|-------|--------|

## Done

| ID | Title | Done |
|----|-------|------|
EOF
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 1 ]
  [[ "$output" == *"STALE"* ]]
  [[ "$output" == *"STORY-007"* ]]
}

@test "reconcile-stories: detects DRIFT when README claims a story in Rankings but it's actually done on disk" {
  mkdir -p docs/stories/draft docs/stories/done
  touch docs/stories/done/STORY-007-foo.md
  cat > docs/stories/README.md <<'EOF'
# Story Backlog

## Story Rankings

| ID | Title | Status |
|----|-------|--------|
| STORY-007 | Foo | draft |

## Done

| ID | Title | Done |
|----|-------|------|
EOF
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 1 ]
  [[ "$output" == *"DRIFT"* ]]
  [[ "$output" == *"STORY-007"* ]]
  [[ "$output" == *"actual=done"* ]]
}

@test "reconcile-stories: archived stories are hidden from both tables (no drift)" {
  mkdir -p docs/stories/archived
  touch docs/stories/archived/STORY-007-foo.md
  cat > docs/stories/README.md <<'EOF'
# Story Backlog

## Story Rankings

| ID | Title | Status |
|----|-------|--------|

## Done

| ID | Title | Done |
|----|-------|------|
EOF
  run bash "$SCRIPT" docs/stories
  [ "$status" -eq 0 ]
}

@test "reconcile-stories: accepts an RFC implemented by a story-map release row" {
  mkdir -p docs/stories/draft docs/{problems,rfcs,jtbd} docs/story-maps/draft
  cat > docs/stories/README.md <<'EOF'
# Stories

## Story Rankings

| ID | Title | Status |
|----|-------|--------|
| STORY-007 | Foo | draft |

## Done
EOF
  cat > docs/stories/draft/STORY-007-foo.md <<'EOF'
---
status: draft
rfcs: [RFC-900]
---
# STORY-007: Foo
EOF
  cat > docs/story-maps/draft/STORY-MAP-001-map.html <<'EOF'
<script id="story-map-data" type="application/json">
{"storyMapId":"STORY-MAP-001","releases":[{"id":"r1","rfc":"RFC-900"}],"tasks":[{"release":"r1","storyId":"STORY-007"}]}
</script>
EOF

  run bash "$SCRIPT" docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps
  [ "$status" -eq 0 ]
}

@test "reconcile-stories: an unresolved RFC does not fall through to a bare ls of cwd" {
  mkdir -p docs/stories/draft docs/{problems,rfcs,jtbd,story-maps}
  cat > docs/stories/README.md <<'EOF'
# Stories

## Story Rankings

| ID | Title | Status |
|----|-------|--------|
| STORY-007 | Foo | draft |

## Done
EOF
  cat > docs/stories/draft/STORY-007-foo.md <<'EOF'
---
status: draft
rfcs: [RFC-901]
---
# STORY-007: Foo
EOF
  printf '## Stories\n\nSTORY-007\n' > AGENTS.md

  run bash "$SCRIPT" docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps
  [ "$status" -eq 1 ]
  [[ "$output" == *"UNRESOLVED_RFC_TRACE STORY-007 claims=RFC-901"* ]]
}

# ---------------------------------------------------------------------------
# Surface 5: SKILL.md presence + read-only contract
# ---------------------------------------------------------------------------

@test "reconcile-stories: SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "reconcile-stories: SKILL.md declares canonical name wr-itil:reconcile-stories" {
  run grep -E '^name: wr-itil:reconcile-stories$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 6: the RFC-markdown reverse-trace leg covers ratified stories only
# (P472 / STORY-099). ADR-090 as amended by ADR-103 forbids an RFC from
# referencing a story whose map is not ratified, so for such a story the
# `## Stories` row is CORRECTLY absent and demanding it reports correct work
# as drift. The ADR-103 release-row leg stays ungated: ADR-095 compels a card
# onto the map at capture, so its absence there is never correct.
# ---------------------------------------------------------------------------

# A map with no ADR-102 data island hashes as whole-file bytes, and the
# fingerprint excludes the two marker lines, so stamping the hash in afterwards
# does not move it.
make_map() {
  local f="$1" confirmed="$2" h
  mkdir -p "$(dirname "$f")"
  {
    printf '<html><head>\n'
    [ "$confirmed" = confirmed ] && printf '<meta name="human-oversight" content="confirmed">\n'
    printf '<meta name="oversight-hash" content="OVERSIGHT_HASH_PLACEHOLDER">\n'
    printf '<title>Map</title>\n</head><body></body></html>\n'
  } > "$f"
  h=$(bash -c "source '${REPO_ROOT}/packages/itil/lib/story-oversight.sh'; oversight_content_hash '$f'")
  sed -e "s/OVERSIGHT_HASH_PLACEHOLDER/${h}/" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# One draft story claiming RFC-900, and an RFC-900 markdown file whose
# `## Stories` section lists nothing.
make_story_tree() {
  local maps_field="$1"
  mkdir -p docs/stories/draft docs/problems docs/jtbd docs/rfcs docs/story-maps/draft
  cat > docs/stories/README.md <<'EOF'
# Stories

## Story Rankings

| ID | Title | Status |
|----|-------|--------|
| STORY-007 | Foo | draft |

## Done
EOF
  cat > docs/stories/draft/STORY-007-foo.md <<EOF
---
status: draft
rfcs: [RFC-900]
${maps_field}
---
# STORY-007: Foo
EOF
  cat > docs/rfcs/RFC-900-thing.proposed.md <<'EOF'
---
status: proposed
stories: []
---
# RFC-900: Thing

## Stories

No story is listed here: the story this RFC will carry is not ratified yet.
EOF
}

run_scope_line() {
  run bash -c "bash '$SCRIPT' docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps 2>&1 >/dev/null"
}

@test "reconcile-stories: no drift when an unratified story's RFC omits it" {
  make_story_tree 'story-maps: [STORY-MAP-001]'
  make_map docs/story-maps/draft/STORY-MAP-001-map.html unconfirmed

  run bash "$SCRIPT" docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps
  [[ "$output" != *"MISSING_REVERSE_TRACE STORY-007 in RFC-900"* ]]
  [ "$status" -eq 0 ]
}

@test "reconcile-stories: a ratified story missing from its RFC Stories section still reports" {
  make_story_tree 'story-maps: [STORY-MAP-001]'
  make_map docs/story-maps/draft/STORY-MAP-001-map.html confirmed

  run bash "$SCRIPT" docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING_REVERSE_TRACE STORY-007 in RFC-900 ## Stories"* ]]
}

@test "reconcile-stories: says how many pairs the RFC leg checked" {
  make_story_tree 'story-maps: [STORY-MAP-001]'
  make_map docs/story-maps/draft/STORY-MAP-001-map.html confirmed

  run_scope_line
  [[ "$output" == *"checked 1 of 1"* ]]
}

@test "reconcile-stories: an unratified story's skip reads as a correct absence" {
  make_story_tree 'story-maps: [STORY-MAP-001]'
  make_map docs/story-maps/draft/STORY-MAP-001-map.html unconfirmed

  run_scope_line
  [[ "$output" == *"checked 0 of 1"* ]]
  [[ "$output" == *"not ratified"* ]]
}

@test "reconcile-stories: a story naming no map is counted apart from a correct absence" {
  make_story_tree ''

  run_scope_line
  [[ "$output" == *"names no story map"* ]]
  [[ "$output" != *"not ratified"* ]]
}

@test "reconcile-stories: an unresolvable map id is counted apart from a correct absence" {
  make_story_tree 'story-maps: [STORY-MAP-404]'

  run_scope_line
  [[ "$output" == *"does not resolve"* ]]
  [[ "$output" != *"not ratified"* ]]
}
