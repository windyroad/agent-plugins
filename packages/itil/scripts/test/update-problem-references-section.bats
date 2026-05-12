#!/usr/bin/env bats

# P170 / Phase 2 Slice 2 — behavioural fixture for the generalised
# update-problem-references-section.sh helper. Covers polymorphic
# extraction (HTML data attributes for Story Maps; markdown frontmatter
# for Stories + RFCs) feeding a uniform markdown-row render into the
# target problem ticket's ## <section-name> section. Per ADR-060
# § Phase 2 encoding amendment 2026-05-12 architect finding 4: helper
# body MUST NOT carry per-section-name branching; section-name is a
# positional argument; per-extension dispatch is the only branch.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/itil/scripts/update-problem-references-section.sh"

  # Build an isolated workspace mirroring the docs layout.
  WORKSPACE="$(mktemp -d)"
  cd "$WORKSPACE"
  mkdir -p docs/problems/open docs/rfcs docs/story-maps/in-progress docs/stories/accepted

  # Sample problem ticket
  cat > docs/problems/open/200-sample-problem.md <<'EOF'
# Problem 200: Sample problem ticket

**Status**: Open
**Reported**: 2026-05-12

## Description

Sample description.

## Related

Sibling refs.
EOF

  # Sample RFC tracing problem 200
  cat > docs/rfcs/RFC-100-sample-rfc.in-progress.md <<'EOF'
---
status: in-progress
rfc-id: sample-rfc
problems: [P200]
adrs: []
jtbd: []
---

# RFC-100: Sample RFC
EOF

  # Sample HTML story map tracing problem 200
  cat > docs/story-maps/in-progress/STORY-MAP-050-sample-map.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>STORY-MAP-050: Sample map</title>
  <meta name="story-map-id" content="STORY-MAP-050">
  <meta name="status" content="in-progress">
  <meta name="problems" content="P200">
  <meta name="rfcs" content="RFC-100">
  <meta name="jtbd" content="JTBD-008">
</head>
<body>
  <h1>STORY-MAP-050: Sample map</h1>
</body>
</html>
EOF

  # Sample markdown story tracing problem 200
  cat > docs/stories/accepted/STORY-300-sample-story.md <<'EOF'
---
status: accepted
story-id: sample-story
problems: [P200]
jtbd: [JTBD-008]
rfcs: [RFC-100]
story-maps: [STORY-MAP-050]
estimated-effort: M
---

# STORY-300: Sample story
EOF
}

teardown() {
  rm -rf "$WORKSPACE"
}

@test "helper: script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "helper: requires problem-file argument; bare invocation halts" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "helper: requires section-name argument" {
  run bash "$SCRIPT" docs/problems/open/200-sample-problem.md
  [ "$status" -ne 0 ]
}

@test "helper: refresh ## RFCs section from docs/rfcs/*.md frontmatter (markdown-extraction path)" {
  cd "$WORKSPACE"
  run bash "$SCRIPT" docs/problems/open/200-sample-problem.md RFCs
  [ "$status" -eq 0 ]
  grep -q '^## RFCs$' docs/problems/open/200-sample-problem.md
  grep -q 'RFC-100' docs/problems/open/200-sample-problem.md
}

@test "helper: refresh ## Story Maps section from docs/story-maps/*.html data attributes (HTML-extraction path)" {
  cd "$WORKSPACE"
  run bash "$SCRIPT" docs/problems/open/200-sample-problem.md "Story Maps"
  [ "$status" -eq 0 ]
  grep -q '^## Story Maps$' docs/problems/open/200-sample-problem.md
  grep -q 'STORY-MAP-050' docs/problems/open/200-sample-problem.md
}

@test "helper: refresh ## Stories section from docs/stories/*.md frontmatter (markdown-extraction path)" {
  cd "$WORKSPACE"
  run bash "$SCRIPT" docs/problems/open/200-sample-problem.md Stories
  [ "$status" -eq 0 ]
  grep -q '^## Stories$' docs/problems/open/200-sample-problem.md
  grep -q 'STORY-300' docs/problems/open/200-sample-problem.md
}

@test "helper: lazy-empty — section removed entirely when no traces match" {
  cd "$WORKSPACE"
  # Create a problem ticket nothing references
  cat > docs/problems/open/201-unreferenced-problem.md <<'EOF'
# Problem 201: Unreferenced

**Status**: Open

## Related

Some related content.

## Story Maps

| ID | Title |
|----|-------|
| STORY-MAP-999 | stale entry |
EOF
  run bash "$SCRIPT" docs/problems/open/201-unreferenced-problem.md "Story Maps"
  [ "$status" -eq 0 ]
  ! grep -q '^## Story Maps$' docs/problems/open/201-unreferenced-problem.md
}

@test "helper: idempotent — running twice produces no change on second invocation" {
  cd "$WORKSPACE"
  bash "$SCRIPT" docs/problems/open/200-sample-problem.md RFCs
  local first_hash
  first_hash=$(md5 -q docs/problems/open/200-sample-problem.md 2>/dev/null || md5sum docs/problems/open/200-sample-problem.md | cut -d' ' -f1)
  bash "$SCRIPT" docs/problems/open/200-sample-problem.md RFCs
  local second_hash
  second_hash=$(md5 -q docs/problems/open/200-sample-problem.md 2>/dev/null || md5sum docs/problems/open/200-sample-problem.md | cut -d' ' -f1)
  [ "$first_hash" = "$second_hash" ]
}

@test "helper: HTML path uses literal data-attribute grep (NOT inline-style match)" {
  # Architect finding 5 (Prohibition reinforcement): the helper MUST
  # grep on `<meta name="problems" content="...">` literal, not on any
  # `style=` attribute. Verify by injecting a fake inline-style on a
  # data-bearing element and asserting the helper's extraction is
  # unaffected (the prohibition is enforced separately by a doc-lint
  # bats; this test asserts the helper's parsing is style-agnostic).
  cd "$WORKSPACE"
  # The fixture's HTML map already lacks any `style=""` — that's the
  # canonical shape. The helper must extract the same set whether the
  # map has style or not. Adding a benign body-level style to the
  # fixture (NOT on a data-bearing element) and re-running the helper
  # must yield the same Story Maps section.
  bash "$SCRIPT" docs/problems/open/200-sample-problem.md "Story Maps"
  local first_body
  first_body=$(grep -A 5 '^## Story Maps$' docs/problems/open/200-sample-problem.md)
  # Inject benign body-level style — NOT on a data-bearing element
  sed -i.bak 's|<body>|<body style="font-family: sans-serif">|' docs/story-maps/in-progress/STORY-MAP-050-sample-map.html
  rm -f docs/story-maps/in-progress/STORY-MAP-050-sample-map.html.bak
  bash "$SCRIPT" docs/problems/open/200-sample-problem.md "Story Maps"
  local second_body
  second_body=$(grep -A 5 '^## Story Maps$' docs/problems/open/200-sample-problem.md)
  [ "$first_body" = "$second_body" ]
}

@test "helper: body does NOT contain a per-section-name branch (architect finding 4)" {
  # Structural test (tdd-review: structural-permitted —
  # justification: P176 SKILL.md I-invariant harness gap is the
  # canonical pattern for asserting no-branching contracts via
  # source grep; behavioural enforcement awaits the master harness
  # at P012). Asserts the helper body does NOT carry a literal
  # `case "$section_name"` or `if [ "$section_name" = "..." ]`
  # branch keyed on the section-name value.
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$SCRIPT"
}
