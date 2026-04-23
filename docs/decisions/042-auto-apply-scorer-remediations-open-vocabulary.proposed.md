---
status: "proposed"
date: 2026-04-23
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-23
supersedes: "ADR-041"
---

# Auto-apply scorer remediations to reach within appetite — open action-class vocabulary

## Context and Problem Statement

`RISK-POLICY.md` defines a risk appetite (4/25, "Low" band). ADR-018 and ADR-020 both define the within-appetite drain path: when residual push/release risk is at or below appetite, `npm run push:watch` + `npm run release:watch` are policy-authorised (ADR-013 Rule 5) and proceed silently. Neither ADR specifies what happens when residual push/release risk lands **above appetite** (≥ 5/25) with a changeset queue already committed.

The implicit default in prose is "skip the drain and report" (ADR-020 §6: `"Release skipped — risk above appetite. Run ... manually when ready."`). That default produces two failure modes:

1. **AFK halt** (P103, observed 2026-04-22): an AFK iteration reaches above-appetite release state; the orchestrator falls back to `AskUserQuestion` instead of using the scorer's `RISK_REMEDIATIONS:` block. The loop halts on a decision the scorer had already resolved. User direction verbatim: *"you have a risk scorer to assess release risk — you didn't need to ask me, instead of doing, you wasted time waiting for me to respond"*.
2. **Painted-into-a-corner queue** (P104): partial-progress iterations can commit slice 1 of a multi-slice fix without slice 2; if slice 1 alone pushes risk above appetite, the skip-and-defer path leaves the queue mid-state for hours or days with the user unaware.

The user's subsequent direction, 2026-04-22: *"we deliberately CANNOT do an above-appetite release — the controls are there for a reason. The agent MUST continue to work to reduce the risk — there is always a way. More importantly, it should release often to avoid risk build up. At the very worst, it can move the changes or feature-flag them or roll them back."*

This ADR encodes that direction. Never release above appetite. The agent reads scorer remediations and decides what to do incrementally until residual risk converges within appetite. Halt the loop/skill on exhaustion — treat exhaustion as a scorer-gap signal, not as permission to release.

This ADR **supersedes ADR-041** (2026-04-22). ADR-041's Rule 2a encoded a **closed action-class enumeration** — only five known classes were permitted, and any unknown class triggered Rule 5 halt. The decision-maker explicitly rejected this constraint (2026-04-23):

> "I do not agree to a closed action class enumeration. This constrains the remediations in an undesired ways and prevents innovative remediations."

ADR-042 replaces the closed enumeration with an **open vocabulary**: the scorer writes free-form prose suggestions; the agent reads them and decides what to do. No lookup tables, no parsers, no pre-built executors.

Concurrently, the `docs/changesets-holding/` convention introduced by the P100 multi-slice work is now **orchestrator-blessed** (Rule 7).

## Decision Drivers

- **JTBD-006 (Progress the Backlog While I'm Away)** — primary motivator. AFK persona expects forward progress without interactive halts when the scorer has already resolved the decision surface. Persona split in `docs/jtbd/solo-developer/persona.md`: *trusts agent for routine, deterministic, mechanical decisions; does NOT trust agent for judgment calls*. The open-vocabulary Rule 2a lets the agent decide what to do, like any other decision in the workflow. The scorer suggests; the agent reads, understands, and acts. No bounded parsing, no expressibility check, no pre-built handlers.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — under-60-second target applies per-edit, so the auto-apply loop's multi-minute duration is out of that budget's scope. Each individual auto-apply commit still goes through gates under the same 60-second-per-edit target.
- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — "agent cannot bypass governance" and "audit trail exists showing governance was followed". Rule 3 (gates apply per auto-apply commit) and Rule 6 (per-auto-apply audit line) encode this directly.
- **Pure-scorer contract (ADR-015)** — scoring + remediation generation live in the scorer; orchestrator interprets and acts. This ADR depends on a stable remediation-class vocabulary (Rule 2a); see P108 for the scorer-contract extension that fills today's free-form `description` column gap.
- **ADR-013 Rule 5 (policy-authorised silent proceed)** — `RISK-POLICY.md` appetite + this ADR's eligibility rules constitute the policy authorising auto-apply actions; no `AskUserQuestion` is required for any action governed by Rules 1–7.
- **Symmetry across modes (ADR-018 ↔ ADR-020)** — AFK and non-AFK governance flows share the same above-appetite behaviour. This ADR supersedes ADR-018 Step 6.5's implicit above-appetite fallback and ADR-020 §6's "release skipped" branch.
- **Lean release principle (ADR-014)** — governance skills commit, and the orchestrator releases, their own work. The above-appetite branch is the missing piece that turned ADR-014 into a *sometimes-I-release* skill instead of an *always-I-release-or-halt* skill.
- **Never-release-above-appetite invariant** — governance controls exist for a reason; there must be no path by which an above-appetite release lands. Halt is the terminal fallback, never release. JTBD-006's "The loop stops gracefully when ... it hits a blocker" authorises loop-halt on scorer exhaustion (exhaustion IS a blocker).
- **Release-often principle** — the primary mitigation for above-appetite accumulation is frequent releases (ADR-018's at-appetite drain trigger, preserved unchanged). This ADR covers the residual case where a single commit or commit-set is intrinsically above appetite despite the draining discipline.
- **Open-vocabulary innovation** — the scorer must be free to propose novel remediation classes without waiting for a human to draft, review, and merge an ADR amendment. The closed-enumeration approach in ADR-041 created a bottleneck where every new class required a coordinated code + ADR update. The open vocabulary removes that bottleneck while preserving safety through the "expressibility check" + Rule 3 gates.
- **P103 + P104** — the two problem tickets this ADR resolves.

## Considered Options

1. **Liberal auto-apply with open vocabulary and halt-on-exhaustion (chosen)** — mandatory auto-apply until within appetite; gates apply per auto-apply commit; open vocabulary; halt (not release) on exhaustion.
2. **Closed enumeration with incremental delivery (ADR-041)** — auto-apply only for known classes; unknown classes trigger halt. **Rejected per decision-maker direction 2026-04-23**: constrains scorer innovation, creates ADR-amendment bottleneck for every new class.
3. **Skip the release, continue the loop** (JTBD-agent counter-proposal) — above-appetite iterations leave commits dirty-for-known-reason; loop continues to next iteration's work. **Rejected**: accumulates unreleasable commits across iterations, re-creates the P104 "painted into a corner" hazard, and defers the scorer-gap bug signal behind productive-looking work. The user's explicit direction ("halt the loop") supersedes this softer interpretation.
4. **Ask the user** (status quo of the narrow draft and pre-ADR prose) — keep `AskUserQuestion` as the above-appetite default. **Rejected per P103 evidence**: defeats JTBD-006 (AFK halts on resolved decisions) and JTBD-001 (non-AFK skills slow down on decisions the scorer has already suggested).
5. **Release above appetite with a loud audit line** — drain the release at whatever residual risk remains, with explicit acceptance. **Rejected**: violates the never-release-above-appetite invariant; controls exist for a reason; release discipline is a load-bearing trust signal the user has explicitly named.

## Decision Outcome

Chosen option: **"Liberal auto-apply with open vocabulary and halt-on-exhaustion"**, because the never-release-above-appetite invariant is the primary constraint and liberal auto-apply is the only mechanism that reliably honours it across AFK and non-AFK flows. The open vocabulary removes the scorer-innovation bottleneck that the closed enumeration created, while the expressibility check + Rule 3 gates preserve safety.

Halt-on-exhaustion is the safety valve: if the scorer cannot find a reduction path, the orchestrator refuses to release and surfaces the exhaustion as a bug signal for user resolution.

**This ADR supersedes ADR-041.** ADR-041 is promoted to `.superseded.md` status with a forward pointer to this document. ADR-018 and ADR-020 cross-references to ADR-041's Rule 2a are updated to point to ADR-042 Rule 2a in the same commit.

### Rules

#### Rule 1 — Work to reduce risk above appetite; never release above

When residual push or release risk is above appetite (≥ 5/25 per `RISK-POLICY.md`), the orchestrator MUST take action to reduce risk until residual risk is within appetite (≤ 4/25). The orchestrator MUST NOT release above appetite under any circumstance. The orchestrator MUST NOT escalate to `AskUserQuestion` as a shortcut — the agent is the decision surface, not the user.

The orchestrator MAY use scorer remediations as input, but is NOT bound to follow them. It MAY:
- Apply a scorer-suggested remediation (Rule 2a).
- Take an alternative action it deems suitable (e.g. splitting a changeset, adding inline documentation, reordering commits, reverting a different commit than the scorer suggested).
- Combine scorer input with its own judgment.

Rule 1 is policy-authorised per ADR-013 Rule 5: `RISK-POLICY.md` appetite + this ADR's eligibility rules constitute the policy. No interactive authorisation is required for any action inside Rules 2–7.

#### Rule 2 — Use scorer input; agent decides; re-score after each

Parse the scorer's `RISK_REMEDIATIONS:` block as **input**, not as **instruction**. The agent reads the suggestions and decides what to do next.

The agent MAY follow a scorer suggestion, adapt it, or do something else entirely. There is no requirement to rank all suggestions upfront or iterate through them in order. The agent decides incrementally, like any other decision in the workflow.

After each action (whether scorer-suggested or agent-initiated), re-score via `wr-risk-scorer:pipeline` (subagent, preferred) or `/wr-risk-scorer:assess-release` (skill, fallback — ADR-015 delegation precedent). Classify the re-score:

- **Within appetite (≤ 4/25)** → proceed to drain via `push:watch` + `release:watch` per ADR-018/ADR-020's within-appetite mechanism. Done.
- **Above appetite (≥ 5/25)** → continue working to reduce risk. Loop.

The loop terminates when one of:

- Re-score reaches within appetite (drain path);
- The agent has exhausted its own ideas and the scorer's suggestions no longer help, and re-score is still above appetite (Rule 5 halt);
- An action fails a gate (Rule 3) or a git operation (conflict, merge failure). Rule 5 halt.

#### Rule 2a — The agent decides

The scorer's `RISK_REMEDIATIONS:` block is free-form prose. The agent reads each recommendation, understands what the scorer is suggesting, and decides what to do.

**There is no structured `action_class` column.** The scorer writes a description; the agent reads it and decides. No pre-built executors, no parsers, no lookup tables.

**The agent decides what to do.** The agent:

1. Reads the description.
2. Decides whether to follow the scorer's suggestion, adapt it, or do something else entirely.
3. Applies the chosen action using standard primitives (git, Edit, Bash, AskUserQuestion).
4. Re-scores after applying.

**Novel suggestions are normal.** The scorer can propose anything. The agent treats it the same way it treats any other recommendation: read, decide, apply or skip.

**Gate on every action (safety valve):** every auto-apply goes through Rule 3 (architect + JTBD + risk-scorer gate). The scorer's suggestion does NOT bypass governance. If the gate rejects the action, the orchestrator falls through to Rule 5 halt with the rejection reason logged.

**Why this is safe:**
- **Agent judgment, not mechanical execution**: the agent decides what to do, so no pre-built executor can be wrong.
- **Gate traversal**: every action goes through the full gate stack (Rule 3).
- **Audit trail**: Rule 6 logs every auto-apply, including the scorer's suggested class, the description, and what the agent actually did.
- **Reversibility**: the agent assesses reversibility from the description and logs it. The user can see whether an action was marked trivial/moderate/low before it was applied.

#### Rule 2b — Verification Pending carve-out

Commits attached to a `.verifying.md` ticket (per ADR-022 Verification Pending lifecycle) are **never** eligible for auto-revert. The scorer MAY propose `revert-commit` against a VP commit; the orchestrator MUST NOT execute it, and routes the remediation to Rule 5 halt with the halt report naming the VP ticket(s) so the user can verify-and-close on return. This prevents auto-undoing fixes that the user is in the middle of verifying.

#### Rule 3 — Governance gates apply to every auto-apply commit

Every auto-apply that requires a commit goes through the standard ADR-014 commit flow: architect review, JTBD review, risk-scorer gate. The scorer's suggestions do NOT bypass the gates — the scorer proposes; the gates authorise. A gate rejection on any auto-apply falls through to Rule 5 halt.

**Amend-based folding (per ADR-032 compatibility):** In AFK mode, a single iteration's auto-apply commits fold into the iteration's main commit via `git commit --amend` rather than producing N sibling commits, preserving ADR-032's one-commit-per-iteration invariant. The final score is run against the amended commit. In non-AFK mode, each auto-apply is a standalone commit since there is no iteration-level wrapper; ADR-014 still applies per-commit.

#### Rule 4 — No per-iteration cap (repealed from prior draft)

The narrow draft's "one auto-apply per iteration" cap is repealed. Apply as many remediations as needed to converge within appetite. Auditability concerns are handled at report-format level (Rule 6), not by artificial caps.

#### Rule 5 — Halt on exhaustion (never release above appetite)

The orchestrator MUST halt (not release) when any of the following hold:

- The scorer produces no remediations and residual risk is above appetite;
- The agent has exhausted its own ideas and the scorer's suggestions no longer help, and residual risk is still above appetite;
- A remediation attempt fails a gate (Rule 3) or a git operation (conflict, merge failure).

**AFK mode (work-problems lineage / ADR-018 Step 6.5):** halt the loop. Emit the iteration summary with `outcome: halted-above-appetite`, the final re-score, the remediations attempted (with outcome for each), and the ticket IDs of any Verification Pending commits implicated per Rule 2b. Do NOT proceed to the next iteration. The tree's dirty state (the iteration's own commit, possibly with auto-apply amendments) is preserved for user inspection on return. This is the JTBD-006 "stops gracefully when it hits a blocker" path.

**Non-AFK mode (manage-problem / manage-incident lineage / ADR-020 terminal):** halt the skill. Emit the skill's terminal report naming the final re-score, the remediations attempted, and any VP ticket implications. The user must resolve interactively — typical resolutions include splitting the commit, feature-flagging the change, or opening a problem ticket documenting the scorer gap.

Halt is a **bug signal**, not a routine outcome. The scorer SHOULD always have progressively more aggressive remediations available (move → revert → feature-flag → rollback). Halt exposes a gap in the scorer's vocabulary or suggestions — the correct follow-up is to improve the scorer, not to relax Rule 1. A halt SHOULD produce a new problem ticket (via run-retro or user-initiated) capturing the scorer gap.

#### Rule 6 — Audit trail

Every auto-apply decision MUST be logged in two places:

1. **Iteration / skill report** — append one line per auto-apply with:
   - Pre-apply `commit/push/release` scores
   - Post-apply re-score
   - Action taken (the git operation or Edit summary)
   - One-line citation of what the scorer suggested

   When multiple auto-applies fire in one iteration, emit one line per apply under a single "Auto-apply trail" subheading so the iteration summary stays skimmable.

2. **Holding-area README** (`docs/changesets-holding/README.md`) — for `move-to-holding` actions only. Append to the "Currently held" section with the parent ticket reference and the reinstate trigger. When a held changeset is later reinstated (`git mv docs/changesets-holding/<name>.md .changeset/<name>.md`), move the entry from "Currently held" to "Recently reinstated" with the reinstate date and reason.

#### Rule 7 — Holding-area convention (blessed)

`docs/changesets-holding/` is now an **orchestrator-blessed convention**, not provisional. The holding-area README's "provisional" banner is removed and the README cites this ADR as the authoritative mechanism. The mechanics (`git mv` to/from the area, file naming preserved, README "Currently held" + "Recently reinstated" sections) are unchanged from the provisional version.

### Scope

**In scope (this ADR's landing commit):**

- `docs/decisions/041-auto-apply-scorer-remediations-above-appetite.superseded.md` — status update + supersession notice + forward pointer.
- `docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md` — this document.
- `packages/itil/skills/work-problems/SKILL.md` — Step 6.5 above-appetite branch per Rules 1–6; Non-Interactive Decision Making table updated for "Commit when risk above appetite" → cites ADR-042.
- `packages/itil/skills/manage-problem/SKILL.md` — Step 11 terminal commit sequence above-appetite branch per Rules 1–6 and Rule 5 non-AFK halt.
- `packages/itil/skills/manage-incident/SKILL.md` — terminal commit step, same shape as manage-problem.
- `docs/changesets-holding/README.md` — provisional banner removal + ADR-042 citation (Rule 7).
- `docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md` — amendment adding above-appetite cross-reference to ADR-042.
- `docs/decisions/020-governance-auto-release-for-non-afk-flows.proposed.md` — §6 above-appetite branch replaced with cross-reference to ADR-042.
- `packages/itil/skills/work-problems/test/work-problems-above-appetite-remediation.bats` — contract-assertion bats file per ADR-037 (structural, to be retrofitted under P081).
- `docs/problems/108-scorer-remediation-action-class-vocabulary.open.md` — update to reflect open vocabulary direction; P108 scoped to scorer-contract extension only.

**Out of scope (this ADR's landing):**

- P108 scorer-contract vocabulary — tracked separately.
- Reinstate automation for held changesets — remains a user-initiated `git mv` once the blocking slices land. Future work may automate this when blocking-ticket close detection is reliable.
- Adjustments to `RISK-POLICY.md` appetite threshold — the invariant "never release above appetite" operates at the current 4/25 threshold; any threshold change is a separate `update-policy` invocation.
- Changing the release-cadence trigger (ADR-018 at-appetite threshold) — out of scope; the release-often principle is preserved via ADR-018 as-is.
- JTBD job for extensible remediation vocabulary — tracked as a follow-up task; see Consequences §JTBD Gap.

## Consequences

### Good

- **Never-release-above-appetite invariant holds.** There is no code path in AFK or non-AFK flows that releases above appetite. Release discipline is a compile-time property of the orchestrator, not a runtime appeal.
- **AFK loops stop escalating decisions the scorer resolved.** P103 closed: above-appetite states no longer halt the loop on `AskUserQuestion`; they route to the auto-apply loop.
- **P104 painted-into-a-corner hazard reduced.** The holding-area is now blessed and auto-apply routes changesets there as a first-line remediation.
- **Symmetry preserved.** AFK and non-AFK flows share the same above-appetite behaviour. No divergence to drift over time.
- **Audit trail per Rule 6** makes auto-apply decisions reviewable on user return: one line per apply in the iteration report + one line per move in the holding-area README.
- **Exhaustion is auditable, not silent.** Rule 5 halt emits a structured report naming what was tried and why it was insufficient — the scorer gap is visible, not hidden behind a successful release.
- **VP carve-out (Rule 2b)** prevents the auto-revert soft-lock that would otherwise destroy fixes the user is verifying.
- **Open vocabulary enables scorer innovation.** New remediation classes can be proposed and applied without waiting for an ADR amendment cycle. The scorer can experiment with novel remediation strategies (e.g. `split-commit` for large changesets, `noop-audit` for audit-only mitigations) and the orchestrator will attempt them if expressible.
- **Incremental decision-making preserves JTJT-001 speed.** The agent decides what to do next without pre-planning all actions, so each step stays within the under-60-second per-edit target.

### Neutral

- **Rules 1–7 add branch complexity.** Step 6.5 in work-problems, Step 11 in manage-problem, and the terminal step in manage-incident each gain a multi-branch above-appetite section. Contract-assertion bats (ADR-037 pattern) verify the load-bearing strings land in each branch.
- **Agent judgment replaces mechanical execution.** The agent decides what to do, which means more variability in what happens for the same scorer output. This is the trade-off for flexibility: no two agents may make the same decision, but neither will make a decision that is mechanically wrong.
- **The holding area accumulates entries during multi-slice WIP.** The README serves as the audit log.
- **Scorer-orchestrator contract drift risk.** The open vocabulary means the scorer could propose classes the orchestrator cannot yet express well, leading to more frequent Rule 5 halts until the scorer learns the orchestrator's primitive set. This is a transient learning phase, not a structural flaw.

### Bad

- **Source-edit auto-apply actions are NOT mechanically reversible the way `move-to-holding` is.** When the agent applies a feature-flag or rollback, the audit trail per Rule 6 becomes load-bearing for user review-and-revert on return. Mitigation: each auto-apply commit is a distinct commit (or a named amendment in AFK mode) so `git revert` works at the commit level.
- **Scorer contract dependency.** The scorer must write clear descriptions so the agent can decide. If the scorer's descriptions are vague, the agent may halt unnecessarily. Mitigation: the scorer learns from halt reports (Rule 6 logs the description text) and adapts its descriptions. The agent's judgment is the fallback.
- **Halt-on-exhaustion can stop an AFK loop mid-queue.** If a scorer gap halts iteration N, iterations N+1..M never fire — even if they would have worked on unrelated tickets. This is the conservative choice: continuing past an unreleasable iteration risks compounding the above-appetite state. Mitigated in practice by the scorer being reliable enough that exhaustion is rare; when it happens, treat as a bug and fix the scorer.
- **Gate traversal cost per auto-apply.** Rule 3 requires architect + JTBD + risk-scorer review on every auto-apply commit. For a 3-remediation iteration that means 3× full gate traversal. Mitigated by AFK mode's `git commit --amend` folding (Rule 3 amend-based folding) — the iteration still produces one final commit that carries one final gate traversal against the amended state.
- **JTBD Gap — no documented job for "extensible remediation vocabulary".** The user's motivation ("prevents innovative remediations") does not map to an existing JTBD job. JTBD-006 desires safe defaults; JTBD-001 desires speed with governance; JTBD-002 desires auditability. None explicitly call for open-ended vocabulary. If extensibility/innovation is a genuine requirement, a new JTBD job (or JTBD-006 extension) should be drafted. This is tracked as a follow-up.

## Confirmation

Compliance is verified by:

1. **Source review**: each in-scope SKILL.md has the above-appetite branch with Rules 1–7 referenced (never-release-above-appetite invariant, open vocabulary, VP carve-out, gate-per-commit, halt-on-exhaustion, audit trail) and cites this ADR. The ADR-018 and ADR-020 amendments cite ADR-042.
2. **Bats contract assertions** (per ADR-037): `packages/itil/skills/work-problems/test/work-problems-above-appetite-remediation.bats` asserts the load-bearing strings — `RISK_REMEDIATIONS`, `docs/changesets-holding/`, `above appetite`, ADR-013 Rule 5 citation, `never release above appetite` invariant phrase, `ADR-042` citation, the Non-Interactive Decision Making table row for the above-appetite branch, and the Rule 5 halt-on-exhaustion semantics.
3. **Behavioural** (manual until P012's harness lands): an AFK loop that hits an above-appetite release-cadence event with an eligible `move-to-holding` remediation auto-applies the move, re-scores within appetite, drains, and proceeds to the next iteration — without invoking `AskUserQuestion`. Verifiable from the iteration report's Auto-apply trail subsection + the holding-area README's "Currently held" entry.
4. **Halt-on-exhaustion behavioural**: an AFK loop hitting a scorer suggestion the agent cannot act on halts with `outcome: halted-above-appetite` naming the class and description. Verifiable from the halt report shape.
5. **Open-vocabulary behavioural**: a scorer proposing a novel class (e.g. `noop-audit`) is read by the agent, which decides what to do and applies its chosen action (subject to Rule 3 gates). Verifiable from the iteration report's action log.

## Reassessment Triggers

Revisit this decision if:

- P108 lands the scorer contract vocabulary — the scorer's descriptions become more actionable over time; bats assertions update.
- The `RISK-POLICY.md` appetite threshold changes — Rule 1's "above appetite" numeric definition shifts.
- A fourth in-scope lineage emerges (e.g., `create-adr` under ADR-014 auto-release) — the ADR may need to extend to that skill's terminal step.
- The scorer's `RISK_REMEDIATIONS:` contract changes shape — Rule 2 parsing and Rule 2a vocabulary both depend on it.
- Halt-on-exhaustion fires frequently in practice (say, more than once per week of active AFK use) — treat as a scorer-gap signal; the correct response is scorer improvement, but a threshold of repeated halt could justify re-evaluating whether the open vocabulary is too permissive and should narrow.
- ADR-014 / ADR-018 / ADR-020 are superseded — lineage assumption breaks.
- A new JTBD job for extensible remediation vocabulary is drafted — the Consequences §Bad JTBD Gap closes and the decision drivers should be updated.

## Related

- **ADR-041** (`docs/decisions/041-auto-apply-scorer-remediations-above-appetite.superseded.md`) — superseded predecessor. Closed-enumeration approach rejected by decision-maker.
- **P103** (`docs/problems/103-work-problems-escalates-resolved-release-decisions-defeats-afk.open.md`) — driver for the auto-apply rule. AFK loop halt at iter 4 2026-04-22.
- **P104** (`docs/problems/104-work-problems-partial-progress-paints-release-queue-into-corner.open.md`) — driver for the holding-area convention's promotion from provisional.
- **P108** (`docs/problems/108-scorer-remediation-action-class-vocabulary.open.md`) — tracks the scorer-contract extension. Now scoped to "improve scorer descriptions" rather than "add structured columns".
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
- **`docs/changesets-holding/README.md`** — holding-area mechanics; provisional banner removed and ADR-042 cited as the authoritative basis per Rule 7.
- Memory: `feedback_act_on_obvious_decisions.md` — captures the user's lesson; this ADR is the structural / repo-wide encoding.
