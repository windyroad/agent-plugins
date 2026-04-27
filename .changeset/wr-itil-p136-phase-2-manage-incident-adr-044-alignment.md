---
"@windyroad/itil": patch
---

P136 Phase 2 (ADR-044 alignment audit — manage-incident SKILL.md) per the inline plan on `docs/problems/136-adr-044-alignment-audit-master.open.md`.

Third per-skill amendment in the suite-wide audit (after `work-problem` singular at `@windyroad/itil@0.21.4` and `mitigate-incident` at `0.21.5`). **Closes Phase 2 of P136** — all three high-ask SKILLs (work-problem singular, mitigate-incident, manage-incident) are now aligned with ADR-044's framework-resolution boundary and 6-class authority taxonomy.

Manage-incident's audit found **0 lazy-deferrals to remove** (incident-declaration is fundamentally interactive — all 4 call surfaces are genuine user-authority surfaces per the 6-class taxonomy). Two refactors and two cosmetic cross-references shipped.

**Surface 1 — Step 2 duplicate-check REFACTOR (closes ADR-013 Confirmation #1 regression).** The prior prompt body at line 134 contained `"Would you like to (a) update an existing incident, (b) declare a new incident anyway, or (c) cancel?"` — both the `would you like` phrasing and the `(a)/(b)/(c)` parenthetical match the regex in ADR-013 Confirmation criterion #1 (`grep -inE "Options:.*\(a\)\|Your call:\|which would you like\|which way?"` — must return zero matches outside test fixtures). The refactor lifts the 3 options into the `AskUserQuestion` `options[]` mechanism (with `header: "Active incidents found"`) and rewrites the prompt body as plain prose ("Choose how to proceed:"). Behavioural change: none — same 3 options, same outcome paths. Compliance fix.

**Surface 2 — Step 4 gather-info KEEP + cosmetic ADR-044 cat-1 cross-ref.** Title / Symptoms / Scope / Start time / Severity are user-knowledge inputs that the framework cannot infer; this is canonical category-1 (direction-setting). No behavioural change.

**Surface 3 — Step 6 evidence-first gate REFACTOR (cross-skill consistency with mitigate-incident).** The prior prose at line 208 was an open backfill prompt: `"ask via AskUserQuestion what evidence supports it"`. The refactor aligns with `/wr-itil:mitigate-incident` Step 3's 3-option pattern (Add evidence / Record anyway with audit-trail bypass / Cancel) and includes the documented `[<timestamp> UTC] Evidence-gate bypassed by user — reason: <justification>` audit-trail prose so post-incident review can grep every bypassed gate. Behavioural change: ADDS an explicit documented bypass option that previously had no documented escape hatch (the implicit bypass existed — a user could type "no evidence" and the skill would comply — but it was un-audited). The refactor converts implicit-soft-gate to explicit-hard-gate-with-audit-trail. Annotated as ADR-044 **category-2 (deviation-approval)** surface.

**Surface 4 — Step 14 risk-above-appetite KEEP + cosmetic ADR-044 cat-3 cross-ref.** Annotated as the **category-3 (one-time-override)** surface for cross-skill consistency with mitigate-incident Step 8.

**Cascading prose updates**: NEW Related section added (manage-incident previously had no Related section); enumerates P136, ADR-044, ADR-013 amended Rule 1, ADR-013 Confirmation criterion #1, ADR-011, ADR-014/015/018/020/026/042, P071, P081, JTBD-001/101/201.

**Bats coverage** (P136 Phase 2 / per inline plan R5-equivalent):
- `packages/itil/skills/manage-incident/test/manage-incident-adr-044-contract.bats` (NEW companion file) — 11 contract assertions covering: Step 2 negative regression guards (`would you like`, `(a)/(b)/(c)`); Step 2 ADR-044 cat-1 cross-ref; Step 2 retains 3-option choices (positive guard); Step 4 ADR-044 cat-1 cross-ref; Step 6 3-option pattern (Add / Record-anyway / Cancel); Step 6 ADR-044 cat-2 cross-ref; Step 6 bypass-marker prose; Step 14 ADR-044 cat-3 cross-ref; bats marker present; SKILL.md cites P136 + ADR-044.
- The companion file carries the `tdd-review: structural-permitted` marker per P081 + P136 bridge. The sibling functional file `manage-incident.bats` deliberately avoids structural-grep on SKILL.md prose (P011 ban); the new companion is the dedicated structural-grep-permitted home for the ADR-044 alignment contract during the bridge window.
- All 11 new + 14 existing manage-incident assertions green; full itil package suite still green.

**Architect + JTBD review verdict**: PASS. Architect explicitly noted the Surface 1 refactor **closes an existing ADR-013 Confirmation criterion #1 violation** at line 134 (line numbers verified). JTBD reviewer addressed the Surface 3 trade-off favorably: making the bypass explicit *strengthens* JTBD-201's "auditability of AI-assisted incident work" outcome by converting an implicit, undocumented evidence-gate bypass into an explicit, audit-trailed bypass option; the cool-headed-commitment is preserved because `Add evidence` remains the friction-free default and bypass requires conscious second choice. JTBD-101 (extend the suite) advanced — adopters now get one consistent evidence-gate pattern across both incident skills.

**P136 audit-log update**: `docs/problems/136-adr-044-alignment-audit-master.open.md` Investigation Tasks checklist marks Phase 2 manage-incident complete. **Phase 2 is now 3/3 done** — all high-ask SKILLs audited. Phase 3 (medium/low-ask SKILLs, ~26 surfaces) is the next phase, deferred to a future session per per-skill release cadence (R1).

Refs: P136 (master), ADR-044 (anchor), ADR-011 (incident lifecycle + evidence-first), ADR-013 amended Rule 1, ADR-013 Confirmation criterion #1 (regression closed), ADR-010, ADR-014, ADR-015, ADR-018, ADR-020, ADR-026, ADR-042, P057, P071, P081, P135, JTBD-001 / JTBD-101 / JTBD-201.
