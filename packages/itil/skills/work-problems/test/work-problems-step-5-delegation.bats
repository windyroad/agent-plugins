#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md Step 5 must delegate each iteration
# to a subagent via the Agent tool. Option B is pinned — reuse subagent_type
# `general-purpose`; no typed iteration-worker.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005
# / P011). These tests assert that the skill specification document encodes
# the delegation contract so context does not accumulate across iterations
# in the main orchestrator's turn.
#
# @problem P077
# @jtbd JTBD-006
#
# Cross-reference:
#   P077 (work-problems Step 5 does not delegate to subagent)
#   ADR-015 (on-demand assessment skills — Agent-vs-Skill tool precedent)
#   ADR-032 (governance skill invocation patterns — AFK iteration-isolation
#     wrapper sub-pattern)
#   ADR-037 (skill testing strategy — contract-assertion pattern)
#   JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md cites P077 (Step 5 delegation)" {
  run grep -n "P077" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 names the Agent tool explicitly" {
  # Bare 'Invoke the manage-problem skill' would read as a Skill-tool
  # invocation (in-process expansion). Step 5 must name the Agent tool
  # the same way Step 6.5 does (per ADR-015).
  run grep -niE "Step 5.{0,160}Agent tool|delegate.{0,60}Agent tool|via the Agent tool" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 cites subagent_type general-purpose" {
  # Option B pinned (per ticket 2026-04-21). The subagent_type must be
  # explicit so a future refactor cannot silently drop back to Skill-tool.
  run grep -nE "subagent_type.{0,20}general-purpose|general-purpose.{0,40}subagent" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 specifies a return-summary contract" {
  # The orchestrator must consume a structured summary from the subagent
  # (not re-read the subagent's tool calls). Contract fields required by
  # architect review (R2) and JTBD review extension.
  run grep -niE "return.{0,30}summary|iteration summary|summary shape|summary contract" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 return-summary contract carries commit state (R2)" {
  # Architect R2: Step 6.75 inter-iteration verification needs the subagent
  # to report committed / commit_sha / reason so the Dirty-for-known-reason
  # branch stays evaluable.
  run grep -niE "commit_sha|committed.*true|committed.*false|commit state" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 return-summary contract carries skip-reason category (JTBD extension)" {
  # JTBD review: the summary's skip_reason_category is what Step 2.5 reads
  # deterministically. Without it the Outstanding Design Questions table
  # would have to re-parse ticket files.
  run grep -niE "skip_reason_category|skip-reason category" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md allowed-tools frontmatter includes Agent" {
  # P077 pre-existing latent bug (flagged by architect review): the skill
  # already requires the Agent tool at Step 6.5 but allowed-tools omits it.
  # Fixing Step 5 is the right place to close the latent bug.
  run grep -nE "^allowed-tools:.*Agent" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers iteration delegation" {
  # Architect + ticket requirement: the non-interactive defaults table must
  # include a row for 'how each iteration runs' (delegated via Agent tool).
  run grep -niE "iteration delegation|delegate.*iteration|iteration.*subagent|iteration.*general-purpose" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Related section cites ADR-032 (iteration-isolation wrapper)" {
  # Architect R3: ADR-032 is amended with the AFK iteration-isolation
  # sub-pattern; SKILL.md must cite it so the contract-to-ADR traceability
  # ADR-037 requires is complete.
  run grep -nE "ADR-032" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 5 preserves inter-iteration continuity (Steps 6.5 / 6.75 remain in orchestrator)" {
  # Architect review confirmation: Step 6.5 (release cadence) and Step 6.75
  # (inter-iteration verification) stay in the main orchestrator's turn.
  # The iteration subagent must NOT run push:watch/release:watch.
  run grep -niE "orchestrator.{0,80}Step 6\\.5|Step 6\\.5.{0,80}orchestrator|Step 6\\.75.{0,80}orchestrator|orchestrator.{0,80}Step 6\\.75|main orchestrator|orchestrator.{0,40}main turn|main.turn.{0,40}orchestrator" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
