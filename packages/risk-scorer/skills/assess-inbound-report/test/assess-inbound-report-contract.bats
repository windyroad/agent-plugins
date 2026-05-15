#!/usr/bin/env bats
# Contract assertions for /wr-risk-scorer:assess-inbound-report skill
# (RFC-004 Slice B — on-demand wrapper per ADR-015). Peer of
# /wr-risk-scorer:assess-external-comms.
#
# Structural assertions — Permitted Exception to the source-grep ban
# per ADR-005 / P011 / ADR-037 / ADR-052 § Surface 2. SKILL.md prose
# governs LLM-driven runtime behaviour; behavioural-replay testing
# requires a synthetic agent harness (P012 / P176). Until that harness
# lands, contract bats assert the load-bearing contract elements are
# present so future edits don't silently strip them.
#
# @problem P079
# @rfc RFC-004 (Slice B)
# @adr ADR-062 (sibling subagent + on-demand wrapper)
# @adr ADR-015 (on-demand assessment skills — § Scope table extended)
# @adr ADR-044 (decision-delegation — taste / silent-mechanical authority)
# @jtbd JTBD-005 (invoke governance assessments on demand)
# @jtbd JTBD-202 (pre-flight governance checks before release/handover)
# @jtbd JTBD-001 (mechanical-stage carve-out on pipeline pre-satisfier path)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  ADR_015="$(cd "${SKILL_DIR}/../../../.." && pwd)/docs/decisions/015-on-demand-assessment-skills.proposed.md"
}

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "frontmatter name is wr-risk-scorer:assess-inbound-report" {
  run grep -nE '^name: wr-risk-scorer:assess-inbound-report$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "frontmatter allowed-tools includes Skill (delegates to subagent)" {
  # ADR-015 § Gate Marker Interaction: on-demand skills MUST delegate
  # via Skill tool; never write markers directly.
  run grep -nE '^allowed-tools:.*Skill' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "frontmatter allowed-tools includes AskUserQuestion (manual-mode step 6)" {
  # Step 6 (manual invocation only — silent on pipeline pre-satisfier
  # invocations per P132) uses AskUserQuestion to surface next-step
  # options.
  run grep -nE '^allowed-tools:.*AskUserQuestion' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "frontmatter allowed-tools includes Bash (gh issue fetch in step 2)" {
  # Step 2 can call `gh issue view --json body,author,labels` to fetch
  # the report body when only a URL/ref is supplied.
  run grep -nE '^allowed-tools:.*Bash' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Delegation to the sibling subagent (NOT marker self-writes)
# ──────────────────────────────────────────────────────────────────────────────

@test "skill delegates to wr-risk-scorer:inbound-report subagent" {
  run grep -nE 'wr-risk-scorer:inbound-report' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "skill MUST NOT write to /tmp/ markers directly (ADR-009 + ADR-015 boundary)" {
  # PostToolUse:Agent hook (risk-score-mark.sh) owns marker writes per
  # ADR-009 + ADR-015 § Gate Marker Interaction.
  run grep -inE 'NOT write.*/tmp|PostToolUse hook' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Mechanical-stage carve-out: pipeline pre-satisfier path is silent
# ──────────────────────────────────────────────────────────────────────────────

@test "skill names the mechanical-stage carve-out (P132) for pipeline pre-satisfier path" {
  run grep -inE 'P132|mechanical-stage carve-out' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "step 6 AskUserQuestion fires ONLY on manual invocation (not pipeline pre-satisfier)" {
  # The carve-out is the load-bearing protection for JTBD-001 + JTBD-006
  # against inverse-P078 drift. The pipeline pre-satisfier path MUST be
  # silent on this step. Match the contract in either direction:
  #   manual-only firing OR pipeline-pre-satisfier silent-on-step.
  run grep -inE 'invoked manually.*pre-flight|manual only|silent on this step|silent on.*pipeline pre-satisfier' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Persona anchors (JTBD-005 + JTBD-202)
# ──────────────────────────────────────────────────────────────────────────────

@test "skill cites JTBD-005 (invoke on demand) as primary persona driver" {
  run grep -nE 'JTBD-005' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "skill cites JTBD-202 (pre-flight governance checks) as secondary persona driver" {
  run grep -nE 'JTBD-202' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# ADR-015 Scope table row exists for assess-inbound-report
# ──────────────────────────────────────────────────────────────────────────────

@test "ADR-015 Scope table includes the assess-inbound-report row" {
  [ -f "$ADR_015" ]
  run grep -nE '`assess-inbound-report`' "$ADR_015"
  [ "$status" -eq 0 ]
  run grep -nE '`wr-risk-scorer:inbound-report`' "$ADR_015"
  [ "$status" -eq 0 ]
}

@test "ADR-015 Confirmation checkbox covers assess-inbound-report skill" {
  run grep -nE '\[x\] `packages/risk-scorer/skills/assess-inbound-report/SKILL\.md` created' "$ADR_015"
  [ "$status" -eq 0 ]
}

@test "ADR-015 Related section names ADR-062 + P079 (driver references)" {
  run grep -nE 'ADR-062.*inbound|inbound.*ADR-062' "$ADR_015"
  [ "$status" -eq 0 ]
  run grep -nE 'P079' "$ADR_015"
  [ "$status" -eq 0 ]
}
