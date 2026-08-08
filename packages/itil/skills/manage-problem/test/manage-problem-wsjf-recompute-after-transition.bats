#!/usr/bin/env bats

# @problem P477 — WSJF is `(Severity × Status Multiplier) / Effort Divisor`
# and the multiplier changes with status (Open 1.0, Known Error 2.0). Both
# re-score surfaces computed WSJF BEFORE the Open → Known Error auto-
# transition and nothing recomputed afterwards, so the persisted value kept
# the Open multiplier and the ticket ranked at half value in both the ticket
# body and docs/problems/README.md.
#
# Contract: in BOTH re-score surfaces — `/wr-itil:manage-problem` Step 9b and
# `/wr-itil:review-problems` Step 2 — the auto-transition to Known Error MUST
# be sequenced BEFORE the WSJF calculation, so the multiplier applied is the
# one the ticket's post-transition status carries.
#
# The sibling assertion in
# `packages/itil/skills/transition-problems/test/transition-problems-contract.bats`
# covers the three transition pre-flight checklists (clause presence across
# the ADR-010 copy-not-move surfaces). This file covers the ordering, which
# is the half of the fix that actually changes the computed number: a future
# edit that moves the calculation back ahead of the transition passes every
# assertion in that file and re-opens P477.
#
# The assertion is a line-number comparison over the two SKILL.md files. It is
# a structural check by the documented Permitted Exception for cross-file /
# ordering drift detection in `*-contract`-class tests — the behavioural
# coverage of the recompute itself lives in
# `packages/itil/scripts/test/check-wsjf-arithmetic.bats`, which drives the
# real script over synthetic ticket fixtures per ADR-052.
#
# @adr ADR-010 (copy-not-move — each surface hosts its own copy)
# @adr ADR-022 (multiplier tracks current lifecycle status)
# @adr ADR-052 (behavioural tests by default; ordering drift is the exception)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — the AFK loop selects
#   by WSJF, so a halved value silently mis-sequences the queue)

setup() {
  SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  MANAGE_SKILL="${SKILLS_DIR}/manage-problem/SKILL.md"
  REVIEW_SKILL="${SKILLS_DIR}/review-problems/SKILL.md"
}

# Line number of the auto-transition list item within a re-score step.
transition_line() {
  grep -nE '^[0-9]+\. \*\*Auto-transition to Known Error\*\*' "$1" | head -1 | cut -d: -f1
}

# Line number of the WSJF calculation list item within the same step.
calculate_line() {
  grep -nE '^[0-9]+\. \*\*Calculate WSJF\*\*' "$1" | head -1 | cut -d: -f1
}

@test "manage-problem Step 9b auto-transitions before it calculates WSJF (P477)" {
  [ -f "$MANAGE_SKILL" ]
  transition="$(transition_line "$MANAGE_SKILL")"
  calculate="$(calculate_line "$MANAGE_SKILL")"
  [ -n "$transition" ]
  [ -n "$calculate" ]
  # Calculating first persists the stale Open multiplier — the P477 defect.
  [ "$transition" -lt "$calculate" ]
}

@test "review-problems Step 2 auto-transitions before it calculates WSJF (P477)" {
  [ -f "$REVIEW_SKILL" ]
  transition="$(transition_line "$REVIEW_SKILL")"
  calculate="$(calculate_line "$REVIEW_SKILL")"
  [ -n "$transition" ]
  [ -n "$calculate" ]
  [ "$transition" -lt "$calculate" ]
}

@test "both re-score surfaces state that the multiplier comes from the post-transition status" {
  # The ordering alone is silent about WHY. Without this, a reader
  # re-sequencing the list for tidiness has nothing telling them the order
  # is load-bearing.
  for f in "$MANAGE_SKILL" "$REVIEW_SKILL"; do
    run grep -icE "status the ticket holds now, after step" "$f"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
  done
}

@test "both re-score surfaces point at the arithmetic self-check" {
  for f in "$MANAGE_SKILL" "$REVIEW_SKILL"; do
    run grep -cF "wr-itil-check-wsjf-arithmetic" "$f"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
  done
}
