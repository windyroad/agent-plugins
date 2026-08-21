# Problem 475: RFCs carry a human-oversight axis they should not have, so 52 false nudges fire at every session start

**Status**: Open
**Reported**: 2026-07-30
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: corrective-feedback
**Effort**: M — derived at capture per Step 4a
**WSJF**: 4 — (8 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

ADR-070's chosen option is that RFCs hold no independent decisions — every decision an RFC leans on lives in an ADR, and the RFC merely traces it. If an RFC holds no decisions of its own, then an RFC-tier ratification marker has nothing to ratify, and the axis is meaningless at that tier.

Maintainer correction 2026-07-30, verbatim: **"RFCs do NOT need human oversight."**

This had already been recorded once, in the ADR-101 confirmation commit note — *"the maintainer note that RFCs need no oversight — ADR-070 — which condition (a) already proxies through the RFC's `adrs:`"* — and the agent restated the wrong claim anyway during the P474 work, describing `human-oversight: unconfirmed` as "the sanctioned state for an RFC". That recurrence is why this is a ticket rather than a one-off correction: the class is an oversight axis that exists in three places without a decision requiring it.

Three surfaces carry the axis:

1. **`itil-rfc-oversight-nudge.sh`** fires on `SessionStart` reporting a count of unoversighted RFCs — currently **52**. It is noise the maintainer cannot action, and it competes for the same session-preamble attention budget the genuinely-actionable nudges use. Worse than useless: a nudge that can never be discharged trains the reader to skim the whole preamble.
2. **The RFC template + `capture-rfc` scaffold** born-write `human-oversight: unconfirmed`, so every new RFC is minted into a state with no legitimate clearing path. RFC-059 (2026-07-30) is the most recent instance.
3. **`detect-unoversighted-rfcs.sh`** exists solely to feed that nudge.

## Symptoms

- Every session preamble carries `[wr-itil] 52 RFCs lack human oversight — run /wr-itil:manage-rfc <RFC-NNN> to ratify them`.
- Running the named skill on an RFC cannot clear the count in any principled way, because there is no RFC-tier decision to ratify.
- Newly captured RFCs immediately increment the count.
- Agents read the marker as meaningful and repeat the claim that RFCs await ratification (observed twice: 2026-07-26 and 2026-07-30).

## Workaround

Ignore the nudge. That is the actual current state and it is the harm — an un-actionable line in the one surface that is supposed to carry only actionable ones.

## Impact Assessment

- **Who is affected**: every adopter with RFCs, and this repo at 52. Anyone whose agent reads the marker and reasons from it.
- **Frequency**: every session start, per project.
- **Severity**: no functional breakage and nothing is blocked — the cost is attention and agent misdirection. Impact 2 rather than 3 because no gate denies anything on this axis.
- **Analytics**: 52 RFCs currently carry the marker; 48 carry the field without a hash. The RFC tier has **no** `oversight-hash` at all, so unlike stories there is no drift-invalidation machinery to unwind.

## Root Cause Analysis

The oversight family (ADR-066 decisions, ADR-068 JTBDs/personas, ADR-090 stories/maps) was extended to the RFC tier by structural analogy rather than because RFCs hold ratifiable substance. ADR-070 had already settled that they do not. So the axis was added to a tier whose governing decision excludes the thing the axis measures.

### Investigation Tasks

- [ ] **Decide the direction — do not pick silently.** This is a LOOSENING of an oversight surface, and by ADR-066's own test that is a change to an Outcome rather than a mechanism tightening, so it needs its own recorded amendment and its own ratification event. At least three viable options, each with a different blast radius for the 48 RFCs already carrying the field: (a) amend ADR-070 to state the axis explicitly and retire the field from the template, the detector and the nudge; (b) keep the field for future use but silence the nudge only; (c) retire the nudge and detector, leaving already-written markers as inert history.
- [ ] Confirm the read against ADR-070's body rather than its compendium entry — the compendium is a derived view.
- [ ] Whichever option lands, check whether `check-rfc-stories-ratified.sh` conflates RFC-tier oversight with the story-tier ratification it actually gates. Its name suggests story ratification; verify it never reads the RFC's own marker.
- [ ] Retire or re-point `docs/rfcs/README.md` if it documents the field as required.
- [ ] Add a behavioural guard so the axis cannot be reintroduced by structural analogy a third time.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the direction decision above (maintainer-owned)
- **Composes with**: P474 (surfaced during its follow-up work), P465

## Related

Captured via `/wr-itil:capture-problem`. Deliberately NOT folded into P474 or RFC-059 on the architect's advice: that would ship a loosening in the same commit as a tightening, which is the split ADR-101 made deliberately; it is governed by ADR-070 rather than ADR-090; it concerns a tier with no fingerprint at all; and removing an oversight axis needs its own ratification event rather than collateral inclusion in a fix commit — the same P348 hollow-marker shape the ADR-090 record went to lengths to avoid.

Title-only duplicate grep matched 30 tickets on the broad keywords `rfc|oversight|nudge`; none is this defect. The nearest neighbours are P462 (amendment-scoped `human-oversight: unconfirmed` has no detector — the ADR tier, opposite direction: a missing detector rather than a spurious one) and P474 (the story-tier fingerprint, where the axis is legitimate and the defect was in what it hashed).
