#!/usr/bin/env bats

# P065 / ADR-036: pre-publish-intake-gate.sh PreToolUse:Bash hook must deny
# `npm publish` (and changesets-release `gh pr merge`) when the four intake
# files are missing, unless the project has opted out via the decline
# marker (`.claude/.intake-scaffold-declined`) or the user sets the
# `INTAKE_BYPASS=1` env override.
#
# Required intake files (per ADR-036 Detection step 5):
#   .github/ISSUE_TEMPLATE/config.yml
#   .github/ISSUE_TEMPLATE/problem-report.yml
#   SECURITY.md
#   SUPPORT.md
#   CONTRIBUTING.md
#
# Per feedback_behavioural_tests.md (P081): behavioural assertions —
# simulate the hook's payload on stdin and assert on emitted JSON
# permissionDecision and exit status. No source-grep on hook content.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/pre-publish-intake-gate.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  unset INTAKE_BYPASS
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  unset INTAKE_BYPASS
}

# Helper: simulate the PreToolUse:Bash payload on stdin.
run_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# Helper: scaffold all five intake files in the test directory.
scaffold_all_intake() {
  mkdir -p .github/ISSUE_TEMPLATE
  echo "blank_issues_enabled: false" > .github/ISSUE_TEMPLATE/config.yml
  echo "name: Report a problem" > .github/ISSUE_TEMPLATE/problem-report.yml
  echo "# Security Policy" > SECURITY.md
  echo "# Getting Help" > SUPPORT.md
  echo "# Contributing" > CONTRIBUTING.md
}

# Helper: set the decline marker.
decline() {
  mkdir -p .claude
  : > .claude/.intake-scaffold-declined
}

# --- Allow paths ---

@test "allow: npm publish proceeds when all five intake files are present" {
  scaffold_all_intake
  run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: missing intake but decline marker present permits publish" {
  decline
  run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: missing intake but INTAKE_BYPASS=1 permits publish (checked BEFORE existence)" {
  # Architect direction: INTAKE_BYPASS must short-circuit before the
  # existence check fires.
  INTAKE_BYPASS=1 run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: non-publish bash commands are out of scope" {
  run run_bash_hook "ls -la"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: non-Bash tool calls are out of scope" {
  json='{"tool_name":"Read","tool_input":{"file_path":"foo"}}'
  run bash -c "echo '$json' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Deny paths ---

@test "deny: npm publish with no intake files, no marker, no bypass" {
  run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"intake"* ]]
  [[ "$output" == *"scaffold-intake"* ]]
}

@test "deny: npm publish with partial intake (3 of 5) still denies" {
  mkdir -p .github/ISSUE_TEMPLATE
  echo "blank_issues_enabled: false" > .github/ISSUE_TEMPLATE/config.yml
  echo "name: Report a problem" > .github/ISSUE_TEMPLATE/problem-report.yml
  echo "# Security Policy" > SECURITY.md
  # SUPPORT.md and CONTRIBUTING.md missing
  run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny message names the recovery affordances (skill, marker, bypass)" {
  run run_bash_hook "npm publish"
  [ "$status" -eq 0 ]
  [[ "$output" == *"scaffold-intake"* ]]
  [[ "$output" == *"INTAKE_BYPASS"* ]]
  [[ "$output" == *".intake-scaffold-declined"* ]]
}

# --- gh pr merge on changeset-release/* ---

@test "deny: gh pr merge of a changeset-release/* PR with missing intake" {
  # ADR-036 Trigger 2 also matches gh pr merge against changeset-release/*
  # branches (the changesets release-PR pattern).
  run run_bash_hook "gh pr merge 42 --repo windyroad/example --branch changeset-release/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: gh pr merge of a non-changeset PR is out of scope" {
  # Only the changeset-release/* branch pattern is in scope; a regular
  # feature-branch merge does not flip the publish boundary.
  run run_bash_hook "gh pr merge 99 --branch feature/foo"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}
