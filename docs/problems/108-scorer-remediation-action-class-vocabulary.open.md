# Problem 108: Scorer remediation action-class vocabulary — known-class table needs expansion beyond `move-to-holding` + `revert-commit` (ADR-042 Rule 2a)

**Status**: Open
**Reported**: 2026-04-22
**Updated**: 2026-04-23
**Priority**: 15 (High) — Impact: Major (5) x Likelihood: Likely (3)
**Effort**: L
**WSJF**: (15 × 1.0) / 3 = **5.0**

> Opened alongside ADR-042 (`docs/decisions/041-auto-apply-scorer-remediations-above-appetite.proposed.md`) in the same landing commit. ADR-042 Rule 2a originally defined a **closed enumeration** of remediation action classes. The decision-maker explicitly rejected this constraint (2026-04-23): *"I do not agree to a closed action class enumeration. This constrains the remediations in an undesired ways and prevents innovative remediations."*
>
> ADR-042 supersedes ADR-042 with an **open vocabulary**: unknown classes are parsed for expressibility rather than triggering halt. This ticket's scope has shifted from "complete a closed enumeration" to "expand the known-class table" — the fast-path floor of natively-supported classes. The novel-class path (description parsing) now handles unknown classes without requiring coordinated ADR amendment.
>
> Today's known-class table (ADR-042 v1) ships with `move-to-holding` and `revert-commit` implemented. The remaining three classes — `amend-commit`, `feature-flag`, `rollback-to-tag` — are deferred to this ticket. Until P108 lands, any above-appetite state whose scorer-ranked remediation is a known class routes through the fast path; unknown classes route through the novel-class path (description parsing) or, if unexpressible, to ADR-042 Rule 5 halt.

## Description

ADR-042 encodes a "never release above appetite" invariant backed by an auto-apply loop over scorer remediations. The loop's Rule 2a accepts an **open vocabulary** of action classes with a known-class table as a fast-path floor:

| Class | Orchestrator action | Implemented in ADR-042 v1? |
|---|---|---|
| `move-to-holding` | `git mv .changeset/<name>.md docs/changesets-holding/<name>.md` | **Yes** |
| `revert-commit` | `git revert <sha>` | **Yes** |
| `amend-commit` | `git commit --amend` (only before push) | **No — this ticket** |
| `feature-flag` | `Edit` tool introduces a conditional gate | **No — this ticket** |
| `rollback-to-tag` | `git reset --hard <tag>` on a fresh branch | **No — this ticket** |

Two coordinated pieces are missing:

1. **Scorer contract extension (ADR-015 update)**: the scorer's `RISK_REMEDIATIONS:` block today has a free-form `description` column. For the orchestrator to classify deterministically, the scorer needs a structured `action_class` column naming one of the enumerated classes. Free-form descriptions produce ambiguity — e.g. "roll back the layout migration" could be `rollback-to-tag`, `revert-commit`, or `feature-flag` depending on implementation. The closed vocabulary must flow from scorer output, not orchestrator parsing.

2. **Orchestrator parsers** for each class beyond `move-to-holding`. The parser translates a classified remediation into the concrete git / Edit operation. Each class has a different set of preconditions (e.g., `amend-commit` only works on the HEAD commit, pre-push) and failure modes (e.g., `git revert` can produce merge conflicts on rollback against recent commits).

## Symptoms

Until P108 lands, ADR-042's auto-apply loop halts via Rule 5 whenever the scorer's top-ranked remediation is not `move-to-holding`. Halt emits a structured report naming the unsupported description, which is auditable — but the loop stops making progress on legitimate above-appetite states that would be resolvable by e.g. a `feature-flag` remediation.

Expected observable rate: any above-appetite state that cannot be resolved by moving a changeset out of `.changeset/` (e.g., an intrinsically risky single commit that was authored with a `minor` bump and produces ≥ 5/25 by itself) halts the loop. Rate is low in practice because most above-appetite states the scorer produces are multi-changeset-accumulation states that `move-to-holding` resolves.

## Workaround

When ADR-042 Rule 5 halt fires with an unsupported-class description:

1. Read the halt report's scorer-gap note to identify the required action class.
2. Manually execute the remediation (`git revert <sha>`, `Edit` to add a feature flag, etc.).
3. Re-run the orchestrator from the halted iteration.

This replicates the closed-enumeration behaviour by hand until the vocabulary extends.

## Impact Assessment

- **Who is affected**: any session running AFK or non-AFK governance flows that hits above-appetite release state with a non-`move-to-holding` remediation ranked first.
- **Frequency**: low — most scorer remediations today propose changeset moves because the scorer's own vocabulary is skewed that way. Expected to grow as scorer capability expands.
- **Severity**: moderate. Halt is safe (never-release-above-appetite invariant holds), but loop productivity stops. User intervention unblocks, but defeats AFK.
- **Composability**: `revert-commit` + Verification Pending carve-out (ADR-042 Rule 2b) interact — must be designed together. `amend-commit` + ADR-032 amend-based folding (ADR-042 Rule 3) also interact — must be designed together.

## Root Cause Analysis

### Preliminary Hypothesis

The scorer contract (ADR-015) does not specify a structured `action_class` column, so the orchestrator cannot classify deterministically. The natural extension is to add a 6th column to the `RISK_REMEDIATIONS:` block:

```
RISK_REMEDIATIONS:
- R1 | <description> | <effort> | <risk_delta> | <files> | <action_class>
- R2 | ...
```

With the new column, the orchestrator's parser reads `action_class` directly and routes to the appropriate executor. The free-form `description` stays as a human-readable summary.

Each executor (one per class) is a small Bash/Edit helper the orchestrator invokes. They share a common "re-score after apply" shape; they differ in their precondition checks and failure modes.

### Investigation Tasks

- [ ] **Scorer contract change**: ADR-015 amendment or new ADR extending the `RISK_REMEDIATIONS:` schema with `action_class`. Bats contract assertion on the schema.
- [ ] **Scorer emitter update**: `packages/risk-scorer/agents/pipeline.md` instructs the agent to classify each remediation. Backfill classification for common scorer-emitted prose shapes.
- [ ] **`revert-commit` executor**: `git revert <sha>` semantics + merge-conflict handling + interaction with Verification Pending carve-out (Rule 2b). What if the scorer proposes reverting the iteration's own commit? (Edge case: produces an empty iteration; needs a no-op-commit path.)
- [ ] **`amend-commit` executor**: only valid on HEAD + pre-push. Needs a precondition check. Interacts with ADR-032 amend-based folding (Rule 3).
- [ ] **`feature-flag` executor**: Edit tool introduces a conditional at the change site. Needs to know the feature's toggle conventions per plugin. Potentially needs a `DEFAULT_OFF=true` / `DEFAULT_ON=true` sub-spec.
- [ ] **`rollback-to-tag` executor**: `git reset --hard <tag>` on a fresh branch (NOT on the main branch). Leaves the old work on the named branch for recovery. Risky; needs explicit confirmation or a separate eligibility gate.
- [ ] **Bats contract assertions** per class — extend `work-problems-above-appetite-remediation.bats` with one assertion per newly-implemented class.
- [ ] **ADR-042 Rule 2a enumeration table update** — promote each newly-implemented class from "deferred to P108" to "Yes — implemented".

### Fix Strategy

Pending investigation. Expected shape: one ADR amendment (ADR-015 schema) + one ADR-042 Rule 2a table update + four small executors (one per class) + four bats assertions + scorer-agent prompt update. Likely 2–3 commits given the dependency between scorer contract and orchestrator parsers.

Slice order (tentative):
1. Scorer contract extension (ADR-015 amendment + emitter update).
2. `revert-commit` executor (simplest; leverages Rule 2b carve-out).
3. `amend-commit` executor (binds to ADR-032 folding).
4. `feature-flag` executor (requires per-plugin toggle convention).
5. `rollback-to-tag` executor (highest blast radius; last).

## Dependencies

- **Blocks**: (none directly — ADR-042 v1 lands without this; v2+ enumeration extension requires it)
- **Blocked by**: (none — this ticket drives the work)
- **Composes with**: ADR-042 Rule 2a, ADR-015, ADR-032

## Related

- **ADR-041** (`docs/decisions/041-auto-apply-scorer-remediations-above-appetite.superseded.md`) — superseded predecessor. Originally defined Rule 2a's closed enumeration; rejected by decision-maker. ADR-042 replaces it with open vocabulary.
- **ADR-015** (`docs/decisions/015-on-demand-assessment-skills.proposed.md`) — pure-scorer contract; `RISK_REMEDIATIONS:` schema lives here. The scorer contract extension lands as an amendment or successor ADR.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — amend-based folding (Rule 3) interacts with `amend-commit` executor.
- **ADR-022** (`docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md`) — Verification Pending carve-out (ADR-042 Rule 2b) interacts with `revert-commit` executor.
- **P103** (`docs/problems/103-work-problems-escalates-resolved-release-decisions-defeats-afk.open.md`) — original driver for ADR-042; this ticket's work closes the vocabulary gap the ADR itself flags as deferred.
- **P104** (`docs/problems/104-work-problems-partial-progress-paints-release-queue-into-corner.open.md`) — `move-to-holding` resolves P104 today; `revert-commit` / `feature-flag` give additional resolution paths for non-changeset-only above-appetite states.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — the AFK persona benefits from wider vocabulary; fewer halts, more convergence.
