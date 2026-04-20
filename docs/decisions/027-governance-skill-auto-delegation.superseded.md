---
status: "superseded"
date: 2026-04-20
superseded-date: 2026-04-21
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-20
superseded-by: [032-governance-skill-invocation-patterns]
---

# Governance skill auto-delegation — Step 0 delegates skill workflow to a subagent

> **SUPERSEDED by [ADR-032](./032-governance-skill-invocation-patterns.proposed.md) on 2026-04-21.**
>
> ADR-032 replaces the synchronous-Step-0-for-every-governance-skill mandate with a pattern taxonomy: foreground synchronous (existing skills, no Step 0), background capture (new sibling `capture-*` skills), foreground edit-gate / commit-gate (unchanged hook-delegated reviewers). The "log Y, keep working on X" promise from P014 is delivered via the new `/wr-itil:capture-problem`, `/wr-retrospective:capture-retro`, `/wr-architect:capture-adr` skills running in background. Existing `manage-problem`, `create-adr`, `run-retro`, `manage-incident` SKILL.md files lose the Step-0 subagent-delegation language and execute Steps 1-N in main-agent context again.
>
> This file is preserved for audit-trail integrity; the decision it records is no longer in force. Read ADR-032 for the current contract.

## Context and Problem Statement

Today, invoking a governance skill (`/wr-itil:manage-problem`, `/wr-retrospective:run-retro`, `/wr-architect:create-adr`, `/wr-itil:manage-incident`) consumes the main agent's turn. Each skill walks a multi-step intake — duplicates check, AskUserQuestion batches, architect and jtbd delegations, multi-concern analysis, file writes, risk-scoring, commit — that displaces whatever task was in flight.

In practice, the user experiences this as: "I was debugging X. I noticed a related problem Y. I ran `/wr-itil:manage-problem Y`. The skill took over my main-agent context for several turns. When it finished, I had to manually get the main agent back to X." The solo-developer persona's JTBD-001 outcome "reviews complete in under 60 seconds so they don't break flow" is violated whenever the full intake exceeds a minute, which is most of the time.

P014 originally framed this as a `/btw`-style aside problem — log a stub, defer the full intake. The user has explicitly rejected that framing: "the user doesn't ask for an aside. When they log a new problem, it should just automatically hand it off." There is no stubbing, no backfill — the full workflow runs, but in a subagent's context, not in the main agent's. The main agent returns to its task after emitting a single delegation call.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — the "without slowing down" axis is exactly this decision. The 60-second-review promise requires the skill's multi-step intake to NOT consume main-agent context.
- **JTBD-003** (Compose Only the Guardrails I Need) — governance skills become composable with active work because they no longer preempt it.
- **JTBD-006** (Progress the Backlog While I'm Away) — AFK orchestrator benefits: the `work-problems` loop's iteration-subagent invokes `manage-problem work`; with Step-0 delegation, `manage-problem` then delegates again. Nested subagents run in isolation; orchestrator's main loop is not displaced.
- **JTBD-101** (Extend the Suite with Clear Patterns) — plugin-developer; every new governance skill follows the same Step-0 pattern. One rule, many skills.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — audit trail unchanged: subagent commits land in git with the same message conventions.
- **P014** — the upstream problem ticket this ADR resolves, reframed per the user's direction (no stubs, automatic hand-off).

## Considered Options

1. **Step-0 auto-delegation to general-purpose subagent for all named governance skills** (chosen) — every listed skill's SKILL.md starts with a Step 0 that delegates the remaining work to a `general-purpose` subagent. Main agent emits the Agent call, receives the subagent's final summary, returns to its task.

2. **Opt-in via `--aside` flag per skill** — user has to remember the flag. Rejected: user direction is "just automatically hand it off", no flag.

3. **Status quo** — main agent runs skill in-context. Rejected: the cost is the problem.

4. **Hook-based detection of governance-shaped user prompts** (`/btw` / `btw, we have a problem with X` auto-detects and delegates) — implicit, false positives, hard to control. Rejected.

5. **Per-skill dedicated subagents** (`wr-itil:manage-problem-executor`, `wr-retrospective:run-retro-executor`, etc.) — proliferates subagent types without clear benefit at current scale. Rejected as first-cut.

6. **Dedicated `governance-executor` subagent (single shared type)** — defined as a new subagent with tool access and a prompt that teaches it to follow SKILL.md. More setup than general-purpose but cleaner contract. Rejected as first-cut; reassessment criterion below triggers a reconsider if the general-purpose subagent's behaviour drifts.

## Decision Outcome

Chosen option: **Option 1 — Step-0 auto-delegation to `general-purpose` subagent for all named governance skills.**

Rationale:
- The user's direction is unambiguous: automatic hand-off, no flag, no user-visible ceremony.
- `general-purpose` subagent type exists today, has broad tool access, and reading a SKILL.md into its prompt is sufficient — no new subagent definition required.
- Step 0 is additive to each skill's SKILL.md; steps 1-N remain exactly as today (the subagent executes them). No reordering of ADR-014's `work → score → commit` sequence.
- Nested subagent behaviour (AFK orchestrator → iteration subagent → governance-skill subagent) works cleanly: each level has its own context, AskUserQuestion calls surface to the user as normal, commits land in the shared worktree.

### Scope

**In scope at acceptance:**

- **Skills that gain Step 0**: `wr-itil:manage-problem`, `wr-itil:manage-incident`, `wr-itil:work-problems` (only the per-iteration `manage-problem work` call — the orchestrator itself is already a subagent), `wr-retrospective:run-retro`, `wr-architect:create-adr`.

- **Skills held for reassessment**: `wr-itil:report-upstream` (ADR-024, not yet implemented — narrow workflow, may not need Step-0 delegation; decide when the skill ships).

- **Step 0 contract** — added to each in-scope SKILL.md at the top of its Steps section, before step 1:

    ```markdown
    ### Step 0: Delegate to a governance subagent

    This skill's full workflow runs in a subagent's context, not the main agent's. The main agent's sole task in this invocation is to delegate; after delegation, the main agent returns to whatever task it was working on before the skill was invoked.

    Mechanism:
    1. Use the Agent tool with `subagent_type: "general-purpose"`.
    2. Construct a self-contained prompt including:
       - The user's verbatim arguments to the skill.
       - The current task context (if the main agent was mid-task, one sentence of "main agent is currently working on <task>" so the subagent's summary can refer back to it).
       - The full text of this SKILL.md (so the subagent knows the steps to follow) OR a pointer to its path (`packages/<plugin>/skills/<skill>/SKILL.md`) that the subagent will read.
       - A clear instruction: "Execute steps 1-N of this SKILL.md end-to-end. When complete, return a summary following the skill's existing 'Report' convention. Do not abbreviate steps or skip reviews."
    3. Wait for the subagent's final report.
    4. Return the subagent's report verbatim to the user. Do not re-execute any of the skill's steps in main-agent context.
    5. Resume the task the main agent was working on before the skill invocation.

    **Do NOT** execute steps 1-N of this SKILL.md in main-agent context under any circumstance. If the delegation fails, surface the failure to the user and ask whether to retry, invoke in main-agent context as a fallback, or abandon — this fallback exists for completeness per ADR-013 Rule 6, not as a common path.
    ```

- **Step 0 text appears verbatim (or near-verbatim) in every in-scope SKILL.md**. Consistency is enforced via a bats doc-lint test.

- **Subagent nesting with AFK orchestrator** (ADR-018 interaction):
  - The `work-problems` orchestrator spawns an iteration-subagent per loop iteration that invokes `/wr-itil:manage-problem work`. Under ADR-027, that invocation's Step 0 delegates to *another* subagent. Two levels of nesting.
  - **Release drain ownership**: the orchestrator's Step 6.5 (post-iteration release-cadence check per ADR-018) runs in the **orchestrator's context**, not in either subagent. The governance-skill subagent skips its own Step 12 auto-release (per the existing "skip if inside AFK orchestrator" rule in manage-problem SKILL.md). Orchestrator owns drain; nothing changes in ADR-018.
  - **Preflight ownership**: ADR-019's fetch-origin + ff-only preflight runs in the **orchestrator's context** at loop start. Iteration-subagent and governance-skill-subagent inherit the same worktree (same git state). They do NOT re-run the preflight. If origin diverges mid-loop, the orchestrator's next-iteration preflight catches it.
  - Two-level nesting is acceptable because each level is bounded — orchestrator spawns one subagent per iteration; governance-skill's Step 0 spawns one subagent per invocation; neither recurses.

- **ADR-014 ordering preservation**: Step 0 inserts delegation BEFORE the skill's steps 1-N. The subagent then executes steps 1-N exactly as today, including the `work → score → commit` ordering. Step 0 does not displace, reorder, or abbreviate ADR-014's sequence. The subagent reads the SKILL.md and follows it verbatim.

- **Subagent AskUserQuestion surfacing**: subagents' `AskUserQuestion` calls surface to the user as interactive questions, same as main-agent-originated ones. The user's answers return to the subagent; the subagent's flow continues. No new mechanism required.

- **Hook re-invocation in subagent context**: when the subagent writes project files, the architect-enforce-edit + jtbd-enforce-edit hooks fire in the subagent's session. The subagent delegates to `wr-architect:agent` and `wr-jtbd:agent` per the hook's requirement, receives markers with a session-scoped TTL, and proceeds. The main agent's earlier review markers do not transfer to the subagent's session — but the subagent's session-scoped reviews are cheap (markers are written once per session), so the extra cost is bounded.

- **Bats doc-lint tests**:
  - `packages/itil/skills/manage-problem/test/manage-problem-step-0.bats` asserts manage-problem's SKILL.md contains Step 0 with the required wording.
  - Equivalents for `manage-incident`, `work-problems` (its iteration-spawn still has the Step 0 at the governance-skill level, not the orchestrator level), `run-retro`, `create-adr`.
  - Each test asserts Step 0 cites ADR-027, names `general-purpose` as the subagent type, and includes the "do not execute in main-agent context" negative constraint.

**Out of scope (follow-up tickets or future ADRs):**

- A dedicated `governance-executor` subagent type (Option 6). If general-purpose behaviour drifts or users report summary-format inconsistency, a future ADR introduces the dedicated type.
- Step-0 delegation for `wr-itil:report-upstream` (narrow workflow; decided at implementation time for that skill).
- Cross-session audit of the "return summary verbatim" contract (whether subagent summaries match each skill's documented reporting format). Behavioural observation over 3 months informs reassessment.
- Automatic recovery from failed delegation (today: surface the failure to the user).

## Consequences

### Good

- Main agent's task context is preserved through governance skill invocations. JTBD-001's "reviews complete in under 60 seconds" promise holds because the main agent spends one turn (the delegation call), not the full skill workflow.
- Governance skills become composable with active work (JTBD-003): capture a problem while debugging, the main agent continues debugging.
- AFK orchestrator benefits structurally: iteration-subagent + governance-skill-subagent nesting keeps each level's context isolated.
- Pattern is reusable — every new governance skill follows the same Step 0 template. JTBD-101 "clear patterns" promise.
- Audit trail unchanged (JTBD-201): subagent commits land in git with the same message conventions.
- No new subagent type to define or maintain — `general-purpose` is sufficient as first-cut.

### Neutral

- Two levels of subagent nesting inside AFK orchestrator. Each level is bounded (one subagent per iteration; one subagent per skill invocation). Acceptable complexity.
- Architect and jtbd-lead reviews fire in the subagent's session with their own TTLs. Marginal extra review cost per skill invocation; bounded and acceptable for the execution-isolation benefit. Documented here so future readers don't re-litigate.
- Subagent's AskUserQuestion surfaces normally but the user sees "subagent is asking" rather than "main agent is asking". UX difference is minimal — the question itself looks the same.
- Each in-scope SKILL.md grows by one step (~30 lines of Step 0 boilerplate). Small doc maintenance cost.

### Bad

- **Subagent summary format drift**: the `general-purpose` subagent's summary may not match each skill's documented "Report" convention exactly. Mitigation: Step 0 instructs the subagent to follow the skill's existing reporting format, and bats doc-lint tests assert Step 0 contains the instruction. The contract is not enforceable structurally — only behaviourally. Reassessment criterion triggers a dedicated `governance-executor` subagent if drift is observed.
- **Delegation failure recovery is manual**: if the subagent fails (timeout, tool-use error, hook failure), Step 0's fallback is "surface the failure to the user and ask whether to retry, invoke in main-agent context, or abandon." This is correct per ADR-013 Rule 6 but means some invocations will surface recoverable errors the user has to triage.
- **Context loss between main agent and subagent**: the subagent doesn't inherit main-agent's conversation history. Step 0 passes the user's arguments + the main-agent's current task context as a sentence, but richer context (e.g. what the main agent was debugging three turns ago) doesn't transfer. Acceptable — governance skills' workflows are self-contained and don't need rich history.
- **Hook re-firing cost**: every subagent spawn fires architect + jtbd hooks on its first file write, requiring fresh reviews. Bounded (one review per subagent-session), but it's not free.
- **Nesting edge cases**: three-level nesting (orchestrator → iteration → governance-skill) is the maximum routinely expected. Deeper nesting (a governance skill invoking another governance skill) is possible in principle; this ADR does not forbid it but also does not exercise it in tests. Reassessment criterion if deeper nesting emerges.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - Each in-scope SKILL.md starts with the Step 0 text (verbatim or near-verbatim) before its Step 1.
   - Step 0 text includes: delegation via `subagent_type: "general-purpose"`, construction of a self-contained prompt, the "do not execute in main-agent context" negative constraint, the verbatim-summary return contract, and a citation to ADR-027.
   - Neither Step 0 nor any subsequent step displaces or reorders ADR-014's `work → score → commit` sequence.
   - `work-problems` SKILL.md documents that its iteration-subagent invocation of `manage-problem work` is subject to ADR-027's Step-0 delegation (two-level nesting), and that the orchestrator retains ownership of ADR-018's release drain and ADR-019's preflight.
   - `manage-problem`'s "Step 12: Auto-release" retains its existing "skip if inside AFK orchestrator" detection so drain stays in the orchestrator.

2. **Test (bats doc-lint, Permitted Exception per ADR-005):**
   - `packages/itil/skills/manage-problem/test/manage-problem-step-0.bats` — asserts Step 0 exists, cites ADR-027, names `general-purpose`, includes the negative constraint, and preserves the `work → score → commit` ordering in steps 1-N.
   - Equivalents for `manage-incident`, `work-problems`, `run-retro`, `create-adr`.
   - A meta-test `packages/itil/skills/test/governance-auto-delegation-coverage.bats` enumerates the in-scope skills and asserts each has its Step-0 bats file present.

3. **Behavioural replay**:
   - Invoke `/wr-itil:manage-problem Test problem for ADR-027 replay` in a fresh session. Verify: the main agent emits one Agent tool call; the subagent runs the full manage-problem workflow; the main agent returns the subagent's summary verbatim and then the main agent is in a state where it can continue its prior task.
   - Same replay for each other in-scope skill.
   - AFK nesting replay: invoke `/wr-itil:work-problems` with a fresh backlog; verify the orchestrator spawns iteration-subagents that then spawn governance-skill-subagents, and that release drain happens in the orchestrator's context, not inside either subagent.

4. **Return-summary-verbatim contract (behavioural)**: the subagent's final message must match the skill's existing "Report" convention. Not structurally enforceable; flagged for observation in the first 3 months of adoption. If drift is observed in 3+ invocations, trigger reassessment toward the dedicated `governance-executor` subagent.

5. **Nesting-boundary assertions**:
   - Orchestrator's ADR-019 preflight runs in orchestrator context; verified by `work-problems-preflight.bats` (existing).
   - Orchestrator's ADR-018 drain runs in orchestrator context; verified by `work-problems-release-cadence.bats` (existing).
   - Governance-skill subagent skips its own auto-release when inside AFK; verified by `manage-problem SKILL.md`'s existing detection text + bats coverage.

## Pros and Cons of the Options

### Option 1: Step-0 auto-delegation, general-purpose subagent, all named skills (chosen)

- Good: user direction exactly — automatic hand-off, no flag, no user ceremony.
- Good: uses existing `general-purpose` subagent; no new type to define.
- Good: additive to each SKILL.md; no reordering of existing steps.
- Good: composes cleanly with AFK orchestrator's two-level nesting.
- Good: governance skills' commit-and-release discipline is preserved by the subagent following SKILL.md verbatim.
- Bad: summary-format drift risk (subagent may not match skill's Report convention exactly).
- Bad: hook re-firing in subagent sessions adds marginal review cost.

### Option 2: Opt-in via `--aside` flag per skill

- Good: explicit user control.
- Bad: user has to remember the flag; rejected by user direction.

### Option 3: Status quo

- Good: no change; no new failure mode.
- Bad: violates JTBD-001's "60 seconds" promise on every multi-step governance invocation.

### Option 4: Hook-based detection of governance-shaped prompts

- Good: zero ceremony.
- Bad: implicit, false positives on conversational "btw", hard to reason about.

### Option 5: Per-skill dedicated subagents

- Good: maximum specialisation per skill.
- Bad: proliferates subagent types without clear benefit at current scale.

### Option 6: Single dedicated `governance-executor` subagent

- Good: cleaner contract than general-purpose.
- Bad: more setup now; reassessment criterion lets us upgrade later if drift is observed.

## Reassessment Criteria

Revisit this decision if:

- **Summary-format drift is observed** in 3+ subagent invocations (the subagent's final message does not match the skill's existing Report convention). That triggers introduction of the dedicated `governance-executor` subagent (Option 6) with a stricter output contract.
- **Delegation failure rate** exceeds 1% of invocations. That signals the `general-purpose` subagent is unreliable for governance workflows; consider either a dedicated subagent or adding structural retry logic in Step 0.
- **Context-loss between main agent and subagent** produces materially worse governance outputs (e.g. the subagent misses duplicates because it lacks the main agent's earlier conversation context). Would trigger a richer Step-0 context-passing contract.
- **Hook re-firing cost** (architect + jtbd reviews in every subagent session) becomes loop-stopping in AFK orchestrators. Would trigger either session-level marker inheritance (a change to the hooks) or a cap on review re-runs.
- **Deeper nesting** emerges (a governance skill invoking another governance skill). Would trigger a separate ADR on nesting bounds.
- **New governance skills** not covered here need their own Step 0. Routine: add them to the Confirmation checklist; no ADR amendment needed.
- **JTBD-006 trust boundary** shifts such that AFK personas no longer tolerate the orchestrator's owning drain/preflight while subagents own everything else. Would trigger a redistribution of responsibilities.

## Related

- **P014** — the upstream problem ticket this ADR resolves (reframed per user direction: no stubs, automatic hand-off).
- **ADR-013** (Structured user interaction for governance decisions) — Step 0's delegation-failure fallback invokes Rule 6 (non-interactive fail-safe when interactive resolution is unavailable).
- **ADR-014** (Governance skills commit their own work) — preserved verbatim by the subagent; Step 0 does not reorder or displace the `work → score → commit` sequence.
- **ADR-015** (On-demand assessment skills) — unaffected; orthogonal (ADR-015 is about skill contract, ADR-027 is about execution context).
- **ADR-018** (Inter-iteration release cadence for AFK loops) — drain ownership clarified: orchestrator owns drain; subagents do not. ADR-018's Step 6.5 is unchanged.
- **ADR-019** (AFK orchestrator preflight) — preflight ownership clarified: orchestrator owns preflight; subagents inherit worktree state.
- **ADR-024** (Cross-project problem-reporting contract) — `report-upstream` skill held for reassessment (not in initial scope); decision at implementation time.
- **JTBD-001**, **JTBD-003**, **JTBD-006**, **JTBD-101**, **JTBD-201** — personas whose needs drive this ADR.
- `packages/itil/skills/manage-problem/SKILL.md` — first target of Step-0 amendment.
- `packages/itil/skills/manage-incident/SKILL.md`, `packages/itil/skills/work-problems/SKILL.md` — also amended.
- `packages/retrospective/skills/run-retro/SKILL.md` — amended.
- `packages/architect/skills/create-adr/SKILL.md` — amended.
