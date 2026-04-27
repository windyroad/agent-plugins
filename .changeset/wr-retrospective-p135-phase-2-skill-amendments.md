---
"@windyroad/retrospective": minor
---

P135 Phase 2 (Skill amendments — `@windyroad/retrospective` half) per ADR-044 (Decision-Delegation Contract).

Removes per-action `AskUserQuestion` calls in `run-retro` where the framework has already resolved the decision (lazy deferral per Step 2d Ask Hygiene Pass classification). Replaces with silent agent-action + Step 5 retro summary surfacing. User correction via the P078 capture-on-correction surface (authentic-correction per ADR-044 category 6).

**Step 3 — briefing removals**: replaced "Use the AskUserQuestion tool to confirm any removals" with silent-classification per Step 1.5 ownership rules. Agent owns remove / trim / compress decisions; user reads Step 5 summary and corrects via authentic-correction if a removal was wrong.

**Step 3 — Tier 3 topic-file rotation (P099)**: replaced the per-file 4-option `AskUserQuestion` with silent agent-picked rotation shape based on heuristics (file mtimes for split-by-date / Step 1.5 signal scores for trim-noise / sub-topic boundaries for split-by-subtopic). Surfaced choice + per-file delta in Step 5 summary. AFK and interactive modes use identical behaviour (no `AskUserQuestion` differentiation).

**Step 4a — verification close**: replaced per-candidate "Close P<NNN> / Leave / Flag" `AskUserQuestion` with close-on-evidence delegation to `/wr-itil:transition-problem <NNN> close` (cross-plugin dispatch). Per-candidate ask was sub-contracting framework-resolved decisions back to the user. Closes are reversible (`/wr-itil:transition-problem <NNN> known-error` flip-back); recovery path documented inline alongside each close action. Cross-plugin dispatch contract has explicit failure-mode handling: dispatch-failed surfaces in summary; dispatch-unavailable gracefully falls back; close-action result records in Decision column.

**Step 4b Stage 2 — fix-shape per ticket**: replaced per-ticket 4-option `AskUserQuestion` with agent-picks-obvious-fit shape from the catalog (skill / agent / hook / settings / script / CI / ADR / JTBD / guide / test fixture / memory / internal-code). User edits ticket if shape was wrong. Recording mechanics unchanged; the Stage 2 catalog is unchanged — only the asking-vs-acting boundary changed.

**Bats coverage** (Phase 2 R3 + R5):
- `packages/retrospective/skills/run-retro/test/run-retro-step-4a-cross-plugin-dispatch.bats` (NEW per R3) — 11 assertions covering dispatch contract, failure-mode surfacing, dispatch-unavailable graceful fallback, recovery-path documentation, same-session-verifyings exclusion preservation, legacy-3-option-block removal.
- `packages/retrospective/skills/run-retro/test/run-retro-step-4a-recovery-path.bats` (NEW per R5) — 6 assertions covering recovery-path documentation inline, recovery skill invocation naming, P124 precedent citation, reversibility affirmation, Step 5 summary surfacing, authentic-correction routing.

Refs: P135 (master), ADR-044 (anchor), ADR-014 (commit grain), ADR-022 (lifecycle), ADR-026 (grounding), ADR-013 Rule 1 narrowing precedent, P078 (authentic-correction surface), P124 (verifying-flip-back precedent), P132 (inverse-P078 enforcement).
