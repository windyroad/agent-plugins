#!/usr/bin/env bats

# P170 / Phase 2 Slice 2b — sanity bats for the 3 sibling helpers
# (update-rfc-references-section.sh, update-jtbd-references-section.sh,
# update-story-references-section.sh). Behavioural coverage of the
# polymorphism is asserted by the comprehensive Slice 2a bats fixture
# at update-problem-references-section.bats; this fixture asserts
# existence + executable + arg-validation + structural no-branching
# guard for the 3 siblings, deferring full behavioural coverage to
# follow-on slice when the siblings are wired into consumer skills.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  RFC_HELPER="$REPO_ROOT/packages/itil/scripts/update-rfc-references-section.sh"
  JTBD_HELPER="$REPO_ROOT/packages/itil/scripts/update-jtbd-references-section.sh"
  STORY_HELPER="$REPO_ROOT/packages/itil/scripts/update-story-references-section.sh"
}

@test "rfc-helper: exists and is executable" {
  [ -x "$RFC_HELPER" ]
}

@test "rfc-helper: requires rfc-file arg" {
  run bash "$RFC_HELPER"
  [ "$status" -ne 0 ]
}

@test "rfc-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$RFC_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "rfc-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$RFC_HELPER"
}

@test "jtbd-helper: exists and is executable" {
  [ -x "$JTBD_HELPER" ]
}

@test "jtbd-helper: requires jtbd-file arg" {
  run bash "$JTBD_HELPER"
  [ "$status" -ne 0 ]
}

@test "jtbd-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$JTBD_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "jtbd-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$JTBD_HELPER"
}

@test "story-helper: exists and is executable" {
  [ -x "$STORY_HELPER" ]
}

@test "story-helper: requires story-file arg" {
  run bash "$STORY_HELPER"
  [ "$status" -ne 0 ]
}

@test "story-helper: requires section-name arg" {
  local tmp
  tmp="$(mktemp)"
  run bash "$STORY_HELPER" "$tmp"
  [ "$status" -ne 0 ]
  rm -f "$tmp"
}

@test "story-helper: body has no per-section-name branch" {
  ! grep -E 'case[[:space:]]+"\$\{?section[_-]?name\}?"|if[[:space:]]+\[[[:space:]]+"\$\{?section[_-]?name\}?"[[:space:]]+=' "$STORY_HELPER"
}

# ---------------------------------------------------------------------------
# P472 / STORY-099 — the RFC helper's Stories population is gated on story
# approval. This helper is the prescribed repair for a MISSING_REVERSE_TRACE
# finding, and it regenerates the WHOLE section from a reverse index over
# every story claiming the RFC. Ungated, repairing one legitimate finding
# swept every unapproved sibling in with it, which is the reference ADR-090
# forbids — and the narrowed detector would then report clean over it. A loud
# false positive traded for a silent true negative.
# ---------------------------------------------------------------------------

make_gate_map() {
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

make_gate_tree() {
  GATE_TMP="$(mktemp -d)"
  GATE_ORIG="$PWD"
  cd "$GATE_TMP"
  mkdir -p docs/stories/draft docs/rfcs docs/story-maps/draft
  make_gate_map docs/story-maps/draft/STORY-MAP-001-ratified.html confirmed
  make_gate_map docs/story-maps/draft/STORY-MAP-002-held.html unconfirmed
  cat > docs/stories/draft/STORY-010-approved.md <<'EOF'
---
status: draft
rfcs: [RFC-900]
story-maps: [STORY-MAP-001]
---
# STORY-010: Approved one
EOF
  cat > docs/stories/draft/STORY-011-held.md <<'EOF'
---
status: draft
rfcs: [RFC-900]
story-maps: [STORY-MAP-002]
---
# STORY-011: Held one
EOF
  cat > docs/rfcs/RFC-900-thing.proposed.md <<'EOF'
---
status: proposed
stories: []
---
# RFC-900: Thing

## Stories
EOF
}

teardown_gate_tree() {
  cd "$GATE_ORIG"
  rm -rf "$GATE_TMP"
}

@test "rfc-helper: does not write a story whose map is not ratified into Stories" {
  make_gate_tree
  run bash "$RFC_HELPER" docs/rfcs/RFC-900-thing.proposed.md "Stories"
  [ "$status" -eq 0 ]
  run cat docs/rfcs/RFC-900-thing.proposed.md
  [[ "$output" != *"STORY-011"* ]]
  teardown_gate_tree
}

@test "rfc-helper: still writes a story whose maps are all ratified" {
  make_gate_tree
  run bash "$RFC_HELPER" docs/rfcs/RFC-900-thing.proposed.md "Stories"
  run cat docs/rfcs/RFC-900-thing.proposed.md
  [[ "$output" == *"STORY-010"* ]]
  teardown_gate_tree
}

@test "rfc-helper: names the story it withheld and the remedy" {
  make_gate_tree
  run bash -c "bash '$RFC_HELPER' docs/rfcs/RFC-900-thing.proposed.md Stories 2>&1 >/dev/null"
  [[ "$output" == *"STORY-011"* ]]
  [[ "$output" == *"ratify"* ]]
  teardown_gate_tree
}

@test "rfc-helper: the Story Maps section is not gated on story approval" {
  make_gate_tree
  cat > docs/story-maps/draft/STORY-MAP-003-plain.html <<'EOF'
<html><head><meta name="rfcs" content="RFC-900"><meta name="status" content="draft">
<title>Plain map</title></head><body></body></html>
EOF
  run bash "$RFC_HELPER" docs/rfcs/RFC-900-thing.proposed.md "Story Maps"
  run cat docs/rfcs/RFC-900-thing.proposed.md
  [[ "$output" == *"STORY-MAP-003"* ]]
  teardown_gate_tree
}
