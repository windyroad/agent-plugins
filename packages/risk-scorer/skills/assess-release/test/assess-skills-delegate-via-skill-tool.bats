#!/usr/bin/env bats
# Contract guard: the on-demand assessment SKILLs (assess-release, assess-wip,
# assess-external-comms) MUST delegate to their scoring agent via the Skill
# tool — not via the Agent tool — matching ADR-015's Confirmation literal
# phrasing ("the skill delegates to wr-risk-scorer:<agent> via the Skill
# tool"). Closes the P205 contradiction surfaced by ADR-015 Confirmation
# vs. SKILL.md prose mismatch.
#
# Structural assertions — Permitted Exception to the source-grep ban
# (ADR-005 / P011), same framing as risk-scorer-register-hint.bats. SKILL.md
# prose IS the contract document the orchestrator (Claude) consumes when
# executing the SKILL; an LLM-output behavioural check is out of scope for
# bats and is the responsibility of the promptfoo harness (ADR-075).
#
# What is asserted (contract, not implementation):
#   1. Each assess-* SKILL's step 5 (release) / step 3 (wip) / step 4
#      (external-comms) names `skill:` as the delegation tool parameter
#      with the correct wrapper SKILL name as the target.
#   2. None of the assess-* SKILLs name `subagent_type:` as the delegation
#      tool parameter (the P205 contradiction class).
#   3. Each wrapper SKILL (`pipeline`, `wip`, `external-comms`) exists at
#      its expected path, is namespaced `wr-risk-scorer:<name>`, and
#      delegates to its sibling agent via `subagent_type:`.
#
# Cross-reference:
#   P205:    docs/problems/known-error/205-wr-risk-scorer-assess-release-skill-md-step-5-prose-says-skill-tool-but-provides-subagent-type.md
#   ADR-015: docs/decisions/015-on-demand-assessment-skills.proposed.md (Confirmation criteria 189-193)
#   ADR-052: docs/decisions/052-behavioural-tests-default.proposed.md (Permitted Exception)
#   @jtbd JTBD-005 (invoke governance assessments on demand)
#   @jtbd JTBD-101 (extend the suite — plugins expose corresponding skills)

setup() {
  SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

  ASSESS_RELEASE="${SKILLS_DIR}/assess-release/SKILL.md"
  ASSESS_WIP="${SKILLS_DIR}/assess-wip/SKILL.md"
  ASSESS_EXTERNAL_COMMS="${SKILLS_DIR}/assess-external-comms/SKILL.md"

  WRAPPER_PIPELINE="${SKILLS_DIR}/pipeline/SKILL.md"
  WRAPPER_WIP="${SKILLS_DIR}/wip/SKILL.md"
  WRAPPER_EXTERNAL_COMMS="${SKILLS_DIR}/external-comms/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Consumer SKILLs delegate via Skill tool (skill: parameter)
# ──────────────────────────────────────────────────────────────────────────────

@test "assess-release delegates via skill: wr-risk-scorer:pipeline" {
  [ -f "$ASSESS_RELEASE" ]
  run grep -E "^skill: wr-risk-scorer:pipeline$" "$ASSESS_RELEASE"
  [ "$status" -eq 0 ]
}

@test "assess-release does NOT use subagent_type: in its delegation block" {
  [ -f "$ASSESS_RELEASE" ]
  # The P205 contradiction was: prose says "Skill tool" but provides
  # subagent_type: wr-risk-scorer:pipeline. After the fix, no
  # `subagent_type:` line may appear in the delegation block.
  run grep -E "^subagent_type: wr-risk-scorer:pipeline$" "$ASSESS_RELEASE"
  [ "$status" -ne 0 ]
}

@test "assess-wip delegates via skill: wr-risk-scorer:wip" {
  [ -f "$ASSESS_WIP" ]
  run grep -E "^skill: wr-risk-scorer:wip$" "$ASSESS_WIP"
  [ "$status" -eq 0 ]
}

@test "assess-wip does NOT use subagent_type: in its delegation block" {
  [ -f "$ASSESS_WIP" ]
  run grep -E "^subagent_type: wr-risk-scorer:wip$" "$ASSESS_WIP"
  [ "$status" -ne 0 ]
}

@test "assess-external-comms delegates via skill: wr-risk-scorer:external-comms" {
  [ -f "$ASSESS_EXTERNAL_COMMS" ]
  run grep -E "^skill: wr-risk-scorer:external-comms$" "$ASSESS_EXTERNAL_COMMS"
  [ "$status" -eq 0 ]
}

@test "assess-external-comms does NOT use subagent_type: in its delegation block" {
  [ -f "$ASSESS_EXTERNAL_COMMS" ]
  run grep -E "^subagent_type: wr-risk-scorer:external-comms$" "$ASSESS_EXTERNAL_COMMS"
  [ "$status" -ne 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Wrapper SKILLs exist with correct names and delegate to the agent
# ──────────────────────────────────────────────────────────────────────────────

@test "wrapper SKILL packages/risk-scorer/skills/pipeline/SKILL.md exists" {
  [ -f "$WRAPPER_PIPELINE" ]
}

@test "wrapper SKILL pipeline declares name: wr-risk-scorer:pipeline" {
  [ -f "$WRAPPER_PIPELINE" ]
  run grep -E "^name: wr-risk-scorer:pipeline$" "$WRAPPER_PIPELINE"
  [ "$status" -eq 0 ]
}

@test "wrapper SKILL pipeline delegates to the pipeline agent via subagent_type:" {
  [ -f "$WRAPPER_PIPELINE" ]
  run grep -E "^subagent_type: wr-risk-scorer:pipeline$" "$WRAPPER_PIPELINE"
  [ "$status" -eq 0 ]
}

@test "wrapper SKILL packages/risk-scorer/skills/wip/SKILL.md exists" {
  [ -f "$WRAPPER_WIP" ]
}

@test "wrapper SKILL wip declares name: wr-risk-scorer:wip" {
  [ -f "$WRAPPER_WIP" ]
  run grep -E "^name: wr-risk-scorer:wip$" "$WRAPPER_WIP"
  [ "$status" -eq 0 ]
}

@test "wrapper SKILL wip delegates to the wip agent via subagent_type:" {
  [ -f "$WRAPPER_WIP" ]
  run grep -E "^subagent_type: wr-risk-scorer:wip$" "$WRAPPER_WIP"
  [ "$status" -eq 0 ]
}

@test "wrapper SKILL packages/risk-scorer/skills/external-comms/SKILL.md exists" {
  [ -f "$WRAPPER_EXTERNAL_COMMS" ]
}

@test "wrapper SKILL external-comms declares name: wr-risk-scorer:external-comms" {
  [ -f "$WRAPPER_EXTERNAL_COMMS" ]
  run grep -E "^name: wr-risk-scorer:external-comms$" "$WRAPPER_EXTERNAL_COMMS"
  [ "$status" -eq 0 ]
}

@test "wrapper SKILL external-comms delegates to the external-comms agent via subagent_type:" {
  [ -f "$WRAPPER_EXTERNAL_COMMS" ]
  run grep -E "^subagent_type: wr-risk-scorer:external-comms$" "$WRAPPER_EXTERNAL_COMMS"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Wrapper SKILLs disambiguate from end-user assess-* surfaces
# ──────────────────────────────────────────────────────────────────────────────

@test "wrapper pipeline description names assess-release as the end-user surface" {
  [ -f "$WRAPPER_PIPELINE" ]
  # JTBD-005 persona-fit: solo developer must not land on the raw wrapper
  # and miss the assess-* gate-satisfaction wrap-up. Description must
  # disambiguate.
  run grep -E "assess-release" "$WRAPPER_PIPELINE"
  [ "$status" -eq 0 ]
}

@test "wrapper wip description names assess-wip as the end-user surface" {
  [ -f "$WRAPPER_WIP" ]
  run grep -E "assess-wip" "$WRAPPER_WIP"
  [ "$status" -eq 0 ]
}

@test "wrapper external-comms description names assess-external-comms as the end-user surface" {
  [ -f "$WRAPPER_EXTERNAL_COMMS" ]
  run grep -E "assess-external-comms" "$WRAPPER_EXTERNAL_COMMS"
  [ "$status" -eq 0 ]
}
