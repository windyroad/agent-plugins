#!/usr/bin/env bats
# Contract-assertion bats for work-problems Step 0 session-continuity
# detection (the extension per P109).
#
# Per ADR-037 SKILL.md is a contract document; these assertions check the
# contract strings the skill prose authoritatively pins for the Step 0
# session-continuity detection pass. Follows the split pattern established
# by work-problems-preflight.bats (fetch/divergence assertions) — this file
# covers the second invariant family: prior-session partial-work signals +
# interactive/AFK routing.
#
# Cross-reference:
#   @problem P109 (work-problems preflight does not detect prior-session partial-work state)
#   ADR-019 (AFK orchestrator preflight — extension scope)
#   ADR-013 (structured user interaction — Rule 1 interactive, Rule 6 non-interactive fail-safe)
#   ADR-032 (governance skill invocation patterns — .afk-run-state/iter-*.json contract)
#   ADR-037 (skill testing strategy — contract-assertion framing)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away — session-continuity detection belongs in Step 0)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md Step 0 cites P109 (session-continuity driver)" {
  # Contract criterion: the extension is traceable to its driver ticket.
  run grep -n "P109" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the session-continuity detection pass" {
  # Contract criterion: the new detection pass is named as a discrete
  # concept in the Step 0 prose (not buried under the divergence check).
  run grep -niE "session.continuity" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates untracked docs/decisions/*.proposed.md signal" {
  # Contract criterion: drafted-but-unlanded ADRs are one of the signals
  # the session-continuity detection pass MUST enumerate.
  run grep -nE "docs/decisions/\*\.proposed\.md|docs/decisions/.*\.proposed\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates untracked docs/problems/*.md signal" {
  # Contract criterion: drafted-but-unlanded problem tickets are enumerated
  # as one of the session-continuity signals. The preflight section already
  # references docs/problems/ for the scan surface; the test checks that
  # the Preflight section names untracked problem files as a detection
  # signal (not merely the backlog-scan surface).
  run grep -niE "untracked.*docs/problems|docs/problems/.*untracked" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates .afk-run-state/iter-*.json error signal" {
  # Contract criterion: the .afk-run-state/iter-*.json subprocess artefacts
  # (per ADR-032) with is_error: true or api_error_status >= 400 are named
  # as a signal.
  run grep -nE "\.afk-run-state/iter-\*\.json|\.afk-run-state/iter-.*\.json" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the is_error / api_error_status fields" {
  # Contract criterion: the specific JSON fields the detection pass reads
  # are named verbatim so the contract is unambiguous.
  run grep -niE "is_error.*true|api_error_status" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates stale .claude/worktrees signal" {
  # Contract criterion: stale subagent worktrees are a detection signal.
  # Detection only (not cleanup/mutation — per P109 scope boundary).
  run grep -nE "\.claude/worktrees" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates git worktree list signal for claude/* branches" {
  # Contract criterion: git worktree list is the detection mechanism for
  # claude/* branches adjacent to the .claude/worktrees/ dir check.
  run grep -niE "git worktree list" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 enumerates uncommitted SKILL.md / source / ADR edits signal" {
  # Contract criterion: mid-authoring source edits are a detection signal.
  run grep -niE "uncommitted.*(SKILL\.md|source|ADR)|(SKILL\.md|source|ADR).*uncommitted" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 routes interactive via AskUserQuestion" {
  # Contract criterion per ADR-013 Rule 1: the interactive branch uses
  # AskUserQuestion.
  run grep -nE "AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 interactive branch names the 4 option categories" {
  # Contract criterion: the AskUserQuestion 4-option shape is pinned so
  # adopters know the branch set. Resume / discard / leave-and-lower-priority / halt.
  run grep -niE "resume" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "discard" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "leave.*lower.priority|leave.and.lower.priority" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 routes AFK via halt-with-report per ADR-013 Rule 6" {
  # Contract criterion per ADR-013 Rule 6: the non-interactive / AFK branch
  # halts with a report rather than silently choosing.
  run grep -niE "halt.with.report|halt with report|Rule 6 fail.safe" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 cites ADR-013 Rule 6 for AFK fail-safe" {
  # Contract criterion: ADR-013 Rule 6 is named as the authority for the
  # non-interactive halt branch.
  run grep -nE "ADR-013.*Rule 6|Rule 6.*ADR-013" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 emits a structured Prior-Session State report" {
  # Contract criterion: the AFK halt branch surfaces a structured report,
  # not a free-text prose blurb — so the user can act on it on return.
  run grep -niE "Prior.Session State" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers session-continuity" {
  # Contract criterion: the decision-matrix section surfaces the new branch
  # so adopters of the skill can find the AFK default without reading
  # Step 0 prose in full.
  run grep -niE "Prior.session partial.work|session.continuity.*dirty|Prior-Session State.*AFK" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
