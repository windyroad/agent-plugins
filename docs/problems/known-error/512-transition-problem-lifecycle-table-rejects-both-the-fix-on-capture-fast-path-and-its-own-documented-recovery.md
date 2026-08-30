# Problem 512: The transition lifecycle table rejects both the fix-on-capture fast path and its own documented recovery path

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture. Impact 3: two legitimate lifecycle moves have no supported route, so tickets either sit in the wrong state or the operator does the rename by hand, which skips the pre-flight checks, the README refresh and the ADR-014 commit the skill exists to guarantee. Likelihood 4: high path-count, no control — the fast path is the common shape for cosmetic and mechanical fixes, and the recovery path is prescribed by another shipped skill that fires on every retro.
**Origin**: inbound-reported (adopter-repo P151)
**Effort**: M
**WSJF**: 12 — (12 × 2.0) / 2 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

`/wr-itil:transition-problem` validates the requested move against a four-row table: `.open.md`→`known-error`, `.known-error.md`→`verifying`, `.verifying.md`→`close`, and "any other pairing → no — emit an error and stop". Two moves the framework itself asks for are not in that table.

### 1. Fix-on-capture — reported by an adopter 2026-06-28, never routed upstream

An adopter ticket reports that a problem captured via `/wr-itil:capture-problem`, fixed, and released in the same session has no supported route. Their witness: nine tickets captured as lightweight skeletons, fixed, released and verified inside one session, with no transition available for any of them.

The lifecycle assumes investigate-then-fix. Capture→fix→release is legitimate and common for cosmetic, UX and mechanical fixes, where Known Error is a state the ticket never meaningfully occupies — there is no root cause to document beyond the fix itself and no workaround to write because the fix already shipped. Forcing the ticket through Known Error records a state that never happened.

Their proposed shape: allow `Open`→`verifying` directly when a `## Fix Released` section is present — the release **is** the evidence.

### 2. The reopen recovery path, prescribed by `run-retro` and rejected by this skill

`run-retro` Step 4a documents the recovery for a wrong close-on-evidence, twice, in its own voice:

> **Recovery path (P135 R5)**: … the recovery path is documented inline in the summary alongside each close: `Recovery: rerun /wr-itil:transition-problem <NNN> known-error to reopen`.

That pairing — `.verifying.md` → `known-error` — is not in the table, so the skill refuses it. **The documented recovery path for the retro's own silent-close mechanism is unreachable through the surface that documents it.**

Hit live on 2026-08-21 while reopening P368: the fix released for its cold path does not cover the warm path an adopter reported, so closing it would have recorded a defect as verified. The reopen had to be done by hand — `git mv`, Status edit, README row move, line-3 rotation — every step the skill exists to get right, performed outside it.

This is the sharper half. Step 4a closes tickets **silently, without asking**, on the explicit reasoning that the recovery is cheap and reversible: *"the agent does not need permission per-close because the recovery path is cheap and reversible."* That justification is load-bearing for the silent-close design, and it rests on a route that does not exist.

## Symptoms

- A captured-fixed-released ticket has no supported transition; it either sits Open with a shipped fix or is walked through a Known Error state that never occurred.
- `transition-problem <NNN> known-error` on a `.verifying.md` ticket errors out, citing the valid next step as `close` — the opposite of what the operator needs.
- Hand-done transitions skip pre-flight checks, P063 external-root-cause detection, the P062 README refresh, the P134 line-3 rotation and the ADR-014 commit.

## Workaround

Do the rename, Status edit and README refresh by hand. That is what happened for P368 on 2026-08-21, and it is what the skill exists to prevent.

## Impact Assessment

- **Who is affected**: anyone whose fix lands in the same session as the capture, and anyone correcting a wrong silent close. Both are common.
- **Frequency**: the adopter hit the fast-path gap on nine tickets in one session. The recovery gap fires whenever Step 4a closes something it should not have.
- **Severity**: no data loss, but the guarantees the skill provides are silently skipped whenever the operator routes around it.
- **Analytics**: none. Nothing counts hand-done transitions.

## Root Cause Analysis

The table encodes the lifecycle as a **strictly forward, one-step-at-a-time walk**. Both gaps are consequences: a fast path skips a state, and a recovery moves backwards. The skill's own prose is explicit that this is deliberate — *"invalid transitions are almost always user typos and a clear error is the cheapest recovery"* — which is true for typos and wrong for these two cases.

The recovery gap is a cross-skill contract break rather than an oversight: `run-retro` was written against a route `transition-problem` never offered, and nothing checks that one skill's prescribed recovery is accepted by the skill it names.

### Investigation Tasks

- [ ] Decide whether `Open`→`verifying` is admitted on a `## Fix Released` precondition, or whether fix-on-capture should auto-walk through Known Error with a derived root cause
- [ ] Decide whether backward moves are admitted generally, or only `verifying`→`known-error` as a named reopen with a required reason
- [ ] Reconcile with `run-retro` Step 4a — either add the route or change what the retro prescribes; do not leave two shipped skills disagreeing
- [ ] Re-check Step 4a's silent-close justification once the route exists: it argues from reversibility, which was not true when written
- [ ] Add a check that a recovery path named in one skill is accepted by the skill it names
- [ ] **Reopen guard on the post-release K→V enumerator.** `packages/itil/lib/enumerate-postrelease-kv-candidates.sh` globs every `docs/problems/known-error/*.md` and calls `wr-itil-derive-release-vehicle`, which resolves a changeset by bare content grep (`derive-release-vehicle.sh` ~line 104) with no heading context — so a Known Error ticket reopened AFTER its fix shipped is auto-moved back to Verification Pending, its WSJF multiplier zeroed under ADR-022, and it leaves the dev-work queue. Recovery is the `verifying`→`known-error` route this ticket says does not exist, so the undo is not reversible through supported means. Deleting the body reference is not sufficient: the P389 co-commit fallback (~line 122) walks `git log --follow` for a changeset added by a commit that also touched the ticket, and re-finds it. The guard must skip a ticket whose body carries a `## Reopened <date>` section dated after the cited changeset's release, and the fallback must honour it too. Live instance: P368, reopened 2026-08-21.
- [ ] Behavioural tests for both new pairings, including that the pre-flight checks and README refresh still fire

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P368, P135

## Related

- **Adopter ticket P151** — the adopter ticket this traces to; its nine-ticket witness is the field evidence for the fast-path half.
- **P368** — reopened 2026-08-21 by hand because this gap blocked the supported route. The live witness for the recovery half.
- **P135** — the decision-delegation contract that made Step 4a's close silent. Its reversibility argument depends on the missing route.
- `packages/itil/skills/transition-problem/SKILL.md` Step 3 — the validation table.
- `packages/retrospective/skills/run-retro/SKILL.md` Step 4a sub-steps 5 and 6 — the prescribed recovery.

## Partial fix landed 2026-08-24 (P519 vehicle — the two backward pairings)

Two of this ticket's missing pairings landed as part of P519, because P519's whole justification for agent-authorised closure is that a close is cheap and reversible — and the reopen route it advertises was one the skill refused, which would have made that argument fiction. `packages/itil/skills/transition-problem/SKILL.md` Step 3 now admits `.verifying.md → known-error` (flip-back, which `review-problems` Bucket 3, `manage-problem` and `run-retro` Step 4a all already instructed) and `.closed.md → known-error` (reopen), each with a minimal pre-flight in Step 4 that does not re-run the Open → Known Error checks.

Caught by the external-comms review of P519's changeset, which spotted that the published entry advertised a recovery command the shipped skill would reject.

**Still open here**: the fix-on-capture fast path (`Open → verifying`), and this ticket's own investigation task *"Re-check Step 4a's silent-close justification once the route exists: it argues from reversibility, which was not true when written"* — the route now exists, so that re-check is unblocked.

## Fix Strategy

RFC-083, the release row "Captured fixes and reopened problems reach the right lifecycle state" on STORY-MAP-002, carries STORY-077. Reuse the existing transition pre-flights, add the objective `## Fix Released` discriminator to the confirmed ADR-022 folded route, verify run-retro's recovery contract against transition-problem, and exclude post-release reopened tickets after release-vehicle derivation.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-077 | STORY-077: Move a captured fix straight to verification and keep a reopened problem in the work queue | in-progress |
