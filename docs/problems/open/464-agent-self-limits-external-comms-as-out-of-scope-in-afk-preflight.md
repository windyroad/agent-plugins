# Problem 464: Agent self-limits external-comms as "out of scope" in AFK / pre-flight contexts — strands dispatchable lifecycle/ack/upstream-report obligations the framework authorises to proceed

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture per Step 4a. Impact 3: strands customer-facing acknowledgement / lifecycle-update obligations (inbound reporters get no verdict; upstream issues we filed get no closure comment) — a feedback-signal-preservation harm, no shipped-package damage. Likelihood 3: fires whenever a pre-flight / AFK pass encounters an external-root-cause, a verdict obligation, or a lifecycle transition on an inbound-reported ticket.
**Origin**: corrective-feedback (user, 2026-07-26 — "External comms is NOT out of pre-flight scope")
**Effort**: S — the fix is contract-clarity in the AFK/pre-flight prose (make explicit that external-comms low-risk dispatches proceed via the silent-pass gate), not new mechanism; cf. the P270/ADR-024 auto-fire contract that already exists.
**WSJF**: 9 — (9 × 1.0) / 1
**JTBD**: JTBD-004, JTBD-006
**Persona**: plugin-developer

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

- **Who is affected**: inbound reporters (no verdict → churn); maintainer (audit-trail integrity; stranded lifecycle obligations); cross-repo collaboration (JTBD-004).
- **Frequency**: every pre-flight/AFK pass that meets an external-root-cause, verdict, or lifecycle-transition obligation.
- **Severity**: Medium (9) — feedback-signal-preservation harm; no shipped-package damage.
- **Analytics**: 2026-07-26 — P164 held in the Step 0b review-problems pre-flight citing external-comms out-of-scope; user corrected the premise.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit the review-problems AFK branch + work-problems Step 0b/Step 4 prose for language implying external-comms is deferred wholesale in pre-flight/AFK.
- [ ] Make explicit (SKILL prose) that low-risk external-comms dispatches proceed via the silent-pass gate in pre-flight/AFK — they are in-scope; only above-appetite queues.
- [ ] Confirm the P164 acknowledgement obligation is dispatchable now and route it (see P363 verdict-posting mechanism).
- [ ] Behavioural coverage: a pre-flight/AFK pass with a low-risk external-comms obligation dispatches it rather than declining as out-of-scope.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P363 (inbound-reported tickets never receive fix-released verdict — the concrete inbound instance of this reasoning), P270 / ADR-024 (report-upstream auto-fire contract that already authorises AFK external-comms), ADR-028 (external-comms gate silent-pass on low-risk — the mechanism that makes external-comms in-scope).

## Related

- Sibling-class ancestor: **P184** (closed) — agent treats conditionally-deferred work as permanently out-of-scope (read-a-guard-as-a-wall reasoning error).
- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-26) following the user correction "External comms is NOT out of pre-flight scope." May be foldable into P363 if the maintainer decides the general principle is better tracked as P363's root-cause framing.
