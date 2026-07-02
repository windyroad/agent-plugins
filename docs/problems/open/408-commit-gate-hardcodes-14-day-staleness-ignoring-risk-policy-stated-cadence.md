# Problem 408: `risk-score-commit-gate` hardcodes a 14-day RISK-POLICY staleness threshold, ignoring the policy's stated review cadence

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 (Likely). Impact 2: spurious commit-blocking friction (a refresh/re-review clears it; no data or safety impact), but it fires for **every adopter**, not just this repo. Likelihood 4: the gate reliably flags the policy stale at 14 days regardless of the stated cadence, so any project whose stated cadence exceeds 14 days hits it routinely.
**Origin**: internal
**Effort**: S — small hook change (parse the policy's stated cadence → threshold; fallback to a default). WSJF = (8 × 1.0) / 1 = 8.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

`packages/risk-scorer/hooks/risk-score-commit-gate.sh` (the staleness branch, ~line 50) blocks commits when `(today - RISK-POLICY "Last reviewed").days > 14`. The `14` is **hardcoded** and the hook never reads the policy's own stated review cadence (`> Reviewed <quarterly|monthly|...>` on line 6).

Witnessed 2026-07-02: RISK-POLICY.md stated a **quarterly** cadence (~90 days) and had been reviewed 16 days earlier, yet the gate flagged it stale and blocked every commit — a ~6× disagreement between the gate (14 days) and the policy's own stated cadence (90 days). The policy was **not** stale by its own terms; the gate's arbitrary threshold flagged it. This affects all adopters, whose stated cadence is unlikely to be exactly 14 days.

## Symptoms

- Commits blocked "RISK-POLICY.md is stale (last reviewed over 2 weeks ago)" even when the policy's stated cadence has not elapsed.
- The stated cadence line (`Reviewed monthly/quarterly/...`) has no effect on the gate.

## Workaround

Run `/wr-risk-scorer:update-policy` to re-review and bump the date (resets the 14-day clock). Repeated every 14 days regardless of the stated cadence.

## Root Cause Analysis

### Investigation Tasks

- [ ] Implement the chosen fix option (below), including a fallback threshold when the cadence line is absent/unrecognised (adopter policies may omit it).
- [ ] Behavioural bats: stated-cadence longer than default → not-stale within cadence; missing cadence line → default threshold.

## Fix options (user to pick — recorded 2026-07-02 via AskUserQuestion; timed out AFK)

- **(a) Gate derives the threshold from the policy's stated cadence** (RECOMMENDED) — parse `> Reviewed <cadence>` (monthly→~30d, quarterly→~90d, weekly→7d, annually→365d), fallback to a default when absent. Makes the policy the single source of truth; the doc and gate can never drift; adopter-portable.
- **(b) Hardcode the gate to ~30 days (monthly)** — quick; keeps the doc↔gate coupling implicit; can drift again.
- **(c) Keep the 14-day gate; state a two-week cadence in the doc** — if bi-weekly enforcement is actually wanted and the `quarterly`/`monthly` wording was the wrong part.

This repo's doc was set to **monthly** (2026-07-02, commit 60cdb04c) pending this decision; options (a) and (b) keep that wording, option (c) would revert it to bi-weekly.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- `packages/risk-scorer/hooks/risk-score-commit-gate.sh` — the hardcoded-14-day staleness branch.
- **60cdb04c** — the RISK-POLICY.md monthly-cadence refresh that surfaced this.
