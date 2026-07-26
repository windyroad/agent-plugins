---
status: "proposed"
date: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-10-26
---

# Capture-time truth discipline for problem tickets — falsify premises, mark unexecuted mechanisms

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain. **The Decision Outcome below is deliberately deferred — no option is chosen.**

## Context and Problem Statement

Problem capture transcribes whatever the reporter or the agent asserted straight into the committed ticket. Two claim classes reach `docs/problems/` unverified and indistinguishable from verified findings:

- **Existence claims** — "component X is missing". Inbound #202 asserted a component was absent when it was in fact exported; the resulting ticket was a phantom, and nothing in the capture path would have caught it.
- **Causal-mechanism claims** — "the root cause is Y", written by an agent that executed nothing to establish Y. Inbound #339 saw a false mechanism replicated into several body locations and nearly steer a fix at a problem that did not exist.

Both were captured against P434, whose root cause was confirmed on 2026-07-26. The shape of the gap is the finding: **the capture flows verify carefully, but every check they run is ticket-space, and none is world-space.** `capture-problem` sub-step 2a greps ticket filenames for duplicates and sub-step 2b dispatches the `hang-off-check` subagent to ask whether a parent should absorb the scope; both answer *"does another ticket already cover this?"*. Neither answers *"is what this ticket asserts actually true?"*. The description itself is transcribed verbatim (`capture-problem/SKILL.md:264`), as it is on the `manage-problem` path (`manage-problem/SKILL.md:476,483`).

Two adjacent decisions look like they should already cover this, and neither does.

**ADR-011 does — but only for incidents.** `/wr-itil:mitigate-incident` refuses the first mitigation until the incident's `## Hypotheses` section carries at least one entry shaped `- [ranked] <hypothesis> — Evidence: <log/repro/diff/metric>. Confidence: <low|med|high>.` (`mitigate-incident/SKILL.md:80-88`). The problem-ticket templates have no `## Hypotheses` section, so an agent with a guess has nowhere to put it except the same prose that holds established findings. `/wr-itil:transition-problem`'s Known-Error checklist already asks that root cause be documented *"not just 'Preliminary Hypothesis'"* (`transition-problem/SKILL.md:81`) — presuming a distinction the templates give no way to record.

**ADR-026 does not reach these claims.** Its in-scope clause binds *"a quantitative estimate (duration, cost, latency, frequency, size, percentage, or any other numeric value)"* plus qualitative **magnitude** descriptors. An existence claim and a causal claim are truth-apt but non-numeric, so a ticket can be fully ADR-026-compliant and still assert a falsified premise as fact.

Every downstream consumer reads the committed ticket body as ground truth — WSJF ranking, `## Fix Strategy`, the ADR-072/073 I13 RFC auto-create, the ADR-060 story traversal. A false premise at intake is therefore not a local error; it propagates into the fix plan.

## Decision Drivers

- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — the grounding job per the `wr-jtbd:agent` ruling on P434. ADR-026's own Decision Drivers cite JTBD-002 for this concern in nearly these words: *"confidence erodes when users discover agent outputs were fabricated. The grounding rule protects confidence by making ungrounded outputs visible rather than disguised."* ADR-026 used JTBD-002 to ground a rule reaching non-code agent output, so this decision widens an established scope rather than opening a new one.
- **JTBD-006 (Progress the Backlog While I'm Away)** — cross-reference, not the anchor. The felt harm is an AFK iteration spent on a phantom ticket, and the persona explicitly does not trust the agent to make judgement calls.
- **ADR-011** — the evidence-first discipline being ported from the incident surface. Reusing its exact entry shape keeps one evidence vocabulary across both surfaces rather than minting a second dialect.
- **ADR-026** — the sibling rule whose coverage gap this fills: ADR-026 governs fabricated *estimates*, this governs fabricated *assertions*.
- **ADR-032** — the lightweight-capture flow budget bounds how much tree-reading any intake check may do.
- **P401 never-discard** — a real problem is never thrown away over a verification or anchoring failure; a falsified premise frequently wraps a real friction worth recording.
- **ADR-052 / P081** — whatever ships needs behavioural coverage, not structural greps over SKILL prose.
- **P463** — the relevance-close evaluator over-fires at 76% on a structurally similar fully-mechanical world-space check. Direct evidence bearing on Axis 2.

## Considered Options

Three axes, each a genuine multi-option choice. None is chosen — see Decision Outcome.

### Axis 1 — what a falsified premise does to the capture

1. **Capture-with-banner** — the ticket is still created, and the falsification travels with it in-body as `**Premise (falsified at capture)**: reporter states "<claim>"; local tree shows <finding> (evidence: <command> → <result>).` The next reader meets the contradiction before fix planning rather than after.
2. **Halt-and-report-to-reporter** — capture refuses, and the reporter is told which claim failed and what the tree actually shows. This is what would have kept inbound #202's phantom ticket out of the backlog entirely.
3. **Capture-with-banner plus auto-park** — create the ticket but park it, so it holds the finding without competing for WSJF rank until a human looks.

### Axis 2 — how much of the falsification pass is committed shell

1. **Fully mechanical predicate** — extraction, the bounded tree reads, and the falsified/corroborated/untestable classification all in committed shell with behavioural bats.
2. **Mechanical extraction plus subagent classification** — extraction and the `ls`/`grep` stay in committed shell; the judgement goes to a fresh-context subagent. This is **ADR-032's fifth invocation pattern**, already demonstrated by the sub-step 2b `hang-off-check`, so it introduces no new architectural shape.
3. **Advisory-only, no classification** — surface the tree reads to the calling skill and let it decide.

### Axis 3 — where the hypothesis-marking discipline homes (near-settled)

1. **Port ADR-011's entry shape to the problem templates** — add a `## Hypotheses` section to both capture templates carrying `- [ranked] <claim> — Evidence: <ref, or "none — unexecuted">. Confidence: <low|med|high>.`, and reserve `## Root Cause Analysis` for executed cited findings.
2. **Invent a problem-specific marker** — e.g. an inline `(hypothesis — unverified)` sentinel.
3. **Extend ADR-026's cite+persist+uncertainty trio to claims** — reuse the grounding vocabulary already in force for estimates.

## Decision Outcome

**Deferred pending human ratification — no option is chosen on any axis.**

Axes 1 and 2 are genuine multi-option substance choices with real trade-offs, and they were surfaced during an AFK `/wr-itil:work-problems` iteration where no `AskUserQuestion` surface exists. Per ADR-074 and P315, dependent work is not built on unconfirmed decision substance; per ADR-073, a decision falling outside existing ADR coverage is captured in a new ADR and **ratified before implementation**. Recording the options now and holding the code is the compliant AFK shape (ADR-066's P348 fallback) — not a licence to build.

The author's leans, offered as **input to the ratification and explicitly not as a decision**:

- **Axis 1**: Option 1 (capture-with-banner), because P401's never-discard rule was itself a user-directed correction of a discard-on-uncertainty design, and re-introducing a refusal path here would walk it back.
- **Axis 2**: Option 2 (mechanical extraction, subagent classification), on the architect's advisory lean and the P463 evidence.
- **Axis 3**: Option 1 (port ADR-011's shape), which is close to settled — both alternatives create a second vocabulary for a discipline the framework already ships.

### Consequences

#### Good

- A falsified premise is caught at intake, where being wrong costs one grep, rather than at fix-planning, where it costs an iteration.
- The hypothesis/fact distinction the Known-Error checklist already assumes becomes recordable, so `## Root Cause Analysis` starts meaning something specific.
- One evidence vocabulary across incidents and problems (Axis 3), and no new architectural pattern (Axis 2 Option 2 reuses ADR-032's fifth).

#### Neutral

- Adopter repos inherit both bricks with the next `@windyroad/itil` release; the discipline is portable because it reads only the adopter's own tree.

#### Bad

- Intake gets slower. Every capture pays the extraction pass, and under Axis 2 Option 2 some captures pay a subagent round-trip inside ADR-032's flow budget.
- A new false-positive surface. A pass that wrongly brands a true premise as falsified is P463's failure mode pointed at intake, and the banner is more visible than a mis-ranked ticket.

## Confirmation

Ratification of the Axis 1 and Axis 2 options via `/wr-architect:review-decisions` (or an equivalent interactive confirm) writing `human-oversight: confirmed`, **before** any implementation lands.

Implementation compliance is then confirmed by behavioural coverage per ADR-052 — structural greps over SKILL prose do not count, per P081:

- A description asserting `X is missing`, where `X` is present in the tree, produces a captured ticket carrying the `**Premise (falsified at capture)**` line naming the contradicting evidence — **and the ticket is still created** (P401).
- A description asserting a root-cause mechanism with no cited evidence produces a ticket recording it under `## Hypotheses` with `Evidence: none — unexecuted`, and `## Root Cause Analysis` does not contain the claim.
- A description with no existence-claims produces byte-identical capture output to the pre-change behaviour.

## Pros and Cons of the Options

### Axis 1 Option 1 — Capture-with-banner

- Good, because it honours P401 never-discard and JTBD-006 save-and-continue: no real finding is lost to a wrong premise.
- Good, because the contradiction is visible at the top of the artefact the fix planner actually reads.
- Bad, because a phantom-shaped ticket stays in the backlog consuming WSJF attention.

### Axis 1 Option 2 — Halt-and-report-to-reporter

- Good, because it is the only option that actually keeps the phantom out of the backlog, which is the harm #202 caused.
- Good, because the reporter learns their premise was wrong, which improves the next report.
- Bad, because any real friction wrapped inside the wrong premise is lost.
- Bad, because it cuts against P401, itself a user-directed correction of an earlier discard-on-uncertainty design — re-introducing a refusal path would walk that correction back.

### Axis 1 Option 3 — Capture-with-banner plus auto-park

- Good, because it holds the finding without letting it compete for rank.
- Bad, because it needs a third lifecycle interaction specified and tested, and parking carries its own review-cadence problem.

### Axis 2 Option 1 — Fully mechanical predicate

- Good, because it is deterministic, cheap, and adopter-portable through an ADR-049 PATH shim with no subagent latency.
- Good, because it is straightforwardly coverable by behavioural bats.
- Bad, because P463 records a structurally similar fully-mechanical world-space check running at a 76% false-positive rate; natural-language claims resist regex classification in exactly that way.

### Axis 2 Option 2 — Mechanical extraction plus subagent classification

- Good, because judgement over natural-language claims is what a subagent is for, and ADR-032's fifth invocation pattern already establishes the shape.
- Good, because the deterministic half stays in committed shell where ADR-052 coverage is natural.
- Bad, because it spends subagent latency inside ADR-032's flow budget.
- Bad, because the classification half is harder to cover behaviourally than a pure predicate.

### Axis 2 Option 3 — Advisory-only, no classification

- Good, because it is the cheapest thing that could possibly help.
- Bad, because it reproduces the current failure whenever the calling agent is the one that authored the claim — which is the #339 case exactly.

### Axis 3 Option 1 — Port ADR-011's entry shape

- Good, because one evidence vocabulary spans incidents and problems, with no second dialect to learn or lint.
- Good, because the `Evidence:` and `Confidence:` fields are what make the shape load-bearing rather than decorative.
- Bad, because it adds a section to two templates that most captures will leave empty.

### Axis 3 Option 2 — Problem-specific inline sentinel

- Good, because it is the smallest possible change.
- Bad, because it creates a second evidence dialect and gives no place for the evidence and confidence fields.

### Axis 3 Option 3 — Extend ADR-026's cite+persist+uncertainty trio

- Good, because it reuses a grounding vocabulary already in force.
- Bad, because the trio is shaped for numbers — uncertainty as a range or confidence band — and maps awkwardly onto an assertion that is simply true or false.

## Reassessment Criteria

Reassess by 2026-10-26, or earlier on either signal:

- **False-positive rate on the falsification pass.** If the pass brands true premises as falsified at a rate approaching P463's 76%, Axis 2's chosen option is wrong and this decision should be re-opened rather than the predicate patched.
- **Flow-budget breach.** If capture latency lands outside ADR-032's lightweight-capture envelope, Axis 2 Option 3 (advisory-only) becomes the live fallback.

## More Information

- **P434** (`docs/problems/known-error/434-capture-flows-write-unverified-premise-and-root-cause-claims-as-fact.md`) — the driving problem, carrying the confirmed root cause, the reproduction, and the two-brick fix design.
- **RFC-057** — the fix vehicle tracing P434 and citing this decision; **STORY-MAP-010** and **STORY-053** carry the decomposition.
- **ADR-011** — incident evidence-first gate; source of the entry shape Axis 3 ports.
- **ADR-026** — agent output grounding; the sibling rule this complements.
- **ADR-032** — the lightweight-capture flow budget and the fifth (fresh-context-subagent-as-decision-arbiter) invocation pattern.
- **ADR-073** — the fix-time rule requiring a new ADR when the choice falls outside existing coverage, ratified before implementation.
- **P463** — relevance-close evaluator over-firing; the evidence against a fully-mechanical classifier, and the sibling defect at the other end of the lifecycle.
- **P401** — never-discard; binds Axis 1.
</content>
