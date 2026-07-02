# Problem 401: Capture/RFC persona-JTBD anchoring shoehorns (or discards the problem) instead of interviewing the human to elicit the real who/why

**Status**: Open
**Reported**: 2026-06-29
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 = 12. Rated at review 2026-07-02: persona-JTBD shoehorning; 5+ session instances.
**Origin**: corrective-feedback (user, 2026-06-29 — during the RFC-first ADR-072/060/087 ratification walkthrough)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 3.0.
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

When a problem is captured (and, symmetrically, when an RFC's stories are mapped), the agent must anchor it to a persona + JTBD. The current `/wr-itil:capture-problem` Step 1.5b **I12 derive-then-ratify** contract handles low-confidence derivation badly:

- On derive-failure/ambiguity it fires an `AskUserQuestion` proposing **candidate persona/JTBD pairs by ID** ("is it JTBD-XXXX?") with a **Reject** option whose semantics are *"reject of proposed persona/JTBD = reject of the problem"* (no ticket created).

Two faults:

1. **It asks the human to ratify a guessed ID-mapping** rather than eliciting the real who/why. This shoehorns problems into the nearest existing persona/JTBD. User (2026-06-29): *"most of the time when we are capturing a problem, I'm not confident with the persona/JTBD. Sometimes it feels like it's shoehorning into an existing persona and JTBD."*
2. **It discards a legitimate problem over anchoring uncertainty** — conflating "I'm unsure which persona fits" with "this isn't a real problem."

### Corrected rule (user direction 2026-06-29)

One principle, applied at both the capture layer and the RFC story-mapping layer:

1. Agent **derives** the persona + JTBD from the description.
2. **Confident** → map to the existing persona/JTBD and **proceed autonomously** (no human).
3. **Not confident** → do **NOT** shoehorn, and do **NOT** ask *"is it JTBD-XXXX?"*. **Interview the human** with substantive, non-leading questions about *who* hits this and *what they are trying to get done* — requirements elicitation of the actual persona/job, **not** ratification of a guessed ID.
4. From the elicited answers, the **agent** classifies: matches an **existing** persona/JTBD → map and proceed; **no existing fit** → a **new** persona/JTBD is warranted → human ratifies the **creation** (per ADR-068 / P288), then proceed.

The human is involved only for substance, never to bless an ID: (a) the interview when derivation is weak, and (b) ratifying the **creation** of a genuinely new persona/JTBD. **A real problem is never discarded over anchoring uncertainty.**

This is the same `covered → agent proceeds / uncovered → human ratifies a new artefact` boundary that ADR-073 (RFC-first) draws for the fix-**approach** axis, applied here to the **who/why** axis.

### The interview is also the legitimate scope-rejection gate (user clarification 2026-06-29)

The corrected rule also handles the **externally-reported** problem (plugin-user / inbound report) cleanly. When an external report does not match an existing persona/JTBD, the agent interviews the human to elicit the real who/why; **through that interview** the human may determine that the elicited persona/JTBD is one **we do not want to support**, and reject the problem on that substantive **scope/strategy** ground.

This is the CORRECT form of "reject = reject the problem": rejection is a deliberate decision about the *elicited* who/why, reached *through* the interview — NOT the old broken "reject the proposed ID-mapping = discard the problem" (which discarded legitimate problems over anchoring uncertainty). The interview surfaces the true persona/job first; the human then decides support-vs-reject on the merits. So the rejection path survives, but only as a real product-scope call, never as a side-effect of an unsure ID guess.

### Internal vs external — the rejection path is external-only (2026-07-02 sharpening)

The scope-rejection path applies **only to externally-reported** problems. A problem the **maintainer** flags always relates to a job we already have, or one we simply haven't captured yet — so it always anchors (to an existing or a new job) and is **never** rejected. Rejection-on-scope is solely for **external** reports, where whether we want the software to support the elicited need is genuinely a maintainer product-scope decision (Yes → create the job + accept; No → decline, nicely).

Surfaced during the STORY-032 (inbound triage-disposition) ratification on 2026-07-02, where the agent **over-applied P401** — treating "never discard over anchoring uncertainty" as "never reject *any* report," and missing that external reports legitimately reject on scope. Captured on STORY-MAP-002's inbound band (STORY-032). The `never discard over anchoring uncertainty` rule and the `external reports may reject on scope` rule are complementary, not in tension — the first bars *anchoring-uncertainty* discards, the second permits *deliberate-scope* declines.

## Symptoms

- The "is it JTBD-XXXX?" ID-centric ratification prompt (violates brief-before-ID / P350 and derive-or-eliminate / P190).
- `reject of proposed persona/JTBD = reject of the problem` discards legitimate problems.
- Provisional best-fit mappings made under low confidence are systematically shoehorned (the downstream JTBD gate then re-anchors them — P395 / `feedback_dont_trust_afk_autocapture_default_jtbd`).

## Workaround

(none — the agent can manually interview + classify, but the contract still prescribes the broken propose-by-ID/reject flow.)

## Impact Assessment

- **Who is affected**: plugin-developer (maintainer capturing problems) — anchoring quality and capture friction; downstream RFC/story trace integrity (JTBD-001/JTBD-008).
- **Frequency**: every low-confidence capture (common — user reports it as "most of the time").
- **Severity**: no functional break, but mis-anchored traces + discarded problems erode the Problem→RFC→Story trace's value.

## Root Cause Analysis

The I12 derive-then-ratify contract (ADR-060 Amendment 2026-06-02) collapsed two distinct human-involvement reasons into one ID-ratification prompt, and over-applied the ADR-068/P288 "lift to human" discipline to the **mapping** step (it belongs only on the **creation** step). It also tied problem-validity to anchoring-confidence.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Amend `/wr-itil:capture-problem` Step 1.5b I12 derive-then-ratify: replace propose-candidate-pairs-by-ID + reject-discards-problem with **derive → interview-on-low-confidence (elicit who/why, not an ID) → agent-classify existing-vs-new → human ratifies only the CREATION of a new persona/JTBD**. Never discard the problem over anchoring.
- [ ] Amend **ADR-060 Amendment 2026-06-02** (the I12 contract) to the corrected shape — architect review + user ratification (P357).
- [ ] Make the symmetric persona/JTBD escalation **explicit in ADR-073** (covered → agent; uncovered → human ratifies a new persona/JTBD), alongside the existing fix-approach rule.
- [ ] AFK behaviour: when not confident and no `AskUserQuestion` is available, **queue the elicitation** for the next interactive session — do not shoehorn and do not auto-create.
- [ ] Behavioural tests: (a) low-confidence capture interviews rather than proposing an ID; (b) a problem is never discarded over anchoring; (c) elicited who/why matching an existing artefact maps autonomously; (d) elicited who/why with no existing fit routes to human-ratified new-artefact creation.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: ADR-073 (RFC-first covered/uncovered boundary — same rule, fix-approach axis), ADR-060 (the I12 contract amended), ADR-068/P288 (new personas/JTBDs need human oversight — the creation side this preserves), P395 (downstream jtbd re-anchoring).

## Related

(captured via /wr-itil:capture-problem.)

- **P288** (verifying) — new JTBDs and personas need human oversight confirmation: the **creation** side this rule preserves; complementary, not a parent.
- **P323** (closed) — jtbd-review does not flag changes built on unratified personas/jobs.
- **P383** (open) — capture-problem persona enum hardcoded; distinct concern (enum extensibility) but same surface.
- **P190** (closed) — derive-or-eliminate classification fields, don't ask.
- **P350** (verifying) — brief-before-ID / don't lead with IDs (the "is it JTBD-XXXX?" prompt violates this).
- **P395** (open) — jtbd re-anchoring downstream (the safety net that currently masks shoehorned anchors).
- **ADR-073** — RFC-first covered/uncovered boundary (the symmetric rule on the fix-approach axis).
- **ADR-060** — Problem→RFC→Story framework; the I12 derive-then-ratify contract to be amended.
- **ADR-068 / ADR-074** — auto-made artefacts lifted to human / substance-confirm-before-build (the creation-side oversight this rule keeps).
- Hang-off pre-filter surfaced >5 shared-signal candidates (JTBD/ADR-060 references are widely cited); per the capture-problem candidate-cap rule the subagent dispatch was skipped and the candidates recorded here for review-time re-evaluation.
