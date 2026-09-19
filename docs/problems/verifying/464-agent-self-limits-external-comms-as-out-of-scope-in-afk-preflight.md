# Problem 464: Agent self-limits external-comms as "out of scope" in AFK / pre-flight contexts — strands dispatchable lifecycle/ack/upstream-report obligations the framework authorises to proceed

**Status**: Verification Pending
**Reported**: 2026-07-26
**Transitioned to Known Error**: 2026-09-19 (root cause documented — the SKILL prose never stated that a gated external-comms action is still an in-scope action, so the agent supplied its own out-of-scope judgement; workaround recorded below).
**Transitioned to Verification Pending**: 2026-09-19 (fix landed — the authorised set is now stated outright in `/wr-itil:work-problems` § External-comms scope in AFK / pre-flight, with the one restrained shape named alongside it, a pointer from review-problems' AFK branch, and eval case 4 asserting dispatch-not-decline).
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture per Step 4a. Impact 3: strands customer-facing acknowledgement / lifecycle-update obligations (inbound reporters get no verdict; upstream issues we filed get no closure comment) — a feedback-signal-preservation harm, no shipped-package damage. Likelihood 3: fires whenever a pre-flight / AFK pass encounters an external-root-cause, a verdict obligation, or a lifecycle transition on an inbound-reported ticket.
**Origin**: corrective-feedback (user, 2026-07-26 — "External comms is NOT out of pre-flight scope")
**Effort**: S — the fix is contract-clarity in the AFK/pre-flight prose (make explicit that external-comms low-risk dispatches proceed via the silent-pass gate), not new mechanism; cf. the P270/ADR-024 auto-fire contract that already exists.
**WSJF**: 9 — (9 × 1.0) / 1
**JTBD**: JTBD-006, JTBD-301
**Persona**: developer

## Description

Agents treat external-comms as **categorically out-of-scope** in AFK / pre-flight / review-problems contexts, and decline dispatchable external-comms actions that the framework actually authorises to proceed.

Concrete trace (2026-07-26): the `/wr-itil:work-problems` Step 0b review-problems pre-flight held **P164** (a genuine close-on-evidence candidate) partly because closing it requires an upstream V→Closed lifecycle dispatch / inbound #273 acknowledgement, and the pre-flight agent reasoned that "that dispatch is an external-comms action outside this pre-flight's scope." That reasoning is wrong: `/wr-itil:review-problems`'s Step 4.5 pipeline carries the external-comms gate, which **silent-passes low-risk verdicts** per ADR-028 (and per the work-problems Step 0b contract's own statement that "external-comms gates on verdict/acknowledgement/pushback comments silent-pass on low-risk verdicts"). So the dispatch WAS in-scope and dispatchable during the pre-flight — declining it stranded the acknowledgement obligation.

User correction (2026-07-26): **"External comms is NOT out of pre-flight scope."**

Class of behaviour: agent conflates "external-comms is gated" with "external-comms is out-of-scope in AFK/pre-flight," and defers rather than dispatching. The gate's whole design is that low-risk external-comms proceeds silently — being gated is not being out-of-scope. Sibling-class ancestor: P184 (closed) — "agent treats conditionally-deferred work as permanently out-of-scope"; same read-a-guard-as-a-wall reasoning error at a different decision surface (there: ticket-closure-readiness; here: external-comms dispatch scope).

Fix shape: make the AFK/pre-flight contract explicit that external-comms low-risk dispatches (report-upstream, update-upstream lifecycle comments, inbound verdicts/acks) are IN-SCOPE and proceed via the silent-pass gate — they are not to be declined as "out of pre-flight scope." Audit the review-problems AFK branch + the work-problems Step 0b/Step 4 prose for language that implies external-comms is deferred wholesale.

## Symptoms

- Pre-flight / AFK passes hold genuine close-candidates whose closure needs a low-risk external-comms dispatch, citing "external-comms out of scope."
- Inbound-reported tickets reach fix-released / closed without the originating issue getting a verdict comment (the P363 mechanism, driven by this reasoning).
- Upstream issues we filed via report-upstream get no lifecycle-update comment on our local transition.

## Workaround

Agent-side: when a pre-flight/AFK action needs an external-comms dispatch, check whether the external-comms gate silent-passes it (low-risk verdict) rather than assuming it is out-of-scope — dispatch the low-risk case, queue only the above-appetite case.

## Impact Assessment

- **Who is affected**: inbound reporters (no verdict → churn; the JTBD-301 acknowledgement promise goes unkept); maintainer (audit-trail integrity; stranded lifecycle obligations); cross-repo coordination generally.
- **Frequency**: every pre-flight/AFK pass that meets an external-root-cause, verdict, or lifecycle-transition obligation.
- **Severity**: Medium (9) — feedback-signal-preservation harm; no shipped-package damage.
- **Analytics**: 2026-07-26 — P164 held in the Step 0b review-problems pre-flight citing external-comms out-of-scope; user corrected the premise.
- **Measured backlog this behaviour produced (2026-09-19)**: of **53 converted inbound reports, 41 have never been acknowledged**, and the oldest has been silent for **75 days**. **24 lifecycle updates are owed to reporters right now**, 23 of them to inbound reporters. These are not projections — a local scanner finds them in under a second. They are the accumulated downstream effect of declining, pass after pass, to dispatch work the framework had already authorised.

## Root Cause Analysis

### Root cause (2026-09-19)

No prose anywhere told the agent that external comms was out of scope. The audit found no such sentence in `work-problems`, `review-problems` or `manage-problem` — the judgement was invented on the spot. What the prose *did* say was scattered: four separate per-step "AFK authorisation" paragraphs each assert, in passing, that their own step's external-comms ride is gate-safe. Nowhere is the authorised set stated as a set. An agent reading any one step sees a gate and no statement that passing through it is expected, so it supplies the missing statement itself — and the conservative guess is "not mine to send." Being gated reads as being forbidden when nothing says otherwise.

That is the same shape as **P184**: a guard read as a wall.

### Fix (2026-09-19)

Make the authorised set legible, and name the one genuinely restrained shape next to it so the boundary is visible rather than guessed at:

- `packages/itil/skills/work-problems/SKILL.md` — new `### External-comms scope in AFK / pre-flight — P464` under `## Non-Interactive Decision Making`. Opens with "being gated is not being out-of-scope", cites the measured cost, then tables the four authorised obligations against the skill that owns each dispatch, and states the restrained shape: P363's cadenced batch back-fill onto third-party issues, ratified user-initiated-only. Closes with the decision test — does a named skill own this for *this one ticket*? Plus one row in the Non-Interactive Decision Making table routing to it.
- `packages/itil/skills/review-problems/SKILL.md` — the AFK-loop-behaviour paragraph now says outright that its verdict / acknowledgement / pushback comments are dispatchable during a pre-flight, and points at the canonical section.
- `packages/itil/skills/work-problems/evals/evals.json` — eval case 4: an AFK pass meeting a per-ticket external-comms obligation dispatches it, does not decline it as out-of-scope, and does not auto-fire the held batch cadence.

**The restraint was deliberately not loosened.** P363 holds a batch back-fill that would comment on and close roughly two dozen real people's issues in one unattended sweep; that hold is a maintainer's ratified call and stands. This fix is about the opposite error — declining the per-ticket work the framework already authorises.

### Investigation Tasks

- [x] Audit the review-problems AFK branch + work-problems Step 0b/Step 4 prose for language implying external-comms is deferred wholesale in pre-flight/AFK. — No such language exists; the out-of-scope judgement was agent-invented. The real defect is the *absence* of a positive statement, recorded above.
- [x] Make explicit (SKILL prose) that low-risk external-comms dispatches proceed via the silent-pass gate in pre-flight/AFK — they are in-scope; only above-appetite queues.
- [x] Confirm the P164 acknowledgement obligation is dispatchable now and route it (see P363 verdict-posting mechanism). — P164 is closed, and its outstanding acknowledgement is one row of the back-fill P363 holds. Routing it here would be firing the held cadence one comment at a time, so it stays queued with the rest of that batch for the maintainer. Per-ticket obligations arising *going forward* are what this fix unblocks.
- [x] Behavioural coverage: a pre-flight/AFK pass with a low-risk external-comms obligation dispatches it rather than declining as out-of-scope. — evals.json case 4.

### Verification

Next AFK pass that meets a per-ticket external-comms obligation dispatches it through the owning skill instead of recording an out-of-scope skip. Counter-evidence to watch for: any iteration summary that skips a ticket citing external-comms scope.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P363 (inbound-reported tickets never receive fix-released verdict — the concrete inbound instance of this reasoning), P270 / ADR-024 (report-upstream auto-fire contract that already authorises AFK external-comms), ADR-028 (external-comms gate silent-pass on low-risk — the mechanism that makes external-comms in-scope).

## Related

- Sibling-class ancestor: **P184** (closed) — agent treats conditionally-deferred work as permanently out-of-scope (read-a-guard-as-a-wall reasoning error).
- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-26) following the user correction "External comms is NOT out of pre-flight scope." May be foldable into P363 if the maintainer decides the general principle is better tracked as P363's root-cause framing.
