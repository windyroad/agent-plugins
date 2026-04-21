#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md Step 5 must delegate each iteration
# by shelling out to a `claude -p` subprocess. Subagents spawned via the Agent
# tool cannot themselves call Agent (platform restriction — P084 confirmed by
# three-source evidence 2026-04-21: ToolSearch probe, Claude Code docs at
# code.claude.com/docs/en/subagents.md, empirical invocation runtime error).
# So architect + JTBD + risk-scorer gate markers cannot be set from inside an
# Agent-tool-spawned iteration worker. The subprocess variant has Agent in its
# surface (empirically verified), so governance review runs at full depth and
# the commit gate unlocks natively.
#
# Structural assertion — Permitted Exception to the source-grep ban under
# ADR-005 + ADR-037 (SKILL.md is explicitly a contract document; doc-lint
# contract assertion is the named permitted pattern). Behavioural tests for
# the subprocess integration path would need a full Claude Code session
# harness, which is out of scope for the skill-level contract layer.
#
# @problem P084
# @problem P077
# @problem P086
# @jtbd JTBD-006
# @jtbd JTBD-001
# @jtbd JTBD-101
#
# Cross-reference:
#   P084 (iteration worker has no Agent tool) — driver for the subprocess swap
#   P077 (Step 5 does not delegate to subagent) — prior amendment; subprocess
#     is the refinement of the same AFK iteration-isolation wrapper intent
#   ADR-015 (on-demand assessment skills — Agent-vs-Skill tool precedent)
#   ADR-032 (governance skill invocation patterns — AFK iteration-isolation
#     wrapper sub-pattern; amended with subprocess-boundary variant for P084)
#   ADR-037 (skill testing strategy — contract-assertion pattern)
#   JTBD-006 (Progress the Backlog While I'm Away)
#   JTBD-001 (Enforce Governance Without Slowing Down)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites P084 (subprocess dispatch driver)" {
  run grep -n "P084" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P077 (prior Step 5 delegation amendment)" {
  run grep -n "P077" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 names claude -p as the dispatch mechanism" {
  # The subprocess boundary is how Step 5 achieves iteration isolation post-P084.
  # Bare 'delegate via Agent tool' would re-introduce the tool-surface gap that
  # P084 proved unshippable.
  run grep -nE "claude -p|claude --print" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 specifies --permission-mode bypassPermissions" {
  # Non-interactive permission handling for AFK subprocess (verified by Probe 4).
  # Without this flag, subprocess Bash/Edit/Write calls halt on prompts.
  run grep -nE "permission-mode[[:space:]]+bypassPermissions|--permission-mode[[:space:]]+bypassPermissions" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 specifies --output-format json for deterministic parsing" {
  # JSON .result field is the stable parse shape for ITERATION_SUMMARY extraction.
  run grep -nE "output-format[[:space:]]+json|--output-format[[:space:]]+json" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 does NOT invoke --max-budget-usd in the dispatch command (user direction 2026-04-21)" {
  # Explicit no-cap decision: quota exhaustion is the natural stop, not an
  # arbitrary per-iteration dollar cap. A cap would halt iterations before
  # quota runs out, leaving remaining backlog unprocessed. The assertion is
  # negative to catch regressions that re-introduce a cap by default.
  # Narrowed to the "used-form" pattern (flag followed by a value or envvar);
  # mentions of --max-budget-usd in explanatory prose are allowed because
  # the SKILL.md documents WHY the flag is omitted.
  run grep -nE '\-\-max-budget-usd[[:space:]]+("?\$|"[0-9])' "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md Step 5 does NOT reference WR_ITERATION_BUDGET_USD envvar (cap removed)" {
  # The envvar was part of the earlier cap design that user directed away
  # from. Assertion catches regression that re-introduces the envvar.
  run grep -nE "WR_ITERATION_BUDGET_USD" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md Step 5 documents quota as the natural stop condition" {
  # User direction 2026-04-21: AFK loop runs until quota exhausted, not until
  # an artificial cap hits. SKILL.md must state this explicitly so future
  # contributors don't re-add a cap "for safety".
  run grep -niE "quota.{0,40}natural|natural.{0,40}quota|quota.{0,60}stop|stop.{0,60}quota|quota exhaust" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 does NOT name subagent_type general-purpose (migrated away)" {
  # Post-P084 the Agent-tool dispatch is removed; Agent-tool-spawned general-purpose
  # subagents cannot satisfy gate markers (no nested Agent). The assertion is
  # negative on purpose: it catches accidental regression to the old dispatch.
  run grep -nE "subagent_type.{0,20}general-purpose" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md Step 5 specifies a return-summary contract" {
  # Contract preserved verbatim from P077. Orchestrator reads ITERATION_SUMMARY
  # from subprocess stdout (JSON .result) instead of Agent-tool return value.
  run grep -niE "return.{0,30}summary|iteration summary|summary shape|summary contract|ITERATION_SUMMARY" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 return-summary contract carries commit state (Step 6.75 dependency)" {
  # Architect R2 (P077): Step 6.75 inter-iteration verification needs the iteration
  # to report committed / commit_sha / reason so the Dirty-for-known-reason branch
  # stays evaluable. Preserved under subprocess swap.
  run grep -niE "commit_sha|committed.*true|committed.*false|commit state" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 return-summary contract carries skip-reason category (Step 2.5 dependency)" {
  # JTBD review (P077): skip_reason_category is what Step 2.5 reads deterministically.
  # Preserved under subprocess swap.
  run grep -niE "skip_reason_category|skip-reason category" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md allowed-tools frontmatter includes Bash (for subprocess shell-out)" {
  # Bash is required to invoke `claude -p` from Step 5.
  run grep -nE "^allowed-tools:.*Bash" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md allowed-tools frontmatter includes Agent (for Step 6.5 risk-scorer)" {
  # Step 6.5 delegates to wr-risk-scorer:pipeline via the Agent tool (orchestrator's
  # main turn, separate from the iteration subprocess). Still required.
  run grep -nE "^allowed-tools:.*Agent" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers iteration delegation" {
  # The non-interactive defaults table must include the iteration dispatch row,
  # updated to name claude -p subprocess (not the legacy Agent-tool path).
  run grep -niE "iteration delegation|delegate.*iteration|iteration.*subprocess|claude -p.*iteration|iteration.*claude -p" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Related section cites ADR-032 (iteration-isolation wrapper)" {
  # ADR-032 is amended with the subprocess-boundary sub-pattern for P084.
  run grep -nE "ADR-032" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 preserves inter-iteration continuity (Steps 6.5 / 6.75 stay in orchestrator)" {
  # Architect + JTBD review confirmation: Step 6.5 (release cadence) and Step 6.75
  # (inter-iteration verification) stay in the main orchestrator's turn. The
  # iteration subprocess does NOT run push:watch/release:watch.
  run grep -niE "orchestrator.{0,80}Step 6\\.5|Step 6\\.5.{0,80}orchestrator|Step 6\\.75.{0,80}orchestrator|orchestrator.{0,80}Step 6\\.75|main orchestrator|orchestrator.{0,40}main turn|main.turn.{0,40}orchestrator" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 documents hook session-id isolation for subprocess" {
  # Architect advisory (2026-04-21): subprocess has its own $CLAUDE_SESSION_ID,
  # so markers in /tmp/architect-reviewed-<ID> are scoped to subprocess hooks.
  # Intended behaviour, but must be explicitly documented to prevent future
  # contributors from wiring cross-process marker sharing.
  run grep -niE "CLAUDE_SESSION_ID|session.?id isolation|session-id isolation|marker.{0,40}isolated|subprocess.{0,40}SESSION_ID" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 iteration prompt names /wr-retrospective:run-retro (P086 retro-on-exit)" {
  # P086 (2026-04-21): iteration subprocesses exit without running retro, so
  # per-iteration friction, hook misbehaviour, repeat-workaround patterns, and
  # pipeline-instability observations evaporate on exit. The iteration prompt
  # body MUST name /wr-retrospective:run-retro as a closing step so the retro
  # skill's Step 2b pipeline-instability scan fires inside the subprocess's
  # full tool-call history. Retro commits its own work per ADR-014; orchestrator
  # picks up retro-created tickets on the next Step 1 scan naturally.
  run grep -nE "/wr-retrospective:run-retro" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 orders retro BEFORE ITERATION_SUMMARY emission (P086)" {
  # The retro-on-exit clause must fire BEFORE the ITERATION_SUMMARY block so
  # any tickets retro creates ride into either the iteration's own commit or
  # a retro-owned follow-up commit — and the orchestrator sees them on the
  # next Step 1 scan. Emitting ITERATION_SUMMARY first and running retro after
  # would leave retro tickets uncommitted when the subprocess exits.
  #
  # The assertion: the first mention of "run-retro" must appear BEFORE a
  # phrase that explicitly names the ordering (e.g. "before emitting
  # ITERATION_SUMMARY" or similar).
  run grep -niE "before.{0,40}emit.{0,40}ITERATION_SUMMARY|before.{0,20}ITERATION_SUMMARY.{0,40}(emission|emit)|prior to.{0,40}ITERATION_SUMMARY" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 names retro as non-blocking closing step (P086)" {
  # Retro findings MUST NOT block ITERATION_SUMMARY emission — if retro fails
  # or surfaces findings, the iteration still returns to the orchestrator with
  # a summary. Otherwise a flaky retro run could silently halt the AFK loop.
  # The SKILL.md prompt body must state that the subprocess proceeds to
  # ITERATION_SUMMARY regardless of retro findings.
  run grep -niE "do not block on retro|regardless of retro|retro.{0,40}non-blocking|proceed.{0,40}regardless.{0,40}retro|non-blocking.{0,40}retro" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 cites ADR-014 for retro commit ownership (P086)" {
  # Retro-created tickets ride into the iteration's commit OR a retro follow-up
  # commit per run-retro's ADR-014 contract. The iteration prompt body must
  # name ADR-014 so contributors do not accidentally wire iteration-side commit
  # of retro artefacts — retro owns its own commits.
  run grep -nE "ADR-014" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
