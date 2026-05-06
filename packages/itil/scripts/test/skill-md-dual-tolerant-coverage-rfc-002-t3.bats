#!/usr/bin/env bats

# @rfc RFC-002 T3 — Bats fixture audit + dual-tolerant assertions
# @adr ADR-031 (Problem-ticket directory layout — per-state subdirs)
# @adr ADR-051 (load-bearing-from-the-start — each SKILL-prescribed
#   enumeration pipeline ships with a behavioural enforcement test
#   exercised against per-state-layout synthetic fixtures, not later
#   by graceful drift discovery during the T5 migration cutover)
# @adr ADR-052 (behavioural-bats default — these tests run the actual
#   shell pipelines the SKILL.md sites prescribe against synthetic
#   fixtures and assert observable enumeration. They do NOT structurally
#   grep SKILL.md prose for the dual-pattern string, which would be
#   P081-class structural-test-disguised-as-behavioural and was
#   explicitly excluded from T2 per architect finding 3)
# @adr ADR-014 (single-purpose: one mechanical contract — the
#   SKILL-prescribed pipelines compose with per-state-layout fixtures)
# @adr ADR-060 (Phase 1 Slice 5 forward-dogfood — T3 commit grain)
# @problem P069 (driving — flat layout unskimmable; the migration this
#   contract guards is the relief)
# @problem P081 (no structural-grep on SKILL.md content — this test
#   is the behavioural alternative)
# @jtbd JTBD-001 (extended scope — multi-commit RFC-grain coordinated
#   change governance; T3 is one of 11 RFC-002 sub-tasks; behavioural
#   coverage is how per-edit governance stays trustworthy across the
#   migration window)
# @jtbd JTBD-006 (work-backlog-AFK — dual-tolerant pipelines preserve
#   AFK-loop continuity during the T2-to-T6 migration window; without
#   this contract, mid-migration AFK iterations silently miss tickets
#   in the un-migrated layout half)
# @jtbd JTBD-008 (decompose-fix-into-coordinated-changes — RFC-002 T3
#   is the load-bearing test artefact for the coordinated-change
#   sub-workstream; visible as an RFC-002-T3 entity rather than
#   diffusing across 14 existing files per JTBD review)
# @jtbd JTBD-101 (extend-the-suite — adopter projects consuming
#   @windyroad/itil at the T2-shipped state must enumerate correctly
#   against their flat-layout tickets AND post-auto-migration per-state
#   tickets; T3 proves both halves)
#
# Contract: every SKILL.md call site updated in T2 (commit `0795e91`,
# 14 SKILL.md surfaces) prescribes a shell pipeline of canonical shape:
#
#   ls docs/problems/*.<state>.md docs/problems/<state>/*.md 2>/dev/null
#   ls docs/problems/*.md         docs/problems/*/*.md       2>/dev/null
#   ls docs/problems/<ID>-*.md    docs/problems/*/<ID>-*.md  2>/dev/null
#
# T2's `dual-tolerant-glob-rfc-002-t2.bats` exercises the canonical
# pattern shapes generically. T3 extends that coverage to the
# end-to-end SKILL-prescribed PIPELINES — the next-ID compute pipeline
# (`ls X Y | sed | grep -oE | sort -n | tail -1`), the multi-state
# union form (4-pathspec for open + known-error backlog scan), the
# verifying-state filter as run-retro Step 4a dispatches it, and the
# brace-expansion ID + state-set form report-upstream uses. Each test
# runs the pipeline against three synthetic fixture shapes (flat-only,
# per-state-only, mixed) and asserts observable enumeration.
#
# T6 (post-T5 verification) drops the flat-layout half. This test
# updates at T6 to single-pattern (per-state only), NOT removed — the
# contract narrows but the behavioural enforcement remains.
#
# CONTRACT NOTE: when one half of the dual-pattern has zero matches
# in the current fixture (single-layout fixtures), `ls X Y 2>/dev/null`
# exits nonzero — the unmatched literal pathname propagates to ls's
# argv and `2>/dev/null` only suppresses the stderr noise, not the
# exit code. SKILL.md call sites MUST treat STDOUT emptiness as the
# canonical "no tickets" signal, NOT exit code zero. Test assertions
# probe stdout content via `run` (which absorbs the exit code into
# `$status`); `$status` is asserted only in the empty-fixture and
# missing-ID cases where nonzero exit is the intended contract.

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
**WSJF**: 5.0
EOF
  cat > docs/problems/101-bar.known-error.md <<'EOF'
# Problem 101: Bar
**Status**: Known Error
**WSJF**: 4.0
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
**WSJF**: 6.0
EOF
  cat > docs/problems/known-error/201-bar2.md <<'EOF'
# Problem 201: Bar2
**Status**: Known Error
**WSJF**: 3.5
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

# ── Pipeline 1: Next-ID compute (manage-problem Step 3 + capture-problem Step 3)
#
# SKILL.md prescribes the recursive local_max formula:
#   ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null \
#     | sed 's|.*/||' \
#     | grep -oE '^[0-9]+' \
#     | sort -n | tail -1
#
# Architect finding 2 (T2): the recursive enumeration MUST contribute
# tickets from BOTH layouts to max-ID, otherwise a per-state ticket at
# ID 204 is invisible to a flat-only-enumerating capture-problem and
# the next ID re-allocates an already-taken slot. T3 exercises the
# pipeline against per-state-only AND mixed fixtures to prove the
# dual-pathspec composes with the downstream sed/grep/sort pipeline.
# ──────────────────────────────────────────────────────────────────────────────

@test "next-ID pipeline: flat-only fixture yields max ID 104" {
  build_flat_layout
  run bash -c "ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1"
  [ "$output" = "104" ]
}

@test "next-ID pipeline: per-state-only fixture yields max ID 204" {
  build_per_state_layout
  run bash -c "ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1"
  [ "$output" = "204" ]
}

@test "next-ID pipeline: mixed fixture yields max ID 204 (recursive enumeration spans both layouts)" {
  # Architect finding 2: a per-state ticket at ID 204 MUST contribute
  # to max-ID even when flat-layout 104 also exists. Drop the per-state
  # half of the dual-pathspec and this test fails — capture-problem
  # would re-allocate ID 105 instead of advancing to 205.
  build_mixed_layout
  run bash -c "ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1"
  [ "$output" = "204" ]
}

@test "next-ID pipeline: empty fixture yields empty result" {
  run bash -c "ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1"
  [ -z "$output" ]
}

# ── Pipeline 2: Open + known-error multi-state union
#   (work-problems Step 1, list-problems live scan)
#
# SKILL.md prescribes the 4-pathspec form:
#   ls docs/problems/*.open.md docs/problems/*.known-error.md \
#      docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null
#
# This is wider than T2's single-state filter — it unions two states
# across two layouts in one ls invocation. The prove-out shape: the
# union enumerates open + known-error from BOTH layouts and excludes
# verifying / parked / closed from BOTH layouts.
# ──────────────────────────────────────────────────────────────────────────────

@test "open+known-error union: per-state-only fixture enumerates 200 and 201" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
  [[ "$output" == *"known-error/201-bar2.md"* ]]
}

@test "open+known-error union: per-state-only fixture excludes verifying/parked/closed" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null'
  [[ "$output" != *"202-baz2"* ]]
  [[ "$output" != *"203-qux2"* ]]
  [[ "$output" != *"204-quux2"* ]]
}

@test "open+known-error union: mixed fixture enumerates all four (100, 101, 200, 201)" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null'
  [[ "$output" == *"100-foo.open.md"* ]]
  [[ "$output" == *"101-bar.known-error.md"* ]]
  [[ "$output" == *"open/200-foo2.md"* ]]
  [[ "$output" == *"known-error/201-bar2.md"* ]]
}

@test "open+known-error union: mixed fixture excludes verifying/parked/closed from BOTH layouts" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null'
  [[ "$output" != *"102-baz"* ]]
  [[ "$output" != *"103-qux"* ]]
  [[ "$output" != *"104-quux"* ]]
  [[ "$output" != *"202-baz2"* ]]
  [[ "$output" != *"203-qux2"* ]]
  [[ "$output" != *"204-quux2"* ]]
}

# ── Pipeline 3: Verifying-state filter (run-retro Step 4a)
#
# SKILL.md prescribes:
#   ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null
#
# run-retro Step 4a uses this to surface verification-close candidates
# from the session-context evidence. T3 proves the pipeline finds the
# verifying ticket in BOTH layouts independently.
# ──────────────────────────────────────────────────────────────────────────────

@test "verifying-state pipeline: flat-only fixture finds 102" {
  build_flat_layout
  run bash -c 'ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null'
  [[ "$output" == *"102-baz.verifying.md"* ]]
}

@test "verifying-state pipeline: per-state-only fixture finds 202" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null'
  [[ "$output" == *"verifying/202-baz2.md"* ]]
}

@test "verifying-state pipeline: mixed fixture finds 102 AND 202" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null'
  [[ "$output" == *"102-baz.verifying.md"* ]]
  [[ "$output" == *"verifying/202-baz2.md"* ]]
}

# ── Pipeline 4: ID-anchored ticket lookup
#   (manage-problem ticket-by-ID, link-incident, close-incident,
#   transition-problem Step 2, capture-problem Step 2 dup-detect)
#
# SKILL.md prescribes:
#   ls docs/problems/<ID>-*.md docs/problems/*/<ID>-*.md 2>/dev/null
#
# T3 exercises lookup of a known-existing ID across both layouts and
# the missing-ID case (asserts empty stdout + nonzero exit).
# ──────────────────────────────────────────────────────────────────────────────

@test "ID-anchored pipeline: per-state-only fixture finds 200 in subdir" {
  build_per_state_layout
  run bash -c 'ls docs/problems/200-*.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "ID-anchored pipeline: mixed fixture finds 100 (flat) and 200 (per-state)" {
  build_mixed_layout
  run bash -c 'ls docs/problems/100-*.md docs/problems/*/100-*.md 2>/dev/null'
  [[ "$output" == *"100-foo.open.md"* ]]
  run bash -c 'ls docs/problems/200-*.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "ID-anchored pipeline: missing ID yields empty stdout + nonzero exit" {
  build_per_state_layout
  run bash -c 'ls docs/problems/999-*.md docs/problems/*/999-*.md 2>/dev/null'
  [ -z "$output" ]
  [ "$status" -ne 0 ]
}

# ── Pipeline 5: Brace-expansion ID + state-set (report-upstream)
#
# SKILL.md prescribes:
#   ls docs/problems/<ID>-*.{open,known-error,verifying,closed}.md \
#      docs/problems/*/<ID>-*.md 2>/dev/null
#
# The flat half restricts to a state-set (excludes parked); the
# per-state half is unrestricted (no state filter). T3 proves the
# brace expansion composes with the per-state pathspec without false
# positives across the migration window.
# ──────────────────────────────────────────────────────────────────────────────

@test "brace-id-state pipeline: per-state-only fixture finds 200 via per-state half" {
  build_per_state_layout
  run bash -c 'ls docs/problems/200-*.{open,known-error,verifying,closed}.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "brace-id-state pipeline: mixed fixture finds flat 100 (open) and per-state 200 (open)" {
  build_mixed_layout
  run bash -c 'ls docs/problems/100-*.{open,known-error,verifying,closed}.md docs/problems/*/100-*.md 2>/dev/null'
  [[ "$output" == *"100-foo.open.md"* ]]
  run bash -c 'ls docs/problems/200-*.{open,known-error,verifying,closed}.md docs/problems/*/200-*.md 2>/dev/null'
  [[ "$output" == *"open/200-foo2.md"* ]]
}

@test "brace-id-state pipeline: parked ticket excluded from flat half but matched in per-state half" {
  # Flat 103 is parked (excluded by the brace state-set); per-state 203
  # is parked but the per-state pathspec is state-unrestricted, so it
  # MUST surface. This is the contract architect finding 2 codifies.
  build_mixed_layout
  run bash -c 'ls docs/problems/103-*.{open,known-error,verifying,closed}.md docs/problems/*/103-*.md 2>/dev/null'
  [[ "$output" != *"103-qux.parked.md"* ]]
  run bash -c 'ls docs/problems/203-*.{open,known-error,verifying,closed}.md docs/problems/*/203-*.md 2>/dev/null'
  [[ "$output" == *"parked/203-qux2.md"* ]]
}

# ── Pipeline 6: Closed-ticket ID-anchored lookup
#   (review-problems Step 5: closed-section rendering uses
#   `docs/problems/*.closed.md docs/problems/closed/*.md`)
# ──────────────────────────────────────────────────────────────────────────────

@test "closed-ticket pipeline: mixed fixture enumerates flat 104 and per-state 204" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.closed.md docs/problems/closed/*.md 2>/dev/null'
  [[ "$output" == *"104-quux.closed.md"* ]]
  [[ "$output" == *"closed/204-quux2.md"* ]]
}

@test "closed-ticket pipeline: per-state-only fixture excludes other-state subdirs" {
  build_per_state_layout
  run bash -c 'ls docs/problems/*.closed.md docs/problems/closed/*.md 2>/dev/null'
  [[ "$output" == *"closed/204-quux2.md"* ]]
  [[ "$output" != *"open/200"* ]]
  [[ "$output" != *"known-error/201"* ]]
  [[ "$output" != *"verifying/202"* ]]
  [[ "$output" != *"parked/203"* ]]
}

# ── Pipeline 7: Parked-state filter (review-problems Step 3 parked section)
# ──────────────────────────────────────────────────────────────────────────────

@test "parked-state pipeline: mixed fixture enumerates flat 103 and per-state 203" {
  build_mixed_layout
  run bash -c 'ls docs/problems/*.parked.md docs/problems/parked/*.md 2>/dev/null'
  [[ "$output" == *"103-qux.parked.md"* ]]
  [[ "$output" == *"parked/203-qux2.md"* ]]
}

# ── Composition: ls-with-2>/dev/null exit-code semantics
# (mirrors T2's empty-fixture contract; proves the SKILL.md contract
# remains "stdout content is the signal, not exit code")
# ──────────────────────────────────────────────────────────────────────────────

@test "all pipelines: empty fixture produces empty stdout across every shape" {
  run bash -c "ls docs/problems/*.md docs/problems/*/*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1"
  [ -z "$output" ]
  run bash -c 'ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null'
  [ -z "$output" ]
  run bash -c 'ls docs/problems/*.verifying.md docs/problems/verifying/*.md 2>/dev/null'
  [ -z "$output" ]
  run bash -c 'ls docs/problems/100-*.md docs/problems/*/100-*.md 2>/dev/null'
  [ -z "$output" ]
}
