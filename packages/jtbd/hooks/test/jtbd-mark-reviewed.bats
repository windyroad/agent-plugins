#!/usr/bin/env bats

# Tests for jtbd-mark-reviewed.sh — verifies the PostToolUse:Agent hook
# creates session markers and stores the right policy-path hash when
# wr-jtbd:agent (or legacy jtbd-lead) returns a PASS verdict.
#
# Per ADR-005 (P011): assertions are functional — execute the hook with
# mock JSON, assert on side-effects (marker files, hash file contents).
# Source-grep assertions for "the script mentions docs/jtbd" were
# removed because they passed even when the surrounding code path was
# unreachable.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-mark-reviewed.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  SESSION_ID="test-session-$$"
  MARKER="/tmp/jtbd-reviewed-${SESSION_ID}"
  PLAN_MARKER="/tmp/jtbd-plan-reviewed-${SESSION_ID}"
  HASH_FILE="/tmp/jtbd-reviewed-${SESSION_ID}.hash"
  VERDICT_FILE="/tmp/jtbd-verdict"
  rm -f "$MARKER" "$PLAN_MARKER" "$HASH_FILE" "$VERDICT_FILE"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  rm -f "$MARKER" "$PLAN_MARKER" "$HASH_FILE" "$VERDICT_FILE"
}

# Helper: pipe a PostToolUse:Agent JSON to the hook for the given subagent.
run_hook() {
  local subagent="$1"
  local json="{\"tool_input\":{\"subagent_type\":\"${subagent}\"},\"session_id\":\"${SESSION_ID}\"}"
  echo "$json" | bash "$HOOK"
}

# --- Path support: docs/jtbd directory (preferred) ---

@test "uses docs/jtbd directory when present (creates marker + hash)" {
  mkdir -p docs/jtbd/solo-developer
  echo "# Persona" > docs/jtbd/solo-developer/persona.md
  echo "# Index" > docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
  [ "$(cat "$HASH_FILE")" != "missing" ]
  [ -n "$(cat "$HASH_FILE")" ]
}

@test "directory hash excludes README.md (only persona/job files contribute)" {
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"
  run_hook "wr-jtbd:agent"
  HASH_README_ONLY="$(cat "$HASH_FILE")"

  rm -f "$HASH_FILE" "$MARKER"
  echo "different content" >> docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"
  run_hook "wr-jtbd:agent"
  HASH_README_CHANGED="$(cat "$HASH_FILE")"

  # Changing README.md alone must not change the hash — README is excluded.
  [ "$HASH_README_ONLY" = "$HASH_README_CHANGED" ]
}

# --- Path support: docs/JOBS_TO_BE_DONE.md fallback (legacy) ---

@test "uses docs/JOBS_TO_BE_DONE.md when docs/jtbd does not exist" {
  mkdir -p docs
  echo "# Jobs" > docs/JOBS_TO_BE_DONE.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
  [ "$(cat "$HASH_FILE")" != "missing" ]

  # Hash should match the file's content hash. _hashcmd in
  # gate-helpers.sh prefers md5sum, falls back to md5 -r, then shasum.
  EXPECTED=$(cat docs/JOBS_TO_BE_DONE.md \
             | (md5sum 2>/dev/null || md5 -r 2>/dev/null || shasum 2>/dev/null) \
             | cut -d' ' -f1)
  [ "$(cat "$HASH_FILE")" = "$EXPECTED" ]
}

@test "prefers docs/jtbd over docs/JOBS_TO_BE_DONE.md when both exist" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "# legacy jobs" > docs/JOBS_TO_BE_DONE.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  # The directory-derived hash must NOT equal the standalone-file hash.
  DIR_HASH="$(cat "$HASH_FILE")"
  FILE_HASH=$(cat docs/JOBS_TO_BE_DONE.md \
              | (md5sum 2>/dev/null || md5 -r 2>/dev/null || shasum 2>/dev/null) \
              | cut -d' ' -f1)
  [ "$DIR_HASH" != "$FILE_HASH" ]
}

# --- Verdict handling ---

@test "FAIL verdict does NOT create review marker (but plan marker still set)" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "FAIL" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  [ ! -f "$MARKER" ]
  [ -f "$PLAN_MARKER" ]
}

@test "missing verdict file allows marker (backward compat)" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md

  run_hook "wr-jtbd:agent"

  [ -f "$MARKER" ]
}

@test "verdict file is consumed (removed) after hook runs" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  [ ! -f "$VERDICT_FILE" ]
}

# --- Subagent routing ---

@test "ignores unrelated subagent (no marker created)" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-architect:agent"

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "matches legacy jtbd-lead subagent name" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "jtbd-lead"

  [ -f "$MARKER" ]
}
