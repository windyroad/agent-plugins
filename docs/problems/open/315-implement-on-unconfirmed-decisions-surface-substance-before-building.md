# Problem 315: Agent implements dependent work on genuine new decisions before human-confirming their SUBSTANCE — surfaces only meta-questions

**Status**: Open
**Reported**: 2026-05-26
**Priority**: 8 (Medium) — Impact: 4 x Likelihood: 2 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

When the agent records a genuine new decision (a choice among ≥2 viable options that the framework cannot resolve) and then builds dependent work on it, it confirms only the **meta-question** (e.g. "one ADR or two?") with the user — not the **load-bearing substance** of the decision (the actual choice). The substance rides unconfirmed until a post-hoc `/wr-architect:review-decisions` drain, by which point dependent artifacts have already been built on it. If the drain then rejects the decision, the dependent work was built on sand.

**Concrete instance (this session, 2026-05-26):** implementing ADR-070/071 via RFC-006, the agent extracted RFC-005's F1/F4 into **ADR-072** (fix-time gate placement = `Open → Known Error`) + **ADR-073** (hard-block RFC-less dispatch). It surfaced ONE `AskUserQuestion` — the *grain* ("one ADR or two?") — and treated the decisions' *substance* as architect-resolved (a faithful extraction of RFC-005 F1/F4). It then built dependent work on them: the RFC-005 retrofit references them, ADR-060's new **I13** invariant encodes both, and RFC-006's slices shipped. Both were born `proposed` without an oversight marker (per the architect's "born-proposed, drain later" guidance for the marker) — but the agent conflated "don't born-confirm the marker" with "OK to implement before confirmation."

At the post-hoc review-decisions drain, the user **rejected both** (ADR-072's placement was built on a wrong Known Error model; ADR-073's hard-block should be auto-create) — so I13 + the RFC-005 retrofit had been written against an incorrect gate design (rework: P314). User frustration (verbatim): *"I'm a bit frustrated that you didn't get my confirmation on those ADRs before you implemented them."*

The correct shape: a genuinely-contested decision the framework can't resolve must have its **substance** human-confirmed BEFORE dependent work is built on it (the way ADR-070/071 were directly ratified via AskUserQuestion at decision time) — not deferred to a post-hoc drain, and not substituted by confirming only a meta/grain question.

## Symptoms

- An `AskUserQuestion` surfaces a decision's framing/grain (e.g. ADR count, file split) but not the substantive choice it records.
- Dependent artifacts (other ADRs, RFC slices, invariants, code) are built on a born-`proposed` decision before any human confirms its substance.
- The post-hoc review-decisions drain is the FIRST time the human sees the substantive choice — and a rejection there means dependent work must be reworked.

## Workaround

When extracting/recording a genuine decision (≥2 viable options, framework can't resolve), surface its SUBSTANCE via AskUserQuestion before building on it. The architect's Needs-Direction verdict (ADR-064) should name the substantive choice, and the main agent should confirm THAT (not just the grain) before dependent work proceeds.

## Impact Assessment

- **Who is affected**: any multi-artifact implementation that extracts/records new decisions and builds on them in the same pass.
- **Frequency**: the "born-proposed + implement, drain later" pattern is the documented ADR-066 flow, so this can recur whenever genuine decisions are recorded mid-implementation.
- **Severity**: Moderate-to-significant — built-on-sand rework when the drain rejects (this session: I13 + RFC-005 retrofit + RFC-006 slices against a wrong gate design).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Decide the contract: for a genuine new decision the framework can't resolve, MUST its substance be human-confirmed (AskUserQuestion at decision time) before dependent work is built? How does this compose with ADR-066's born-proposed-then-drain (marker) — i.e. born-proposed is fine for the MARKER, but implementation must wait for substance-confirmation. Distinguish "decision recorded" (born-proposed OK) from "decision built upon" (needs substance-confirm).
- [ ] Where does the contract live: ADR-064 (architect Needs-Direction must name the substantive choice, not just defer to a meta-question) + a run-retro / work-problems guard? Possibly an amendment to ADR-064 or a new ADR.
- [ ] Distinguish from lazy-AskUserQuestion (ADR-044 Step 2d): this is the INVERSE — under-asking on substance, not over-asking. The fix must not swing into over-asking; the trigger is specifically "a genuine ≥2-option decision is about to be BUILT ON."

## Dependencies

- **Composes with**: ADR-064 (architect Needs-Direction + main-agent AskUserQuestion ownership), ADR-066 (oversight marker + review-decisions drain — born-proposed-then-drain), ADR-044 (decision-delegation taxonomy; this is the under-ask inverse of the lazy-count metric), P310 (RFC-decision blind spot), P283 (oversight drain origin).
- **Blocks / drove**: P314 (the gate-design rework that resulted from building on the rejected ADR-072/073).

## Related

- **ADR-072 / ADR-073** — the built-on-then-rejected decisions (this session's instance).
- **P314** — the rework caused by this failure mode.
- captured via /wr-architect:review-decisions Reject path + P078 capture-on-correction, 2026-05-26.
