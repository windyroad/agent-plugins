#!/usr/bin/env bats

# Behavioural fixture for /wr-retrospective:migrate-briefing per ADR-052.
# Exercises the implementation script against synthetic legacy
# docs/BRIEFING.md fixtures in a temp dir. Asserts observable
# file-system outcomes — per feedback_behavioural_tests.md (P081),
# not source content.
#
# Closes P204 verification surface.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/retrospective/scripts/migrate-briefing.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d -t migrate-briefing-bats.XXXXXX)
  cd "$TEST_DIR"
  mkdir -p docs
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# Idempotency direction 1: no legacy file → no-op exit 0
# ---------------------------------------------------------------------------

@test "fixture: no legacy file → no-op exit 0, tree not created" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to migrate"* ]] || [[ "$output" == *"no action"* ]]
  [ ! -d docs/briefing ]
}

@test "fixture: empty legacy file (zero-byte) → no-op exit 0" {
  : > docs/BRIEFING.md
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no action"* ]]
  [ ! -d docs/briefing ]
}

# ---------------------------------------------------------------------------
# Idempotency direction 2: tree already present → no-op exit 0
# ---------------------------------------------------------------------------

@test "fixture: tree already present → no-op exit 0, legacy untouched" {
  mkdir -p docs/briefing
  cat > docs/briefing/README.md <<'EOF'
# Project Briefing
existing content
EOF
  cat > docs/BRIEFING.md <<'EOF'
# Legacy
## Hooks
content
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already migrated"* ]]
  [ -f docs/BRIEFING.md ]
  run grep -F 'existing content' docs/briefing/README.md
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Core migration: synthetic legacy file with three H2 sections
# ---------------------------------------------------------------------------

@test "fixture: three-section legacy → three topic files + README index" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

Preamble content here.

## Hooks

Hook entry one.

## Releases

Release entry one.

## Plugin Distribution

Plugin distribution entry one.
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f docs/briefing/README.md ]
  [ -f docs/briefing/hooks.md ]
  [ -f docs/briefing/releases.md ]
  [ -f docs/briefing/plugin-distribution.md ]
  run grep -F 'Hook entry one.' docs/briefing/hooks.md
  [ "$status" -eq 0 ]
  run grep -F 'Release entry one.' docs/briefing/releases.md
  [ "$status" -eq 0 ]
  run grep -F 'Plugin distribution entry one.' docs/briefing/plugin-distribution.md
  [ "$status" -eq 0 ]
  run grep -F '[hooks.md](./hooks.md)' docs/briefing/README.md
  [ "$status" -eq 0 ]
  run grep -F 'Preamble content here.' docs/briefing/README.md
  [ "$status" -eq 0 ]
}

@test "fixture: migration retires legacy under date-stamped suffix" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Hooks

Hook content.
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -f docs/BRIEFING.md ]
  run bash -c 'ls docs/BRIEFING.md.migrated-* 2>/dev/null'
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

# ---------------------------------------------------------------------------
# Idempotent re-run after successful migration: tree present → no-op
# ---------------------------------------------------------------------------

@test "fixture: re-run after successful migration → no-op exit 0" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Hooks

Hook content.
EOF
  bash "$SCRIPT" >/dev/null
  # Second run sees the tree, no-ops, and does NOT re-process the
  # already-retired legacy file.
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already migrated"* ]]
}

# ---------------------------------------------------------------------------
# Slug collision: two H2 sections with the same heading text
# ---------------------------------------------------------------------------

@test "fixture: duplicate H2 headings → second slug gets -2 suffix" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Hooks

First hooks section.

## Hooks

Second hooks section.
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f docs/briefing/hooks.md ]
  [ -f docs/briefing/hooks-2.md ]
  run grep -F 'First hooks section.' docs/briefing/hooks.md
  [ "$status" -eq 0 ]
  run grep -F 'Second hooks section.' docs/briefing/hooks-2.md
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Code-fence awareness: H2 inside a fenced block must NOT be promoted
# ---------------------------------------------------------------------------

@test "fixture: H2 inside fenced code block → not promoted to topic marker" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Real Topic

Real content.

```bash
## This looks like H2 but is inside a fence
echo "do not promote"
```

More real content after the fence.

## Second Real Topic

Second real content.
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # Only two topic files — the fenced ## did NOT create a third.
  [ -f docs/briefing/real-topic.md ]
  [ -f docs/briefing/second-real-topic.md ]
  [ ! -f "docs/briefing/this-looks-like-h2-but-is-inside-a-fence.md" ]
  # The fenced ## line is preserved inside real-topic.md.
  run grep -F '## This looks like H2 but is inside a fence' docs/briefing/real-topic.md
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Dry-run: prints plan, does NOT write
# ---------------------------------------------------------------------------

@test "fixture: --dry-run prints plan and does NOT write tree" {
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Hooks

Hook content.
EOF
  run bash "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"hooks"* ]]
  [ ! -d docs/briefing ]
  [ -f docs/BRIEFING.md ]
}

# ---------------------------------------------------------------------------
# --force: re-runs even when tree already exists
# ---------------------------------------------------------------------------

@test "fixture: --force overrides tree-present idempotency guard" {
  mkdir -p docs/briefing
  echo "# stale" > docs/briefing/README.md
  cat > docs/BRIEFING.md <<'EOF'
# Project Briefing

## Hooks

Hook content.
EOF
  run bash "$SCRIPT" --force
  [ "$status" -eq 0 ]
  [ -f docs/briefing/hooks.md ]
  run grep -F 'Migrated from legacy' docs/briefing/README.md
  [ "$status" -eq 0 ]
}
