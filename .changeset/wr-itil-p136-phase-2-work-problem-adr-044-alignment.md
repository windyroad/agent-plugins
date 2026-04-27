---
"@windyroad/itil": patch
---

P136 Phase 2 (ADR-044 alignment audit — work-problem singular SKILL.md) per the inline plan on `docs/problems/136-adr-044-alignment-audit-master.open.md`.

First per-skill amendment in the suite-wide audit. Removes the lazy-deferral `AskUserQuestion` from Step 2 ticket selection and converges the interactive and AFK paths to a single framework-mediated tie-break ladder per ADR-044's Framework-Mediated Surface (Prioritisation row).

**Step 2 — selection becomes framework-mediated.** The agent applies the WSJF formula + 5-rung tie-break ladder (1: WSJF score descending; 2: Known Error before Open; 3: smaller effort first; 4: older reported date wins; 5: ticket number ascending) and reports the chosen ticket + the rung that decided. No `AskUserQuestion` fires for selection. The ladder mirrors the logic the plural orchestrator (`/wr-itil:work-problems`) Step 3 already uses, removing the prior interactive-vs-AFK asymmetry that was the lazy-deferral surface ADR-044 was written to close. User-override path documented explicitly: `/wr-itil:work-problem <NNN>` skips the ladder; mid-flow correction (ADR-044 category 6 / P078) is the long-tail catcher.

**Step 4 — scope-expansion gets explicit ADR-044 cross-reference.** No behavioural change. The 3-option scope-change `AskUserQuestion` (Continue / Re-rank / Pick different) is now annotated as the work-item-tactical analog of ADR-044's framework-tactical 5-option deviation-approval vocabulary (Approve+amend / Approve+supersede / Approve+one-time / Reject / Defer). Effort growth IS the contradicting evidence against the WSJF score that ranked the ticket; the user IS the right authority for the shape — the `AskUserQuestion` here is genuine, not lazy.

**Cascading prose updates** (per architect advisory): frontmatter `description` reframed from "Interactive singular variant" to "framework-mediated selection (WSJF + tie-break ladder per ADR-044); singular variant"; overview, Scope bullet list, Ownership Boundary, and Related sections updated for ADR-044 citation discipline. ADR-013 amended Rule 1 reference now scoped to Step 4 only (the retained `AskUserQuestion` surface).

**Bats coverage** (P136 Phase 2 / per inline plan R5-equivalent):
- `packages/itil/skills/work-problem/test/work-problem-contract.bats` (UPDATED) — 6 new assertions covering: framework-mediated selection prose; tie-break-rung-citation report shape (JTBD-201 audit-trail); user-override-path-via-direct-NNN-invocation literal-form (with substring-trap guard against `/wr-itil:work-problems` plural); negative regression guard against `AskUserQuestion`-driven selection re-emerging in Step 2; ADR-044 category-2 cross-reference in Step 4; `tdd-review: structural-permitted` marker present (P081 + P136 bridge). All 25 assertions green; all 534 itil package skill tests still green.
- File carries the `tdd-review: structural-permitted` marker per the P136 Phase 2 inline plan's bridge-marker rule (P081 Phase 2 owns the canonical retrofit).

**Architect + JTBD review verdict**: PASS. No conflicts with existing decisions (ADR-013 amended, ADR-010 amended Skill Granularity, ADR-014, ADR-022, ADR-026, ADR-032, ADR-040, ADR-042, P031, P062, P077). JTBD-001 (enforce governance without slowing down) advanced — one consent gate per session removed; deterministic ladder IS the governance enforcement. JTBD-006 (AFK backlog) simplified — singular and plural now share one selection algorithm. JTBD-101 (extend the suite) cleaner — adopters inherit one path instead of two. JTBD-201 (audit trail) preserved/improved — agent's "I picked P\<NNN\> using rung X" report is reproducible from README state.

**P136 audit-log update**: `docs/problems/136-adr-044-alignment-audit-master.open.md` Investigation Tasks checklist marks Phase 2 work-problem singular complete (1 of 3 high-ask SKILLs done; mitigate-incident next).

Refs: P136 (master), ADR-044 (anchor), ADR-013 amended Rule 1, ADR-010 amended Skill Granularity, ADR-014 (commit grain), ADR-026 (grounding for tie-break-rung citations), ADR-032 + P077 (work-problems plural delegation), ADR-037 (contract-assertion bats pattern), P031 (cache-freshness check), P062 (review-problems canonical README writer), P081 (structural-grep retrofit; bridge marker), JTBD-001 / JTBD-006 / JTBD-101 / JTBD-201.
