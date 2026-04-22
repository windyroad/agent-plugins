---
"@windyroad/itil": minor
---

ADR-041: auto-apply scorer remediations when above appetite; never release above appetite

Land ADR-041 closing P103 (`/wr-itil:work-problems` escalated resolved above-appetite release decisions) and P104 (partial-progress painted the release queue into a corner).

Behaviour:

- `work-problems` Step 6.5 gains an above-appetite branch. When `push` or `release` residual risk lands ≥ 5/25, the orchestrator auto-applies scorer remediations in rank order (largest `|risk_delta|` first) until residual risk converges within appetite (≤ 4/25). Each auto-apply amends the iteration's main commit per ADR-041 Rule 3 (preserves ADR-032 one-commit-per-iteration invariant).
- `manage-problem` Step 12 and `manage-incident` Step 15 terminal release sequences inherit the same above-appetite branch; each auto-apply is its own commit since there is no iteration wrapper in non-AFK mode.
- **Never release above appetite**: there is no code path in either lineage that drains at ≥ 5/25. Exhaustion halts the loop/skill per ADR-041 Rule 5.
- **Closed action-class enumeration (Rule 2a)**: ADR-041 v1 ships with `move-to-holding` implemented (`git mv .changeset/<name>.md docs/changesets-holding/<name>.md`). Classes `revert-commit`, `amend-commit`, `feature-flag`, `rollback-to-tag` are deferred to P108. Unsupported class descriptions route to Rule 5 halt.
- **Verification Pending carve-out (Rule 2b)**: auto-revert never fires against commits attached to `.verifying.md` tickets; Rule 5 halt names the VP ticket(s).
- **Governance gates apply per auto-apply (Rule 3)**: the scorer proposes; architect + JTBD + risk-scorer gates authorise. No scorer-bypass path.
- **Audit trail (Rule 6)**: iteration/skill reports emit an Auto-apply trail subsection (one line per apply); `docs/changesets-holding/README.md` "Currently held" appends for `move-to-holding` actions.
- **Holding-area blessed (Rule 7)**: `docs/changesets-holding/` promoted from provisional to authoritative. ADR-041 cited as the governing decision; provisional banner removed.

Supersedes the implicit above-appetite branch of ADR-018 Step 6.5 and the explicit above-appetite branch of ADR-020 §6; both ADRs cross-reference ADR-041 from the same commit. At-or-below-appetite drain behaviour in both is unchanged.

Authorised by ADR-013 Rule 5 (policy-authorised silent proceed): `RISK-POLICY.md` appetite + ADR-041 Rule 2a enumeration constitute the policy for the auto-apply loop.

Follow-up work tracked in **P108** (`docs/problems/108-scorer-remediation-action-class-vocabulary.open.md`) — scorer contract extension (structured `action_class` column in `RISK_REMEDIATIONS:`) + orchestrator parsers for the four deferred classes. Until P108 lands, ADR-041 v1's scope is the `move-to-holding` subset.

Closes P103, P104. Opens P108.
