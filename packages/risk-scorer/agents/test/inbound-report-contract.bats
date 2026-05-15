#!/usr/bin/env bats
# Contract assertions for the wr-risk-scorer:inbound-report subagent
# (RFC-004 Slice B). Sibling of wr-risk-scorer:external-comms — NOT
# extension. Reviews INBOUND third-party prose on two axes (Request-risk +
# Fix-risk) per RISK-POLICY.md § Inbound Report Risk Classes.
#
# Structural assertions — Permitted Exception to the source-grep ban
# per ADR-005 / P011 / ADR-037 / ADR-052 § Surface 2. Subagent prompt
# prose governs LLM-driven verdict behaviour; behavioural-replay
# testing requires a synthetic agent harness (P012 / P176). Until that
# harness lands, contract bats assert the load-bearing rubric + structured
# verdict format are present so future edits don't silently strip them.
#
# @problem P079
# @rfc RFC-004
# @adr ADR-062 (inbound discovery + assessment pipeline — § Sibling subagent)
# @adr ADR-015 (on-demand assessment skills — § Scope table)
# @adr ADR-026 (grounding discipline — every FAIL verdict cites policy class)
# @adr ADR-029 (diagnose before implement — hypothesis / evidence / structured verdict)
# @adr ADR-052 (behavioural-tests default + Permitted Exception)
# @jtbd JTBD-301 (acknowledgement contract grounded in policy classes)
# @jtbd JTBD-001 (mechanical-stage carve-out via structured verdict)

setup() {
  AGENTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENTS_DIR}/inbound-report.md"
  POLICY_FILE="$(cd "${AGENTS_DIR}/../../.." && pwd)/RISK-POLICY.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Frontmatter + tool surface
# ──────────────────────────────────────────────────────────────────────────────

@test "inbound-report.md exists and has frontmatter (RFC-004 Slice B)" {
  [ -f "$AGENT_FILE" ]
  run head -1 "$AGENT_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "frontmatter name is 'inbound-report' (sibling of external-comms)" {
  run grep -nE '^name: inbound-report$' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "frontmatter tools are read-only (Read, Glob, Grep)" {
  # Per ADR-062 § Sibling subagent: read-only contract; subagent emits
  # verdict, PostToolUse hook owns marker writes.
  run grep -nE '  - Read' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '  - Glob' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '  - Grep' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "frontmatter tools do NOT include Write / Edit / Bash (read-only invariant)" {
  run grep -nE '^  - (Write|Edit|Bash)$' "$AGENT_FILE"
  [ "$status" -ne 0 ]
}

@test "frontmatter model is inherit" {
  run grep -nE '^model: inherit$' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Sibling-not-extension positioning (ADR-062 § Sibling subagent)
# ──────────────────────────────────────────────────────────────────────────────

@test "agent prose names sibling-not-extension positioning vs external-comms" {
  # ADR-062 explicitly carves the inbound-report subagent as a sibling
  # (NOT extension) of external-comms. Protects JTBD-101 plugin-developer
  # constraint "must not break existing plugins" by preserving
  # external-comms scope-purity.
  run grep -inE 'sibling.*external-comms|external-comms.*sibling' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent prose names the inbound-direction framing (third-party prose flowing INWARD)" {
  run grep -inE 'INWARD|inbound prose|third-party prose' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Two-axis review structure (Request-risk + Fix-risk)
# ──────────────────────────────────────────────────────────────────────────────

@test "Axis 1 Request-risk documented (attack-vector axis)" {
  run grep -nE 'Axis 1.*Request-risk' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "Axis 1 enumerates info-extraction / backdoor request / malicious-code injection classes" {
  run grep -inE 'Info-extraction' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'Backdoor request' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'Malicious-code injection' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "Axis 2 Fix-risk documented (work-to-be-weighed axis)" {
  run grep -nE 'Axis 2.*Fix-risk' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "Axis 2 enumerates privilege escalation / removal-of-safety-check / adopter-attack-surface-expansion classes" {
  run grep -inE 'Privilege escalation' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'Removal of load-bearing safety check' "$AGENT_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'Adopter-attack-surface expansion' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Structured verdict block (consumed by assessment-pipeline branch routing)
# ──────────────────────────────────────────────────────────────────────────────

@test "verdict block defines INBOUND_REPORT_VERDICT" {
  run grep -nE 'INBOUND_REPORT_VERDICT' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict block defines INBOUND_REPORT_KEY (sha256 hex for marker matching)" {
  run grep -nE 'INBOUND_REPORT_KEY' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict block defines INBOUND_REPORT_CLASS (one of four classifications)" {
  run grep -nE 'INBOUND_REPORT_CLASS' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict block defines INBOUND_REPORT_REASON for FAIL path" {
  run grep -nE 'INBOUND_REPORT_REASON' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Four classifications enumerated (branch-routing vocabulary)
# ──────────────────────────────────────────────────────────────────────────────

@test "classification safe-low-fix-risk enumerated" {
  run grep -nE 'safe-low-fix-risk' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "classification safe-high-fix-risk enumerated" {
  run grep -nE 'safe-high-fix-risk' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "classification above-threshold-risk enumerated" {
  run grep -nE 'above-threshold-risk' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "classification clear-malicious-request enumerated" {
  run grep -nE 'clear-malicious-request' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Grounding discipline (ADR-026)
# ──────────────────────────────────────────────────────────────────────────────

@test "FAIL verdict requires citing the specific RISK-POLICY.md class" {
  run grep -inE 'cite|class violated' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent prose cites ADR-026 grounding discipline" {
  run grep -nE 'ADR-026' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Read-only constraints + marker boundary
# ──────────────────────────────────────────────────────────────────────────────

@test "agent declares read-only (no file writes / commits / draft modifications)" {
  run grep -inE 'read-only' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent forbids self-writing to /tmp/ or marker locations" {
  # PostToolUse hook owns marker writes per ADR-009; the subagent
  # emits the verdict and the hook computes the marker key.
  run grep -inE 'NOT write to /tmp|PostToolUse hook owns' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Mechanical-stage carve-out integration (P132 — pipeline branch routing)
# ──────────────────────────────────────────────────────────────────────────────

@test "agent prose names the mechanical-stage carve-out integration (P132)" {
  run grep -nE 'P132|mechanical' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent does NOT make a block-list decision (P123 scope carve-out)" {
  # Block-list enforcement is a separate ticket's concern; this subagent's
  # verdict feeds the audit-log via the assessment-pipeline's clear-malicious
  # branch and stops there.
  run grep -inE 'NOT make a block-list|P123' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# RISK-POLICY.md integration (the policy classes the agent grounds verdicts against)
# ──────────────────────────────────────────────────────────────────────────────

@test "RISK-POLICY.md has the '## Inbound Report Risk Classes' section the agent reads" {
  [ -f "$POLICY_FILE" ]
  run grep -nE '^## Inbound Report Risk Classes$' "$POLICY_FILE"
  [ "$status" -eq 0 ]
}

@test "agent prose references RISK-POLICY.md § Inbound Report Risk Classes" {
  run grep -nE 'Inbound Report Risk Classes' "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
