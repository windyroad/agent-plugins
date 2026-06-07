---
"@windyroad/retrospective": patch
---

Trace `/wr-retrospective:migrate-briefing` SKILL.md to the new JTBD-009 (Migrate Adopter Artefacts When a Plugin Layout Evolves) — the primary JTBD home ratified by the user on 2026-06-07 (P204 Q1).

JTBD-009 carves out adopter-artefact-layout-currency as a distinct dimension from JTBD-007 (Keep Plugins Current Across Projects), which retains code-currency + README-content-currency + maturity-band-currency. The migrate-briefing skill is JTBD-009's first concrete realisation.

Changes:

- `SKILL.md` now carries an `<!-- @jtbd JTBD-009 -->` HTML-comment annotation (matching the convention used in `packages/itil/skills/work-problems/SKILL.md` and `packages/itil/skills/manage-problem/SKILL.md`).
- `SKILL.md` "See also" section replaces the old `JTBD-007 — pending amendment` forward-reference with a dual trace: JTBD-009 (primary) + JTBD-007 (sibling).

No behaviour change. Trace-only documentation fidelity update so README scans and JTBD reviews resolve the skill to its ratified job home.
