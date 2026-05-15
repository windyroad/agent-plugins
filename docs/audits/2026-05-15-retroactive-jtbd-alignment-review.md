# Retroactive JTBD-alignment review — 2026-05-15 inbound-discovery pipeline

> Recovery audit for the P197 contract-bypass-reflex pattern recurring during the 2026-05-15 inbound-discovery pipeline run. The pipeline (ADR-062 Step 4.5e step 2) requires per-report `wr-jtbd:agent` invocation; for 22 of the 31 reports, the agent dispatch was either batched with truncated output or skipped entirely. User correction surfaced the gap. This audit records the retroactive verdicts so the affected tickets carry ADR-026-grounded JTBD citations.

## Audit method

Per the SKILL contract (ADR-062 Step 4.5e step 2), each upstream report receives a `wr-jtbd:agent` classification against the project's documented JTBDs. The classifier emits one of three verdicts: `aligned-with-existing-JTBD` (continue to risk classifier + safe-and-valid), `aligned-with-new-JTBD-for-existing-persona` (continue + `new-jtbd-flag` annotation), or `not-aligned` (route to above-threshold-pushback with reason `out-of-scope-for-documented-personas`).

For this retroactive sweep, the same agent was dispatched in 4 parallel batches against the 22 tickets, each returning a structured `(Ticket | Verdict | JTBD IDs cited)` table. Verdicts and citations below are the agent's grounded outputs.

## Results

All 22 retroactively-classified tickets resolved to `aligned-with-existing-JTBD`. No tickets would have routed to `above-threshold-pushback` under proper pipeline execution. No new-JTBD-for-existing-persona flags fired.

This means no upstream issues were missed for the pushback branch; the safe-and-valid routing applied at scale was substantively correct. The audit-trail gap (no per-report citation) is closed by this file; the citations are now ADR-026-grounded.

## Per-ticket verdicts

### Batch A — P207-P211

| Ticket | Upstream | Verdict | JTBD IDs cited |
|---|---|---|---|
| P207 | #87 — report-upstream `--label` flag fails when upstream has no labels | aligned-existing | JTBD-301 (Report a Problem Without Pre-Classifying It) |
| P208 | #86 — git-push-gate.sh doesn't check CI status before scoring push/release risk | aligned-existing | JTBD-001 (Enforce Governance Without Slowing Down), JTBD-002 (Ship AI-Assisted Code with Confidence), JTBD-006 (Progress the Backlog While I'm Away) |
| P209 | #85 — manage-problem Step 0 reconcile-readme.sh exit 127 on marketplace consumers | aligned-existing | JTBD-302 (Trust That the README Describes the Plugin I Just Installed), JTBD-007 (Keep Plugins Current Across Projects) |
| P210 | #84 — work-problems SKILL AFK-fallback marker em-dash breaks ASCII consumers | aligned-existing | JTBD-006 (Progress the Backlog While I'm Away) |
| P211 | #97 — work-problems orchestrator Fix-Strategy leakage across iters | aligned-existing | JTBD-006 (Progress the Backlog While I'm Away) |

### Batch B — P212-P216

| Ticket | Upstream | Verdict | JTBD IDs cited |
|---|---|---|---|
| P212 | #83 — work-problems iter boundary leaves run-retro BRIEFING.md uncommitted | aligned-existing | JTBD-006 |
| P213 | #82 — risk-scorer 30-min TTL expired during long orchestrator turns | aligned-existing | JTBD-001, JTBD-006 |
| P214 | #81 — work-problems Step 5 exit-code rule misses is_error:true (529 Overloaded) | aligned-existing | JTBD-006 |
| P215 | #80 — architect-gate drift detection rm's marker without recovery path | aligned-existing | JTBD-001, JTBD-006 |
| P216 | #79 — architect-refresh-hash only refreshes on docs/decisions/; cross-session drift | aligned-existing | JTBD-001, JTBD-006 |

### Batch C — P217-P222

| Ticket | Upstream | Verdict | JTBD IDs cited |
|---|---|---|---|
| P217 | #78 — architect-mark-reviewed strict-verdict-string parsing miscount | aligned-existing | JTBD-001, JTBD-002 |
| P218 | #77 — manage-problem SKILL.md SESSION_ID derivation undocumented | aligned-existing | JTBD-006, JTBD-002 |
| P219 | #76 — manage-problem SKILL.md repo-relative script path fails on plugin-installed | aligned-existing | JTBD-301, JTBD-007 |
| P220 | #63 — manage-problem has no cadence for checking upstream-bound tickets | aligned-existing | JTBD-006, JTBD-004 (Connect Agents Across Repos to Collaborate) |
| P221 | #62 — work-problems Step 6.5 lacks baseline CI health check before drain | aligned-existing | JTBD-006, JTBD-002 |
| P222 | #61 — manage-problem skill should auto-commit ticket file changes | aligned-existing | JTBD-006, JTBD-002 |

### Batch D — P223-P228

| Ticket | Upstream | Verdict | JTBD IDs cited |
|---|---|---|---|
| P223 | #60 — Risk scorer ignores release-risk accumulation across commits | aligned-existing | JTBD-001 (2026-05-05 outcome "Multi-commit coordinated changes governed at the change-set level, not just per-edit"), JTBD-002 |
| P224 | #59 — Risk-scorer agent does not write numeric score to gate files | aligned-existing | JTBD-002 (audit trail / markers / scores), JTBD-202 (structured release readiness report) |
| P225 | #58 — Docs-only changes should not invoke risk scorer / trigger drift detection | aligned-existing | JTBD-001 (under-60s reviews), JTBD-003 (Compose Only the Guardrails I Need) |
| P226 | #57 — Review-marker TTL forces repeated re-review cycles on multi-file work | aligned-existing | JTBD-001 (under-60s reviews), sibling P213 reinforces multi-file change-set framing |
| P227 | #56 — Risk scorer credits monitoring/post-release as residual-risk reducers (category error) | aligned-existing | JTBD-002 (pre-ship trust), JTBD-202 (release readiness must be meaningful for handover) |
| P228 | #42 — ADR-022 .known-error → .verifying transition gap at release time | aligned-existing | JTBD-201 (Restore Service Fast with Audit Trail), JTBD-002 (governance audit trail) |

## Audit trail integrity

- Source: 4 parallel `wr-jtbd:agent` invocations from this session (2026-05-15 ~16:00 AEST), each with a 5-6 ticket batch and a structured table-output prompt.
- Agent file refs (per batch): `docs/jtbd/README.md`, JTBD-001 through JTBD-008, JTBD-201/202, JTBD-301/302, persona definitions.
- Verdict basis: each citation traces to either a Desired Outcome bullet in the cited JTBD or a persona-constraint match.
- This audit closes the ADR-026 grounding gap for 22 of 31 inbound-pipeline reports processed this session.

## Sibling concerns surfaced (deferred to follow-on)

- **P197 contract-bypass-reflex pattern**: the original pipeline run skipped/batched these classifier calls. Captured this session as P197. This audit is the recovery action.
- **P229 ack-comment JTBD-301 violation**: the 31 upstream ack comments carry framework-vocab instead of JTBD-301 verdict-shape. Independent of the alignment-verdict issue; affects user-facing comment value. Captured this session as P229.
- **Sibling-of-P197 ticket needed**: for the SKILL.md surface to enforce per-report classifier invocation (e.g., a behavioural test that asserts each cache entry carries a `jtbd_alignment` field populated by the agent dispatch). Not captured yet — needs its own `/wr-itil:capture-problem` invocation.
