---
"@windyroad/retrospective": minor
---

P135 Phase 5 (Measurement) — `run-retro` Step 2d "Ask Hygiene Pass" + advisory script.

Per ADR-044 (Decision-Delegation Contract), every retro emits a per-session classification of the agent's `AskUserQuestion` calls so the **lazy-AskUserQuestion-count** regression metric is visible at session-time rather than after the user notices the friction. Phase 5 lands BEFORE Phase 2/3 to establish baseline so the lazy-count drop after Phase 2/3 land is measurable.

**New surfaces:**

- `packages/retrospective/skills/run-retro/SKILL.md` Step 2d — classify each session AskUserQuestion call per ADR-044's 6-class authority taxonomy (direction / deviation-approval / override / silent-framework / taste / correction-followup / **lazy**). Emit table in Step 5 retro summary; persist trail entry at `docs/retros/<YYYY-MM-DD>-ask-hygiene.md`.
- `packages/retrospective/scripts/check-ask-hygiene.sh` — advisory diagnostic mirroring `check-briefing-budgets.sh` shape. Reads `docs/retros/*-ask-hygiene.md` trail; tabulates lazy-count trend over last N retros. Exits 0 (always advisory). Window override via `ASK_HYGIENE_WINDOW`.
- `packages/retrospective/scripts/test/check-ask-hygiene.bats` — 18 behavioural assertions covering empty dir, missing dir, single entry, multi-entry sort, TREND line, window override, category-coverage, format tolerance, cross-shell portability (P124 / P133 lessons), and read-only contract.

**Anti-pattern preserved**: classification ownership is silent agent judgement (no AskUserQuestion-about-AskUserQuestion meta-loop). The lazy count is the regression signal; correction is the user's call (via direction-setting / deviation-approval / authentic-correction per ADR-044 categories) on the user's own cadence.

Refs: P135 (master ticket), ADR-044 (anchor), ADR-040 (Tier 3 advisory-not-fail-closed precedent), ADR-038 (progressive-disclosure budget), ADR-026 (cost-source grounding for citations), ADR-005 / ADR-037 (behavioural test pattern).
