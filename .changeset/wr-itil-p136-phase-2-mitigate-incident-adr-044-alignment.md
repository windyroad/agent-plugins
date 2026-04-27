---
"@windyroad/itil": patch
---

P136 Phase 2 (ADR-044 alignment audit — mitigate-incident SKILL.md) per the inline plan on `docs/problems/136-adr-044-alignment-audit-master.open.md`.

Second per-skill amendment in the suite-wide audit (after `work-problem` singular at `@windyroad/itil@0.21.4`). Removes the lazy-deferral argument-backfill `AskUserQuestion` from Step 1 / Arguments section and adds inline ADR-044 cross-references on the two retained user-authority surfaces (evidence-first gate; risk-above-appetite commit).

**Surface 1 — argument backfill becomes fail-fast (AMEND).** Replaces the `ask via AskUserQuestion` instructions at lines 20 / 50 / 52 with a fail-fast usage message + exit. Argument malformation is a typo-class signal, not a decision; the slash command IS the input contract. Re-typing in 1 second beats a multi-turn `AskUserQuestion` dialogue, and the suite now has consistent argument-backfill semantics across `transition-problem` Step 1, `work-problem` singular, and `mitigate-incident` Step 1. The new Step 1 emits an explicit `Usage:` block (incident ID format + action shape + `/wr-itil:list-incidents` pointer for ID discovery) so adopters and first-time users get a discoverable contract.

**Surface 2 — evidence-first gate (KEEP + cross-ref).** ADR-011's evidence-first rule IS the existing decision; "Record anyway" IS the user-approved deviation; user IS the right authority. Annotated as the ADR-044 **category-2 (deviation-approval)** surface. The 3-option vocabulary (Add evidence / Record anyway / Cancel) and the `## Audit trail` note appended on bypass are both unchanged. The cross-reference makes the framework-resolution boundary visible at the call site (Step 3 + the Evidence-first gate header).

**Surface 3 — risk-above-appetite commit (KEEP + cross-ref).** In incident-mitigation context, the tech lead may need to ship a mitigation despite higher residual risk to restore service fast (JTBD-201). The rule (RISK-POLICY appetite) still stands; this specific case is a strategic exception. Annotated as the ADR-044 **category-3 (one-time-override)** surface. The 3-option vocabulary (commit anyway / remediate / park) is unchanged; the ADR-013 Rule 6 fail-safe (skip + report when `AskUserQuestion` is unavailable) is preserved.

**Bats coverage** (P136 Phase 2 / per inline plan R5-equivalent):
- `packages/itil/skills/mitigate-incident/test/mitigate-incident-contract.bats` (UPDATED) — 7 new contract assertions: Step 1 fail-fast usage block; Step 1 negative regression guard against `AskUserQuestion` re-entry for argument backfill; Arguments section negative regression guard; Step 3 ADR-044 category-2 cross-reference; Step 8 ADR-044 category-3 cross-reference; positive guard that `AskUserQuestion` is RETAINED for Surfaces 2 + 3 (frontmatter `allowed-tools` + Step 3 prose + Step 8 prose); `tdd-review: structural-permitted` marker present per P081 + P136 bridge. All 20 assertions green; all 534 itil package skill tests still green.
- File carries the `tdd-review: structural-permitted` marker per the P136 Phase 2 inline plan's bridge-marker rule (P081 Phase 2 owns the canonical retrofit).

**Architect + JTBD review verdict**: PASS. Architect cited the `transition-problem` Step 1 precedent line-for-line as the matching shape for Surface 1; no conflicts with ADR-011, ADR-013 amended, ADR-014, ADR-015, ADR-018, ADR-020, ADR-026, ADR-042, ADR-044, P057, P062, P071. JTBD-201 (restore service fast with audit trail) advanced — fail-fast preserves "restore fast" by avoiding multi-turn dialogue during high-adrenaline incident response; evidence-first audit-trail outcome unchanged. JTBD-001 (governance without slowing down) advanced — consent-gate-for-the-obvious removed from Surface 1; legitimate consent gates retained on Surfaces 2 + 3. JTBD-101 (extend the suite) cleaner adopter contract — argument backfill is now consistent across `transition-problem` / `work-problem` / `mitigate-incident`. JTBD-006 (AFK backlog) neutral — incident skills are interactive by definition; no AFK-loop regression.

**P136 audit-log update**: `docs/problems/136-adr-044-alignment-audit-master.open.md` Investigation Tasks checklist marks Phase 2 mitigate-incident complete (2 of 3 high-ask SKILLs done; manage-incident next).

Refs: P136 (master), ADR-044 (anchor), ADR-011 (incident lifecycle), ADR-013 amended Rule 1, ADR-010, ADR-014, ADR-015, ADR-018, ADR-020, ADR-026, ADR-037, P057, P071, P081, P135, JTBD-001 / JTBD-006 / JTBD-101 / JTBD-201.
