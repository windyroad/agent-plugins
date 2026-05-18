# Problem 261: iter subprocess API stream timeout class — orchestrator salvage path for stuck-before-commit needs documentation

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 6 (Medium) — Impact: 3 (Moderate — wasted iter cost if not salvaged; iter 4 of session 6 burned $12.91 on Phase 3b work that would have been lost) x Likelihood: 2 (Unlikely — observed once per ~10 iters in session 6; may correlate with iter length / context size)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; SKILL.md amendment + bats coverage)
**Type**: technical

## Description

Surfaced 2026-05-18 during iter 4 of session 6 (P246 cohort-graduation pre-check work). The iter subprocess hit `API Error: Stream idle timeout - partial response received` (is_error: true in the JSON envelope) AFTER doing substantive semantic work — 7 files staged, including a complete SKILL.md amendment + 290-line bats fixture + ADR amendments — but BEFORE invoking `git commit`. The work was intact in the working tree but uncommitted.

Per `/wr-itil:work-problems` SKILL.md Step 5 exit-code semantics:
> Non-zero exit → halt the loop; report the exit code, stderr, and any partial `.result` in the final summary. Do NOT spawn the next iteration.

The literal contract halts. But the work was SALVAGEABLE — the staged content was coherent, bats passed (39/39 green), the ADR amendments cited the user direction verbatim, and the SKILL amendment composed cleanly with iter 2's P250 fix.

**Orchestrator-salvage path used** (this session, not yet in SKILL contract):
1. Run the bats fixture as a structural sanity check (39/39 green confirms coherence).
2. Inspect the changeset + SKILL.md diff to verify quality.
3. Commit the staged work from the orchestrator main turn with attribution to the iter ("Iter 4 hit API stream timeout during commit; salvaged complete staged work — all 39 behavioural bats fixtures pass...").
4. The commit gate fires fresh on the salvage commit, so architect/JTBD/risk-scorer review the work cleanly.

This salvage path saved ~$13 of iter cost AND landed the Phase 2b cohort-graduation pre-check that triggered the P170 graduation later in the loop.

P147 documents the broader "SIGTERM exit-flush is conditional" class, but the stream-timeout class is different (no SIGTERM involved; iter exits on its own with is_error=true; metadata IS preserved in the JSON; bats are runnable to verify).

## Symptoms

- Iter subprocess returns `is_error: true` with `API Error: Stream idle timeout - partial response received` in `.result`.
- Working tree has staged files from the iter's work.
- Bats fixtures (if the iter created them) are runnable and pass.
- No commit landed; ITERATION_SUMMARY not emitted.

## Workaround

Orchestrator main turn applies the 4-step salvage path (above) when the iter's staged work is structurally coherent. The commit-gate flow validates the work fresh.

## Impact Assessment

- **Who is affected**: AFK orchestrator loops that hit iter API errors.
- **Frequency**: Unlikely (2) — observed once in session 6 across 10 iters; ~10% per-iter rate; gated on iter length / API stability.
- **Severity**: Moderate — without salvage, the iter cost is lost AND the loop halts; with salvage, the work lands cleanly.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Amend `packages/itil/skills/work-problems/SKILL.md` Step 5 exit-code semantics to add the "is_error: true with coherent staged work" carve-out:
  - If is_error: true AND staged files exist AND any iter-authored bats fixtures pass → orchestrator MAY apply the 4-step salvage path before halting.
  - Else (staged work incoherent, bats fail, no work staged) → halt per existing contract.
- [ ] Add behavioural bats coverage for the salvage path: fake-stuck-shim that exits is_error=true with staged work; assert orchestrator commits with attribution; assert commit-gate validates.
- [ ] Update `docs/briefing/afk-subprocess.md` to document the salvage path as "What You Need to Know" entry.

## Dependencies

- **Blocks**: (none — workaround works)
- **Blocked by**: (none)
- **Composes with**: P121 (SIGTERM idle-timeout — different class), P147 (SIGTERM exit-flush conditional — different class), P146 (bash polling antipattern — different class)

## Related

- `packages/itil/skills/work-problems/SKILL.md` Step 5 — surface to amend.
- P121 + P147 + P146 — sibling iter-failure-class tickets.
- Iter 4 of session 6 (commit dd93da4 history note + salvage commit 229539c → final c0625ff) — empirical instance.

(captured via /wr-retrospective:run-retro Step 4b Stage 1; expand at next investigation)
