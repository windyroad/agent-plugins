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
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  HOOK_DIR="$TEST_DIR/hook"
  mkdir -p "$HOOK_DIR"
  ln -s "$SCRIPT_DIR/lib" "$HOOK_DIR/lib"
  VERDICT_FILE="$TEST_DIR/jtbd-verdict"
  HOOK="$HOOK_DIR/jtbd-mark-reviewed.sh"
  copy_hook "$SCRIPT_DIR/jtbd-mark-reviewed.sh" "$HOOK" "$VERDICT_FILE"
  cd "$TEST_DIR"
  SESSION_ID="test-session-$$"
  MARKER="/tmp/jtbd-reviewed-${SESSION_ID}"
  PLAN_MARKER="/tmp/jtbd-plan-reviewed-${SESSION_ID}"
  HASH_FILE="/tmp/jtbd-reviewed-${SESSION_ID}.hash"
  rm -f "$MARKER" "$PLAN_MARKER" "$HASH_FILE"
}

copy_hook() {
  python3 - "$@" <<'PY'
from pathlib import Path
import shlex
import sys

source, destination, verdict = sys.argv[1:]
text = Path(source).read_text()
needle = 'VERDICT_FILE="/tmp/jtbd-verdict"'
if text.count(needle) != 1:
    sys.exit("Cannot isolate hook verdict: expected exactly one assignment")
Path(destination).write_text(text.replace(needle, "VERDICT_FILE=" + shlex.quote(verdict)))
PY
}

@test "fixture refuses missing or duplicate verdict assignments before writing a hook" {
  for content in 'VERDICT_FILE=/tmp/jtbd-verdict' $'VERDICT_FILE="/tmp/jtbd-verdict"\nVERDICT_FILE="/tmp/jtbd-verdict"'; do
    printf '%s\n' "$content" > "$TEST_DIR/source"
    run copy_hook "$TEST_DIR/source" "$TEST_DIR/copy" "$VERDICT_FILE"
    [ "$status" -ne 0 ]
    [ ! -e "$TEST_DIR/copy" ]
  done
}

@test "fixture preserves verdict paths containing shell metacharacters" {
  printf '%s\n' 'VERDICT_FILE="/tmp/jtbd-verdict"' 'printf "%s" "$VERDICT_FILE"' > "$TEST_DIR/source"
  local path="$TEST_DIR/quote' and \$(touch injected) & |"
  copy_hook "$TEST_DIR/source" "$TEST_DIR/copy" "$path"
  run bash "$TEST_DIR/copy"
  [ "$status" -eq 0 ]
  [ "$output" = "$path" ]
  [ ! -e injected ]
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  rm -f "$MARKER" "$PLAN_MARKER" "$HASH_FILE" "$VERDICT_FILE"
}

# Helper: pipe a realistic PostToolUse:Agent JSON to the hook.
run_hook() {
  local subagent="$1"
  local prompt="${2:-}"
  local response="${3:-}"
  python3 - "$subagent" "$prompt" "$response" "$SESSION_ID" <<'PY' | bash "$HOOK"
import json
import sys

subagent, prompt, response, session_id = sys.argv[1:]
print(json.dumps({
    "session_id": session_id,
    "tool_name": "Agent",
    "tool_input": {"subagent_type": subagent, "prompt": prompt},
    "tool_response": {"content": [{"type": "text", "text": response}]},
}))
PY
}

# --- Path support: docs/jtbd directory (preferred) ---

@test "uses docs/jtbd directory when present (creates marker + hash)" {
  mkdir -p docs/jtbd/solo-developer
  echo "# Persona" > docs/jtbd/solo-developer/persona.md
  echo "# Index" > docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  [ -f "$MARKER" ]
  [ -f "$HASH_FILE" ]
  [ "$(cat "$HASH_FILE")" != "missing" ]
  [ -n "$(cat "$HASH_FILE")" ]
}

@test "directory hash excludes README.md (only persona/job files contribute)" {
  mkdir -p docs/jtbd
  echo "# Index" > docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"
  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'
  HASH_README_ONLY="$(cat "$HASH_FILE")"

  rm -f "$HASH_FILE" "$MARKER"
  echo "different content" >> docs/jtbd/README.md
  echo "PASS" > "$VERDICT_FILE"
  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'
  HASH_README_CHANGED="$(cat "$HASH_FILE")"

  # Changing README.md alone must not change the hash — README is excluded.
  [ "$HASH_README_ONLY" = "$HASH_README_CHANGED" ]
}

# --- Path support: docs/jtbd/ is the sole canonical layout (ADR-008 Option 3, P019) ---

@test "does NOT store a review hash when only legacy docs/JOBS_TO_BE_DONE.md exists (P019)" {
  # Legacy single-file layout — the mark-reviewed hook must exit early
  # without storing a hash, because the enforce hook cannot gate the
  # project until it runs /wr-jtbd:update-guide to migrate to docs/jtbd/.
  mkdir -p docs
  echo "# Jobs" > docs/JOBS_TO_BE_DONE.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  # No marker, no hash file — the gate is inactive on legacy-layout projects.
  [ ! -f "$MARKER" ]
  [ ! -f "$HASH_FILE" ]
}

@test "hashes docs/jtbd/ when both layouts coexist (legacy single-file is ignored, P019)" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "# legacy jobs" > docs/JOBS_TO_BE_DONE.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  # The directory-derived hash must NOT equal the standalone-file hash —
  # proves the hook did not consult the legacy file.
  DIR_HASH="$(cat "$HASH_FILE")"
  FILE_HASH=$(cat docs/JOBS_TO_BE_DONE.md \
              | (md5sum 2>/dev/null || md5 -r 2>/dev/null || shasum 2>/dev/null) \
              | cut -d' ' -f1)
  [ "$DIR_HASH" != "$FILE_HASH" ]
}

# --- Verdict handling ---

@test "FAIL verdict does not authorise edits or plans" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "FAIL" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "missing verdict file fails closed" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "verdict file is consumed (removed) after hook runs" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent"

  [ ! -f "$VERDICT_FILE" ]
}

@test "marked recommendation output does not consume an edit verdict or authorise markers" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" $'RECOMMENDATION REVIEW\nReview these options.' "malformed output"

  [ -f "$VERDICT_FILE" ]
  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
  [ ! -f "$HASH_FILE" ]
}

@test "inline recommendation heading binds an unmarked completion to recommendation mode" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "Review these options." $'**JTBD Recommendation Review: PASS**\n\nAligned.'

  [ -f "$VERDICT_FILE" ]
  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
  [ ! -f "$HASH_FILE" ]
}

@test "stale edit verdict is consumed only by a later edit review completion" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" $'RECOMMENDATION REVIEW\nReview these options.' "JTBD Recommendation Review: PASS"
  run_hook "wr-jtbd:agent" "PRE-EDIT review." "**JTBD Review: PASS**"

  [ ! -f "$VERDICT_FILE" ]
  [ -f "$MARKER" ]
  [ -f "$PLAN_MARKER" ]
  [ -f "$HASH_FILE" ]
}

@test "later-line recommendation text does not misclassify an edit review" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" $'PRE-EDIT review.\nRECOMMENDATION REVIEW is quoted context.' $'**JTBD Review: PASS**\n**JTBD Recommendation Review: PASS** was quoted.'

  [ ! -f "$VERDICT_FILE" ]
  [ -f "$MARKER" ]
  [ -f "$PLAN_MARKER" ]
}

@test "stale PASS with malformed current edit output fails closed" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." "malformed output"

  [ ! -f "$VERDICT_FILE" ]
  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "stale PASS with current ISSUES FOUND output fails closed" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: ISSUES FOUND**\n\nMisaligned.'

  [ ! -f "$VERDICT_FILE" ]
  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "inline PASS with file FAIL fails closed" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "FAIL" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  [ ! -f "$VERDICT_FILE" ]
  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "PASS prefix does not authorise edits or plans" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." "**JTBD Review: PASSING**"

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "PASS heading with suffix text does not authorise edits or plans" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." "**JTBD Review: PASS** extra"

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "unbolded PASS does not authorise edits or plans" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." "JTBD Review: PASS"

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
}

@test "unterminated PASS heading does not authorise edits or plans" {
  mkdir -p docs/jtbd
  echo "# job" > docs/jtbd/job.md
  echo "PASS" > "$VERDICT_FILE"

  run_hook "wr-jtbd:agent" "PRE-EDIT review." "**JTBD Review: PASS"

  [ ! -f "$MARKER" ]
  [ ! -f "$PLAN_MARKER" ]
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

  run_hook "jtbd-lead" "PRE-EDIT review." $'**JTBD Review: PASS**\n\nAligned.'

  [ -f "$MARKER" ]
}
