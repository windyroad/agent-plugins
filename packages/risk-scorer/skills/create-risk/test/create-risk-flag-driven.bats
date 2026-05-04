#!/usr/bin/env bats
# Doc-lint guard: /wr-risk-scorer:create-risk MUST accept --slug and --prefill
# flags for orchestrator-driven prefilled invocation per ADR-059 verdict F2.
# Flag-driven path skips AskUserQuestion and writes the entry deterministically
# under ADR-013 Rule 5 (catalog framing in RISK-POLICY.md IS the policy
# authorisation). Existing AskUserQuestion-driven authoring path preserved
# for human invocation (no flags).
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# SKILL.md is a specification document; behavioural verification of LLM-driven
# skills is out of scope for bats. The contract document is what consuming
# orchestrators (work-problems Step 6.4 drain, install-updates Step 6.5
# bootstrap auto-trigger, etc.) rely on.
#
# Cross-reference:
#   ADR-059: docs/decisions/059-pipeline-consume-catalog-and-bootstrap-from-reports.proposed.md
#   ADR-056: docs/decisions/056-risk-register-back-channel-write-contract.proposed.md (queue source)
#   ADR-026: docs/decisions/026-agent-output-grounding.proposed.md (sentinel pattern)
#   ADR-013: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md (Rule 5)
#   P168:    docs/problems/168-risk-scorer-doesnt-consume-catalog-or-bootstrap.known-error.md
#   @jtbd JTBD-001 (enforce governance without slowing down — auto-write closes missed-class hazard)
#   @jtbd JTBD-006 (AFK-safety — flag-driven path is non-interactive)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Flag-driven path section exists; cites ADR-059
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md defines orchestrator flag-driven path section" {
  run grep -qE "^### 1b. Orchestrator flag-driven path|Orchestrator flag-driven path" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md cites ADR-059 in the flag-driven section" {
  run grep -q "ADR-059" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Flags: --slug and --prefill (required); --report-path (optional)
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md accepts --slug flag" {
  run grep -q -- "--slug" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md accepts --prefill flag" {
  run grep -q -- "--prefill" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md accepts --report-path flag (optional)" {
  run grep -q -- "--report-path" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Deterministic-write defaults under flag-driven path
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md sets pending-review Status under flag-driven path" {
  run grep -q "Active (auto-scaffolded — pending review)" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md uses ADR-026 sentinel for ungrounded scoring" {
  run grep -q "not estimated — no prior data" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md sets pending review Curation field" {
  run grep -qE "Curation.*pending review|pending review .auto-scaffolded" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Source Evidence block (required for flag-driven path per ADR-026 grounding)
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md requires Source Evidence block under flag-driven path" {
  run grep -q "## Source Evidence" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md cites .risk-reports/ in Source Evidence shape" {
  run grep -q ".risk-reports/" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# AskUserQuestion handling: skipped under flags, preserved without flags
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md skips AskUserQuestion under flag-driven path" {
  # Per CLAUDE.md P132 (inverse-P078) — the framework has resolved the decision
  # via ADR-056 queue + ADR-013 Rule 5 policy authorisation; no per-class consent gate.
  run grep -qE "[Ss]kip AskUserQuestion|SKIP step 2|skips AskUserQuestion" "$SKILL"
  [ "$status" -eq 0 ]
}

@test "create-risk SKILL.md preserves AskUserQuestion path for human invocation" {
  run grep -qE "preserved for human invocation|interactive authoring path preserved|no.*flags" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Slug-collision handling: append to existing file's Source Evidence block
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md handles slug collision via Source Evidence append" {
  run grep -qE "slug.collision|slug is the dedupe key|append.*Source Evidence" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Policy authorisation: ADR-013 Rule 5
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md cites ADR-013 Rule 5 for the flag-driven authorisation" {
  run grep -qE "ADR-013 Rule 5|Rule 5.*policy-authorised|policy.authorisation.*RISK-POLICY" "$SKILL"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Per-action invocation pattern: orchestrator dedupes by slug
# ──────────────────────────────────────────────────────────────────────────────

@test "create-risk SKILL.md describes orchestrator dedupe-by-slug pattern" {
  run grep -qE "dedupe by slug|dedupe.*slug|once per unique slug" "$SKILL"
  [ "$status" -eq 0 ]
}
