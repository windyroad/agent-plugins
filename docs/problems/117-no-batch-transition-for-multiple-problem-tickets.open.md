# Problem 117: No batch-transition surface for multiple problem tickets in a single run-retro / review cycle

**Status**: Open
**Reported**: 2026-04-24
**Priority**: 6 (Med) — Impact: Minor (2) x Likelihood: Likely (3)
**Effort**: M (new skill OR argument extension + arg parser changes + bats)
**WSJF**: (6 × 1.0) / 2 = **3.0**

> Surfaced during this session's run-retro Step 4a. User explicitly requested the ticket after observing four verification-close transitions executed inline (not via `/wr-itil:transition-problem` delegation) because per-ticket Skill invocations would each re-load the transition-problem SKILL.md context, creating N× overhead on an inherently-batchable operation.

## Description

`/wr-itil:transition-problem` is the canonical executor for per-ticket lifecycle transitions (Open → Known Error → Verification Pending → Closed). Per ADR-010 amended "Split-skill execution ownership" and P093's resolution, the skill hosts the rename + Edit + P057 re-stage + P062 README refresh + ADR-014 commit inline.

The skill's argument shape is `<NNN> <status>` — one ticket per invocation. There is no batch surface. When N tickets need the same transition in one operation — as in `run-retro` Step 4a's verification-close housekeeping after a multi-ticket session, or `manage-problem review` Step 9d's closure prompts across the Verification Queue — the caller faces a choice:

1. **Delegate N separate times**, one `Skill` invocation per ticket. Each invocation re-loads the full `transition-problem` SKILL.md into context. For 4 tickets this is ~4× the SKILL.md footprint in context, duplicating the same procedural knowledge for each closure. Given SKILL.md runtime size concerns (P097), the amplification is material.
2. **Batch inline**, running the rename + Edit + README refresh + commit outside the transition-problem skill's ownership. Efficient but violates the ADR-014 / ADR-010-amended ownership boundary — run-retro is not supposed to commit its own work; transition-problem is. Inline batching makes run-retro (or whatever caller) effectively a shadow executor.
3. **Sequence `git mv` + `Edit` manually, then invoke transition-problem just for the commit**. Hybrid. Ambiguous ownership; the skill's pre-flight checks and P063 external-root-cause detection are bypassed on the inline edits. Unsafe.

None of the three is satisfying. The session that surfaced this hit (2026-04-24 run-retro): 4 verification-close candidates (P063, P067, P092, P094) all approved in one user AskUserQuestion batch; the assistant chose Option 2 inline for efficiency, noting the ownership-boundary drift.

## Symptoms

- Closing 4+ tickets in one run-retro invocation costs either 4× SKILL.md reloads (if delegated) OR an ownership-boundary violation (if inline).
- The `transition-problem` skill has no batch mode; no `--batch`, no comma-separated IDs.
- The `run-retro` skill contract explicitly requires delegation to `transition-problem` for closures, but provides no guidance on how to avoid the N× context cost.
- Same issue presents in `manage-problem review` Step 9d when multiple verifyings are old enough to be closure candidates.

## Workaround

Chosen 2026-04-24: batch inline (Option 2). Run `git mv` + `Edit` + README refresh for all N tickets, commit once with a batch commit message listing all closed tickets (`docs(problems): close P<A>, P<B>, P<C> — verified in-session via run-retro Step 4a`). Explicitly acknowledge the ownership-boundary drift in the run-retro summary. Not a sustainable long-term pattern.

## Impact Assessment

- **Who is affected**: every run-retro Step 4a invocation that finds ≥ 2 verification-close candidates from in-session evidence. Manage-problem review Step 9d with ≥ 2 stale verifyings. Any future batch-ticket-lifecycle workflow.
- **Frequency**: once per multi-ticket run-retro. Observed 2026-04-22 run-retros (P084/P036/P060/P054 batch-close, 4 tickets; P057/P095 batch-close, 2 tickets) and 2026-04-24 (this session, 4 tickets P063/P067/P092/P094). Pattern: every retro that follows a productive multi-ticket session trips this.
- **Severity**: Moderate. Not blocking — the workaround works. But it forces a choice between context bloat and ownership-boundary violation on every batch retro. Accumulates toward P097's SKILL.md-runtime-size pressure.
- **Analytics**: N/A — developer-experience observation.

## Root Cause Analysis

### Preliminary hypothesis (ADR decision needed)

Four candidate shapes for the fix, each with different contract surfaces:

1. **Extend `transition-problem` argument shape** to accept `<NNN>[,<NNN>...] <status>` (comma-separated IDs, single destination). One Skill invocation, single SKILL.md load, iterates over IDs internally. Clean. Respects the ownership boundary. Needs argument-parser update + bats assertions. Risk: all IDs must transition to the same destination; mixed transitions are separate invocations.
2. **New `/wr-itil:batch-transition` skill** with full batch semantics (mixed destinations allowed, e.g. `--close P063,P067 --verifying P076`). More flexible. Higher implementation cost. Proliferates skill surfaces (arguably counter to ADR-010's one-skill-per-intent rule — batching IS a distinct intent). Risk: duplication of transition-problem's internal logic.
3. **Run-retro embeds transition-problem as an inlined library**. Make the SKILL.md body of transition-problem smaller / more library-like so the "re-load on each invocation" cost is negligible. Generalisation of P097. Doesn't add batch surface but makes the N× delegation cheap. Risk: requires P097's resolution first.
4. **Accept the status quo, document the inline-batch pattern**. Inline batching becomes a blessed ownership exception when the caller is run-retro (or manage-problem review) batch-closing ≥ 2 tickets. Lowest implementation cost but explicit exception-to-ownership feels wrong. Risk: sets precedent that "when inconvenient, the ownership boundary is optional".

### Investigation Tasks

- [ ] Architect Q1: which shape? (comma-separated args / new batch skill / P097-inlined / documented exception)
- [ ] Architect Q2: if shape 1, does the comma-separated form require mixed destinations (`P063:close,P076:verifying`) or is same-destination-only sufficient? Same-destination is simpler but only handles run-retro Step 4a's canonical shape (multiple closes).
- [ ] Architect Q3: how should the bats contract-assertion verify batch safety — that P057 re-stage fires once per ticket, that P063 external-root-cause detection fires per ticket, that the commit groups them in one transaction?
- [ ] JTBD alignment: JTBD-001 (enforce governance without slowing down) — the N× context cost DOES slow us down on long retros. JTBD-006 (progress backlog while AFK) — work-problems orchestrator batch-transitions might also benefit.
- [ ] Implementation TBD after architect decision.

### Reproduction

Run `/wr-retrospective:run-retro` after a multi-ticket session where ≥ 2 verifyings are exercised in-session. Step 4a prompts the close candidates; approve all; observe the assistant chooses between N Skill-loads and inline-batch. Both paths work; neither is satisfying.

### Fix Strategy

Deferred pending architect decision on contract shape. Implementation effort is M regardless of shape: argument parser / new skill / inlining / doc edit all carry roughly the same implementation + test footprint.

## Dependencies

- **Blocks**: efficient multi-ticket lifecycle operations from run-retro + manage-problem review + future work-problems AFK release orchestration (when tracking N close-candidates post-drain).
- **Blocked by**: architect decision on shape (Q1-Q3 above).
- **Composes with**: P097 (SKILL.md runtime size — the N× reload cost is a direct symptom of P097's broader problem). If P097's progressive-disclosure solution sufficiently shrinks per-skill runtime footprint, shape 3 (inlined library) may be the cleanest answer; otherwise shape 1 (batch args) is likely the best cost/benefit tradeoff.

## Related

- **P093** (closed-ish) — transition-problem ↔ manage-problem circular delegation; resolved by giving transition-problem ownership of the per-ticket transition. P117 extends the question: batch ownership.
- **P097** (open) — SKILL.md runtime size cluster. P117 is a concrete cost case of P097's generalised concern.
- **P057** — `git mv` + Edit staging trap. Any batch-transition implementation must hold P057's contract per ticket.
- **P063** — external-root-cause detection in transition-problem Open → Known Error. Batch transitions at the Open → Known Error boundary must not silently skip P063.
- **ADR-010 amended** — Skill Granularity + Split-skill execution ownership. Any new batch surface needs this decision's amendment or cross-reference.
- **ADR-014** — governance skills commit their own work. Batch-transition is still one commit per batch (one transaction); ADR-014 does not need amending, but the skill body must state the batch-as-single-transaction invariant explicitly.
- **run-retro Step 4a** (`packages/retrospective/skills/run-retro/SKILL.md` — governance-workflow topic of briefing) — primary caller of the batch-close path.
- **manage-problem review Step 9d** — secondary caller.
