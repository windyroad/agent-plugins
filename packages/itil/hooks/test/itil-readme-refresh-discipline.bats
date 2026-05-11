#!/usr/bin/env bats

# P165: itil-readme-refresh-discipline.sh PreToolUse:Bash hook must deny
# `git commit` invocations whose staged set includes any
# docs/problems/<state>/NNN-*.md (or legacy docs/problems/NNN-*.md) but
# does NOT also stage docs/problems/README.md. Hook-level enforcement
# closes the P094/P062 README-refresh enforcement gap — iter subprocess
# commits could previously ship a `.verifying.md` rename or Status edit
# without the corresponding Verification Queue / WSJF Rankings row in
# the README.
#
# Detection logic (per ticket Fix Strategy + architect verdict):
#   On `git commit` invocations, run `git diff --staged --name-only`.
#   If any path matches docs/problems/(open|verifying|closed|known-error|parked)/NNN-*.md
#   OR docs/problems/NNN-*.<state>.md (legacy flat layout) AND
#   docs/problems/README.md is NOT staged, emit a deny with recovery
#   directive `git add docs/problems/README.md` and the P165 cite.
#   Allow when README is staged alongside, when no ticket file is
#   staged at all (README-only / retro-only / ADR-only / source-only
#   commits), or when BYPASS_README_REFRESH_GATE=1 is set.
#
# Per ADR-005 (plugin testing strategy) — hook bats live under
# packages/<plugin>/hooks/test/ and assert behaviour on emitted JSON,
# not source content. Per P081 — no source-grep on hook text. Simulate
# the PreToolUse:Bash payload on stdin and assert on the emitted
# permissionDecision.
#
# Per ADR-045 Pattern 1 (silent-on-pass) — allow paths emit 0 bytes.
# Per ADR-045 deny-band — deny messages target ~245 bytes; cap at 300.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/itil-readme-refresh-discipline.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  mkdir -p docs/problems/open docs/problems/verifying docs/problems/closed \
           docs/problems/known-error docs/problems/parked docs/retros \
           docs/decisions packages/itil/skills/foo .changeset
  echo "seed" > seed.txt
  git add seed.txt
  git -c commit.gpgsign=false commit --quiet -m "initial"
  # README must exist for the "stage it alongside" tests to work.
  echo "# Problem Backlog" > docs/problems/README.md
  git add docs/problems/README.md
  git -c commit.gpgsign=false commit --quiet -m "seed readme"
  unset BYPASS_README_REFRESH_GATE
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  unset BYPASS_README_REFRESH_GATE
}

run_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# --- Trap detection: the canonical P165 shape ---

@test "deny: staged docs/problems/open/NNN-*.md without README refresh triggers deny on git commit" {
  echo "# Problem 999" > docs/problems/open/999-some-new-ticket.md
  git add docs/problems/open/999-some-new-ticket.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P165"* ]]
}

@test "deny: staged docs/problems/verifying/NNN-*.md without README refresh triggers deny" {
  echo "# Problem 999 verifying" > docs/problems/verifying/999-some-ticket.md
  git add docs/problems/verifying/999-some-ticket.md
  run run_bash_hook "git commit -m 'fix'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P165"* ]]
}

@test "deny: staged docs/problems/closed/NNN-*.md without README refresh triggers deny" {
  echo "# Problem 999 closed" > docs/problems/closed/999-some-ticket.md
  git add docs/problems/closed/999-some-ticket.md
  run run_bash_hook "git commit -m 'close'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny: staged docs/problems/known-error/NNN-*.md without README refresh triggers deny" {
  echo "# Problem 999 known error" > docs/problems/known-error/999-some-ticket.md
  git add docs/problems/known-error/999-some-ticket.md
  run run_bash_hook "git commit -m 'transition'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny: staged docs/problems/parked/NNN-*.md without README refresh triggers deny" {
  echo "# Problem 999 parked" > docs/problems/parked/999-some-ticket.md
  git add docs/problems/parked/999-some-ticket.md
  run run_bash_hook "git commit -m 'park'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny: staged legacy flat-layout docs/problems/NNN-*.<state>.md without README triggers deny" {
  echo "# Problem 999 flat" > docs/problems/999-some-legacy.open.md
  git add docs/problems/999-some-legacy.open.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny message names offending ticket ID, recovery command, P165 cite" {
  echo "# Problem 999" > docs/problems/open/999-some-new-ticket.md
  git add docs/problems/open/999-some-new-ticket.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  # Deny names the ticket as `P<NNN>` (not full path — see hook
  # comment: full descriptive ticket slugs exceed ADR-045 deny-band).
  [[ "$output" == *"P999"* ]]
  [[ "$output" == *"docs/problems/README.md"* ]]
  [[ "$output" == *"P165"* ]]
}

@test "deny message stays under ADR-045 deny-band (<300 bytes)" {
  echo "# Problem 999" > docs/problems/open/999-some-ticket.md
  git add docs/problems/open/999-some-ticket.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 300 ]
}

# --- Allow paths: each non-trap shape must NOT deny ---

@test "allow: staged ticket file WITH docs/problems/README.md allows the commit" {
  echo "# Problem 999" > docs/problems/open/999-new.md
  echo "# Problem Backlog updated" > docs/problems/README.md
  git add docs/problems/open/999-new.md docs/problems/README.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: README-only commit (reconcile-readme path) allows without ticket change" {
  echo "# Problem Backlog reconciled" > docs/problems/README.md
  git add docs/problems/README.md
  run run_bash_hook "git commit -m 'docs: reconcile readme'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: retro-only commit allows without ticket change or README refresh" {
  echo "# Retro 2026-05-11" > docs/retros/2026-05-11-iter.md
  git add docs/retros/2026-05-11-iter.md
  run run_bash_hook "git commit -m 'docs(retros): iter'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: ADR-only commit allows without ticket change or README refresh" {
  echo "# ADR 999" > docs/decisions/999-some-decision.proposed.md
  git add docs/decisions/999-some-decision.proposed.md
  run run_bash_hook "git commit -m 'docs(decisions): adr-999'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: source-only commit (packages/) allows without ticket change or README refresh" {
  echo "skill body" > packages/itil/skills/foo/SKILL.md
  git add packages/itil/skills/foo/SKILL.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: BYPASS_README_REFRESH_GATE=1 env var allows ticket commit without README refresh" {
  echo "# Problem 999" > docs/problems/open/999-bypass.md
  git add docs/problems/open/999-bypass.md
  BYPASS_README_REFRESH_GATE=1 run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: docs/problems/README-history.md edit alone does NOT trigger deny (not a ticket file)" {
  echo "# History" > docs/problems/README-history.md
  git add docs/problems/README-history.md
  run run_bash_hook "git commit -m 'docs: rotate history'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Allow path silence (ADR-045 Pattern 1) ---

@test "allow path emits 0 bytes (ADR-045 Pattern 1 silent-on-pass)" {
  echo "# Retro" > docs/retros/2026-05-11-iter.md
  git add docs/retros/2026-05-11-iter.md
  run run_bash_hook "git commit -m 'docs'"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

# --- Tool-name and command-shape filters ---

@test "allow: non-Bash tool exits 0 without deny" {
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: Bash command that is NOT git commit (e.g., git status) bypasses detection" {
  echo "# Problem 999" > docs/problems/open/999-x.md
  git add docs/problems/open/999-x.md
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Mixed staged sets ---

@test "deny: staged ticket + ADR (no README) still triggers deny (mixed surface dominance)" {
  echo "# Problem 999" > docs/problems/open/999-x.md
  echo "# ADR 999" > docs/decisions/999-x.proposed.md
  git add docs/problems/open/999-x.md docs/decisions/999-x.proposed.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: staged ticket + ADR + README allows (mixed set with README)" {
  echo "# Problem 999" > docs/problems/open/999-x.md
  echo "# ADR 999" > docs/decisions/999-x.proposed.md
  echo "# Problem Backlog updated" > docs/problems/README.md
  git add docs/problems/open/999-x.md docs/decisions/999-x.proposed.md docs/problems/README.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# --- Parse / fail-open contracts ---

@test "allow: empty JSON exits 0 without deny (fail-open on parse-incomplete)" {
  run bash -c "echo '{}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: outside a git work tree exits 0 without deny (fail-open)" {
  cd "$ORIG_DIR"
  TEMP_NONGIT=$(mktemp -d)
  cd "$TEMP_NONGIT"
  run run_bash_hook "git commit -m 'feat'"
  cd "$TEST_DIR"
  rm -rf "$TEMP_NONGIT"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}
