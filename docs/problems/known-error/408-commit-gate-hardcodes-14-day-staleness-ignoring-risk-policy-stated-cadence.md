# Problem 408: `risk-score-commit-gate` hardcodes a 14-day RISK-POLICY staleness threshold, ignoring the policy's stated review cadence

**Status**: Known Error
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

**Confirmed 2026-07-03** (AFK work-problems iter). Read `packages/risk-scorer/hooks/risk-score-commit-gate.sh`: the `POLICY_STALE` python block hardcodes the comparison `(date.today() - reviewed).days > 14`. It parses only the `Last reviewed:` date line and never reads the policy's `> Reviewed <cadence>` line (line 6 of `RISK-POLICY.md`, currently `> Reviewed monthly and after any significant change ...`). So the cadence the policy declares has no effect on when the gate fires. Root cause is a hardcoded constant that ignores a machine-readable field already present in the doc. **Workaround** (documented above): run `/wr-risk-scorer:update-policy` to bump the review date.

### Governance gate outcome (AFK 2026-07-03)

- **JTBD gate: PASS** — serves JTBD-001 (enforce governance without slowing down); removes a false-positive friction class without weakening the gate (fallback default preserves enforcement).
- **Architect gate: ISSUES FOUND — anchor ADR required before implementation.** The derive-from-policy *principle* is pinned by confirmed ADR-065 / ADR-086 (which cover the pipeline *appetite/score* threshold), but applying it to the *staleness* threshold introduces a NEW machine-read contract on `RISK-POLICY.md` (the prose `> Reviewed <cadence>` line becomes load-bearing parsed input) plus an adopter-inherited cadence vocabulary. ADR-073's confirmation clause ("a fix whose approach-choice is not covered by existing ADRs has a new ratified ADR before implementation") fires. A sibling ADR to ADR-065/086 must be **ratified** before the hook is edited.
- **Why implementation is deferred (ADR-074 + ADR-066 P340).** The anchor ADR's substance must be human-confirmed via an option-shaped `AskUserQuestion` (ADR-066 as amended by P340 — a born-`confirmed` marker writes ONLY on a real substance-confirm event; writing it without one is the P340/P348/P357 hollow-marker defect). This iteration is AFK, so the substance-confirm cannot fire and ADR-074 forbids building the hook change on the unconfirmed substance. Implementation is therefore deferred to a post-ratification interactive iter; the ADR ratification is queued at the loop-end `outstanding_questions` drain.

### Investigation Tasks

- [x] Confirm root cause — hardcoded `> 14` in the `POLICY_STALE` block; cadence line unread. (2026-07-03)
- [ ] **BLOCKED on ratification** — ratify the anchor ADR (sibling to ADR-065/086) recording the cadence-derivation mechanism + the `RISK-POLICY.md` cadence-line machine-read contract. Then auto-create the fix-time RFC tracing P408 (I13 gate fired `no-rfc-trace`; no existing fix vehicle) with ≥1 story per ADR-089.
- [ ] Implement the fix per `## Fix Strategy` below (fallback threshold when the cadence line is absent/unrecognised).
- [ ] Behavioural bats: stated-cadence longer than default → not-stale within cadence; missing cadence line → default threshold; **both `Last reviewed:` and `Reviewed <cadence>` lines present → cadence parses from the capital-R line, NOT the lowercase date line** (regression guard on the regex).

## Fix Strategy (designed 2026-07-03 — implement post-ratification)

Chosen option: **(a)** derive the threshold from the policy's stated cadence. Turnkey design for the implementing iter:

In `risk-score-commit-gate.sh`, extend the `POLICY_STALE` python block to parse the cadence line and derive the threshold, keeping the existing 14-day value as the fallback:

- Cadence vocabulary → threshold days: `weekly=7`, `fortnightly`/`biweekly`=14, `monthly=30`, `quarterly=90`, `annually`/`yearly`=365. Fallback `DEFAULT=14` when the line is absent or the word is unrecognised.
- Match the cadence with a **case-sensitive, line-anchored** regex — `(?m)^>?\s*Reviewed\s+([A-Za-z]+)` — so it binds to line 6's capital-`R` `> Reviewed monthly …` and NEVER to the lowercase `> Last reviewed: <date>` line (the architect flagged this collision; it is the load-bearing regression case).
- Compare `(date.today() - reviewed).days > threshold`.

The `deny` message should name the derived threshold (e.g. "stale — reviewed over 30 days ago per the policy's stated monthly cadence") instead of the hardcoded "over 2 weeks ago" string, so the reason matches the doc.

Shippable code under `packages/risk-scorer/hooks` → the implementing commit must carry a `.changeset/*.md` bumping `@windyroad/risk-scorer` **patch**, and a `Refs: STORY-<NNN>` trailer once the RFC/story exist.

## Fix options (option (a) selected 2026-07-03; substance-of-anchor-ADR ratification queued at loop end)

- **(a) Gate derives the threshold from the policy's stated cadence** (RECOMMENDED — SELECTED) — parse `> Reviewed <cadence>` (monthly→~30d, quarterly→~90d, weekly→7d, annually→365d), fallback to a default when absent. Makes the policy the single source of truth; the doc and gate can never drift; adopter-portable.
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


## Ratified Direction - 2026-07-04 interactive decision drain

Confirm fix option (a): derive the RISK-POLICY staleness threshold from the policy's stated review cadence (weekly=7/monthly=30/quarterly=90/annually=365, fallback=14 when absent). Born-confirm the anchor ADR, author fix-time RFC tracing P408 (>=1 story), implement hook + bats + changeset.
