#!/usr/bin/env bats

# P088: run-retro SKILL.md MUST carry a "Never invoke as a background
# agent" anti-pattern clause that warns the agent off the
# Agent(run_in_background: true) surface before it commits to that
# invocation shape. The clause is the user-direction-settled outcome
# of P088 ((b)): foreground /wr-retrospective:run-retro is the only
# supported invocation; `claude -p` subprocess invocation (per P086)
# remains supported because the subprocess has the iteration's context
# naturally; background-agent invocation is deferred pending the
# context-marshalling problem (ADR-032 capture-retro sibling, also
# deferred).
#
# # Test shape: structural contract-assertion (ADR-037 fallback path)
#
# The architect-review verdict on P088 (2026-04-26 iter) was:
# **structural-with-fallback-note, ship this iter**. P081 (architect-
# design / open) flags structural grep tests on SKILL.md prose as
# wasteful; the behavioural alternative would programmatically simulate
# the subagent surface, invoke run-retro, and assert the skill detects
# the surface and emits an anti-pattern denial. That requires
# infrastructure (mock subagent stub, mock Agent-tool harness) which
# does not exist in this repo today.
#
# Per ADR-037's "permitted exception" affordance for prose-only
# contracts, this fixture takes the structural path. P081 follow-up
# tracks the behavioural-test infrastructure build; once P081 lands a
# subagent-surface mock, this file's structural assertions become
# replaceable by behavioural assertions exercising the actual surface
# detection. Until then, structural is the contract.
#
# # @adr ADR-037 fallback — P081 behavioural follow-up tracked.
# # @ticket P088 — run-retro context-visibility settlement.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/run-retro/SKILL.md"
}

@test "run-retro: SKILL.md carries 'Never invoke as a background agent' anti-pattern clause (P088)" {
  run grep -F 'Never invoke as a background agent' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: anti-pattern clause cites P088 as driver" {
  run grep -F 'P088' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: anti-pattern clause names the supported invocation surfaces" {
  # Foreground /wr-retrospective:run-retro — the canonical invocation.
  run grep -F 'Foreground' "$SKILL_MD"
  [ "$status" -eq 0 ]
  # claude -p subprocess invocation — supported per P086 (subprocess has
  # iteration context naturally).
  run grep -F 'claude -p' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'P086' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: anti-pattern clause names the deferred background-agent surface explicitly" {
  # The clause MUST mention Agent(run_in_background: true) or the
  # capture-retro sibling so a future contributor can pattern-match
  # the surface to the warning.
  run grep -E 'run_in_background|capture-retro' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "run-retro: anti-pattern clause appears in the preamble (before Step 1)" {
  # The anti-pattern note belongs near the top of the SKILL so the
  # agent encounters it before committing to an invocation surface.
  # Placement requirement: clause appears before the '### 1. Read the
  # current briefing' section header.
  pos_clause=$(grep -n 'Never invoke as a background agent' "$SKILL_MD" | head -1 | cut -d: -f1)
  pos_step1=$(grep -n '^### 1\. Read the current briefing' "$SKILL_MD" | head -1 | cut -d: -f1)
  [ -n "$pos_clause" ]
  [ -n "$pos_step1" ]
  [ "$pos_clause" -lt "$pos_step1" ]
}

@test "run-retro: anti-pattern clause cross-references ADR-032 capture-retro deferral" {
  # The clause should pin the ADR amendment so a contributor reading
  # the SKILL can trace the deferral decision back to the ADR.
  run grep -F 'ADR-032' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
