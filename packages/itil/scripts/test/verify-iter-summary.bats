#!/usr/bin/env bats

# @problem P335 — AFK iter subprocess over-claims completion in
# ITERATION_SUMMARY notes / commit message while on-disk Confirmation
# checkboxes remain `[ ]`. Step 6.75 currently runs `git status --porcelain`
# only — catches commit-didn't-land but not commit-landed-with-false-claim.
# This verifier closes the gap.
#
# Contract: `verify-iter-summary.sh` (or PATH shim
# `wr-itil-verify-iter-summary`) reads:
#   $1 = commit_sha (the iter's landed commit)
#   $2 = path to a file containing the ITERATION_SUMMARY notes field
#   $3 = repo root (optional; defaults to `git rev-parse --show-toplevel`)
#
# Mechanism:
#   1. Extract `ADR-NNN` identifiers from the commit message
#      (`git log -1 --format=%B <sha>`) AND the notes file.
#   2. For each identifier, resolve to `docs/decisions/<NNN>-*.md` (any
#      status suffix — `.proposed.md` / `.accepted.md` / etc).
#   3. Detect completion-claim signal in commit message OR notes (regex
#      family: `all .*(green|complete|done|checked|ticked)`,
#      `\([a-z]\)\s*[-–]\s*\([a-z]\)\s+(green|complete|all)`,
#      `all\s+Confirmation\s+items`).
#   4. When signal present AND any `- [ ]` item exists in the cited ADR's
#      `## Confirmation` section → emit `OVER-CLAIM:` line and exit 1.
#   5. Otherwise exit 0.
#
# Exit codes:
#   0 = OK (no signal, or signal-and-all-items-checked, or no ADR referenced)
#   1 = OVER-CLAIM detected
#   2 = invocation error (missing args, bad sha, etc)
#
# @adr ADR-032 (subprocess-boundary trust contract — orchestrator decides
#               trust boundary; verifier is the policy-authorised silent check)
# @adr ADR-049 (Plugin-bundled scripts ship as bin/ PATH shims;
#               wr-itil-verify-iter-summary is the shim name)
# @adr ADR-052 (Behavioural tests for skill testing; this bats covers
#               the OVER-CLAIM detection behaviour, not script structure)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — orchestrator-side
#                 verification keeps AFK loop integrity intact when iter
#                 self-certification fails)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/verify-iter-summary.sh"
  FIXTURE_DIR="$(mktemp -d)"
  cd "$FIXTURE_DIR"
  git init -q
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p docs/decisions
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# Helper: create a fake ADR with the given Confirmation-section body.
_make_adr() {
  local num="$1" status="$2" confirmation_body="$3"
  cat > "docs/decisions/${num}-fake-adr.${status}.md" <<EOF
# ${num}. Fake ADR

## Status
${status}

## Confirmation
${confirmation_body}
EOF
}

# Helper: commit a file with the given message; return the SHA via stdout.
_commit_with_message() {
  local message="$1"
  echo "dummy" > dummy.txt
  git add dummy.txt
  git commit -q -m "$message"
  git log -1 --format=%H
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "verify-iter-summary: script exists" {
  [ -f "$SCRIPT" ]
}

@test "verify-iter-summary: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Exit 0: no completion-claim signal ──────────────────────────────────────

@test "verify-iter-summary: notes mention ADR but no completion-claim signal → OK" {
  _make_adr 077 proposed "- [ ] **(a) Item A**
- [ ] **(b) Item B**"
  local sha; sha=$(_commit_with_message "feat(architect): ADR-077 Slice 1 partial work")
  echo "P327 progressed; partial slice landed; further work needed for Confirmation items (a)+(b)." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "verify-iter-summary: no ADR referenced at all → OK" {
  local sha; sha=$(_commit_with_message "fix(itil): rename helper variable")
  echo "Bugfix; no governance impact." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Exit 0: signal present but all items checked ────────────────────────────

@test "verify-iter-summary: completion-claim signal AND all items checked → OK" {
  _make_adr 077 proposed "- [x] **(a) Item A**
- [x] **(b) Item B**"
  local sha; sha=$(_commit_with_message "feat(architect): ADR-077 — all Confirmation items complete")
  echo "All ADR-077 Confirmation items green." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Exit 1: P335 witness shape — claim "all green" + unchecked items ────────

@test "verify-iter-summary: claim 'all green at source' + unchecked items → OVER-CLAIM" {
  # The P335 session 8 iter 1 witness shape: commit message claims (a)–(j)
  # green; all 10 boxes are `[ ]`.
  _make_adr 077 proposed "- [ ] **(a) Agent prompt amendment**
- [ ] **(b) Generator script**
- [ ] **(c) Initial compendium**
- [ ] **(d) create-adr integration**
- [ ] **(e) capture-adr integration**
- [ ] **(f) review-decisions integration**
- [ ] **(g) CI drift bats**
- [ ] **(h) Pre-commit hook**
- [ ] **(i) ADR-031 assertion**
- [ ] **(j) No silent regression**"
  local sha; sha=$(_commit_with_message "feat(architect): ADR-077 Slice 3 — all (a)-(j) green at source")
  echo "ADR-077 Slice 3 — Confirmation items (a)-(j) all green at source." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "OVER-CLAIM"
  echo "$output" | grep -q "ADR-077"
}

@test "verify-iter-summary: claim 'all Confirmation items complete' + unchecked → OVER-CLAIM" {
  _make_adr 100 accepted "- [x] **(a) Done**
- [ ] **(b) Still pending**"
  local sha; sha=$(_commit_with_message "feat: ADR-100 — all Confirmation items complete")
  echo "Implementation finished." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "OVER-CLAIM"
}

@test "verify-iter-summary: signal only in notes (not commit msg) + unchecked → OVER-CLAIM" {
  _make_adr 200 proposed "- [ ] **(a) Missing**"
  local sha; sha=$(_commit_with_message "feat: ADR-200 progress")
  # Note completion signal lives in notes, not the commit subject.
  echo "All Confirmation items ticked for ADR-200." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "OVER-CLAIM"
  echo "$output" | grep -q "ADR-200"
}

# ── Invocation errors ───────────────────────────────────────────────────────

@test "verify-iter-summary: missing notes file → invocation error" {
  local sha; sha=$(_commit_with_message "init")
  run "$SCRIPT" "$sha" /nonexistent/notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 2 ]
}

@test "verify-iter-summary: missing sha → invocation error" {
  echo "" > notes.txt
  run "$SCRIPT" "" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 2 ]
}

# ── Multi-ADR case ──────────────────────────────────────────────────────────

@test "verify-iter-summary: two ADRs cited — one clean, one over-claim → OVER-CLAIM only on the bad one" {
  _make_adr 050 accepted "- [x] **(a) Clean**"
  _make_adr 060 proposed "- [ ] **(a) Dirty**"
  local sha; sha=$(_commit_with_message "feat: ADR-050 + ADR-060 — all green")
  echo "Both ADRs progressed; all items green." > notes.txt

  run "$SCRIPT" "$sha" notes.txt "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "ADR-060"
}
