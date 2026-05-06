#!/usr/bin/env bats

# @rfc RFC-002 T2 — Dual-tolerant SKILL.md glob updates
# @adr ADR-031 (Problem-ticket directory layout)
# @adr ADR-051 (load-bearing-from-the-start — the dual-tolerant glob
#   contract ships with a behavioural enforcement test, not later by
#   graceful drift)
# @adr ADR-052 (behavioural-bats default — this test exercises the
#   glob shape against synthetic fixtures and asserts observable
#   enumeration behaviour; it does NOT structurally grep SKILL.md
#   prose for the dual-pattern string, which would be P081-class
#   structural-test-disguised-as-behavioural)
# @adr ADR-014 (single-purpose: one mechanical contract — dual-glob
#   enumeration parity across both layouts)
# @problem P069 (driving — flat layout unskimmable; the migration this
#   contract guards is the relief)
# @problem P081 (no structural-grep on SKILL.md content — this test
#   is the behavioural alternative)
# @jtbd JTBD-001 (extended scope — multi-commit RFC-grain coordinated
#   change; the test is the cross-skill invariant the SKILL.md edits
#   share)
# @jtbd JTBD-006 (work-backlog-AFK — dual-tolerant globs preserve
#   AFK-loop continuity across the migration window; without this
#   contract, mid-migration loop iterations silently miss tickets in
#   the un-migrated layout)
#
# Contract: SKILL.md enumeration globs of `docs/problems/<state>/...`
# during the RFC-002 migration window MUST match BOTH the flat layout
# (`docs/problems/<NNN>-<title>.<state>.md`) AND the per-state subdir
# layout (`docs/problems/<state>/<NNN>-<title>.md`). The dual-tolerant
# pattern shape is:
#
#   ls docs/problems/*.<state>.md docs/problems/<state>/*.md 2>/dev/null
#
# (with `2>/dev/null` swallowing the no-match error from whichever
# half of the OR currently has zero matches.)
#
# This test exercises the canonical dual-tolerant pattern shapes (state-
# filtered enumeration, ID-anchored lookup, all-state-all-tickets) on
# synthetic fixtures of three shapes (flat-only, per-state-only, mixed).
# Each cross-product asserts non-empty enumeration of every present
# ticket and zero false-positive enumeration of absent tickets.
#
# CONTRACT NOTE: when one half of the dual-glob has zero matches in the
# current fixture (single-layout fixtures), `ls X Y 2>/dev/null` exits
# nonzero — the unmatched literal pathname propagates to ls's argv and
# `2>/dev/null` only suppresses the stderr noise, not the exit code.
# This is CORRECT behaviour — SKILL.md call sites MUST treat STDOUT
# emptiness as the canonical "no tickets" signal, NOT exit code zero.
# Test assertions therefore probe stdout content, not `$status`, except
# in the empty-fixture and missing-ID cases where nonzero exit is the
# intended contract.
#
# T6 (post-T5 verification) drops the flat-layout half. This test
# updates at T6 to single-pattern, NOT removed — the contract becomes
# "per-state layout enumerates correctly" but remains behavioural.

setup() {
  REPO_ROOT="$(mktemp -d)"
  cd "$REPO_ROOT"
  mkdir -p docs/problems
}

teardown() {
  cd /
  rm -rf "$REPO_ROOT"
}

# ── fixture builders ─────────────────────────────────────────────────────────

build_flat_layout() {
  cat > docs/problems/100-foo.open.md <<'EOF'
# Problem 100: Foo
**Status**: Open
EOF
  cat > docs/problems/101-bar.known-error.md <<'EOF'
# Problem 101: Bar
**Status**: Known Error
EOF
  cat > docs/problems/102-baz.verifying.md <<'EOF'
# Problem 102: Baz
**Status**: Verification Pending
EOF
  cat > docs/problems/103-qux.parked.md <<'EOF'
# Problem 103: Qux
**Status**: Parked
EOF
  cat > docs/problems/104-quux.closed.md <<'EOF'
# Problem 104: Quux
**Status**: Closed
EOF
}

build_per_state_layout() {
  mkdir -p docs/problems/open docs/problems/known-error docs/problems/verifying docs/problems/parked docs/problems/closed
  cat > docs/problems/open/200-foo2.md <<'EOF'
# Problem 200: Foo2
**Status**: Open
EOF
  cat > docs/problems/known-error/201-bar2.md <<'EOF'
# Problem 201: Bar2
**Status**: Known Error
EOF
  cat > docs/problems/verifying/202-baz2.md <<'EOF'
# Problem 202: Baz2
**Status**: Verification Pending
EOF
  cat > docs/problems/parked/203-qux2.md <<'EOF'
# Problem 203: Qux2
**Status**: Parked
EOF
  cat > docs/problems/closed/204-quux2.md <<'EOF'
# Problem 204: Quux2
**Status**: Closed
EOF
}

build_mixed_layout() {
  build_flat_layout
  build_per_state_layout
}

# ── Pattern A: state-filtered enumeration ────────────────────────────────────

@test "dual-tolerant state-filtered glob: flat-only fixture enumerates open ticket" {
  build_flat_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null'
  # ls exits nonzero because the per-state half has no match — stdout
  # content is the canonical signal, not exit code.
  [[ "$output" == *"100-foo.open.md"* ]]
}

@test "dual-tolerant state-filtered glob: per-state-only fixture enumerates open ticket" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "dual-tolerant state-filtered glob: mixed fixture enumerates BOTH layouts simultaneously" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null'
  [ "$status" -eq 0 ]
  [[ "$output" == *"100-foo.open.md"* ]]
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "dual-tolerant state-filtered glob: mixed fixture, known-error" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.known-error.md docs/problems/known-error/*.md 2>/dev/null'
  [ "$status" -eq 0 ]
  [[ "$output" == *"101-bar.known-error.md"* ]]
  [[ "$output" == *"known-error/201-bar2.md"* ]]
}

@test "dual-tolerant state-filtered glob: mixed fixture, verifying" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null'
  [ "$status" -eq 0 ]
  [[ "$output" == *"102-baz.verifying.md"* ]]
  [[ "$output" == *"verifying/202-baz2.md"* ]]
}

@test "dual-tolerant state-filtered glob: mixed fixture, parked" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.parked.md docs/problems/parked/*.md 2>/dev/null'
  [ "$status" -eq 0 ]
  [[ "$output" == *"103-qux.parked.md"* ]]
  [[ "$output" == *"parked/203-qux2.md"* ]]
}

@test "dual-tolerant state-filtered glob: state filter excludes other-state tickets in flat layout" {
  build_flat_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null'
  [[ "$output" != *"known-error"* ]]
  [[ "$output" != *"verifying"* ]]
  [[ "$output" != *"parked"* ]]
  [[ "$output" != *"closed"* ]]
}

@test "dual-tolerant state-filtered glob: state filter excludes other-state subdirs in per-state layout" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null'
  # No known-error/, verifying/, parked/, closed/ subdir contents leak into open enumeration.
  [[ "$output" != *"201-bar2.md"* ]]
  [[ "$output" != *"202-baz2.md"* ]]
  [[ "$output" != *"203-qux2.md"* ]]
  [[ "$output" != *"204-quux2.md"* ]]
}

# ── Pattern B: ID-anchored lookup (any state) ────────────────────────────────

@test "dual-tolerant ID-anchored glob: flat-only fixture finds ticket by ID" {
  build_flat_layout
  run bash -c 'ls docs/problems/100-*.md docs/problems/*/100-*.md 2>/dev/null'
  # Single-layout fixture: ls exits nonzero on the unmatched half;
  # stdout content is the contract signal.
  [[ "$output" == *"100-foo.open.md"* ]]
}

@test "dual-tolerant ID-anchored glob: per-state-only fixture finds ticket by ID" {
  build_per_state_layout
  run bash -c 'ls docs/problems/200-*.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "dual-tolerant ID-anchored glob: mixed fixture finds tickets across both layouts" {
  build_mixed_layout
  run bash -c 'ls docs/problems/100-*.md docs/problems/*/100-*.md 2>/dev/null'
  [[ "$output" == *"100-foo.open.md"* ]]
  run bash -c 'ls docs/problems/200-*.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "dual-tolerant ID-anchored glob: missing ID returns empty (status nonzero from ls)" {
  build_flat_layout
  set +e
  result=$(ls docs/problems/999-*.md docs/problems/*/999-*.md 2>/dev/null)
  rc=$?
  set -e
  [ -z "$result" ]
  [ "$rc" -ne 0 ]
}

# ── Pattern C: all-states-all-tickets (next-ID compute, count) ───────────────

@test "dual-tolerant all-tickets glob: flat-only enumerates every ticket regardless of state" {
  build_flat_layout
  run bash -c 'ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null'
  # Single-layout fixture: stdout is contract signal, not $status.
  [[ "$output" == *"100-foo.open.md"* ]]
  [[ "$output" == *"101-bar.known-error.md"* ]]
  [[ "$output" == *"102-baz.verifying.md"* ]]
  [[ "$output" == *"103-qux.parked.md"* ]]
  [[ "$output" == *"104-quux.closed.md"* ]]
}

@test "dual-tolerant all-tickets glob: per-state-only enumerates every ticket regardless of state" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
  [[ "$output" == *"known-error/201-bar2.md"* ]]
  [[ "$output" == *"verifying/202-baz2.md"* ]]
  [[ "$output" == *"parked/203-qux2.md"* ]]
  [[ "$output" == *"closed/204-quux2.md"* ]]
}

@test "dual-tolerant all-tickets glob: mixed fixture enumerates ALL tickets in BOTH layouts" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null'
  [ "$status" -eq 0 ]
  for ticket in 100-foo.open.md 101-bar.known-error.md 102-baz.verifying.md 103-qux.parked.md 104-quux.closed.md \
                open/200-foo2.md known-error/201-bar2.md verifying/202-baz2.md parked/203-qux2.md closed/204-quux2.md; do
    [[ "$output" == *"${ticket}"* ]]
  done
}

@test "dual-tolerant all-tickets next-ID compute: highest ID across both layouts" {
  # Critical for capture-problem next-ID compute (architect finding 2):
  # the next-ID surface MUST recurse so flat-layout 104 and per-state 204
  # both contribute to max-ID; missing the per-state half re-allocates
  # already-taken IDs.
  build_mixed_layout
  result=$(ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null \
    | sed 's/.*\///' \
    | grep -oE '^[0-9]+' \
    | sort -n \
    | tail -1)
  [ "$result" = "204" ]
}

# ── Pattern D: pathspec-pair shell-glob equivalence ──────────────────────────
# git log accepts multiple pathspecs; the dual-tolerant filter is two
# pathspecs side-by-side. We validate this against the working-tree
# semantics that git uses (the same shell-glob shape).

@test "dual-tolerant pathspec pair: each pathspec enumerates its layout half independently" {
  build_mixed_layout
  flat_count=$(ls docs/problems/*.md 2>/dev/null | wc -l | tr -d ' ')
  subdir_count=$(ls docs/problems/*/*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$flat_count" -ge 5 ]
  [ "$subdir_count" -ge 5 ]
}

# ── Pattern E: brace-expansion ID + state-set (report-upstream) ──────────────

@test "dual-tolerant ID + state-set lookup: flat brace expansion + per-state lookup" {
  build_mixed_layout
  # Old shape: ls docs/problems/${ID}-*.{open,known-error,verifying,closed}.md
  # Dual-tolerant: add docs/problems/*/${ID}-*.md as a sibling pathspec.
  run bash -c 'ls docs/problems/100-*.{open,known-error,verifying,closed}.md docs/problems/*/100-*.md 2>/dev/null'
  [[ "$output" == *"100-foo.open.md"* ]]
  run bash -c 'ls docs/problems/200-*.{open,known-error,verifying,closed}.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

# ── Composition: empty-tree fixture exit-code semantics ──────────────────────

@test "dual-tolerant glob: empty fixture produces empty output and ls exits nonzero" {
  # Critical for null-safe `2>/dev/null` semantics — `ls` on a
  # non-matching glob exits nonzero. SKILL.md call sites must rely on
  # `2>/dev/null` to suppress the stderr noise but still treat empty
  # stdout as the canonical "no tickets" signal.
  set +e
  result=$(ls docs/problems/*.open.md docs/problems/open/*.md 2>/dev/null)
  rc=$?
  set -e
  [ -z "$result" ]
  [ "$rc" -ne 0 ]
}
