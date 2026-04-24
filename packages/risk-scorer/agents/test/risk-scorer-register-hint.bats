#!/usr/bin/env bats
# Doc-lint guard: pipeline scorer MUST emit a structured RISK_REGISTER_HINT
# block when a register-worthy risk shape is identified.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the pipeline scorer's prompt defines the passive-trigger
# contract required by P110. Agent prompts are specification documents; a
# behavioural check of an LLM's output is out of scope for bats — the contract
# document is what the PostToolUse hook and consuming orchestrator rely on.
#
# Background: P102 landed `/wr-risk-scorer:create-risk` as an on-demand
# invocation surface for the risk register (docs/risks/). JTBD-001
# (Enforce Governance Without Slowing Down) requires passive triggers that
# fire "without a manual step" — assistant-remembering-to-invoke is the same
# failure mode the job identifies as a pain point. P110 closes the gap by
# having the pipeline scorer — which fires on every commit/push/release gate
# — emit a structured hint line when it sees a register-worthy risk shape.
# The calling orchestrator consumes the hint post-remediation-loop and
# invokes /wr-risk-scorer:create-risk with pre-filled context.
#
# Cross-reference:
#   P110:    docs/problems/110-risk-register-has-no-passive-trigger-slash-command-alone-partial-jtbd-001.open.md
#   P102:    the parent ticket (slash-command MVP invocation surface)
#   ADR-015: docs/decisions/015-on-demand-assessment-skills.proposed.md (Scorer Output Contract)
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   ADR-042: docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md (consumption timing)
#   @jtbd JTBD-001 (enforce governance without slowing down — passive trigger)
#   @jtbd JTBD-005 (invoke governance assessments on demand — composed via pre-filled create-risk)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Contract surface: RISK_REGISTER_HINT block exists and is documented
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md defines RISK_REGISTER_HINT block" {
  # The structured hint line is the machine-readable passive-trigger contract.
  run grep -q "RISK_REGISTER_HINT:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md RISK_REGISTER_HINT uses bulleted-list shape" {
  # Multi-hint capable: a single pipeline run can surface both an
  # above-appetite residual AND a confidentiality-disclosure risk.
  # Shape parallels RISK_REMEDIATIONS: (list-valued), not RISK_BYPASS_REASON: (single).
  run grep -qE "^RISK_REGISTER_HINT:[[:space:]]*$" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Trigger conditions: architect-approved three-trigger set
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md names above-appetite-residual trigger" {
  # Trigger (a): any cumulative residual score > appetite.
  run grep -q "above-appetite-residual" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md names confidentiality-disclosure trigger" {
  # Trigger (b): confidential information (client names, revenue, pricing) flagged.
  # Composes with the existing "Confidential Information Disclosure" section.
  run grep -q "confidentiality-disclosure" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md names user-stated-precondition trigger" {
  # Trigger (c): unmet user-stated precondition flagged as a Risk item.
  # Composes with the existing "User-Stated Preconditions Check" section.
  run grep -q "user-stated-precondition" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Consumption semantics: hint is consumed post-loop, not interleaved
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md documents post-loop consumption semantics" {
  # Architect advisory: the hint is consumed by the orchestrator AFTER the
  # ADR-042 auto-apply remediation loop converges (or Rule 5 halts), not
  # interleaved — otherwise register entries would be created for risks the
  # loop might have remediated away.
  run grep -qiE "post.?loop|after.*remediation.*(converge|loop)|after.*auto.?apply" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Cross-reference: hint hands off to /wr-risk-scorer:create-risk
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md names the create-risk hand-off target" {
  # The hint routes the consuming orchestrator to the MVP invocation surface
  # from P102. Without the hand-off target, a hint line is undirected.
  run grep -q "create-risk" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Silence guarantee: below appetite + no special triggers = no hint
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md documents no-hint silence when within appetite and no triggers fire" {
  # JTBD-001 "without slowing down": no hint noise when nothing is
  # register-worthy. This parallels the Below-Appetite Output Rule for
  # RISK_REMEDIATIONS: and protects the solo-developer 60-second review budget.
  run grep -qE "[Dd]o NOT emit.*RISK_REGISTER_HINT|[Oo]mit.*RISK_REGISTER_HINT|no hint|no.*RISK_REGISTER_HINT" "$PIPELINE"
  [ "$status" -eq 0 ]
}
