#!/usr/bin/env bats
# P211 — work-problems Step 5 iteration-prompt-body must EXPLICITLY re-ground
# each iter's dispatch prompt against the CURRENT ticket only. The orchestrator
# MUST NOT inline the ticket's `## Fix Strategy` text verbatim, and MUST NOT
# leak prior-iter content (prior ticket ID, prior Fix Strategy text, prior
# outcome reason, prior commit SHA, prior retro findings) across iterations.
#
# Reported as inbound from downstream consumer bbstats (their P194) on
# 2026-05-15; covered by ADR-076 Origin field tier.
#
# Behavioural mechanism for the bug: AFK iter subprocesses inherit a stale
# design-rationale frame and may attempt fixes anchored on the wrong ticket's
# intent. Workaround the ticket names: user-in-the-loop verification after
# each iter, reading the subprocess's commit and checking whether it cites
# the correct ticket's design rationale — a manual-policing burden the AFK
# loop is meant to eliminate. JTBD-006 (Progress the Backlog While I'm Away)
# is load-bearing: the audit trail and trust in the AFK loop degrade if iters
# work the wrong ticket's design rationale.
#
# tdd-review: structural-permitted (justification: SKILL.md is the named
# contract document under ADR-052; behavioural alternative would require a
# synthetic `claude -p` iter dispatch harness that simulates multiple
# sequential iters and asserts no cross-iter prompt-body content leakage —
# that harness sits outside the skill layer and depends on the Anthropic CLI
# binary. Same Permitted Exception precedent as
# `work-problems-step-5-iter-changeset-required.bats:14-21`,
# `work-problems-step-5-delegation.bats:99-105`, and the P083 / P086 / P089
# ScheduleWakeup / retro / stdin-redirect fixtures in the same directory.
# P012 is the harness-gap ticket).
#
# @problem P211
# @problem P012
# @jtbd JTBD-006
# @jtbd JTBD-001
#
# Cross-reference:
#   P211 — this ticket (orchestrator carries prior-ticket Fix Strategy into
#     next iter's dispatch context — pollutes the new iter's framing)
#   bbstats#194 — inbound report from downstream consumer
#   ADR-014 (single-commit grain — fix lands as one coherent commit)
#   ADR-032 (governance skill invocation patterns — AFK iteration-isolation
#     wrapper; re-grounding is a clarification of that isolation intent)
#   ADR-052 (behavioural tests default; structural-permitted with comment)
#   ADR-076 (inbound-reported problems rank ahead via sort tier — Origin
#     field stamping)
#   JTBD-006 (Progress the Backlog While I'm Away) — load-bearing

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites P211 (re-grounding driver) in Related section" {
  # Self-documenting contract — a future contributor weakening the
  # re-grounding constraint reads P211 and understands why it exists.
  run grep -nE 'P211' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration prompt body names re-grounding per iter explicitly" {
  # The "self-contained" opener at line 510 is the existing weaker form; the
  # stricter "re-ground per iter" phrasing names the construction invariant
  # the orchestrator MUST satisfy on each iter dispatch. P211's bug shape is
  # exactly the case where "self-contained" was read as a subprocess-side
  # property only, with the orchestrator-side construction leaking prior-iter
  # content into the new iter's prompt body.
  run grep -niE "re.?ground.{0,40}per iter|re.?grounded.{0,40}per iter|per.?iter.{0,40}re.?ground" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iter prompt body forbids inlining Fix Strategy verbatim" {
  # The bug shape: orchestrator reads target ticket's `## Fix Strategy` and
  # cites it verbatim into the iteration subprocess's prompt body. The
  # SKILL.md MUST explicitly forbid this so future contributors understand
  # the subprocess reads Fix Strategy from disk via manage-problem inside
  # its own context.
  run grep -niE "(not|never|MUST NOT|does not).{0,40}inline.{0,40}Fix Strategy|Fix Strategy.{0,40}(not|never|MUST NOT|does not).{0,40}inline|do not.{0,40}cite.{0,40}Fix Strategy.{0,40}verbatim|Fix Strategy.{0,40}verbatim.{0,40}(not|never|forbid)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iter prompt body explicitly forbids prior-iter content leakage" {
  # The cross-iter leakage class names: prior ticket ID, prior Fix Strategy
  # text, prior outcome reason, prior commit SHA, prior retro findings. The
  # SKILL.md MUST name the no-leakage invariant explicitly so the orchestrator
  # main turn's prompt construction is constrained on every iter.
  run grep -niE "(no prior|not.{0,20}prior|prior.?iter.{0,40}(leak|carry|inherit)|leak.{0,40}prior|carry.{0,40}prior.{0,40}iter)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 names template-driven reset-per-iter construction" {
  # The construction shape: template-driven, reset per iter, no global
  # accumulator across iters. This is the structural invariant the
  # orchestrator main turn must satisfy when building each iter's prompt.
  run grep -niE "template.?driven|reset per iter|reset.{0,20}per.{0,20}iter|no.{0,20}(global )?accumulator" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration prompt body cites P211 inline" {
  # The re-grounding clause must cite P211 inline so the contract document
  # is self-documenting — a future contributor removing the clause reads the
  # P211 reference and understands why it exists before deleting it. Same
  # pattern as the P083 / P086 / P146 / P232 inline citations in the same
  # block.
  run grep -nE "re.?ground.{0,200}P211|P211.{0,200}re.?ground|P211.{0,200}Fix Strategy|Fix Strategy.{0,200}P211" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md re-grounding clause sits inside Step 5 iteration prompt body section" {
  # Structural locality: the re-grounding clause must live INSIDE Step 5's
  # Iteration prompt body section (after the "self-contained" opener at
  # line 510), not free-floating elsewhere in SKILL.md. Locality matters
  # because the rule is read alongside the rest of the prompt-body contract,
  # and a future contributor refactoring Step 5 must encounter it inline.
  # Assertion shape: the line containing "re-ground" sits after the line
  # containing "Iteration prompt body" and before the line containing
  # "Return-summary contract".
  iter_line=$(grep -nE '^\*\*Iteration prompt body' "$SKILL_FILE" | head -1 | cut -d: -f1)
  # Tightened regex: require the literal hyphenated form "re-ground" /
  # "re-grounded" / "re-grounding" so partial-substring matches like
  # "foreground" (line 33) don't satisfy the assertion.
  reground_line=$(grep -niE "re-ground(ed|ing)?" "$SKILL_FILE" | head -1 | cut -d: -f1)
  return_summary_line=$(grep -nE '^\*\*Return-summary contract' "$SKILL_FILE" | head -1 | cut -d: -f1)
  [ -n "$iter_line" ]
  [ -n "$reground_line" ]
  [ -n "$return_summary_line" ]
  [ "$reground_line" -gt "$iter_line" ]
  [ "$reground_line" -lt "$return_summary_line" ]
}
