#!/usr/bin/env bats

# P125: p057-staging-trap-detect.sh PreToolUse:Bash hook must detect the
# rename-then-edit-without-re-stage pattern that drops post-rename edits
# into the next commit (P057 staging trap).
#
# Detection logic (per ticket Fix Strategy):
#   On `git commit` invocations, run `git diff --staged --name-status`
#   and `git diff --name-only`. If a file appears in --staged with an
#   `R<num>` (rename) status AND in working-tree `git diff --name-only`
#   as modified, the trap shape is present — emit a deny with recovery
#   command `git add <new-path>` and the P057 cite.
#
# Per ADR-005 (plugin testing strategy) — hook bats live under
# packages/<plugin>/hooks/test/ and assert behaviour on emitted JSON,
# not source-content. ADR-037 partitions skill tests separately.
#
# Per feedback_behavioural_tests.md (P081) — no source-grep on hook
# text. Simulate the PreToolUse:Bash payload on stdin and assert on
# the emitted permissionDecision.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/p057-staging-trap-detect.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  echo "original" > foo.md
  git add foo.md
  git -c commit.gpgsign=false commit --quiet -m "initial"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: simulate the PreToolUse:Bash payload on stdin.
run_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# --- Trap detection: the canonical P057 shape ---

@test "deny: rename + post-rename edit without re-stage triggers deny on git commit" {
  git mv foo.md bar.md
  echo "modified content" > bar.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P057"* ]]
  [[ "$output" == *"bar.md"* ]]
  [[ "$output" == *"git add bar.md"* ]]
}

# --- Allow paths: each non-trap shape must NOT deny ---

@test "allow: rename + post-rename edit + re-stage allows the commit" {
  git mv foo.md bar.md
  echo "modified content" > bar.md
  git add bar.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: pure rename without subsequent edit allows the commit" {
  git mv foo.md bar.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: modify-only batch (no rename) allows the commit" {
  echo "modified" > foo.md
  git add foo.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: empty batch (nothing staged, nothing modified) allows the commit" {
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Tool-name and command-shape filters ---

@test "allow: non-Bash tool exits 0 without deny" {
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: Bash command that is NOT git commit (e.g., git status) bypasses detection" {
  # Trap shape IS present in the working tree, but the command isn't
  # `git commit` — the hook only fires on commit invocations.
  git mv foo.md bar.md
  echo "modified" > bar.md
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Parse / fail-open (mirror create-gate.sh's exit-0 on parse failure) ---

@test "allow: empty JSON exits 0 without deny (fail-open on parse-incomplete)" {
  run bash -c "echo '{}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Deny message contract (ADR-038 progressive disclosure budget) ---

@test "deny message names the file, recovery command, and P057 cite" {
  git mv foo.md bar.md
  echo "modified" > bar.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P057"* ]]
  [[ "$output" == *"git add bar.md"* ]]
  [[ "$output" == *"bar.md"* ]]
}

@test "deny message stays under ADR-038 progressive-disclosure budget (<400 bytes)" {
  # Voice-tone draft target is ~245 bytes; allow generous headroom for
  # JSON envelope. Hard cap at 400 keeps the message terse per
  # ADR-038 — fail loudly if the message bloats over time.
  git mv foo.md bar.md
  echo "modified" > bar.md
  run run_bash_hook "git commit -m 'test'"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 400 ]
}
