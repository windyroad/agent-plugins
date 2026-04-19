---
status: "proposed"
date: 2026-04-20
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-20
---

# Diagnose before implement — structured hypothesis + evidence + RED-for-the-right-reason gate

## Context and Problem Statement

Autonomous multi-step loops (`wr-itil:work-problems`, `wr-itil:manage-problem work`, `wr-itil:manage-incident`) frequently race from a prompt directly into code changes without first producing a verified root-cause hypothesis with evidence. The result: fixes that are logically coherent against the *wrong* model of the problem ship through the TDD + ADR + release pipeline before the diagnosis error is caught — forcing revert-and-retry cycles.

Per the session insights report (1,464 messages across 86 sessions, 2026-03-17 to 2026-04-16), "Wrong Approach" (54 instances) and "Buggy Code" (41 instances) are the two dominant friction types — combined, ~61% of all flagged friction. Specific examples:

- **RapidAPI outage misdiagnosis**: Claude diagnosed a production outage as a frontend/worker/API-key issue and proposed a vendor-locked fix before user screenshots forced recognition of the real gateway bug.
- **P140 shipped without P141**: Claude removed capture buttons without the conditional resume-recording path the user explicitly required, introducing stale-links bugs.
- **P011 "literal replay" requirement**: the first green test didn't prove the fix — the test had to be rewritten to replay the actual bug literally.

The insights report's recommended pattern is "Split investigate from implement": before any fix, (1) state the hypothesis, (2) show evidence, (3) write a failing test that reproduces the *actual* bug (verify it fails for the right reason), and (4) implement.

P039 is the upstream problem ticket. This ADR operationalises the pattern across every autonomous loop that can transition from diagnosing to implementing.

**User direction (this session)**: no user-ack at the diagnose→implement boundary. User reasoning: "why do we need a user-ack point there at all? would that just be a 'let's pretend the human is helping' step?" The self-check IS the verification; the user sees the hypothesis + RED output + citation match in the summary regardless; an ack carries no new information and breaks the autonomy outcome of JTBD-006.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — "the agent cannot bypass governance" applies to cognition as well as commits. Fixes that ship against the wrong model of the problem ARE a governance bypass — the TDD gate cleared, but for the wrong invariant. Structured diagnose-phase closes the bypass path.
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — 54 Wrong Approach + 41 Buggy Code instances over 30 days are the measured cost of skipping diagnose. Confidence erodes on every revert-and-retry cycle.
- **JTBD-006** (Progress the Backlog While I'm Away) — per jtbd-lead review, the self-check is a "routine decision" (mechanical citation match) not a "judgement call"; JTBD-006 trusts routine decisions. A user-ack at this boundary would break JTBD-006's autonomy outcome.
- **JTBD-101** (Extend the Suite with Clear Patterns) — plugin-developer; the structured diagnose-phase is a reusable pattern. New orchestrator skills adopt it.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — tech-lead; incident response per JTBD-201 explicitly requires "hypotheses cite evidence (logs, repro, diff, metric) before any mitigation is attempted." ADR-029 operationalises this into manage-incident.
- **P039** — the upstream problem ticket this ADR resolves.
- **P022 / ADR-026** — shares the "evidence-before-claims" principle; ADR-029 extends it from agent quantitative output to agent *reasoning*.

## Considered Options

1. **Per-skill amendment with shared contract text in ADR; self-check only; no user-ack** (chosen) — each in-scope SKILL.md adds a "Diagnose Phase" section citing ADR-029's contract. The agent runs hypothesis → evidence → RED test → self-check → implement in sequence. No user-ack at the boundary; self-check failure halts and persists findings.

2. **New diagnose-first subagent that each orchestrator delegates to** — shared subagent handles the diagnose phase. Rejected: adds infrastructure without benefit; per-skill amendment is simpler and reuses existing context.

3. **Hook-based gate blocking code-file writes until a "diagnosed" marker exists** — PreToolUse denies Edit/Write until the marker is present. Rejected: too many false positives on routine refactors; hook can't distinguish diagnose-driven writes from unrelated edits.

4. **User-ack at the diagnose→implement boundary** — halt the loop, ask via AskUserQuestion whether the hypothesis is sound before implementation. Rejected per user direction: the ack carries no information the user doesn't already have from the summary, and breaks JTBD-006's autonomy.

## Decision Outcome

Chosen option: **Option 1 — per-skill amendment with shared contract; self-check only; no user-ack; self-check failure halts the iteration and persists findings to the ticket's Root Cause Analysis.**

Rationale:
- Self-check is mechanical (citation match), not qualitative. Routine by JTBD-006's definition; can be automated without violating the AFK trust boundary.
- User-ack at the boundary is theatre — the user sees the hypothesis + RED output + self-check in the iteration report either way. Per ADR-013 Rule 6 the ack is a policy-authorised action that can be skipped when it carries no information; per the user's direction this is the correct reading.
- Per-skill amendment keeps the contract close to where it applies; ADR body carries the shared rule. Matches ADR-027's precedent for cross-skill rules (per-skill amendment + shared contract).

### Scope

**In scope at acceptance:**

- **Skills amended**: `wr-itil:manage-problem` (specifically the `work` operation on Open problems), `wr-itil:manage-incident`, `wr-itil:work-problems` (via the orchestrator's post-iteration report — the inner manage-problem invocation carries the rule).

- **Future scope**: `feature-implementation` skill if added. Deferred — no such skill exists today.

- **The Diagnose Phase contract** — added to each in-scope SKILL.md before any implementation step:

    ```markdown
    ### Diagnose Phase (per ADR-029)

    Before any implementation step runs, the skill MUST emit a structured diagnose-phase output in the following order:

    1. **Hypothesis** — a concrete statement citing a specific file:line, log line,
       or data point. "The issue is in packages/foo/bar.ts:42 where X happens" is
       valid. "There seems to be a problem with authentication" is not.

    2. **Evidence** — linked artefacts that support the hypothesis. At minimum:
       - A source-code reference (file:line or blame link).
       - OR a log excerpt / telemetry reading with its source.
       - OR a git-history reference (commit or blame).
       Prose alone is not evidence.

    3. **Failing test** — a test that reproduces the defect, RED'd against the
       hypothesis. The test file must follow ADR-025's traceability invariant:
       include `@problem:P<NNN>` for the ticket being worked so the RED test's
       provenance is traceable. The test's RED output must be captured.

    4. **Self-check** — affirm that the RED output fails for the reason stated in
       the hypothesis, not for a trivial reason (file-not-found, import error,
       typo, missing fixture). The self-check is a structural citation match:
       the RED output must contain either the file:line cited in the hypothesis
       OR a substring match on the hypothesis's log-line citation.

    5. **Transition** — only after self-check passes does the skill proceed to
       implementation. If self-check fails:
       - Persist the hypothesis + evidence + RED output + self-check failure
         reason to the problem ticket's Root Cause Analysis section.
       - Halt this iteration. In AFK mode: move to the next problem. In
         interactive mode: surface the failure to the user for diagnosis.
    ```

- **Self-check structural criteria** (soft-enforced in the SKILL.md prompt):
  - RED output MUST contain a citation matching the hypothesis's cited file:line (exact string match, e.g. "packages/foo/bar.ts:42"), OR
  - RED output MUST contain a substring of the hypothesis's log-line citation.
  - If neither match, self-check fails.
  - The agent explicitly affirms "Self-check: RED output contains <citation>; test fails for the hypothesised reason" in the iteration report. No affirmation = no transition.

- **ADR-025 cross-check**: the RED test written in the diagnose phase MUST satisfy ADR-025's traceability invariant. Since `docs/problems/` exists in this project, traceability is blocking; the test must include `@problem:P<NNN>` annotation for the ticket being worked. ADR-025's concreteness layer applies independently. This ADR does NOT relax ADR-025; it REINFORCES it by giving the test a concrete citation to satisfy the traceability layer.

- **ADR-022 interaction**: the diagnose-phase output IS the evidence that satisfies ADR-022 Step 7's "root cause confirmed, fix path clear" precondition for the Open → Known Error transition. `manage-problem`'s transition mechanic at step 7 is unchanged; ADR-029 gives it the upstream guarantee that the Root Cause Analysis section has been populated with structured evidence before the transition fires.

- **ADR-013 Rule 6 authorisation**: skipping the user-ack at the diagnose→implement boundary is a policy-authorised action per ADR-013 Rule 6 on two grounds:
  - The self-check is structural (mechanical citation match), not a judgement call that requires user input.
  - The user sees the hypothesis + RED output + self-check in the iteration report; an ack carries no new information.
  This ADR cites ADR-013 Rule 6 as the authorisation basis for skipping the boundary ack, consistent with ADR-027's precedent for policy-authorised delegations.

- **Self-check failure branch** — the skill writes to the ticket's `## Root Cause Analysis` section:

    ```markdown
    ### Diagnose Phase Failure — <YYYY-MM-DD>

    **Hypothesis**: <hypothesis text>
    **Evidence**: <evidence references>
    **RED output**: <test output>
    **Self-check failure reason**: <e.g. "RED output does not cite hypothesis file:line packages/foo/bar.ts:42; test failed at import time with 'Cannot find module'">
    ```

  In AFK mode the orchestrator records this as a "diagnose-halt" event in its iteration summary and moves to the next problem. In interactive mode the skill surfaces the failure to the user for manual diagnosis. No auto-retry.

- **Bats doc-lint tests**:
  - `packages/itil/skills/manage-problem/test/manage-problem-diagnose-phase.bats` asserts SKILL.md contains the Diagnose Phase contract, cites ADR-029, names the four required outputs, and includes the self-check criteria.
  - Equivalents for `manage-incident` and `work-problems`.
  - `packages/itil/skills/work-problems/test/work-problems-diagnose-halt-report.bats` asserts the orchestrator's iteration summary format includes a diagnose-halt case for self-check failures.

**Out of scope (follow-up tickets or future ADRs):**

- Structural enforcement via a hook (PreToolUse blocking on missing diagnose marker). Soft guidance is the first-cut; reassessment triggers structural enforcement if self-check drift is observed in 3+ iterations.
- Feature-implementation skill (doesn't exist today).
- Cross-iteration diagnose-phase caching (re-using a prior iteration's hypothesis for a recurring bug). Possible future extension; initial contract is per-iteration.
- Automatic RED-output parsing to validate the citation match. Agent's self-check is trust-based; structural parsing is the escalation path.

## Consequences

### Good

- Revert-and-retry cycles caused by diagnosis errors drop because the structured diagnose-phase forces the agent to produce evidence before implementing.
- JTBD-201's "hypotheses cite evidence before mitigation" requirement is operationalised in manage-incident, closing the gap this JTBD has today.
- ADR-022 Step 7's "root cause confirmed" precondition is upstream-enforced by the diagnose phase — the Root Cause Analysis section is always populated before transition.
- ADR-025's traceability invariant is reinforced by the RED test needing to cite the Problem ID; the two ADRs are operationally coupled and mutually-strengthening.
- AFK loops stay autonomous per JTBD-006 — no user-ack halts; self-check failure records findings and moves to the next problem.
- Pattern is reusable for future autonomous skills (JTBD-101).

### Neutral

- Every Open-problem iteration and every incident iteration now emits 4+ structured output items (hypothesis, evidence, RED test, self-check affirmation, transition). More visible log output per iteration. Acceptable: the structure is the audit trail JTBD-201 wants.
- The self-check criteria are soft-enforced in the SKILL.md prompt, not hook-gated. Heuristic but honest; reassessment trigger escalates to structural enforcement if drift observed.
- Diagnose-halt events in AFK mode produce iteration summaries with "halted on diagnose-phase" entries. User reviews these on return. Normal failure path for the AFK loop; no extra handling.

### Bad

- **Self-check drift**: the agent may affirm "Self-check passed" without the RED output actually matching the hypothesis. Heuristic vulnerable to lazy affirmation. Mitigation: reassessment criterion explicitly triggers structural enforcement if self-check drift is observed in 3+ iterations.
- **Diagnose-phase overhead for trivially-understood problems**: a clearly one-line bug fix now goes through four structured outputs before the fix. Cost is bounded (minutes of agent time) and is net-positive per the P039 friction counts, but some users may find the overhead annoying for genuinely-obvious cases. No escape hatch provided — consistent with ADR-025's no-escape-hatch stance on test-content-quality.
- **Hypothesis-citation false negatives**: the self-check requires an exact file:line or substring match between hypothesis and RED output. Legitimate cases where the hypothesis is correct but the RED output doesn't structurally cite it (e.g. the bug manifests one frame up the stack from the cited line) fail self-check and halt the iteration. Mitigation: the halt writes findings to Root Cause Analysis; user reviews and can override at interactive time. In AFK mode, the ticket is flagged and the loop moves on — the halt is recoverable on next session.
- **Nesting with ADR-027**: manage-problem Step 0 delegates to a subagent; the subagent runs the diagnose phase; self-check happens in the subagent context. The subagent's summary includes the diagnose phase output. If the subagent's summary truncates or omits the self-check output, the caller (main agent or orchestrator) can't audit the diagnose phase. Mitigation: SKILL.md Step 0's verbatim-summary contract (per ADR-027) requires the subagent to return the full report; bats doc-lint for ADR-029 and ADR-027 together assert both contracts hold.
- **First cross-ADR operational coupling** (ADR-022 Step 7 + ADR-025 traceability + ADR-027 Step-0 nesting + ADR-029 diagnose phase). Each ADR stands alone, but together they require mental coherence to implement correctly. Reassessment criterion flags re-review if the coupling becomes a maintenance burden.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - Each in-scope SKILL.md contains the Diagnose Phase section citing ADR-029, naming the four required outputs (hypothesis, evidence, failing test, self-check), and specifying the transition rule.
   - Each SKILL.md's self-check failure branch writes to the ticket's `## Root Cause Analysis` section with the `### Diagnose Phase Failure — <date>` subsection format documented above.
   - SKILL.md text does not contradict ADR-022's Step 7 precondition; the diagnose phase's outputs are the evidence for the transition.
   - RED tests written during the diagnose phase carry `@problem:P<NNN>` per ADR-025's traceability invariant.

2. **Test (bats doc-lint):**
   - `packages/itil/skills/manage-problem/test/manage-problem-diagnose-phase.bats` asserts the contract: Hypothesis/Evidence/Failing-Test/Self-check headings present, ADR-029 cited, transition-on-pass + halt-on-fail text present.
   - Equivalents for `manage-incident` and `work-problems`.
   - `packages/itil/skills/manage-problem/test/manage-problem-diagnose-failure-section.bats` asserts the self-check failure branch names the `## Root Cause Analysis` ticket section with the `### Diagnose Phase Failure` subsection header format.

3. **ADR cross-coupling confirmation**:
   - ADR-022 Step 7 precondition: the diagnose-phase output is the evidence. No ADR-022 text change; ADR-029 is the upstream enforcer.
   - ADR-025 traceability: the RED test carries `@problem:` annotation. Verified by ADR-025's bats traceability tests.
   - ADR-027 Step-0 nesting: the subagent's summary-verbatim contract propagates the diagnose phase output back to the caller. Verified by ADR-027's bats step-0 tests.
   - ADR-013 Rule 6 authorisation: skipping user-ack at the diagnose→implement boundary is explicitly cited. No ADR-013 text change.

4. **Behavioural replay**:
   - Seed a known-misdiagnosis scenario (e.g. a ticket where the initial hypothesis cites packages/foo/bar.ts:42 but the bug is actually in packages/foo/baz.ts:10). Invoke manage-problem work. Verify: the agent emits the diagnose-phase output; the RED test's output does not contain a citation matching the hypothesis; self-check fails; findings are written to Root Cause Analysis; iteration halts without implementation.
   - Seed a correctly-diagnosed scenario. Verify: self-check passes, transition to implementation proceeds.
   - Run an AFK loop where one iteration hits self-check failure; verify the orchestrator records the halt and moves to the next problem.

5. **Audit-trail inspection**: after 5 iterations, read each ticket's `## Root Cause Analysis` section. Every Open-or-Known-Error ticket worked through ADR-029 should have either:
   - A successful diagnose-phase record (hypothesis, evidence, RED citation, self-check affirmation) followed by the implementation, OR
   - A `### Diagnose Phase Failure` subsection documenting the halt.

## Pros and Cons of the Options

### Option 1: Per-skill amendment, shared contract, self-check only, no user-ack (chosen)

- Good: operationalises JTBD-201's "hypotheses cite evidence before mitigation" directly.
- Good: preserves JTBD-006 autonomy (no user-ack at the boundary).
- Good: cross-couples with ADR-022, ADR-025, ADR-027 to reinforce the governance graph.
- Good: reusable pattern for new autonomous skills.
- Bad: self-check drift is possible; reassessment escalates to structural enforcement if observed.
- Bad: diagnose-phase overhead on trivially-obvious problems.

### Option 2: New diagnose-first subagent

- Good: clean separation of diagnose from implement in execution context.
- Bad: adds infrastructure; subagent can't do implementation work so the iteration has two delegations (diagnose subagent → implement subagent).

### Option 3: Hook-based gate on code-file writes

- Good: structural enforcement.
- Bad: false positives on routine refactors; hook can't distinguish diagnose-driven writes from unrelated edits.

### Option 4: User-ack at the diagnose→implement boundary

- Good: maximum control.
- Bad: user direction explicitly rejects this ("let's pretend the human is helping" — the ack carries no new information).
- Bad: breaks JTBD-006 autonomy.

## Reassessment Criteria

Revisit this decision if:

- **Self-check drift is observed in 3+ iterations** (the agent affirms "self-check passed" but the RED output does not structurally cite the hypothesis, or the hypothesis changes between affirmation and implementation). That triggers structural enforcement — escalate from SKILL.md-prompt-based to a hook-gated check that parses the RED output and compares against the hypothesis.
- **Diagnose-phase overhead becomes loop-stopping** in AFK mode (a significant fraction of iterations halt on self-check failure). Would trigger either relaxing the self-check criteria (substring match thresholds) or introducing an explicit halt-and-continue mode where findings are saved and the next problem is worked without a halt-event marker.
- **Hypothesis-citation false-negative rate exceeds 10%** — agent's hypothesis is correct but self-check fails because the structural citation doesn't match. Would trigger either richer match heuristics (regex, fuzzy match) or adding an explicit override mechanism for the agent to assert "self-check passed despite citation mismatch, here's why".
- **ADR-025 annotation changes** (e.g. a new annotation form emerges). ADR-029's RED-test requirement must stay in sync.
- **ADR-027 Step-0 summary contract is relaxed** (subagent summaries become shorter / don't include the diagnose phase output). That would break ADR-029's cross-coupling; requires reassessment of both ADRs together.
- **A feature-implementation skill is added** — routine amendment to the Scope section; no new ADR needed.
- **JTBD-006 AFK persona constraints change** (user wants to re-introduce the user-ack at the boundary). Would require user-driven re-decision; no reassessment trigger from ADR mechanics.

## Related

- **P039** — the upstream problem ticket this ADR resolves.
- **P011** — literal replay requirement; one of the precedent incidents that motivated the "test must fail for the right reason" principle.
- **P022 / ADR-026** — evidence-before-claims principle; ADR-029 extends it from quantitative output to agent reasoning.
- **ADR-013** (Structured user interaction) — Rule 6 authorisation basis for skipping user-ack at the diagnose→implement boundary.
- **ADR-014** (Governance skills commit their own work) — the iteration still commits per ADR-014; ADR-029 is pre-commit reasoning.
- **ADR-018** (Inter-iteration release cadence) — orthogonal; runs post-iteration.
- **ADR-019** (AFK orchestrator preflight) — orthogonal; runs at loop start.
- **ADR-022** (Problem lifecycle Verification Pending) — reinforced: the diagnose-phase output IS the evidence for Step 7's "root cause confirmed, fix path clear" precondition.
- **ADR-025** (Test content quality review) — cross-coupled: the RED test written during diagnose carries the `@problem:P<NNN>` annotation required by ADR-025's traceability layer.
- **ADR-027** (Governance skill auto-delegation) — nested: the subagent that runs manage-problem also runs the diagnose phase. ADR-027's summary-verbatim contract preserves the diagnose output back to the caller.
- **JTBD-001**, **JTBD-002**, **JTBD-006**, **JTBD-101**, **JTBD-201** — personas whose needs drive this ADR.
- `packages/itil/skills/manage-problem/SKILL.md` — first target of amendment; the "Open problem (no confirmed root cause)" section is where the Diagnose Phase slots in.
- `packages/itil/skills/manage-incident/SKILL.md` — amended; JTBD-201's evidence-before-mitigation requirement operationalised here.
- `packages/itil/skills/work-problems/SKILL.md` — iteration summary format extended to cover diagnose-halt events.
