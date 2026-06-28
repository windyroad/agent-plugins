# Problem 174: Topic-file rotation contract requires `first-written` HTML metadata that doesn't exist on most briefing entries — Step 3 Branch A unenforceable in practice

**Status**: Known Error
**Reported**: 2026-05-06
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

Topic-file rotation contract assumes `first-written` HTML metadata that doesn't exist on most entries — Step 3 Branch A unenforceable.

`/wr-retrospective:run-retro` Step 3 Tier 3 budget pass surfaces files with bytes >= 2x ceiling as `MUST_SPLIT`, mandating split-by-subtopic OR split-by-date with no defer permitted. Split-by-date requires the `first-written` HTML comment metadata per Step 1.5; split-by-subtopic needs sub-topic boundaries.

**2026-05-06 evidence (I001 mitigation retro)**: 3 MUST_SPLIT files (`governance-workflow.md`, `hooks-and-gates.md`, `releases-and-ci.md`). `grep -c first-written` returns 1, 1, 3 entries per file (vs ~20-30 entries each). `grep -nE '^##\|^###'` shows 1-2 top-level sections per file with bullet entries directly under them.

Without metadata, split-by-date is arbitrary (no signal for which entries are oldest). Without rich heading structure, split-by-subtopic isn't a clean fit. Contract ends up unenforceable in practice — agent must defer (which Branch A says is not eligible) or pick arbitrary splits.

**Fix candidates** (deferred to investigation; pick after architect review):

- **(a) One-time metadata-bootstrap pass** that backfills `first-written` from `git blame` per entry. Mechanical: walk `docs/briefing/*.md`, run `git blame -L <line>,<line>` for each entry's anchor line, extract the earliest commit date, append `<!-- first-written: YYYY-MM-DD | last-classified: <today> | signal-score: 0 -->` HTML comment per Step 1.5 schema. Reversible (just delete the comments). Preserves existing entries.
- **(b) Amend Step 3 Branch A** to accept "no metadata + no clear subtopic → record OVER and surface in summary, no forced action this retro" as a non-defer outcome. Effectively narrows Branch A to files where AT LEAST ONE rotation option is feasible. Avoids the unenforceability trap.
- **(c) Add a Step 1.5b requirement** that any new briefing entry MUST carry `first-written` comment. Bootstraps forward but doesn't address the legacy-entry gap.

Likely combination: (a) for the bootstrap + (c) for going forward. (b) as a fail-safe on top.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Open → Known Error 2026-06-16 — fixed-elsewhere reconcile (AFK work-problems iter 22).**

**Root cause (confirmed).** The capture (2026-05-06) was written against an earlier Step 3 Tier 3 contract in which split-by-date was specified as **requiring** the `first-written` HTML-comment metadata to determine entry age. With ~1–3 `first-written` comments per ~20–30-entry file, that metadata gap made split-by-date infeasible on most files. Combined with P145's "do-nothing options not eligible on MUST_SPLIT" amendment, Branch A had no feasible action left → the unenforceability trap (defer-not-permitted AND no metadata-backed split possible).

**Why now closed (superseded by the P145 → P246 → P247 rotation rework).** The unenforceability was eliminated when split-by-date was re-specified as a **metadata-independent mechanical safe default** during the evidence-based-rotation rework — not via a dedicated P174 fix. Current released contract (`@windyroad/retrospective` 0.23.2 cache / 0.24.1 source), `run-retro/SKILL.md` Step 3 Tier 3:

- **Branch A split-by-date (SKILL line 362)**: *"the **safe default** when no sub-topic boundary is obvious. Older entries archive cleanly without semantic judgement (**mtime-sort + median-age threshold**), so the action is mechanical and AFK-safe … split-by-date is preferred when the boundary is unclear because it has **zero false-split risk**."* No `first-written` dependency — there is always a feasible Branch A action, so the defer-trap is gone.
- **Branch B fall-through (SKILL line 369)**: identical metadata-free safe default — *"mtime-sort entries, archive the oldest half"* — explicitly *"the same safe-default Branch A uses when its boundary is unclear."*
- `first-written` survives only as a **preferred-when-present** signal for the Branch B clear-date-stratified case (SKILL line 367), never as a precondition.

This resolves fix-candidate **(b)** in substance (Branch A always has a feasible non-defer action) and **(c)** in substance — the forward-fill contract is in place: SKILL line 67 sets `first-written` when an entry is created and treats a missing comment as today. Candidate **(a)**, the one-time `git blame` legacy backfill, is **not load-bearing** because no rotation branch depends on `first-written`; empirically it has also been largely satisfied organically (the 3 originally-cited MUST_SPLIT files now carry near-complete metadata: `hooks-and-gates.md` 7/7, archive siblings 100%).

**Corroboration.** Closed sibling **P247** (`@windyroad/retrospective@0.19.0`, commit `b22e006`) shipped the Branch B evidence-based rotation and explicitly cites *"split-by-date safe-default fall-through mirroring **Branch A precedent**"* — i.e. Branch A's metadata-free mtime-sort safe default already existed and was the precedent P247 built on. Composes-with [[P145]] (recurring-defer), and the P246/P247 evidence-based-rotation cohort.

**Residual (non-blocking, noted not split out).** The SKILL phrase "mtime-sort entries" is loosely worded for *within-file* entry ordering — filesystem mtime is a whole-file property, so per-entry age in practice uses document order (entries are appended chronologically) or `git blame`, with whole-file mtime selecting *which* file to rotate. The behaviour ("archive the oldest half / oldest entries," reversible) is well-defined and AFK-safe; the wording is a doc-precision nit, not a behavioural defect. Recorded here per the hang-off-before-new-ticket discipline rather than captured as a sibling; pick up only if a future retro shows ambiguity causing a bad split.

**ADR-074**: no born-proposed unconfirmed decision — this disposition is evidence-based reconciliation against the released SKILL, not a design choice requiring substance-confirm.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — deferred (ownership: `/wr-itil:review-problems`; WSJF 1.5 unchanged this reconcile)
- [x] Investigate root cause — confirmed: pre-rework split-by-date required `first-written`; rework made it metadata-free mechanical safe default (above)
- [x] Create reproduction test — not separately needed; behavioural coverage already lands via P247's `check-briefing-budgets.sh` Branch A/B selector fixture (11 assertions, per P247 closure note)
- [ ] Verification: confirm no recurrence of the unenforceability trap across ≥1 further retro cycle on the released contract, then advance Known Error → Verification Pending → Closed per ADR-022. Recovery if wrong: `/wr-itil:transition-problem 174 open`

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P145 (run-retro Tier 3 rotation prompt accumulates defer answers recurringly — same Step 3 surface; P145 fixed the recurring-defer pattern, this ticket addresses the new failure mode that emerged after P145's fix forced action on MUST_SPLIT)

## Related

(captured via /wr-itil:capture-problem during 2026-05-06 I001 mitigation retro Step 3; expand at next investigation)
