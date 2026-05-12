#!/usr/bin/env bats
# Behavioural fixtures for reconcile-story-maps.sh + bin shim + skill
# (P170 Phase 2 Slice 5 — sibling of reconcile-stories.sh / reconcile-rfcs.sh).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/reconcile-story-maps.sh"
  BIN_SHIM="${REPO_ROOT}/packages/itil/bin/wr-itil-reconcile-story-maps"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/reconcile-story-maps/SKILL.md"

  TMPROOT=$(mktemp -d)
  ORIG_DIR="$PWD"
  cd "$TMPROOT"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPROOT"
}

@test "reconcile-story-maps: script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "reconcile-story-maps: bin shim exists, executable, exec's the script" {
  [ -f "$BIN_SHIM" ]
  [ -x "$BIN_SHIM" ]
  run grep -E 'exec.*scripts/reconcile-story-maps\.sh' "$BIN_SHIM"
  [ "$status" -eq 0 ]
}

@test "reconcile-story-maps: exits 2 when README is missing" {
  mkdir -p docs/story-maps
  run bash "$SCRIPT" docs/story-maps
  [ "$status" -eq 2 ]
}

@test "reconcile-story-maps: exits 0 on empty story-maps dir + empty README" {
  mkdir -p docs/story-maps/draft docs/story-maps/accepted docs/story-maps/in-progress docs/story-maps/completed docs/story-maps/archived
  echo "# Story Maps" > docs/story-maps/README.md
  run bash "$SCRIPT" docs/story-maps
  [ "$status" -eq 0 ]
}

@test "reconcile-story-maps: detects STALE when filesystem has a map not in README" {
  mkdir -p docs/story-maps/draft
  touch docs/story-maps/draft/STORY-MAP-007-foo.html
  echo "# Story Maps" > docs/story-maps/README.md
  run bash "$SCRIPT" docs/story-maps
  [ "$status" -eq 1 ]
  [[ "$output" == *"STALE"* ]]
  [[ "$output" == *"STORY-MAP-007"* ]]
}

@test "reconcile-story-maps: detects MISSING when README claims a map that isn't on disk" {
  mkdir -p docs/story-maps/draft
  cat > docs/story-maps/README.md <<'EOF'
# Story Maps
| ID | Status |
|----|--------|
| STORY-MAP-007 | draft |
EOF
  run bash "$SCRIPT" docs/story-maps
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING"* ]]
  [[ "$output" == *"STORY-MAP-007"* ]]
}

@test "reconcile-story-maps: SKILL.md exists with canonical name" {
  [ -f "$SKILL_FILE" ]
  run grep -E '^name: wr-itil:reconcile-story-maps$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
