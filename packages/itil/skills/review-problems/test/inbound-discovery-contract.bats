#!/usr/bin/env bats
# Contract assertions for /wr-itil:review-problems Step 4.5
# inbound-discovery + assessment-pipeline (RFC-004 Slice C + Slice E).
#
# Structural assertions — Permitted Exception to the source-grep ban
# per ADR-005 / P011 / ADR-037 / ADR-052 § Surface 2. SKILL.md prose
# governs LLM-driven runtime behaviour; behavioural-replay testing
# requires a synthetic agent harness (P012 master ticket; P176 follow-up
# for the SKILL.md surface). Until that harness lands, contract bats
# assert the load-bearing prompt elements are present so future edits
# don't silently strip them.
#
# @problem P079
# @rfc RFC-004
# @adr ADR-062 (inbound discovery + assessment pipeline)
# @adr ADR-028 (external-comms gate)
# @adr ADR-044 (decision-delegation contract — category 4 mechanical-stage carve-out)
# @adr ADR-052 (behavioural-tests default + Permitted Exception)
# @jtbd JTBD-301 (acknowledgement contract — non-negotiable)
# @jtbd JTBD-001 (mechanical-stage carve-out — preserve without slowing down)
# @jtbd JTBD-006 (AFK silent path)
# @jtbd JTBD-101 (downstream non-obligation)
# @jtbd JTBD-201 (audit-log replay)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5 presence + ADR-062 naming reconciliation
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 inbound-discovery section exists in SKILL.md (RFC-004 Slice C)" {
  run grep -nE '^### 4\.5\. Inbound-discovery' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 header preserves ADR-062 'Step 8.5' substring anchor verbatim" {
  # ADR-062 § Confirmation criterion 1 hard-keys on the "Step 8.5"
  # substring. SKILL.md numbering is "Step 4.5"; header cross-references
  # ADR-062's "Step 8.5" verbatim so the criterion remains string-anchorable.
  # Do NOT strip the "Step 8.5" substring on rename.
  run grep -nE 'Step 8\.5' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preserves ADR-062 'Step 9e' substring anchor verbatim" {
  # ADR-062 § Confirmation criterion 1 final bullet hard-keys on the
  # "Step 9e" substring (the renderer is owned by Slice G; this skill
  # carries the cross-reference forward).
  run grep -nE 'Step 9e' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 naming-reconciliation HTML comment marker exists" {
  # Architect issue 1+2: preserve both "Step 8.5" and "Step 9e" anchors
  # via a single HTML comment so a future rename doesn't silently strip
  # them. Comment names ADR-062 explicitly.
  run grep -nE 'ADR-062-step-naming-reconciliation' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5 sub-step structure (4.5a through 4.5g)
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5a — read channel config (docs/problems/.upstream-channels.json)" {
  run grep -nE '4\.5a\..*[Cc]hannel config' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '\.upstream-channels\.json' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5b — cache TTL check (docs/problems/.upstream-cache.json)" {
  run grep -nE '4\.5b\..*[Cc]ache TTL' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '\.upstream-cache\.json' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5c — polls all three GitHub channels (issues / discussions / security-advisories)" {
  run grep -nE 'github-issues' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'github-discussions' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'github-security-advisories' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5d — P070 semantic-comparator with cross-reference comment on hit (JTBD-301)" {
  # Architect issue 5: JTBD-301 acknowledgement contract requires a
  # gated cross-reference comment on matched-local-ticket hits; silent-skip
  # would break the contract.
  run grep -nE '4\.5d.*[Mm]atch.*local' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'cross-reference' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5e — six-step assessment pipeline" {
  run grep -nE '4\.5e\..*[Ss]ix-step assessment pipeline' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5f — audit-log append to docs/audits/inbound-discovery-log.md" {
  run grep -nE '4\.5f\..*[Aa]udit-log' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'inbound-discovery-log\.md' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5g — render-time integration seam (consumed by Slice G renderer)" {
  run grep -nE '4\.5g\..*[Rr]ender' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Six pipeline outcomes (4.5e steps 1-6)
# ──────────────────────────────────────────────────────────────────────────────

@test "Pipeline step 1 — version-aware classification stub seam (P129 carve-out)" {
  run grep -inE 'version-aware classification.*P129|P129.*stub seam' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 2 — JTBD-alignment classifier (wr-jtbd:agent)" {
  run grep -nE 'JTBD-alignment classifier' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'wr-jtbd:agent' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 3 — dual-axis risk classifier (wr-risk-scorer:inbound-report from Slice B)" {
  run grep -inE 'dual-axis risk classifier' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'wr-risk-scorer:inbound-report' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4 — above-threshold-pushback branch (gated declining comment)" {
  run grep -nE 'above-threshold-pushback' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 5 — clear-malicious branch with verdict comment BEFORE close (JTBD-301)" {
  # JTBD-301 acknowledgement contract: silent close is forbidden per ADR-062.
  run grep -nE 'clear-malicious' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'verdict comment.*BEFORE close|silent close.*forbidden' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 6 — safe-and-valid branch invokes capture-problem --no-prompt" {
  # Architect issue 3: documenting the default-technical choice explicitly
  # so the maintainer-re-classify safety net is visible.
  run grep -nE 'safe-and-valid' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'capture-problem.*--no-prompt' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Mechanical-stage carve-out (P132 / ADR-044 category 4)
# Load-bearing test protecting JTBD-001 + JTBD-006 against inverse-P078 drift
# per the architect's named Slice E acceptance criterion.
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 cites the mechanical-stage carve-out (P132 / ADR-044)" {
  run grep -inE 'mechanical-stage carve-out|P132' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 explicitly forbids AskUserQuestion at the branch decision (anti-inverse-P078 drift)" {
  # The load-bearing structural assertion per architect Slice E acceptance.
  # If a future edit adds AskUserQuestion to the pipeline branch decision,
  # this assertion fails and surfaces the P132 carve-out regression.
  run grep -nE 'does NOT use .AskUserQuestion. at the branch decision' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 cites ADR-044 category 4 (silent framework action)" {
  run grep -nE 'ADR-044 category 4' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# JTBD-301 acknowledgement contract (non-negotiable per ADR-062)
# ──────────────────────────────────────────────────────────────────────────────

@test "JTBD-301 acknowledgement contract cited on the matched-local-ticket path (architect issue 5)" {
  run grep -nE 'JTBD-301' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'JTBD-301 acknowledgement' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Per-branch gate-denial sub-branches preserve report on external-comms gate FAIL" {
  # Silent-skip on gate-denial would break JTBD-301; the report is preserved
  # via cache_audit_note for the next discovery pass.
  run grep -nE '[Gg]ate-denial sub-branch' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'cache_audit_note' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Fail-soft contract + downstream non-obligation
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 declares the fail-soft contract" {
  run grep -inE 'fail-soft contract' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Missing channel config skips Step 4.5 (downstream-adopter non-obligation per JTBD-101)" {
  run grep -nE 'channel config absent|missing or malformed' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'JTBD-101' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "AFK-loop silent behaviour documented" {
  run grep -nE 'AFK-loop|AFK orchestrator.*silently' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Slice C flag stub marker (Slice F replaces with parsed-flag variable)
# ──────────────────────────────────────────────────────────────────────────────

@test "SLICE-C-FLAG-STUB marker present on --force-upstream-recheck string-match" {
  # Architect issue 4: declare the stub explicitly so Slice F's refactor
  # surface is discoverable. Stub is removed when Slice F lands.
  run grep -nE 'SLICE-C-FLAG-STUB' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE -- '--force-upstream-recheck' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Cross-reference integrity (ADRs + sibling JTBDs)
# ──────────────────────────────────────────────────────────────────────────────

@test "ADR-062 cross-reference present in Step 4.5 header" {
  run grep -nE 'ADR-062' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "ADR-028 (external-comms gate) cited for gated-comment paths" {
  run grep -nE 'ADR-028' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
