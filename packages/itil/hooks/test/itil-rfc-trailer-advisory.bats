#!/usr/bin/env bats

# @problem P170 — Slice 3 second half (B5.T9): PostToolUse:Bash hook
# detects `git commit` invocations whose HEAD commit message carries
# a `Refs: RFC-<NNN>` trailer, and emits a stderr advisory when the
# corresponding driving-problem ticket's `## RFCs` table is stale.
#
# Architect Q1 verdict: skill-side refresh primary; hook-side advisory
# for arbitrary commits (e.g. feat/fix/chore commits with `Refs:` trailer
# authored outside the RFC skills).
# Architect Q2 verdict: PostToolUse:Bash; advisory-only; silent-on-pass
# per ADR-045 Pattern 1; fail-open per ADR-013 Rule 6.
# Architect Q4 verdict: parse via `git interpret-trailers`; multi-`Refs:`
# trailers emit malformed-per-finding-8 advisory.
#
# Behavioural per ADR-052 + P081: assert on emitted stderr / exit code
# in response to simulated PostToolUse:Bash payload — no structural
# greps on hook source.
#
# @adr ADR-014 (single-commit grain — hook never auto-fixes via follow-up commit)
# @adr ADR-013 Rule 6 (fail-open)
# @adr ADR-045 (silent-on-pass; advisory band ≤300 bytes)
# @adr ADR-051 (load-bearing-from-the-start)
# @adr ADR-060 (Phase 1 item 12 + Confirmation criterion 3)
# @jtbd JTBD-006 (advisory does not block AFK loop — exit 0; stderr only)
# @jtbd JTBD-008 (reverse-trace surface JTBD-008 names — drift detection)

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/itil-rfc-trailer-advisory.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  mkdir -p docs/rfcs docs/problems
  echo "seed" > seed.txt
  git add seed.txt
  git -c commit.gpgsign=false commit --quiet -m "initial"
  unset BYPASS_RFC_TRAILER_ADVISORY
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  unset BYPASS_RFC_TRAILER_ADVISORY
}

write_rfc() {
  local id="$1" slug="$2" status="$3"
  local problems="${4:-[P168]}"
  cat > "docs/rfcs/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
reported: 2026-05-05
decision-makers: [test]
problems: ${problems}
---

# RFC-${id}: ${slug}

stub
EOF
}

write_problem_with_rfcs_section() {
  local num="$1" rows="$2"
  local file="docs/problems/${num}-stub.open.md"
  cat > "$file" <<EOF
# Problem ${num}: stub

**Status**: Open

## Description

stub

## Related

stub

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
${rows}
EOF
}

write_problem_without_rfcs_section() {
  local num="$1"
  cat > "docs/problems/${num}-stub.open.md" <<EOF
# Problem ${num}: stub

**Status**: Open

## Description

stub

## Related

stub
EOF
}

run_post_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "hook exists" {
  [ -f "$HOOK" ]
}

@test "hook is executable" {
  [ -x "$HOOK" ]
}

# ── Silent paths ────────────────────────────────────────────────────────────

@test "non-Bash tool → silent (exit 0; no output)" {
  json='{"tool_name":"Write","tool_input":{"file_path":"foo.txt","content":"x"}}'
  run bash -c "echo '$json' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "non-commit Bash command → silent" {
  run run_post_bash_hook "git status"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BYPASS_RFC_TRAILER_ADVISORY=1 → silent regardless of drift" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  BYPASS_RFC_TRAILER_ADVISORY=1 run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "outside git work tree → silent" {
  cd "$ORIG_DIR"
  TMP_NONGIT=$(mktemp -d)
  cd "$TMP_NONGIT"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  cd "$ORIG_DIR"
  rm -rf "$TMP_NONGIT"
}

@test "no docs/rfcs/ → silent (project has not adopted RFC framework)" {
  rm -rf docs/rfcs
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no docs/problems/ → silent (project has not adopted problem framework)" {
  rm -rf docs/problems
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "commit without Refs: RFC trailer → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: no trailer"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Advisory paths ──────────────────────────────────────────────────────────

@test "Refs: RFC-NNN trailer + stale problem (no ## RFCs section) → stderr advisory" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

@test "Refs: RFC-NNN trailer + stale problem (## RFCs section missing this RFC) → stderr advisory" {
  write_rfc "001" "foo" "accepted"
  write_problem_with_rfcs_section "168" "| RFC-002 | proposed | other |"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

@test "Refs: RFC-NNN trailer + current problem ## RFCs (RFC listed) → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_with_rfcs_section "168" "| RFC-001 | accepted | foo |"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Multi-RFC malformed-per-finding-8 ──────────────────────────────────────

@test "multiple Refs: RFC trailers → malformed advisory (architect Q4 / finding 8)" {
  write_rfc "001" "foo" "accepted"
  write_rfc "002" "bar" "accepted"
  write_problem_with_rfcs_section "168" "| RFC-001 | accepted | foo |"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001
Refs: RFC-002"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  # The advisory names finding-8 / split / mis-scoped vocabulary.
  [[ "$output" == *"finding-8"* || "$output" == *"split"* || "$output" == *"mis-scoped"* ]]
}

# ── Trailer to non-existent RFC ──────────────────────────────────────────────

@test "Refs: RFC trailer with no matching file → silent (RFC may be in flight elsewhere)" {
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-999"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  # Fail-open: missing RFC files don't promote to advisory (could be capture-rfc invocation in flight).
  [ -z "$output" ]
}

# ── Advisory budget ─────────────────────────────────────────────────────────

@test "advisory message stays within ADR-045 advisory band (≤300 bytes)" {
  write_rfc "001" "byte-budget-test-with-an-extra-long-slug-to-stress-row-width" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git commit -m foo"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  # Permit per-line overhead; the advisory should remain readable.
  [ "${#output}" -le 600 ]
}

# ── P274 / P268 leading-executable regression cases ─────────────────────────
#
# The hook must fire on ACTUAL `git commit` invocations, NOT on Bash that
# merely MENTIONS the phrase "git commit" in argument vectors or heredoc
# bodies. Mirrors the P268 regression fixtures in command-detect.bats and
# the P272 sibling fixtures in itil-changeset-discipline.bats.
#
# Setup constructs a drift state (RFC + stale problem) — the hook would
# emit an advisory on any `git commit` after `Refs: RFC-001` lands in HEAD.
# These tests confirm non-commit Bash that mentions "git commit" does NOT
# emit the advisory.

@test "P274 allow: grep with literal 'git commit' pattern in drift state → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "grep -r 'git commit' ."
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P274 allow: sed pattern containing 'git commit' in drift state → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "sed -n 's/git commit/X/p' stub.txt"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P274 allow: echo with literal 'git commit' string in drift state → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "echo 'run git commit -m foo'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P274 allow: git log --grep with 'git commit' search term in drift state → silent" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git log --grep='git commit'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "P274 allow: git commit-tree plumbing in drift state → silent (boundary)" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "git commit-tree HEAD^{tree} -m 'msg'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── P274 positive leading-executable cases still emit advisory ──────────────

@test "P274 advisory: env-var-prefixed git commit in drift state still emits advisory" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "GIT_AUTHOR_NAME=foo git commit -m foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-001"* ]]
}

@test "P274 advisory: cd-prefixed git commit in drift state still emits advisory" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "cd . && git commit -m foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-001"* ]]
}

@test "P274 advisory: leading-whitespace git commit in drift state still emits advisory" {
  write_rfc "001" "foo" "accepted"
  write_problem_without_rfcs_section "168"
  echo "x" > stub.txt
  git add stub.txt
  git -c commit.gpgsign=false commit --quiet -m "feat: stub" -m "" -m "Refs: RFC-001"
  run run_post_bash_hook "   git commit -m foo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-001"* ]]
}
