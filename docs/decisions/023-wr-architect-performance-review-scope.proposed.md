---
status: "proposed"
date: 2026-04-19
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-19
---

# wr-architect agent performance review scope — prompt amendment + performance-budget ADR template

## Context and Problem Statement

`wr-architect:agent` reviews proposed changes against existing decisions in `docs/decisions/` and flags ADR conflicts. Its review scope today is ADR-driven — it checks whether a change violates an accepted decision, whether a new decision is warranted, and whether file-placement / testing conventions are right. What it does NOT systematically check is the **per-request performance and load implications** of runtime-path changes on high-traffic endpoints.

Upstream problem: P046 (wr-architect agent misses performance implications on high-traffic endpoints). Downstream incident: addressr P024 (2026-04-18) — the architect recommended `cache-control: no-cache` for a HATEOAS root endpoint reasoning "load is genuinely negligible, CPU cost per revalidation is microseconds". The addressr maintainer rejected because every client page-load would cost an origin round-trip across the entire paid + free-tier consumer base. Without the human override, the fix would have shipped and degraded live-service performance on a revenue-generating endpoint.

The same architect agent reviews changes across multiple downstream projects (addressr observed; bbstats noted as next-most-likely affected). A blind spot for per-request cost trade-offs is therefore systemic across the whole `wr-architect` user base, not a per-project configuration gap.

Two structural gaps combine to produce the miss:

1. The agent prompt has no instruction to quantify per-request cost × request-frequency on runtime-path changes. "Load is negligible" is a qualitative claim that slips through.
2. Projects have no repeatable way to express "endpoint X has a per-request budget of Y" in a form the architect can read. If an ADR encoded the budget, the architect's existing "check against ADRs" flow would naturally catch violations.

This ADR decides how to close both gaps.

## Decision Drivers

- **JTBD-101** (Extend the Suite with Clear Patterns) — a reusable performance-budget template is the "clear pattern" downstream projects need; filling the agent's review scope is the plugin-developer's responsibility.
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — "the agent cannot bypass governance" is weakened when the agent's review scope has a systemic blind spot that the human has to backstop manually.
- **Upstream vs downstream split** — addressr already has a per-session memory guardrail (`feedback_ask_before_ops_tradeoffs.md`) as a local workaround. That is a per-user fix. The systemic fix lives in this repo's `@windyroad/architect` plugin.
- **Grounded quantification** — P022 (agents must not fabricate time estimates) shares the principle: agent outputs that look authoritative but are ungrounded are the failure mode. Performance claims must be grounded in concrete per-request cost × request-frequency estimates, not qualitative assertions.
- **Cross-project relevance** — one architect agent reviews N projects. A prompt-level fix benefits all N; a per-project fix benefits 1.
- **Review-cost proportionality** — not every change is runtime-path. The performance check should fire only when the change touches cache directives, throttles, rate limits, or other request-frequency-sensitive surfaces. Always-on performance review would inflate review cost with no benefit.
- **P046** — the upstream problem ticket this ADR resolves.

## Considered Options

1. **Amend the agent prompt only (Candidate 1)** — add a per-request performance-check step to the architect's review checklist when a change touches runtime paths.
2. **Prompt amendment + performance-budget ADR template (Candidates 1 + 2 combined)** (chosen) — ship the prompt amendment AND establish a reusable "performance budget" ADR template downstream projects adopt. The architect's existing "check against ADRs" flow then catches violations against adopted budgets.
3. **Performance-specialist sub-agent (Candidate 3)** — introduce a new sub-agent that the architect delegates to for runtime-path changes (mirrors `wr-risk-scorer:pipeline`).
4. **Downstream memory guardrail only (Candidate 4)** — keep addressr's per-session memory wrapper as the fix; no upstream ADR.

## Decision Outcome

Chosen option: **"Prompt amendment + performance-budget ADR template"**, because the prompt change closes the immediate blind spot (the architect asks the right question) while the template gives downstream projects a reusable surface the architect can read (the architect has a source of truth to check against). Together, they move performance from "a qualitative claim the agent makes" to "a numeric budget the agent verifies". Neither half alone is sufficient:

- Prompt-only leaves every quantification ungrounded (same class of failure mode as P022).
- Template-only has no trigger — the agent would need a reason to read it.

A performance-specialist sub-agent is architecturally cleaner in the long run but is overkill for the single observed incident. Reassessment criteria below flag the trigger for revisiting this.

### Scope

**In scope (this ADR):**

- **Prompt amendment**: edit `packages/architect/agents/` (primary agent definition) to add a runtime-path-change performance-review step. The step fires when the proposed change touches one of:
  - HTTP cache directives (`cache-control`, `etag`, `last-modified`)
  - Rate limiting, throttling, or request quotas
  - Response content size or compression behaviour
  - Any per-request handler whose change alters wall-clock latency or CPU cost
  - New endpoints whose traffic profile is non-trivial (defined as: invoked from client code paths documented in the project's JTBD or README, OR named in an ADR as "runtime-path")
  When the step fires, the agent MUST report:
  - **Per-request cost delta** — estimated CPU / memory / network delta per request, in terms of concrete units (ms, bytes, KB/s), not qualitative phrases.
  - **Request-frequency estimate** — how many times per user-session × user-sessions per day (or equivalent aggregate) the endpoint is invoked. Cite the source of the estimate (ADR, JTBD, telemetry link, or "no data — worst-case assumption").
  - **Product** — cost × frequency = aggregate load delta.
  - **Verdict against any project-local performance budget ADR** (see template below). If no budget exists, the agent must flag "no performance budget in scope; recommend creating one or explicitly accepting ungoverned risk".
  - The agent MUST NOT emit qualitative phrases like "load is negligible", "microseconds only", "no measurable impact" without attaching quantitative backing.
- **Performance-budget ADR template**: embedded in the Decision Outcome below as a fenced markdown block downstream projects copy into their own `docs/decisions/NNN-performance-budget-<endpoint>.proposed.md` (architect's review picks it up via the existing "check against ADRs" scan).
- **Bats test** in `packages/architect/agents/test/` asserting the prompt contains the quantification-required wording AND the qualitative-ban wording.

**Architect template location**: embedded in-body as a fenced block (architect Option (a) from session review). No new `docs/decisions/_templates/` directory is introduced by this ADR — downstream projects copy-paste from the ADR body. If a second template emerges, the follow-up ADR can establish the `_templates/` convention at that point.

**Out of scope (follow-up tickets or future ADRs):**

- Performance-specialist sub-agent (Candidate 3) — reassessment criterion below.
- Telemetry-grounded request-frequency data (rather than estimates). Pairs with P022 (grounded estimates) when that fix lands.
- Automatic enforcement of budgets at CI time. Today's verification is the architect's review; a future hook could fail a PR if its estimated load exceeds the budget. Out of scope for this ADR.
- Memory-level guardrail propagation to other downstream projects — each project decides locally whether to keep one alongside the upstream fix.

### Performance-budget ADR template

Downstream projects copy the following template into `docs/decisions/<NNN>-performance-budget-<scope>.proposed.md` and fill in the placeholders. The wr-architect agent picks it up via its existing "check against ADRs" scan.

```markdown
---
status: "proposed"
date: YYYY-MM-DD
decision-makers: [<names>]
consulted: [wr-architect:agent]
informed: [<downstream consumers>]
reassessment-date: YYYY-MM-DD  # 3 months from today
---

# Performance budget — <endpoint or subsystem>

## Context and Problem Statement

<Endpoint or subsystem description; who calls it, how often, what's at stake if its
per-request cost drifts upward.>

## Budget

| Dimension | Budget | Measurement method |
|-----------|--------|--------------------|
| p95 latency | < <N> ms | <where/how measured> |
| Origin CPU per request | < <N> ms | <where/how measured> |
| Response size | < <N> KB | <where/how measured> |
| Request frequency (informational) | <N> req/session × <M> sessions/day | <source: ADR, JTBD, telemetry link> |

## Decision Drivers

- <e.g. JTBD that owns the endpoint; SLA commitments; revenue path>
- <e.g. architectural promise the endpoint embodies — HATEOAS root, auth primary, etc.>

## Scope

This budget applies to the following runtime-path changes (non-exhaustive):

- Changes to `cache-control`, `etag`, `last-modified` on the endpoint.
- Changes to rate-limit, throttle, or quota behaviour.
- Changes to response content size or compression.
- Any per-request handler edit whose effect is not purely refactor.

A change that falls within budget proceeds; a change that exceeds budget requires
explicit product/maintainer sign-off AND an update to this ADR (or supersession).

## Enforcement

- The `wr-architect:agent` review compares the proposed change's estimated
  per-request cost delta × frequency against this budget. The review blocks
  approval until the estimate is within budget OR the ADR is updated.
- Future: CI-time automated estimate (out of scope for this ADR).
```

### Example exercise

Applying the prompt amendment to addressr's 2026-04-18 P018 incident:

> Proposed change: `cache-control: no-cache` on root `/`.
>
> Architect performance review (per ADR-023):
> - Per-request cost delta: +1 origin round-trip per page-load (no cached revalidation). Estimated p95 latency increase: +80 ms (typical RTT + minimal CPU).
> - Request frequency: 1 root fetch per client page-load. Source: addressr HATEOAS contract (documented in addressr project README). Aggregate: N page-loads/day × 1 root fetch.
> - Product: aggregate load delta = N × 80 ms = significant perceived-latency tax on every client session.
> - Verdict against performance-budget ADR: addressr project has no `performance-budget-root` ADR yet. Recommend creating one or explicitly accepting ungoverned risk.
>
> Review result: FLAG. The quantitative estimate shows the change is not "negligible"; it is aggregate-significant. Recommend rejection or ADR-accept-with-justification.

The same review today (without ADR-023) produces "Load is genuinely negligible — microseconds only". The ADR turns that into a quantified flag.

## Consequences

### Good

- Closes the immediate blind spot the P018 addressr incident surfaced.
- Establishes a reusable pattern: any project that adopts `@windyroad/architect` gets the performance-review question for free.
- Forces agent output to be grounded (latency numbers, frequency estimates, aggregate math), consistent with P022's "no ungrounded estimates" principle.
- Downstream projects don't need to each invent their own guardrail — the template is authoritative and copy-pasteable.
- Maintains the architect's existing ADR-driven review model; this ADR adds one input to that model, not a new model.

### Neutral

- Architect reviews of runtime-path changes gain one check, adding review latency. Mitigated by the trigger condition (only fires when the change touches cache / throttle / rate-limit / per-request handler surfaces).
- The template is copy-pasted rather than centrally maintained. If the template evolves, downstream projects need to re-copy. Acceptable at current scale (1-2 downstream adopters); reassess if more.

### Bad

- Estimates may be poorly-grounded in practice — the agent will quantify but the numbers are only as good as the data sources available. Partial mitigation: the agent must cite its source (ADR / JTBD / telemetry / worst-case). Full mitigation depends on P022 landing.
- A project without a performance-budget ADR gets "no budget — recommend creating one" from every review. That could become noise. Mitigated by the architect's existing "new decision needed" flag semantics (the agent already surfaces missing decisions; this is an incremental case).
- If the prompt amendment wording is unclear, the agent could over-fire (flagging non-runtime-path changes) or under-fire (missing edge cases). Bats test covers the wording; future evolution may need a second-pass review if false-positive/negative rates become visible.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/architect/agents/` (primary agent file) contains the runtime-path performance-review step with quantification requirements AND the qualitative-ban wording.
   - The performance-budget ADR template is embedded in this ADR's Decision Outcome as a fenced markdown block (this confirms the template location).
2. **Test:** bats test in `packages/architect/agents/test/` asserts:
   - The agent prompt contains the phrase "per-request cost delta" or equivalent quantification language.
   - The agent prompt contains a ban on qualitative-only phrases (e.g. grep for "must not emit qualitative" or similar).
   - The agent prompt references the performance-budget ADR convention by name.
3. **Behavioural replay:** running the agent on a cache-directive change on a high-traffic endpoint produces a quantified review (latency delta, frequency estimate, product) and a verdict against any in-scope performance-budget ADR. Addressr's 2026-04-18 P018 scenario serves as the canonical replay case.
4. **Downstream adoption (advisory)**: at least one downstream project (addressr is the obvious candidate) creates a `performance-budget-*` ADR using the template within 3 months. Non-blocking for this ADR's acceptance, but flagged in Reassessment Criteria below.

## Pros and Cons of the Options

### Option 1: Prompt amendment only

- Good: cheapest; ships in one agent file edit + bats test.
- Good: closes the immediate blind spot.
- Bad: quantification stays ungrounded in projects without a performance budget — agent estimates numbers with no source to check against, same class of failure as P022.
- Bad: the template-less state means each project reinvents the budget format; inconsistency across downstream projects.

### Option 2: Prompt amendment + performance-budget ADR template (chosen)

- Good: closes the immediate blind spot AND gives downstream projects a reusable surface.
- Good: the architect's existing "check against ADRs" flow naturally catches violations — no new agent flow needed.
- Good: consistent with ADR-013's pattern of embedding reusable structures in-body.
- Good: grounds quantification (when a budget exists) rather than leaving it purely estimate-based.
- Neutral: marginally longer agent prompt than Option 1.
- Bad: downstream adoption of the template is voluntary; projects that skip it still get ungrounded quantification.

### Option 3: Performance-specialist sub-agent

- Good: cleanest long-run architecture; mirrors `wr-risk-scorer:pipeline` delegation.
- Good: isolates performance expertise from ADR-conformance expertise.
- Bad: substantial effort (new agent file, new delegation contract, new tests).
- Bad: overkill for the single observed incident.
- Bad: delays the fix; addressr has a workaround but other projects may not.

### Option 4: Downstream memory guardrail only

- Good: zero upstream change.
- Good: fast.
- Bad: not systemic — every downstream project reinvents the guardrail.
- Bad: leaves P046 Open indefinitely; the architect's blind spot persists for every new project that adopts the plugin.

## Reassessment Criteria

Revisit this decision if:

- Two or more downstream projects adopt the performance-budget ADR template and start requesting coordinating features (budget composition, cross-project aggregation, shared library). That would trigger moving the template into a centrally-maintained `docs/decisions/_templates/` directory (architect Option (b) from session review).
- A second quantifiable-blind-spot category emerges in the agent's review scope (e.g. security posture, accessibility, I/O patterns). That would signal the agent's review checklist has grown too long and a performance-specialist sub-agent (Option 3) becomes worth the investment.
- Performance estimates prove unreliable in practice because no project has grounded data. P022's "no fabricated estimates" fix, once landed, may change the quantification layer this ADR assumes.
- The bats test for the prompt amendment becomes too brittle (false-positive/negative on prompt wording). That suggests the prompt needs a more structured representation.
- addressr or bbstats explicitly reports that the prompt amendment fires incorrectly (over-fires on non-runtime changes, or under-fires on true runtime changes). That is a signal the trigger condition needs refinement.

## Related

- P046: `docs/problems/046-architect-agent-misses-performance-implications.open.md` — the upstream problem ticket this ADR resolves.
- addressr P024 (`architect-agent-misses-performance-implications`) — downstream ticket; retains memory guardrail as per-project workaround. Cross-referenced via the P046 `## Related` section.
- P022: `docs/problems/022-agents-should-not-fabricate-time-estimates.open.md` — shared principle (no ungrounded estimates in agent output). This ADR applies P022's principle to performance claims specifically.
- P037: `docs/problems/037-jtbd-reviewer-returns-bare-verdict-without-reason.open.md` — sibling failure mode (governance agent scope gap).
- P038: `docs/problems/038-no-voice-tone-gate-on-external-comms.open.md` — sibling failure mode.
- ADR-013: `docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md` — precedent for embedding reusable structures in-body (AskUserQuestion patterns).
- ADR-015: `docs/decisions/015-on-demand-assessment-skills.proposed.md` — sub-agent delegation precedent (for the future-option sub-agent direction).
- `packages/architect/agents/` — the fix target for the prompt amendment.
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
