---
status: "proposed"
date: 2026-04-22
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-22
---

# Auto-apply scorer remediations to reach within appetite — never release above

## Context and Problem Statement

`RISK-POLICY.md` defines a risk appetite (4/25, "Low" band). ADR-018 and ADR-020 both define the within-appetite drain path: when residual push/release risk is at or below appetite, `npm run push:watch` + `npm run release:watch` are policy-authorised (ADR-013 Rule 5) and proceed silently. Neither ADR specifies what happens when residual push/release risk lands **above appetite** (≥ 5/25) with a changeset queue already committed.

The implicit default in prose is "skip the drain and report" (ADR-020 §6: `"Release skipped — risk above appetite. Run ... manually when ready."`). That default produces two failure modes:

1. **AFK halt** (P103, observed 2026-04-22): an AFK iteration reaches above-appetite release state; the orchestrator falls back to `AskUserQuestion` instead of using the scorer's `RISK_REMEDIATIONS:` block. The loop halts on a decision the scorer had already resolved. User direction verbatim: *"you have a risk scorer to assess release risk — you didn't need to ask me, instead of doing, you wasted time waiting for me to respond"*.
2. **Painted-into-a-corner queue** (P104): partial-progress iterations can commit slice 1 of a multi-slice fix without slice 2; if slice 1 alone pushes risk above appetite, the skip-and-defer path leaves the queue mid-state for hours or days with the user unaware.

The user's subsequent direction, 2026-04-22: *"we deliberately CANNOT do an above-appetite release — the controls are there for a reason. The agent MUST continue to work to reduce the risk — there is always a way. More importantly, it should release often to avoid risk build up. At the very worst, it can move the changes or feature-flag them or roll them back."*

This ADR encodes that direction. Never release above appetite. Auto-apply scorer remediations in rank order until residual risk converges within appetite. Halt the loop/skill on exhaustion — treat exhaustion as a scorer-gap signal, not as permission to release.

Concurrently, the `docs/changesets-holding/` convention introduced by the P100 multi-slice work is currently self-declared **provisional**, deferring to "candidate ADR-039" that never landed. The holding-area mechanics are tightly coupled to Rule 2's canonical `move-to-holding` action class, so they belong in this decision document. Rule 7 blesses the convention.

## Decision Drivers

- **JTBD-006 (Progress the Backlog While I'm Away)** — primary motivator. AFK persona expects forward progress without interactive halts when the scorer has already resolved the decision surface. Persona split in `docs/jtbd/solo-developer/persona.md`: *trusts agent for routine, deterministic, mechanical decisions; does NOT trust agent for judgment calls*. This ADR restricts auto-apply to a **closed enumeration of remediation action classes** (Rule 2a) so the orchestrator stays on the mechanical side of the split. The under-60-second target from JTBD-001 is scoped to per-edit review, not to release-drain orchestration; multi-minute auto-apply loops at release time are acceptable within that scope.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — under-60-second target applies per-edit, so the auto-apply loop's multi-minute duration is out of that budget's scope. Each individual auto-apply commit still goes through gates under the same 60-second-per-edit target.
- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — "agent cannot bypass governance" and "audit trail exists showing governance was followed". Rule 3 (gates apply per auto-apply commit) and Rule 6 (per-auto-apply audit line) encode this directly.
- **Pure-scorer contract (ADR-015)** — scoring + remediation generation live in the scorer; orchestrator interprets and acts. This ADR depends on a stable remediation-class vocabulary (Rule 2a); see P108 for the scorer-contract extension that fills today's free-form `description` column gap.
- **ADR-013 Rule 5 (policy-authorised silent proceed)** — `RISK-POLICY.md` appetite + this ADR's eligibility rules constitute the policy authorising auto-apply actions; no `AskUserQuestion` is required for any action governed by Rules 1–7.
- **Symmetry across modes (ADR-018 ↔ ADR-020)** — AFK and non-AFK governance flows share the same above-appetite behaviour. This ADR supersedes ADR-018 Step 6.5's implicit above-appetite fallback and ADR-020 §6's "release skipped" branch.
- **Lean release principle (ADR-014)** — governance skills commit, and the orchestrator releases, their own work. The above-appetite branch is the missing piece that turned ADR-014 into a *sometimes-I-release* skill instead of an *always-I-release-or-halt* skill.
- **Never-release-above-appetite invariant** — governance controls exist for a reason; there must be no path by which an above-appetite release lands. Halt is the terminal fallback, never release. JTBD-006's "The loop stops gracefully when ... it hits a blocker" authorises loop-halt on scorer exhaustion (exhaustion IS a blocker).
- **Release-often principle** — the primary mitigation for above-appetite accumulation is frequent releases (ADR-018's at-appetite drain trigger, preserved unchanged). This ADR covers the residual case where a single commit or commit-set is intrinsically above appetite despite the draining discipline.
- **P103 + P104** — the two problem tickets this ADR resolves.

## Considered Options

1. **Liberal auto-apply with halt-on-exhaustion (chosen)** — mandatory auto-apply in rank order until within appetite; gates apply per auto-apply commit; closed enumeration of action classes; halt (not release) on exhaustion.
2. **Narrow auto-apply (original 2026-04-22 draft)** — auto-apply only for `effort=S` + `.changeset/*.md` + sufficient `risk_delta`; one per iteration; fall through to AskUserQuestion / skip-release on exhaustion. **Rejected**: too narrow to resolve P103; preserves the AskUserQuestion escape hatch the user's direction forbids; eligibility criteria (effort=S + changeset-only + sufficient risk_delta) would route most real-world above-appetite states to the fallback, defeating the ADR's purpose.
3. **Skip the release, continue the loop** (JTBD-agent counter-proposal) — above-appetite iterations leave commits dirty-for-known-reason; loop continues to next iteration's work. **Rejected**: accumulates unreleasable commits across iterations, re-creates the P104 "painted into a corner" hazard, and defers the scorer-gap bug signal behind productive-looking work. The user's explicit direction ("halt the loop") supersedes this softer interpretation.
4. **Ask the user** (status quo of the narrow draft and pre-ADR prose) — keep `AskUserQuestion` as the above-appetite default. **Rejected per P103 evidence**: defeats JTBD-006 (AFK halts on resolved decisions) and JTBD-001 (non-AFK skills slow down on decisions the scorer has already ranked).
5. **Release above appetite with a loud audit line** — drain the release at whatever residual risk remains, with explicit acceptance. **Rejected**: violates the never-release-above-appetite invariant; controls exist for a reason; release discipline is a load-bearing trust signal the user has explicitly named.

## Decision Outcome

Chosen option: **"Liberal auto-apply with halt-on-exhaustion"**, because the never-release-above-appetite invariant is the primary constraint and liberal auto-apply is the only mechanism that reliably honours it across AFK and non-AFK flows. Halt-on-exhaustion is the safety valve: if the scorer cannot find a reduction path, the orchestrator refuses to release and surfaces the exhaustion as a bug signal for user resolution.

**This ADR supersedes** the implicit above-appetite fallback of ADR-018 Step 6.5 and the explicit above-appetite branch of ADR-020 §6. Both ADRs remain authoritative for their at-or-below-appetite paths; above-appetite behaviour in both is governed by Rules 1–7 below. Cross-reference amendments land in the same commit as this ADR.

### Rules

#### Rule 1 — Auto-apply is mandatory above appetite; never release above

When residual push or release risk is above appetite (≥ 5/25 per `RISK-POLICY.md`), the orchestrator MUST auto-apply scorer remediations until residual risk is within appetite (≤ 4/25). The orchestrator MUST NOT release above appetite under any circumstance. The orchestrator MUST NOT escalate to `AskUserQuestion` as a shortcut out of the auto-apply loop — the scorer is the decision surface, not the user.

Rule 1 is policy-authorised per ADR-013 Rule 5: `RISK-POLICY.md` appetite + this ADR's enumeration (Rule 2a) constitute the policy. No interactive authorisation is required for any action inside Rules 2–7.

#### Rule 2 — Apply in rank order; re-score after each

Parse the scorer's `RISK_REMEDIATIONS:` block. Rank remediations by:

1. Largest absolute `risk_delta` first;
2. Smaller effort (S < M < L);
3. Lower remediation ID (R1 before R2).

Apply the top-ranked remediation per its action class (Rule 2a). After each apply, re-score via `wr-risk-scorer:pipeline` (subagent, preferred) or `/wr-risk-scorer:assess-release` (skill, fallback — ADR-015 delegation precedent). Classify the re-score:

- **Within appetite (≤ 4/25)** → proceed to drain via `push:watch` + `release:watch` per ADR-018/ADR-020's within-appetite mechanism. Done.
- **Above appetite (≥ 5/25)** → apply the next remediation in rank order. Loop.

The loop terminates when one of:

- Re-score reaches within appetite (drain path);
- Every ranked remediation has been applied and re-score is still above appetite (Rule 5 halt);
- A remediation's action class is outside the enumerated vocabulary (Rule 5 halt — scorer-gap signal);
- A remediation apply fails (merge conflict, hook rejection, failing tests) — halt with the failed-remediation detail per Rule 5.

#### Rule 2a — Closed action-class enumeration

The orchestrator recognises a closed enumeration of remediation action classes. The scorer's `RISK_REMEDIATIONS:` description column MUST classify under exactly one of these; any description that does not parse into a known class is treated as scorer-contract violation and routes to Rule 5 halt.

**Today's enumeration (ADR-041 v1):**

| Class | Orchestrator action | Reversibility | Supported now? |
|---|---|---|---|
| `move-to-holding` | `git mv .changeset/<name>.md docs/changesets-holding/<name>.md` | Trivial (`git mv` back) | **Yes** — implemented in this landing |
| `revert-commit` | `git revert <sha>` (new inverse commit) | Trivial (`git revert` the revert) | **No** — deferred to P108 + scorer contract extension |
| `amend-commit` | `git commit --amend` (only before push) | Moderate (requires force-push if published) | **No** — deferred to P108 |
| `feature-flag` | `Edit` tool introduces a conditional gate | Moderate (delete the flag) | **No** — deferred to P108 |
| `rollback-to-tag` | `git reset --hard <tag>` on a fresh branch | Low (other commits can be cherry-picked back) | **No** — deferred to P108 |

Until P108 lands a structured scorer-contract extension (with an explicit `action_class` column in `RISK_REMEDIATIONS:` and orchestrator parsers for each class), the only auto-apply action the orchestrator executes is `move-to-holding`. Any other description → Rule 5 halt with the description logged so the vocabulary gap is visible. This is deliberate incremental delivery — the ADR codifies the full vocabulary intent while the implementation lands the mechanical subset.

#### Rule 2b — Verification Pending carve-out

Commits attached to a `.verifying.md` ticket (per ADR-022 Verification Pending lifecycle) are **never** eligible for auto-revert. The scorer MAY propose `revert-commit` against a VP commit; the orchestrator MUST NOT execute it, and routes the remediation to Rule 5 halt with the halt report naming the VP ticket(s) so the user can verify-and-close on return. This prevents auto-undoing fixes that the user is in the middle of verifying.

#### Rule 3 — Governance gates apply to every auto-apply commit

Every auto-apply that requires a commit goes through the standard ADR-014 commit flow: architect review, JTBD review, risk-scorer gate. The scorer's ranking does NOT bypass the gates — the scorer proposes; the gates authorise. A gate rejection on any auto-apply falls through to Rule 5 halt.

**Amend-based folding (per ADR-032 compatibility):** In AFK mode, a single iteration's auto-apply commits fold into the iteration's main commit via `git commit --amend` rather than producing N sibling commits, preserving ADR-032's one-commit-per-iteration invariant. The final score is run against the amended commit. In non-AFK mode, each auto-apply is a standalone commit since there is no iteration-level wrapper; ADR-014 still applies per-commit.

#### Rule 4 — No per-iteration cap (repealed from prior draft)

The narrow draft's "one auto-apply per iteration" cap is repealed. Apply as many remediations as needed to converge within appetite. Auditability concerns are handled at report-format level (Rule 6), not by artificial caps.

#### Rule 5 — Halt on exhaustion (never release above appetite)

The orchestrator MUST halt (not release) when any of the following hold:

- The scorer produces no remediations and residual risk is above appetite;
- Every ranked remediation has been applied and residual risk is still above appetite;
- A remediation's description does not parse into the Rule 2a enumeration;
- A remediation attempt fails a gate (Rule 3) or a git operation (conflict, merge failure).

**AFK mode (work-problems lineage / ADR-018 Step 6.5):** halt the loop. Emit the iteration summary with `outcome: halted-above-appetite`, the final re-score, the remediations attempted (with outcome for each), and the ticket IDs of any Verification Pending commits implicated per Rule 2b. Do NOT proceed to the next iteration. The tree's dirty state (the iteration's own commit, possibly with auto-apply amendments) is preserved for user inspection on return. This is the JTBD-006 "stops gracefully when it hits a blocker" path.

**Non-AFK mode (manage-problem / manage-incident lineage / ADR-020 terminal):** halt the skill. Emit the skill's terminal report naming the final re-score, the remediations attempted, and any VP ticket implications. The user must resolve interactively — typical resolutions include splitting the commit, feature-flagging the change, or opening a problem ticket documenting the scorer gap.

Halt is a **bug signal**, not a routine outcome. The scorer SHOULD always have progressively more aggressive remediations available (move → revert → feature-flag → rollback). Halt exposes a gap in the scorer's vocabulary or ranking — the correct follow-up is to improve the scorer, not to relax Rule 1. A halt SHOULD produce a new problem ticket (via run-retro or user-initiated) capturing the scorer gap.

#### Rule 6 — Audit trail

Every auto-apply decision MUST be logged in two places:

1. **Iteration / skill report** — append one line per auto-apply with:
   - Remediation ID (`R<n>`)
   - Action class (per Rule 2a)
   - Pre-apply `commit/push/release` scores
   - Post-apply re-score
   - Action taken (the git operation or Edit summary)
   - One-line citation of the remediation's `description` column

   When multiple auto-applies fire in one iteration, emit one line per apply under a single "Auto-apply trail" subheading so the iteration summary stays skimmable.

2. **Holding-area README** (`docs/changesets-holding/README.md`) — for `move-to-holding` actions only. Append to the "Currently held" section with the parent ticket reference and the reinstate trigger. When a held changeset is later reinstated (`git mv docs/changesets-holding/<name>.md .changeset/<name>.md`), move the entry from "Currently held" to "Recently reinstated" with the reinstate date and reason.

#### Rule 7 — Holding-area convention (blessed)

`docs/changesets-holding/` is now an **orchestrator-blessed convention**, not provisional. The holding-area README's "provisional" banner is removed and the README cites this ADR as the authoritative mechanism. The mechanics (`git mv` to/from the area, file naming preserved, README "Currently held" + "Recently reinstated" sections) are unchanged from the provisional version.

### Scope

**In scope (this ADR's landing commit):**

- `packages/itil/skills/work-problems/SKILL.md` — Step 6.5 above-appetite branch per Rules 1–6; Non-Interactive Decision Making table updated for "Commit when risk above appetite" → cites ADR-041.
- `packages/itil/skills/manage-problem/SKILL.md` — Step 11 terminal commit sequence above-appetite branch per Rules 1–6 and Rule 5 non-AFK halt.
- `packages/itil/skills/manage-incident/SKILL.md` — terminal commit step, same shape as manage-problem.
- `docs/changesets-holding/README.md` — provisional banner removal + ADR-041 citation (Rule 7).
- `docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md` — amendment adding above-appetite cross-reference to ADR-041.
- `docs/decisions/020-governance-auto-release-for-non-afk-flows.proposed.md` — §6 above-appetite branch replaced with cross-reference to ADR-041.
- `packages/itil/skills/work-problems/test/work-problems-above-appetite-remediation.bats` — new contract-assertion bats file per ADR-037.
- `docs/problems/108-scorer-remediation-action-class-vocabulary.open.md` — new problem ticket captures the scorer-contract extension deferred from Rule 2a.

**Out of scope (this ADR's landing):**

- Implementation of `revert-commit`, `amend-commit`, `feature-flag`, `rollback-to-tag` action classes — deferred to P108's scorer-contract extension + orchestrator parser work.
- Reinstate automation for held changesets — remains a user-initiated `git mv` once the blocking slices land. Future work may automate this when blocking-ticket close detection is reliable.
- Adjustments to `RISK-POLICY.md` appetite threshold — the invariant "never release above appetite" operates at the current 4/25 threshold; any threshold change is a separate `update-policy` invocation.
- Changing the release-cadence trigger (ADR-018 at-appetite threshold) — out of scope; the release-often principle is preserved via ADR-018 as-is.

## Consequences

### Good

- **Never-release-above-appetite invariant holds.** There is no code path in AFK or non-AFK flows that releases above appetite. Release discipline is a compile-time property of the orchestrator, not a runtime appeal.
- **AFK loops stop escalating decisions the scorer resolved.** P103 closed: above-appetite states no longer halt the loop on `AskUserQuestion`; they route to the auto-apply loop.
- **P104 painted-into-a-corner hazard reduced.** The holding-area is now blessed and auto-apply routes changesets there as a first-line remediation.
- **Symmetry preserved.** AFK and non-AFK flows share the same above-appetite behaviour. No divergence to drift over time.
- **Audit trail per Rule 6** makes auto-apply decisions reviewable on user return: one line per apply in the iteration report + one line per move in the holding-area README.
- **Exhaustion is auditable, not silent.** Rule 5 halt emits a structured report naming what was tried and why it was insufficient — the scorer gap is visible, not hidden behind a successful release.
- **VP carve-out (Rule 2b)** prevents the auto-revert soft-lock that would otherwise destroy fixes the user is verifying.

### Neutral

- **Rules 1–7 add branch complexity.** Step 6.5 in work-problems, Step 11 in manage-problem, and the terminal step in manage-incident each gain a multi-branch above-appetite section. Contract-assertion bats (ADR-037 pattern) verify the load-bearing strings land in each branch.
- **Closed action-class enumeration (Rule 2a) is intentionally small today.** Only `move-to-holding` is implemented. Any above-appetite state whose scorer-ranked remediation is not `move-to-holding` routes to Rule 5 halt until P108 extends the scorer contract + orchestrator parsers. This is conservative-by-design during the scorer-contract evolution window.
- **The holding area accumulates entries during multi-slice WIP.** The README serves as the audit log.

### Bad

- **Source-edit auto-apply classes (`feature-flag`) are NOT mechanically reversible the way `move-to-holding` is.** When P108 lands source-touching remediations, the audit trail per Rule 6 becomes load-bearing for user review-and-revert on return. Mitigation: each auto-apply commit is a distinct commit (or a named amendment in AFK mode) so `git revert` works at the commit level.
- **Scorer contract dependency.** Rule 2a's closed enumeration creates a contract between scorer output and orchestrator parser. Any scorer change (new action class, description-format change) requires a coordinated orchestrator update. Mitigation: P108 owns the contract-evolution path; Rule 2a is versioned (`ADR-041 v1` today) so future ADRs can extend cleanly.
- **Halt-on-exhaustion can stop an AFK loop mid-queue.** If a scorer gap halts iteration N, iterations N+1..M never fire — even if they would have worked on unrelated tickets. This is the conservative choice: continuing past an unreleasable iteration risks compounding the above-appetite state. Mitigated in practice by the scorer being reliable enough that exhaustion is rare; when it happens, treat as a bug and fix the scorer.
- **Gate traversal cost per auto-apply.** Rule 3 requires architect + JTBD + risk-scorer review on every auto-apply commit. For a 3-remediation iteration that means 3× full gate traversal. Mitigated by AFK mode's `git commit --amend` folding (Rule 3 amend-based folding) — the iteration still produces one final commit that carries one final gate traversal against the amended state.

## Confirmation

Compliance is verified by:

1. **Source review**: each in-scope SKILL.md has the above-appetite branch with Rules 1–7 referenced (never-release-above-appetite invariant, rank-order apply, action-class enumeration, VP carve-out, gate-per-commit, halt-on-exhaustion, audit trail) and cites this ADR. The ADR-018 and ADR-020 amendments cite ADR-041.
2. **Bats contract assertions** (per ADR-037): `packages/itil/skills/work-problems/test/work-problems-above-appetite-remediation.bats` asserts the load-bearing strings — `RISK_REMEDIATIONS`, `docs/changesets-holding/`, `above appetite`, ADR-013 Rule 5 citation, `never release above appetite` invariant phrase, `ADR-041` citation, the Non-Interactive Decision Making table row for the above-appetite branch, and the Rule 5 halt-on-exhaustion semantics.
3. **Behavioural** (manual until P012's harness lands): an AFK loop that hits an above-appetite release-cadence event with an eligible `move-to-holding` remediation auto-applies the move, re-scores within appetite, drains, and proceeds to the next iteration — without invoking `AskUserQuestion`. Verifiable from the iteration report's Auto-apply trail subsection + the holding-area README's "Currently held" entry.
4. **Halt-on-exhaustion behavioural**: an AFK loop hitting a remediation outside Rule 2a's enumeration (pre-P108) halts with `outcome: halted-above-appetite` naming the unsupported description. Verifiable from the halt report shape.

## Reassessment Triggers

Revisit this decision if:

- P108 lands the scorer contract extension + orchestrator parsers — Rule 2a enumeration expands; bats assertions update; "today's enumeration" becomes "v2+".
- The `RISK-POLICY.md` appetite threshold changes — Rule 1's "above appetite" numeric definition shifts.
- A fourth in-scope lineage emerges (e.g., `create-adr` under ADR-014 auto-release) — the ADR may need to extend to that skill's terminal step.
- The scorer's `RISK_REMEDIATIONS:` contract changes shape — Rule 2 parsing and Rule 2a enumeration both depend on it.
- Halt-on-exhaustion fires frequently in practice (say, more than once per week of active AFK use) — treat as a scorer-gap signal; the correct response is scorer improvement, but a threshold of repeated halt could justify re-evaluating whether the invariant is operationally tenable at the current threshold.
- ADR-014 / ADR-018 / ADR-020 are superseded — lineage assumption breaks.

## Related

- **P103** (`docs/problems/103-work-problems-escalates-resolved-release-decisions-defeats-afk.open.md`) — driver for the auto-apply rule. AFK loop halt at iter 4 2026-04-22.
- **P104** (`docs/problems/104-work-problems-partial-progress-paints-release-queue-into-corner.open.md`) — driver for the holding-area convention's promotion from provisional.
- **P108** (`docs/problems/108-scorer-remediation-action-class-vocabulary.open.md`) — opened in the same commit as this ADR. Tracks the scorer-contract extension + orchestrator parsers for `revert-commit`, `amend-commit`, `feature-flag`, `rollback-to-tag` action classes deferred from Rule 2a.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 5 (policy-authorised proceeds silently) authorises every auto-apply action inside Rules 2–7; Rule 6 (non-interactive fail-safe) no longer applies to the above-appetite branch since Rule 5 halt is the fail-safe now.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — commit layer this ADR extends with the above-appetite auto-apply branch. Rule 3 requires gates per auto-apply commit; ADR-032 amend-based folding (Rule 3) keeps the one-commit-per-iteration invariant intact.
- **ADR-015** (`docs/decisions/015-on-demand-assessment-skills.proposed.md`) — pure-scorer contract; defines the `RISK_REMEDIATIONS:` machine-readable interface this ADR consumes. P108 will extend ADR-015's contract with structured action-class columns.
- **ADR-018** (`docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md`) — AFK lineage; above-appetite behaviour in ADR-018 Step 6.5 is superseded by this ADR. ADR-018's at-or-below-appetite drain is unchanged.
- **ADR-020** (`docs/decisions/020-governance-auto-release-for-non-afk-flows.proposed.md`) — non-AFK lineage; §6 above-appetite branch is superseded by this ADR. ADR-020's at-or-below-appetite drain is unchanged.
- **ADR-022** (`docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md`) — Verification Pending lifecycle. Rule 2b carves out VP commits from auto-revert to prevent the lifecycle soft-lock.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — subprocess-boundary iteration pattern. Rule 3's amend-based folding preserves the one-commit-per-iteration invariant across auto-apply loops.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern used for Confirmation criterion 2.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — under-60-second target (per-edit scope, not release-drain scope).
- **JTBD-002** (`docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`) — audit trail requirement satisfied by Rule 6.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — AFK persona, primary motivator; "stops gracefully when it hits a blocker" authorises Rule 5 loop-halt on exhaustion.
- **`docs/changesets-holding/README.md`** — holding-area mechanics; provisional banner removed and ADR-041 cited as the authoritative basis per Rule 7.
- Memory: `feedback_act_on_obvious_decisions.md` — captures the user's lesson; this ADR is the structural / repo-wide encoding.
