#!/usr/bin/env bats
# Contract assertions for /wr-itil:review-problems Step 4.5d + Step 4.5e
# verdict-shape ack-comment templates (P229 / JTBD-301).
#
# Structural assertions — Permitted Exception to the source-grep ban
# per ADR-005 / P011 / ADR-037 / ADR-052 § Surface 2. SKILL.md prose
# governs LLM-driven runtime behaviour; behavioural-replay testing
# requires a synthetic agent harness (P012 master ticket; P176 follow-up
# for the SKILL.md surface; P324 review-problems agent-prose harness gap).
# Until that harness lands, contract bats assert the load-bearing
# template elements are present so future edits don't silently strip
# the JTBD-301 verdict vocabulary and re-introduce framework-vocab leakage.
#
# @problem P229
# @problem P012 (master harness ticket — justification for structural exception)
# @problem P176 (SKILL.md surface follow-up)
# @problem P324 (review-problems agent-prose harness gap)
# @jtbd JTBD-301 (verdict-shape acknowledgement contract — non-negotiable)
# @adr ADR-024 (report-upstream contract — symmetry mirror)
# @adr ADR-036 (downstream-scaffold contract — adopter inheritance)
# @adr ADR-052 (behavioural-tests default + Permitted Exception)
# @adr ADR-062 (inbound-discovery + assessment pipeline)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Verdict-shape contract subsection exists at the head of Step 4.5e
# ──────────────────────────────────────────────────────────────────────────────

@test "4.5e-comment-shape subsection exists (briefs JTBD-301 contract upstream of branch templates)" {
  run grep -nE '^#### 4\.5e-comment-shape' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection names all four JTBD-301 verdict words verbatim" {
  # JTBD-301 Desired Outcome row 6 names exactly four verdicts.
  # The subsection MUST name all four so a reader sees the vocabulary
  # before reading the per-branch templates that implement it.
  run grep -nE 'fix released' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'won.t-fix|won\\.t fix' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'duplicate' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'parked' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection explicitly forbids framework-vocab leakage in ack-comment bodies" {
  # Load-bearing rule: maintainer-internal jargon (Step IDs, branch
  # names, classification tokens) MUST NOT appear in reporter-facing
  # comment bodies. Audit-log at 4.5f keeps the tokens.
  run grep -inE 'framework.vocab|maintainer.internal|reporter.facing' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection cites the report-upstream symmetry (ADR-024 / ADR-036)" {
  # JTBD-301 line 23 + ADR-024 / ADR-036 establish the inbound/outbound
  # symmetry: outbound `/wr-itil:report-upstream` posts structured
  # human-language; inbound ack mirrors that shape.
  run grep -nE 'symmetry|mirror' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection documents the C2 gate-substitution caveat (architect condition C2)" {
  # The external-comms gate (ADR-028) fires on the SUBSTITUTED body,
  # not the template — template authors must ensure no maintainer
  # jargon leaks via P<NNN> title substitution or <reason> expansion.
  run grep -inE 'substituted body|gate.fires.on.the.*substituted|template.author' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5d — matched-local-ticket cross-reference uses verdict-shape
# (duplicate verdict)
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5d cross-reference comment uses 'duplicate' verdict language" {
  # Replaces the bureaucratic "Tracked locally as docs/problems/..." boilerplate
  # with verdict-shape "we're tracking this as a duplicate of P<NNN>".
  run grep -inE 'duplicate of P.NNN.|tracking.*duplicate' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5d cross-reference comment template is documented inline (not just referenced)" {
  # SKILL prose must carry the actual template body so a single-pass
  # reader sees the shape, not just a cross-reference to JTBD-301.
  run grep -nE '4\.5d.*[Cc]omment template|matched-local-ticket.*template' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5e Step 4 — above-threshold-pushback verdict template (won't-fix)
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5e Step 4 pushback template uses 'we don't plan to fix this' verdict language" {
  run grep -inE "we don.t plan to fix|don.t plan to fix this" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5e Step 5 — clear-malicious verdict template (policy-violation close)
# Architect condition C4: name this as fifth implicit verdict, not conflated
# with won't-fix
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5e Step 5 clear-malicious template uses 'we're closing this report' verdict language" {
  run grep -inE "we.re closing this|closing this report" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection names clear-malicious as fifth implicit verdict (architect C4)" {
  # The four documented JTBD-301 verdicts are fix-released / parked /
  # duplicate / won't-fix. clear-malicious is a stronger close
  # (policy-violation) — name it precisely in the subsection prose
  # rather than conflating with won't-fix.
  run grep -inE 'policy.violation close|fifth.*verdict|implicit.*verdict' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "clear-malicious classification gloss is plain-language (JTBD non-blocking advisory)" {
  # JTBD advisory: <classification> in the clear-malicious template
  # MUST be a plain-language gloss, NOT the raw wr-risk-scorer verdict
  # token. SKILL prose must specify this so the reporter sees
  # human language, not "out-of-scope-for-documented-personas".
  run grep -inE 'plain.language gloss|plain-language.*classification' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5e Step 6 — safe-and-valid verdict template (accepted-into-backlog)
# Architect condition C3: name as "accepted into backlog", not fix-released
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5e Step 6 safe-and-valid template uses 'we're tracking this as a real bug' verdict language" {
  run grep -inE "tracking this as a real|tracking.*real bug" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5e Step 6 template does NOT include framework vocab 'safe-and-valid branch' in comment body" {
  # The 31-comment leak: "classified via /wr-itil:review-problems Step
  # 4.5e safe-and-valid branch with safe-low-fix-risk" appeared in
  # comment bodies. The new template prose must show the reporter-facing
  # body and not include the framework-vocab phrasing inside a comment-body block.
  # Note: the steps section header itself names "Safe-and-valid branch" —
  # that's the maintainer prose and fine. This test checks the COMMENT-BODY
  # template (which lives in a fenced code block under Step 6) does not include
  # the leak phrase "safe-low-fix-risk".
  run grep -nE 'safe-low-fix-risk' "$SKILL_FILE"
  # Token may appear in maintainer prose / classifier docs — but MUST NOT
  # appear inside a fenced comment-body template block. We assert the token
  # appears AT MOST in step-3 dual-axis-risk-classifier prose and the audit-log
  # surface; not in a quoted comment template body. We use a structural proxy:
  # the new 4.5e-comment-shape subsection MUST explicitly call out that the
  # token belongs in maintainer-side audit-log only, not in the user-facing comment.
  run grep -inE "safe-low-fix-risk.*audit.log only|safe.low.fix.risk.*maintainer.side" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection names Step 6 verdict as 'accepted into backlog' (architect C3)" {
  # JTBD-301 'fix released' is the post-release verdict — the Step 6
  # ack fires at accept-into-backlog time. Name the verdict precisely
  # in the subsection prose.
  run grep -inE 'accepted into backlog|accept.into.backlog' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5e Step 6 template references release-notes / status surface for future updates" {
  # JTBD-301 desired outcome: reporter knows where to watch for updates.
  # The template must point to a stable surface (release notes / status
  # page / linked issue) so the reporter has actionable expectation.
  run grep -inE 'release notes|release-notes|watch this issue' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Architect condition A1 — gate-denial sub-branches preserved across all four
# verdict-shape templates (no silent-skip regression)
# ──────────────────────────────────────────────────────────────────────────────

@test "All four ack-comment branches preserve gate-denial sub-branches (architect A1)" {
  # Step 4 (pushback), Step 5 (clear-malicious), Step 6 (safe-and-valid)
  # already have gate-denial sub-branches in the current SKILL. The
  # P229 fix preserves them; this assertion catches a regression where
  # a template rewrite accidentally drops the sub-branch.
  run grep -nE 'gate-denied-pushback' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'gate-denied-clear-malicious' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'gate-denied-safe-and-valid' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Architect condition A2 — audit-log preserves classification tokens verbatim
# ──────────────────────────────────────────────────────────────────────────────

@test "Audit-log surface at 4.5f preserves classification tokens (architect A2)" {
  # The user-side template change strips framework vocab from comment
  # bodies; the audit-log surface (4.5f) MUST continue receiving the
  # raw classification tokens for replay determinism per ADR-062.
  run grep -nE '4\.5f.*[Aa]udit-log' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'safe-and-valid-local-ticket-created|above-threshold-pushback|clear-malicious-closed' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# JTBD-301 vocabulary visibility — four-verdict words appear in branch templates
# ──────────────────────────────────────────────────────────────────────────────

@test "P229 root-cause ticket cross-referenced from verdict-shape subsection" {
  # Audit-trail grounding per ADR-026: the SKILL prose change cites
  # the originating ticket so the rationale stays discoverable.
  run grep -nE 'P229' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "verdict-shape subsection cites JTBD-301 by ID" {
  run grep -nE 'JTBD-301' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
