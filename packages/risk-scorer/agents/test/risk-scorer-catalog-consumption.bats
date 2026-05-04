#!/usr/bin/env bats
# Doc-lint guard: pipeline scorer MUST define the catalog consumption protocol
# per ADR-059 — read docs/risks/ first, hybrid filter (slug-token primary,
# judgement fallback), residual reconciliation (per-action residual in
# RISK_SCORES, catalog lifetime baseline in risk-item block), per-run
# CATALOG_HIT_RATE observability line.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# Agent prompts are specification documents; behavioural verification of an LLM's
# output is out of scope for bats — the contract document is what consuming
# orchestrators and reviewers rely on. This pattern matches existing tests in
# this directory (see risk-scorer-register-hint.bats).
#
# Cross-reference:
#   ADR-059: docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md
#   ADR-056: docs/decisions/056-risk-register-back-channel-write-contract.proposed.md (slug primitive consumed)
#   ADR-015: docs/decisions/015-on-demand-assessment-skills.proposed.md (pure-scorer contract preserved)
#   ADR-026: docs/decisions/026-agent-output-grounding.proposed.md
#   P168:    docs/problems/168-risk-scorer-doesnt-consume-catalog-or-bootstrap.known-error.md
#   P167:    docs/problems/167-risk-register-aggregate-reads-as-dont-ship.known-error.md
#   @jtbd JTBD-001 (enforce governance without slowing down — closes missed-risk-class hazard)
#   @jtbd JTBD-202 (pre-flight governance — catalog as ISO 31000/27001 audit-trail artefact)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PIPELINE="${AGENTS_DIR}/pipeline.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Contract surface: Catalog Consumption Protocol section exists
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md defines Catalog Consumption Protocol section" {
  run grep -q "## Catalog Consumption Protocol" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md cites ADR-059 in the catalog protocol section" {
  run grep -q "ADR-059" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md names docs/risks/ as the catalog read source" {
  run grep -qE "READ.*docs/risks/|read.*standing-risk catalog at .docs/risks/" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Hybrid filter: slug-token-match primary, judgement fallback
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md describes slug-token-match as primary filter path" {
  run grep -qE "[Ss]lug-token-match.*primary|[Ss]lug-token-match \(primary" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md describes judgement as fallback filter path" {
  run grep -qE "[Jj]udgement.*fallback|[Ff]ree-form judgement.*fallback" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Risk Item Format: Catalog match + Catalog baseline lines
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md Risk Item Format includes Catalog match line" {
  run grep -q "Catalog match:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md Risk Item Format includes Catalog baseline line" {
  run grep -q "Catalog baseline:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md names the three Catalog match values" {
  # slug-token | judgement | none — matches the ADR-059 verdict E3 contract.
  run grep -qE "slug-token.*judgement.*none|slug-token \| judgement \| none" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Residual reconciliation: per-action residual in RISK_SCORES, baseline contextual
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md names per-action residual as RISK_SCORES output" {
  run grep -qE "RISK_SCORES.*per-action residual|per-action residual.*RISK_SCORES" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md describes catalog lifetime baseline as context not RISK_SCORES" {
  run grep -qE "lifetime baseline|Catalog baseline:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Hit-rate observability: CATALOG_HIT_RATE line emitted per run
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md defines CATALOG_HIT_RATE observability line" {
  run grep -q "CATALOG_HIT_RATE:" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md names the CATALOG_HIT_RATE matched + missed columns" {
  run grep -qE "matched=N missed=M|CATALOG_HIT_RATE: matched" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Empty catalog handling: nudge but do NOT halt or inflate residual
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md handles empty catalog with nudge not halt" {
  run grep -qE "[Ee]mpty catalog|catalog is empty.*nudge|do NOT halt" "$PIPELINE"
  [ "$status" -eq 0 ]
}

@test "pipeline.md cites bootstrap-catalog skill in empty catalog nudge" {
  run grep -qE "bootstrap-catalog|/install-updates.*bootstrap" "$PIPELINE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Pure-scorer contract preserved: no Write tool grant added
# ──────────────────────────────────────────────────────────────────────────────

@test "pipeline.md preserves pure-scorer contract (Read + Glob only)" {
  # The agent's tool grant must remain Read + Glob per ADR-015.
  # Adding Write would break the architectural boundary ADR-059 verdict F2 preserves.
  run grep -qE "^  - Read$" "$PIPELINE"
  [ "$status" -eq 0 ]
  run grep -qE "^  - Glob$" "$PIPELINE"
  [ "$status" -eq 0 ]
  # Negative: Write tool MUST NOT appear in tool grant
  run grep -qE "^  - Write$" "$PIPELINE"
  [ "$status" -ne 0 ]
}
