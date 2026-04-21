#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must extract cost + usage metadata
# from each iteration's `claude -p --output-format json` response, surface it
# in the per-iteration Step 6 progress line, and aggregate it in the ALL_DONE
# Output Format as a dedicated "Session Cost" section.
#
# Rationale: the subprocess-boundary dispatch lands per-iteration cost in the
# JSON response alongside `.result`. Without an explicit extraction contract,
# that data is invisible to the user even though it's already emitted. Cost
# logging lets the user calibrate AFK loop sizing on return (e.g. "max out
# the token usage" direction 2026-04-21 needs a feedback loop).
#
# Structural assertion — Permitted Exception under ADR-005 + ADR-037 (SKILL.md
# is the contract document). A behavioural harness that exercises the `jq`
# extraction against a fixture JSON is a potential follow-up; out of scope
# for this doc-lint pass.
#
# @problem P084
# @jtbd JTBD-006
#
# Cross-reference:
#   P084 (iteration worker has no Agent tool) — parent ticket; cost logging
#     is an additive observability overlay on P084's shipped subprocess
#     dispatch.
#   ADR-032 (governance skill invocation patterns) — subprocess-boundary
#     sub-pattern; `--output-format json` parse shape is already pinned.
#   ADR-026 (agent output grounding) — Session Cost section cites its source
#     so downstream audits can distinguish measured-actual from estimated.
#   ADR-037 (skill testing strategy) — contract-assertion pattern.
#   JTBD-006 (Progress the Backlog While I'm Away) — "clear summary when I
#     return" documented outcome includes cost/token traceability.

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md Step 5 extracts .total_cost_usd from iteration JSON response" {
  # Cost per iteration lives in the same JSON blob as .result; parsing it
  # costs nothing more than a jq call the orchestrator already needs for
  # ITERATION_SUMMARY.
  run grep -nE 'total_cost_usd' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 extracts usage token fields from iteration JSON response" {
  # input_tokens / output_tokens / cache_creation_input_tokens /
  # cache_read_input_tokens are the four usage fields that give a full
  # accounting. Cache-read is the key signal for reuse across subprocess
  # invocations in the same Bash session.
  run grep -nE 'input_tokens|output_tokens|cache_creation_input_tokens|cache_read_input_tokens' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 names jq (or equivalent) as the extraction mechanism" {
  # jq is already implicit in `--output-format json` consumption; naming it
  # in the SKILL.md prevents bespoke sed/awk reimplementations.
  run grep -nE '\\bjq\\b|JSON parser|JSON extraction' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 scopes the extraction to named fields only (PII guard)" {
  # Architect advisory 2026-04-21: the JSON response also carries session_id,
  # model, stop_reason, etc. that should NOT be surfaced in user-visible
  # output. The extraction list must be explicit so future contributors
  # don't unconsciously broaden it.
  run grep -niE 'extract only|only the fields|do not (surface|log|emit)|scoped to (the )?named fields|explicit field list' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 6 per-iteration progress line includes cost marker" {
  # Example progress line in Step 6 should show the (cost, duration, tokens)
  # suffix so contributors see the target format.
  run grep -nE '\$[0-9]+\.[0-9]+.{0,40}(tokens|iteration|s,)' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Output Format includes a Session Cost section" {
  # ALL_DONE summary aggregates per-iteration cost across the run. The
  # section renders in every ALL_DONE — interactive OR AFK — because it's
  # output-side, not a decision branch.
  run grep -nE '^### Session Cost|## Session Cost|Session Cost.{0,40}Total' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Output Format Session Cost table includes cache-read reuse signal" {
  # Cache-read is the signal for "warm-cache savings across subprocess
  # invocations in the same Bash session" — empirically observed 65-147K
  # cache-read tokens on probes 2-4 during the P084 probe sequence. Making
  # this visible to the user helps them reason about AFK loop cost dynamics.
  run grep -niE 'cache.?read|cache reuse|reuse signal|cache hit' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Output Format Session Cost section cites its data source (ADR-026)" {
  # Architect advisory: the Session Cost numbers are measured-actual (from
  # each iteration's claude -p JSON output), not estimates. Name the source
  # so audit / downstream-tooling can trust the numbers.
  run grep -niE 'extracted from.{0,80}(claude -p|--output-format json|iteration)|source:.{0,80}claude -p|measured.{0,40}(iteration|subprocess)' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Session Cost section renders in both interactive and AFK modes" {
  # JTBD-006 Rule 6 check: Session Cost is pure output, no AskUserQuestion,
  # no policy-authorised action. Must render identically in both modes so
  # AFK users see the same summary on return.
  run grep -niE 'Session Cost.{0,160}(regardless|both|interactive.{0,40}AFK|AFK.{0,40}interactive)|output-side|no decision branch' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
