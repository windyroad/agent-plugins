---
status: "proposed"
date: 2026-04-20
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-20
---

# Agent output grounding — no fabricated quantitative estimates, cite + persist + uncertainty

## Context and Problem Statement

LLM agents across the Windy Road suite emit plausible-sounding quantitative estimates (time, cost, latency, frequency, size) that have no grounding in measured data. The estimates look authoritative, feed into prioritisation math (WSJF), performance-review verdicts (ADR-023), and retro timelines — but they are fabrication.

Concrete examples observed and captured in the problem backlog:

- **P022 (trigger)** — `wr-risk-scorer` emitted "Your call: accept 3/25 explicitly and merge, or take the 1 hour for the two remediations". The "1 hour" had no basis; the agent has never measured how long these remediations take.
- **ADR-023 upstream incident** — `wr-architect:agent` recommended `cache-control: no-cache` on a HATEOAS root endpoint reasoning "load is genuinely negligible — microseconds only". Qualitative claim with no quantitative backing; ADR-023 has already resolved this specifically for performance reviews.
- **`manage-problem` WSJF Effort buckets** — S/M/L/XL thresholds are calibrated to human hours ("S < 1hr, M 1-4hr, L > 4hr, XL > 1 day"), but the agent's *choice of bucket* for any specific ticket is a guess, not a measurement.
- **Retro and briefing outputs** — agent-produced durations in session retros ("this took ~30 min") with no source.

This is a cross-cutting failure mode. ADR-023 resolved it specifically for performance-review claims in the architect agent. P022 calls for the principle to apply across the suite. ADR-026 establishes the cross-cutting rule.

The user's direction (AskUserQuestion answers this session): the grounding definition requires all three of **cite + persist + uncertainty**; the measurement surface is an `Actual Effort:` field on closed problem tickets; WSJF buckets stay as S/M/L/XL but require a comparable-prior citation when the agent assigns one; ungrounded outputs emit `not estimated — no prior data` explicitly rather than being omitted or fabricated.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — "the agent cannot bypass governance" extends to output content, not just gate compliance. Fabricated estimates are a content-level governance bypass.
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — confidence erodes when users discover agent outputs were fabricated. The grounding rule protects confidence by making ungrounded outputs visible rather than disguised.
- **JTBD-003** (Compose Only the Guardrails I Need) — output grounding is itself a composable guardrail alongside TDD, risk scoring, JTBD review. Per jtbd-lead advisory.
- **JTBD-101** (Extend the Suite with Clear Patterns) — plugin-developer; a single cross-cutting rule every new agent writer follows. No per-agent reinvention.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — tech-lead; audit trail quality depends on output quality. Fabricated durations in retro output corrupt the audit record.
- **JTBD-006** (AFK) — the AFK persona explicitly "does not trust the agent to make judgement calls". Fabricated numbers are exactly that. Ungrounded-bucket default-to-M plus explicit advisory keeps AFK loops from blocking while preserving the audit signal.
- **P022** — the upstream problem ticket this ADR resolves.
- **P047** (WSJF effort bucket accuracy gaps) — sibling in flight. ADR-026's default-M-when-ungrounded rule is the forward-compatible answer to P047's concern that creation-time estimates drift; citing a comparable prior problem pins the bucket at the moment of sizing.
- **ADR-023** (wr-architect performance review scope) — specialization of this rule. ADR-023's per-request cost-delta × frequency rule is one application of ADR-026's cross-cutting principle.

## Considered Options

1. **Cite + persist + uncertainty** (chosen) — three-part grounding definition. An estimate is grounded only if (a) it cites a specific source measurement, (b) the source is persisted somewhere the agent can re-read, and (c) the estimate includes explicit uncertainty (range or confidence). Anything else is forbidden; the agent emits `not estimated — no prior data` or equivalent.

2. **Cite + persist (uncertainty optional)** — require a specific-source citation and persistence but don't require uncertainty bands. Rejected because it still lets fabricated-sounding precision slip through ("45 min" based on a non-comparable prior without explicit ±).

3. **Qualitative-relative only** — forbid absolute durations entirely. Agents emit "smaller-than P046 / larger-than P037" relative sizings. Rejected because it loses the duration signal that users need for scheduling.

4. **Measurement surface = separate `docs/measurements/` log** — dedicated JSONL or markdown log. Rejected in favour of reusing problem-ticket artefacts (Option 1 for measurement surface) so the governance artefacts stay consolidated.

5. **Measurement surface = git-history derived** — compute actuals from `git log` timestamps. Rejected because wall-clock duration between ticket creation and fix commit is noisy (tickets sit open across days even when actual work is 1 hour).

6. **Central "grounding validator" agent/gate** — parse every agent output for quantitative estimates and validate the cite/persist/uncertainty trio structurally. Rejected: requires parsing unstructured agent output, adds complexity, and a per-agent prompt amendment + bats doc-lint is sufficient to encode the rule where it's emitted.

## Decision Outcome

Chosen option: **Option 1 — Cite + persist + uncertainty, measurement surface on `.closed.md` tickets, WSJF buckets with comparable-prior citation, explicit `not estimated` marker when ungrounded.**

Rationale:
- Three-part definition leaves no room for plausible-sounding-but-ungrounded estimates.
- Measurement surface on `.closed.md` reuses existing governance artefacts; no new infrastructure, no separate dashboard to maintain.
- WSJF buckets keep their shape (S/M/L/XL) so existing tooling (`manage-problem`, README.md cache, WSJF math) doesn't churn. The change is at the *sourcing* layer — the agent must now cite a comparable prior.
- Explicit `not estimated — no prior data` keeps output shape stable (no missing fields) while making the grounding state auditable.

### Scope

**In scope (this ADR):**

- **Cross-cutting rule**: No agent in the suite may emit a quantitative estimate (duration, cost, latency, frequency, size, percentage, or any other numeric value) unless grounded. Grounded = cite + persist + uncertainty, all three required. Qualitative descriptors without numeric backing ("load is negligible", "microseconds only", "small change") are also forbidden per the same principle and must be replaced with either a grounded quantitative estimate or an explicit "not estimated — no prior data" marker.

- **Grounding components**:
  1. **Cite** — name the specific source: a closed problem ticket ID (`P037 took 45 min`), a telemetry link (`p95 latency from bbstats.grafana.internal/... 2026-04-18`), a committed measurement (`docs/problems/<NNN>.closed.md#actual-effort`), or a documented ADR value (`ADR-023 budget for root-endpoint p95`). "Based on my experience" is not a valid source.
  2. **Persist** — the cited source must be re-readable by another agent in a future session. A `.closed.md` ticket qualifies (committed to repo). A screenshot in the conversation does not (transient). A dashboard URL qualifies (external persistence). A dictionary lookup the agent built in-session and discarded does not.
  3. **Uncertainty** — explicit range or confidence. Forms accepted: range (`45–60 min`), bilateral tolerance (`50 min ± 15%`), confidence band (`~50 min, P80 30–80 min`). A single point value without uncertainty is forbidden unless the source measurement was itself a point value with known reproduction (e.g. exact CI run duration).

- **Measurement surface — `Actual Effort:` field on `.closed.md` problem tickets**:
  - When `manage-problem` transitions a ticket `.verifying.md → .closed.md`, the skill prompts the user (via `AskUserQuestion`) for the actual effort in the same bucket scale (S/M/L/XL) plus an optional free-form duration note ("~40 min").
  - The field is optional; the user may decline to provide. Tickets without `Actual Effort:` cannot be used as calibration sources later (which is an advisory flag, not an error).
  - Field format in the `.closed.md` file body:
    ```
    **Actual Effort**: S (~40 min)
    **Estimated Effort**: S — WSJF used S/1 divisor
    ```
  - Non-interactive fallback (AFK): skill logs `Actual Effort: not captured — AFK closure` and proceeds. The user can backfill from git history when they return.

- **WSJF effort-bucket grounding**:
  - `manage-problem` SKILL.md's bucket-selection step (step 9b7 "Re-estimate Effort") is amended: when assigning a bucket, the agent MUST cite a comparable prior problem ("S — comparable to P037 which was S and took 45 min").
  - When no comparable prior exists (e.g. first problem of its kind in the repo), default to **M** with an advisory "ungrounded bucket — default M per ADR-026" note on the Effort line. Rationale for defaulting to M: (a) it's the middle of the S/M/L/XL scale so it biases neither toward under-prioritisation (L/XL too eager) nor over-prioritisation (S gets work scheduled that shouldn't); (b) P047 flagged creation-time estimates as drift-prone, and M-with-advisory preserves the signal that this bucket is a placeholder awaiting the first comparable-prior calibration.
  - Re-rate at every `manage-problem review` (step 9b re-rating already lives there per P047): the advisory-M ticket gets re-rated the next time a comparable prior closes and surfaces its `Actual Effort:`.

- **Ungrounded-output degradation**:
  - Output field that would normally carry a quantitative estimate but has no grounded data: emit `not estimated — no prior data` (or equivalent language: `ungrounded — no comparable prior`, `not measured — telemetry unavailable`).
  - Output shape stays stable — the field is present, its value is an explicit absence marker. Callers and downstream parsers get a known sentinel rather than a missing key.
  - When the agent could emit a *qualitative relative sizing* (e.g. a prior problem exists but isn't a close match), the agent may emit a qualitative form with the prior cited as the anchor ("larger than P037 which was S; likely M"). This is the bridge between "fully grounded" and "not estimated at all".

- **Per-agent prompt amendments** — every agent that emits quantitative output gets its prompt amended to cite ADR-026 and encode the rule. Initial targets:
  - `packages/risk-scorer/agents/pipeline.md` — the trigger offender per P022.
  - `packages/risk-scorer/agents/plan.md` — plan-time estimates.
  - `packages/architect/agents/agent.md` — already carries ADR-023's performance-review rule; ADR-026 generalises the same principle, so the performance-review section cites ADR-026 as the parent.
  - `packages/itil/skills/manage-problem/SKILL.md` — WSJF Effort bucket selection rule.
  - `packages/itil/skills/manage-incident/SKILL.md` — mitigation timing estimates.
  - `packages/retrospective/skills/run-retro/SKILL.md` — session duration and observation timing.

- **Bats doc-lint tests** — one bats file per amended agent/skill asserting the prompt contains ADR-026's grounding rule. Structural assertion — Permitted Exception per ADR-005.

- **ADR-023 follow-up**: update ADR-023's prose to cite ADR-026 as the parent principle rather than P022 as a "shared principle". ADR-023 becomes a specialization — it applies ADR-026's rule to the specific performance-review surface. Lands in the same commit as ADR-026 acceptance, not as a separate change.

- **ADR-022 extension (not modification)**: `manage-problem` SKILL.md's `.verifying.md → .closed.md` transition gains the `AskUserQuestion` for `Actual Effort:`. ADR-022's status-transition mechanics are unchanged; only the close-time field capture is added. The manage-problem SKILL.md update lands in the same commit as ADR-026 so ADR-022's Confirmation section does not become stale.

**Out of scope (follow-up tickets or future ADRs):**

- CI-time validation that cited sources resolve to real entries. Agent-local advisory catches blatant mismatch; repo-wide CI validation is a follow-up ticket.
- Automated extraction of actuals from git history (ticket-open time to fix-commit time). Noisy; rejected as a measurement surface. Could become a complementary signal in a future ADR if noise filtering becomes feasible.
- OpenTelemetry-grade measurement pipeline for performance estimates. Out of scope; ADR-023 and ADR-026 rely on external telemetry links for that data.
- A central grounding-validator agent. Rejected above; per-agent prompt amendments + bats doc-lint is the chosen surface.

## Consequences

### Good

- Every quantitative estimate the agent emits is either grounded (cite + persist + uncertainty) or explicitly marked as ungrounded. No silent fabrication.
- Measurement surface reuses governance artefacts (`.closed.md` tickets) — no new tooling to build or maintain.
- WSJF buckets stay functional during the transition; the advisory-M default means ungrounded new tickets don't blow up the queue but do flag themselves for recalibration.
- ADR-023's performance-review rule becomes a specialization rather than a peer principle — the governance graph tightens as ADR-026 accepts.
- Agent output becomes auditable end-to-end: a retro claim citing `Actual Effort: S (~40 min) — source P037` can be reverse-engineered by any subsequent reviewer.
- Consistent pattern for plugin-developers (JTBD-101): one rule, many applications.

### Neutral

- The `Actual Effort:` field is optional at close-time. Tickets where the user declines to provide it cannot be used as future calibration sources. This creates a long-tail of uncalibrated closed tickets, but the agent advisory "no comparable prior" surfaces this honestly rather than hiding it.
- Per-agent prompt amendments mean every agent/skill file gets one paragraph added. Small maintenance cost; the bats doc-lint tests make drift detectable.
- The `not estimated — no prior data` marker increases output verbosity for early-lifecycle projects with few closed tickets. Acceptable: explicit is better than implicit; the marker shrinks organically as calibration sources accumulate.

### Bad

- **Default-M when ungrounded can compound**: if a cluster of XL-actual tickets all default-to-M at creation (no comparable priors), the WSJF ranking under-prioritises them until the first one closes and recalibrates the rest at the next `manage-problem review`. Mitigation: re-rating is already a per-review step (P047); the advisory "ungrounded bucket" note in the Effort line makes this case visible to the user.
- **`Actual Effort:` burden on AFK closure**: when the user closes tickets in batch without attending each transition, actuals go uncaptured. Mitigation: non-interactive fallback logs `Actual Effort: not captured — AFK closure`, preserving the audit trail even when actuals are absent.
- **Retrofitting existing agents** — every plugin with an agent that emits estimates now needs an ADR-026 citation. The initial amendment sweep is coordinated (lands alongside ADR-026 acceptance), but third-party agents built on Windy Road patterns may lag. Not a blocker; ADR-026 is .proposed status until downstream adoption catches up.
- **Grounding vs productivity trade-off** — some estimates that were "good enough for planning" under the old regime become `not estimated — no prior data` under the new. Users who valued the plausible-sounding-number-for-scheduling signal lose it. Accepted trade-off: the confidence cost of fabrication outweighs the convenience of plausible-sounding-numbers (JTBD-002's "ship with confidence" dominates here).

## Confirmation

Compliance is verified by:

1. **Source review:**
   - Every agent/skill file listed under "Per-agent prompt amendments" contains a section citing ADR-026 and encoding the cite-persist-uncertainty rule.
   - `packages/itil/skills/manage-problem/SKILL.md` includes the WSJF bucket-selection comparable-prior-citation rule and the default-M-when-ungrounded fallback.
   - `packages/itil/skills/manage-problem/SKILL.md` includes the `AskUserQuestion` for `Actual Effort:` in the `.verifying.md → .closed.md` transition.
   - `packages/architect/agents/agent.md`'s performance-review section cites ADR-026 as the parent principle (replacing its current P022 reference).
   - No agent emits qualitative phrases ("load is negligible", "microseconds only", "minimal", "small") without an accompanying quantitative estimate or an explicit "not estimated" marker.

2. **Test (bats):**
   - `packages/risk-scorer/agents/test/pipeline-grounding-contract.bats` asserts `pipeline.md` contains the cite/persist/uncertainty wording and the forbidden-qualitative-phrase ban.
   - `packages/risk-scorer/agents/test/plan-grounding-contract.bats` — same for `plan.md`.
   - `packages/architect/agents/test/architect-grounding-contract.bats` — asserts the performance-review section cites ADR-026.
   - `packages/itil/skills/manage-problem/test/manage-problem-effort-grounding.bats` — asserts the WSJF bucket-selection step requires comparable-prior citation, the default-M fallback, and the `Actual Effort:` close-time capture.
   - `packages/retrospective/skills/run-retro/test/run-retro-duration-grounding.bats` — asserts session-duration output grounding.

3. **ADR cross-references:**
   - ADR-023 (performance-review) updated to cite ADR-026 as parent principle in its Related section. The follow-up commit lands in the same batch as ADR-026 acceptance so ADR-023 never carries stale P022 references.
   - ADR-022 (Verification Pending lifecycle) explicitly extended (not modified) — the `.closed.md` file body gains an `Actual Effort:` optional field; lifecycle transitions are unchanged.

4. **Behavioural replay**: exercise the amended agents on a scenario with no grounded data. Verify every agent emits `not estimated — no prior data` (or equivalent) in each field that would carry a quantitative value. Verify `manage-problem` defaults to M with an advisory note when the first-of-its-kind ticket is sized.

5. **Calibration chain verification**: close a problem ticket with `Actual Effort: S (~40 min)`. Wait one `manage-problem review` cycle. Confirm that a subsequently-created similar ticket cites the closed ticket's actuals in its bucket assignment.

## Pros and Cons of the Options

### Option 1: Cite + persist + uncertainty (chosen)

- Good: closes the fabrication path completely.
- Good: reuses existing artefacts (`.closed.md` tickets) as the measurement surface.
- Good: keeps WSJF bucket shape stable; change is at the sourcing layer.
- Good: explicit `not estimated` marker keeps output shape auditable.
- Bad: initial lifecycle has many `not estimated` markers until calibration sources accumulate.
- Bad: optional `Actual Effort:` capture creates a long-tail of uncalibrated tickets.

### Option 2: Cite + persist (uncertainty optional)

- Good: lighter friction per estimate.
- Bad: fabricated-sounding precision still slips through ("45 min" without ± from a non-comparable prior).
- Bad: fails the P022 "silent quality erosion" criterion — users calibrate to false precision.

### Option 3: Qualitative-relative only

- Good: fully eliminates absolute-duration fabrication.
- Bad: loses the duration signal users need for scheduling.
- Bad: relative sizings don't translate to business-time estimates consumed by planning tools.

### Option 4: Separate docs/measurements/ log

- Good: dedicated measurement surface; cleaner separation from problem tickets.
- Bad: new artefact to maintain and keep in sync with problem tickets.
- Bad: duplicates the data that would otherwise sit on `.closed.md` where it's contextually adjacent to the work it measures.

### Option 5: Git-history derived

- Good: fully automatic; no user prompt at close-time.
- Bad: wall-clock duration between ticket creation and fix commit is noisy (tickets sit open for days while actual work is 1 hour).
- Bad: misses cross-session batches of work where multiple iterations happen rapidly.

### Option 6: Central grounding-validator agent/gate

- Good: structural enforcement across all outputs.
- Bad: requires parsing unstructured agent output; brittle.
- Bad: per-agent prompt amendments + bats doc-lint is sufficient and cheaper.

## Reassessment Criteria

Revisit this decision if:

- **`not estimated — no prior data` becomes the dominant output shape** across agents after 3 months of adoption. That signals the measurement surface is starving (`Actual Effort:` rarely captured) or the comparable-prior match is too strict. Options: loosen match criteria, allow qualitative relative sizing more often, or add a git-history-derived fallback.
- **Three consecutive comparable-prior citations are junk** (the cited prior is not actually comparable). Signals the match heuristic is unreliable and needs structural refinement (e.g. per-domain similarity embeddings).
- **The default-M-when-ungrounded rule produces misranking clusters** — multiple related tickets all default to M but should be L or XL. Mitigated today by per-review re-rating; if the re-rating cycle is too slow, consider either defaulting to an "ungrounded" sentinel bucket excluded from WSJF ranking, or prompting the user at ticket-creation time.
- **A new agent joins the suite** that emits quantitative outputs not covered by the initial prompt-amendment sweep. Routine: add the agent to the Confirmation checklist, add a bats doc-lint test, no ADR amendment needed.
- **Telemetry infrastructure matures** (OpenTelemetry, dedicated measurement pipeline) such that performance estimates can be sourced from live data rather than one-shot measurements. That would extend the "persist" definition to include telemetry sources — an additive amendment, not a supersession.
- **ADR-023 and ADR-026 diverge** (the specialization stops matching the parent rule). Reassess both together.
- **Third-party agents built on Windy Road patterns fail to adopt** the grounding rule because the prompt amendment is too granular. Consider packaging the rule as a shared prompt fragment distributed via `@windyroad/shared` or similar.

## Related

- **P022** — the upstream problem ticket this ADR resolves.
- **P047** (WSJF effort bucket accuracy gaps) — sibling concern; ADR-026's default-M-with-advisory rule is the forward-compatible answer.
- **P046** (architect performance implications) — resolved by ADR-023, which becomes a specialization of this ADR.
- **P037** (JTBD reviewer output contract) — precedent for explicit output-shape contracts.
- **ADR-022** (Problem lifecycle Verification Pending) — **extended**, not modified. `Actual Effort:` field added at close-time; status-transition mechanics unchanged.
- **ADR-023** (wr-architect performance review scope) — **specialization** of this ADR. The per-request cost-delta × frequency rule is one application of ADR-026's cross-cutting principle. Follow-up commit updates ADR-023's prose to cite ADR-026 as parent.
- **ADR-015** (On-demand assessment skills) — unchanged; ADR-026 is a content rule that applies regardless of skill shape.
- **ADR-005** (Plugin testing strategy) — the bats doc-lint tests required by this ADR follow ADR-005's Permitted Exception for structural assertions.
- **JTBD-001**, **JTBD-002**, **JTBD-003**, **JTBD-006**, **JTBD-101**, **JTBD-201** — personas whose needs drive this ADR.
- `packages/risk-scorer/agents/pipeline.md` — trigger offender per P022; first target of the prompt-amendment sweep.
- `packages/architect/agents/agent.md` — currently cites P022; update to cite ADR-026 as parent.
- `packages/itil/skills/manage-problem/SKILL.md` — WSJF bucket selection + `.closed.md` `Actual Effort:` capture.
