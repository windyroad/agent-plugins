# Problem 247: run-retro Step 3 Tier 3 Branch B "leave-as-is" encodes fictional defer — sibling to P246 evidence-based criterion

**Status**: Open
**Reported**: 2026-05-17
**Priority**: 9 (Med) — Impact: 3 (Moderate — briefing topic files accumulate past Tier 3 thresholds; each retro defers ratherthan rotating; the deferred rotations have no scheduled-future-surface; same fictional-defer class as P234 / P145 / P246 at a different SKILL surface) × Likelihood: 3 (Likely — fired today on session 4 wrap retro for 14 OVER files; will fire on EVERY future retro until SKILL contract is amended)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**WSJF**: 9/2 = **4.5** (deferred — provisional; ties with P132 + P246)
**Type**: technical (skill-contract violation)

## Description

Class-of-behaviour: when `/wr-retrospective:run-retro` Step 3 Tier 3 budget pass detects topic files OVER threshold but with ratio < 2.0x (Branch B), the contract permits "leave-as-is" as an option. The agent picks "leave-as-is" reflexively (Branch B default) and records `Decision: defer (Branch B)` in the retro summary. **The defer has no scheduled-future-surface** — "next retro will pick it up when more signal accumulates" is the same fictional defer that P246 captures for held-cohort graduation.

The SKILL contract's Branch B is itself a defective contract clause (sibling to ADR-061's calendar-trigger predicates that P246 flags). Both encode "wait for more time/signal" without a concrete trigger condition.

Evidence — 2026-05-17 session 4 wrap retro:
- 14 topic files detected OVER threshold (5120 bytes):
  - 12 in Branch B (1.0x-2.0x range)
  - 2 within 0.05x of MUST_SPLIT threshold (hooks-and-gates-archive.md 1.96x; releases-and-ci-archive.md 1.94x)
- Agent's retro summary marked ALL 14 as `defer (Branch B)` without:
  - Evaluating whether sub-topic boundaries exist (Branch B option 1)
  - Evaluating whether date stratification exists (Branch B option 2)
  - Evaluating whether ≥3 noise-classified entries surfaced this retro per file (Branch B option 3)
- User correction: *"The 14 files are over the limit, but you are deferring splitting them. Why? When are you hoping they will get dealt with?"*
- The "leave-as-is" option's contract semantics: *"record the OVER state in the Step 5 summary; no action this retro. Picks up next retro when more signal accumulates."* — but next retro isn't scheduled; the "more signal" condition is undefined.

Sibling tickets:
- **P246** — agent waits on calendar trigger for held-cohort graduation; same class at the held-changeset surface
- **P234** — fictional defer rationalization (prose-defer surface)
- **P145** — recurring-defer at Tier 3 budget rotation surface specifically (this ticket generalizes)
- **P148** — Stage 1 ticketing fictional-defer at Step 4b Stage 1 surface
- **P179** — phases are fine IF captured with scheduled-future-surface

Distinguishing surface: run-retro Step 3 Tier 3 Branch B "leave-as-is" option. The Branch A force-action path (ratio ≥ 2.0x) is correct — that's the evidence threshold. Branch B's defer-permitted should be either:
(a) eliminated entirely — if OVER, rotate now via the best-fit option (subtopic / date / trim-noise); never leave-as-is
(b) tightened to require explicit per-file justification when leave-as-is fires (e.g. "no subtopic boundary AND no date stratification AND no noise entries — file content is fundamentally dense and cannot rotate"); record the justification per-file in the retro summary

Preferred fix: option (a). Per the P246 principle (evidence-based criterion, not heuristic), if a file is OVER threshold there IS evidence to act on; "no action" requires positive evidence that none of the rotation options apply, which is itself a per-file evaluation that's mechanical and AFK-safe.

## Symptoms

- Retro summaries show `defer (Branch B)` for files OVER threshold without per-file justification.
- Topic files accumulate past 2.0x threshold before forced action via Branch A — the lag time is wasted potential, not safety margin.
- Each retro re-defers the same files; the "more signal" condition for "next retro" is never explicitly evaluated.
- Sibling P145 already documented "recurring defer of Tier 3 rotation at retros 2026-05-15 + 2026-05-17 morning" — the pattern is RECURRENT, evidence-attested, and the SKILL contract still encodes it as the default.

## Workaround

User catches each retro's defer + manually directs rotation. Currently manual (the 2026-05-17 session 4 wrap retro is the worked example — user's "When are you hoping they will get dealt with?" surfaced the gap).

## Impact Assessment

- **Who is affected**: every retro that touches topic files past threshold. Frequency: every retro that runs (the budget script always emits OVER lines for accumulated content).
- **Frequency**: today's retro has 14 OVER files; every prior retro since the briefing tree was split (~2026-04-22) probably had at least 1-3 deferred files per cycle.
- **Severity**: Moderate. Files accumulate past 2.0x before forced action; user has to police the defer.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Amend `/wr-retrospective:run-retro` Step 3 Tier 3 SKILL.md** to eliminate or tighten Branch B "leave-as-is" per the preferred fix (option (a) or (b))
- [ ] **Rotate the 14 OVER files** currently in `docs/briefing/` per evidence-based criterion (the same work this ticket scope-defines — the ticket IS the scheduled-future-surface for that work per P179 carve-out)
- [ ] Audit other run-retro Step contracts for similar "leave-as-is" / "defer to next retro" patterns (Step 1.5 Tier 1 promotion, Step 2b detection skipping, Step 4a verification-pending leaving-alone)
- [ ] Create reproduction test — bats fixture: file at 1.5x ratio + with subtopic boundary → should rotate, not defer; file at 1.5x ratio + no boundary → should require per-file justification, not silent defer

## Dependencies

- **Blocks**: every future retro will continue to over-defer until fixed
- **Blocked by**: none — fix is purely SKILL.md edit + per-Branch-B-option mechanical evaluation
- **Composes with**: P246 (parent class principle), P234 (fictional defer parent), P145 (Tier 3 surface predecessor — should fold P145 into this ticket or supersede)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P246** — sibling class at held-cohort graduation surface (calendar trigger vs evidence)
- **P234** — parent class (fictional defer rationalization)
- **P145** — predecessor ticket at this exact surface (Tier 3 recurring defer) — likely fold this ticket into P145 OR supersede P145
- **P148** — sibling class at Step 4b Stage 1 (deferring observations to Tickets Deferred section without skill_unavailable cause)
- **P179** — phases are fine IF scheduled-future-surface named (this ticket IS the SFS for the 14-file rotation work)
- **ADR-061** Rule 1 — symmetric balance principle (evidence-based, not time-based)
- **ADR-013** Rule 5 — policy-authorised silent proceed (Branch A correctly uses this; Branch B should too when evidence supports rotation)
