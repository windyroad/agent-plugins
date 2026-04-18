# Problem 048: manage-problem does not surface Fix Released problems as verification candidates when the fix path has been exercised

**Status**: Open
**Reported**: 2026-04-19
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: 4.0 — (8 × 1.0) / 2

## Description

`wr-itil:manage-problem` has the "Fix Released" → "Closed" transition gated on an explicit user verification prompt in step 9d (review) via `AskUserQuestion`. The rule is intentional: never auto-close without explicit user confirmation. The problem is not the rule — the problem is that the skill **has no detection layer** that surfaces Fix Released tickets whose fix path has been demonstrably exercised during the current (or prior) sessions.

Canonical example: P031 (`manage-problem work stale cache detection`) has a Fix Released section (commit 824cb2c). The stale cache detection logic has been exercised repeatedly and correctly in this session alone — every iteration of the 2026-04-19 AFK loop invoked the git-based freshness check, and it returned correct results. The fix is functionally verified by observable behaviour. Yet P031 remains in `.known-error.md` limbo because step 9d's verification prompt was never triggered in a way that could capture this evidence.

Same pattern this session for:
- **P035** (`manage-problem commit gate no subagent delegation fallback`) — the Skill-based fallback was used successfully to satisfy the commit gate when a pipeline subagent wasn't available.
- **P040** (`work-problems does not fetch origin before starting`) — preflight `git fetch origin` fired correctly at loop start.
- **P041** (`work-problems does not enforce release cadence`) — the post-iteration `assess-release` delegation fired after each of the 3 iterations.
- **P043** (`next-ID collision guard in ticket-creators`) — `max(local, origin) + 1` was used correctly when assigning P046, P047, and this ticket (P048).
- **P026** (`install-utils duplicated across packages`) — the sync script and its CI guard continued to pass without drift.

All six problems have Fix Released sections. All six have demonstrably-working fixes this session. None of them progressed toward Closed.

The effect is a growing Fix Released backlog. The session's `## Known Errors (Fix Released)` list in `docs/problems/README.md` currently has 12 entries; most of them have been exercised in prior sessions without any regression commits. The skill has no detection surface that says "hey, these six fixes clearly work — want to close them?" — so they accumulate, and the user has to remember each ticket individually when they want to verify.

This is a **missing detection layer**, not a broken verification rule. The closure rule is fine; the discovery mechanism in front of it is the gap.

## Symptoms

- Fix Released tickets accumulate across sessions even when the fix behaviour is obviously working (6+ observed this session alone).
- `manage-problem work` fast-path skips step 9d entirely — when the cache is fresh, the skill never considers the verification queue, so verified-in-practice fixes never surface.
- Full `manage-problem review` fires step 9d, but its prompt treats all Fix Released tickets equivalently — no signal about which ones have strong evidence of working vs which have landed-but-never-exercised.
- Users have to remember each Fix Released ticket individually to close it — cognitive load scales with backlog size.
- The `docs/problems/README.md` Fix Released table grows without bound; its age is not visible from the table.
- During AFK loops, `AskUserQuestion` is unavailable, so step 9d's existing prompt is deferred — but the deferral leaves no artefact of "this fix was exercised N times in the loop", losing the evidence.

## Workaround

- User manually reads `docs/problems/README.md` Fix Released list and runs `manage-problem review` interactively to hit step 9d's prompts.
- User relies on memory to know which fixes have been exercised recently.
- Periodic "verification sweep" sessions where the user skims the whole Fix Released list and answers the prompts batch-style.

None of these scale; all depend on user recall of which fix paths have been observable in recent sessions.

## Impact Assessment

- **Who is affected**: solo-developer persona (JTBD-001, JTBD-006) — a growing Fix Released backlog clutters ranking output and obscures truly-in-progress work; plugin-developer persona (JTBD-101) — inconsistent closure hygiene hurts the signal-quality of the problem-tracking suite.
- **Frequency**: every session where any existing Known Error's fix path is touched (essentially every session once a handful of Known Errors exist).
- **Severity**: Minor — problems sit in limbo rather than Closed; no functional breakage, no user-visible defect. The cost is cognitive and administrative, not operational.
- **Analytics**: session 2026-04-19 observation: 6 Fix Released tickets exercised and visibly working; 0 closed. Backlog's Fix Released table has 12 entries spanning 3+ weeks.

## Root Cause Analysis

### Structural: verification discovery is pull-only, not push

`packages/itil/skills/manage-problem/SKILL.md` step 9d triggers an `AskUserQuestion` for each Fix Released ticket, but only when the full review runs. The fast-path cache skip (step 9 preamble) bypasses step 9b AND step 9d. In `work-problems` AFK loops, `AskUserQuestion` is further unavailable so the prompt is the equivalent of "defer" anyway.

No part of the skill observes actual usage patterns:
- Does a commit in the current session touch code paths the Fix Released section names?
- Has the fix path been exercised (script run, test passed, delegation triggered)?
- Has time passed without any regression indicator (a reverted commit, a new problem filed against the same surface)?

Without these observations, step 9d has no evidence to present to the user. The prompt reduces to "this was released in version X — verified?" which is what P030 already flagged as insufficient (that fix added a fix summary to the prompt). P048 extends P030: the summary alone is still one-shot; accumulating evidence across sessions is absent.

### Structural: the Fix Released table is static text

`docs/problems/README.md` lists Fix Released tickets but shows no "last exercised" or "age since release" signal. The user reading the README cannot rank the list by "how confident are we this still works".

### Candidate fixes

1. **Always fire step 9d on `review`, even via the fast-path**: when cache is fresh, still check the Fix Released queue for candidates to surface. Low-cost SKILL.md edit. Addresses the pull-only bias partially (user still runs review).
2. **Add a "Fix Released sweep" sub-operation to `manage-problem`**: e.g. `/wr-itil:manage-problem verify-fixes` that walks the Fix Released queue, summarises each, and uses one AskUserQuestion per ticket (batched if possible). Makes verification a first-class action, not a review side-effect.
3. **Observe exercise signals and annotate the problem file**: when a fix path is exercised during a session (e.g. `work-problems` uses the stale cache detection, or `manage-problem` uses the Skill fallback), append a `- Exercised: <date> — <context>` bullet to the Fix Released section. Over time the section accumulates evidence; the verification prompt can quote it.
4. **Auto-surface "likely verified" in review output**: during step 9c's summary table, add a column or highlight for Fix Released tickets with N exercise observations AND Z days since release without regression. User still confirms closure; the detection surfaces the candidates prominently.
5. **AFK-mode hook**: when `work-problems` or another AFK orchestrator exercises a Fix Released fix path, record the observation in the ticket's Fix Released section as "exercised (AFK session <date>)" without prompting. Next interactive session's review surfaces the accumulated evidence.

Candidates 1 + 3 + 4 are complementary and form a reasonable "detection layer" without changing the closure rule. Candidate 2 is the user-visible entry point. Candidate 5 is the AFK-specific plumbing.

### Related to existing tickets

- **P030** (verification prompts lack fix summary, CLOSED 2026-04-16) — added a one-shot summary to step 9d's prompt. Helpful but not detection: the user still has to initiate the review to see the prompt. P048 adds the layer P030 did not touch.
- **P047** (WSJF effort buckets coarse and not re-rated at transitions) — sibling theme: `manage-problem` has static data (effort, verification state) that should update from observed usage. Both are "the skill's model of reality doesn't track reality".
- **P031** (`manage-problem work stale cache detection`) — canonical example of the detection gap. Worked in every iteration this session and still sits Fix Released.
- **P022** (agents must not fabricate time estimates) — closely related: both concern agent outputs / state that look authoritative but lack grounded observations.

### Investigation Tasks

- [ ] Architect review: is "record exercise observations" a new-ADR-level concern (it adds a state dimension to problem files) or a within-skill pattern?
- [ ] Design the Fix Released section addendum format — a bullet list of exercises with date + context; must remain human-readable and survive markdown round-trips.
- [ ] Decide which orchestrator hooks record exercises. Minimum: `work-problems` Step 6.5 (release cadence) hits P041's path; Step 0 hits P040's path; every iteration's commit gate hits P035's path. These can be annotated automatically.
- [ ] Draft SKILL.md edits for Candidate 1 (always fire step 9d) and Candidate 4 (surface evidence in step 9c summary). Require step 9c to flag Fix Released items with exercise count ≥ 1 or release age ≥ 14 days.
- [ ] Consider a standalone `verify-fixes` operation (Candidate 2) as a follow-up; not a blocker for this ticket's fix if Candidates 1/3/4 suffice.
- [ ] Add bats test: assert SKILL.md's step 9d fires on both fast-path and full-review branches; assert step 9c surfaces Fix Released entries when exercise evidence is present.
- [ ] Backfill exercise records for the six tickets observed this session (P026, P031, P035, P040, P041, P043) once the format is defined. Low priority — prefer to do this organically as future sessions exercise the paths.
- [ ] Cross-reference P047 (effort re-rating) for shared update-the-model-from-observation patterns.

## Related

- `packages/itil/skills/manage-problem/SKILL.md` — the fix target (step 9 preamble fast-path; step 9c summary; step 9d verification prompt).
- P031: `docs/problems/031-manage-problem-work-stale-cache-detection.known-error.md` — canonical example of the detection gap in action this session.
- P030: `docs/problems/030-manage-problem-verification-prompts-lack-fix-summary.closed.md` — predecessor fix for the prompt content side; P048 is the detection side.
- P047: `docs/problems/047-wsjf-effort-bucket-accuracy-gaps.open.md` — sibling "static skill model doesn't track reality" ticket.
- P022: `docs/problems/022-agents-should-not-fabricate-time-estimates.open.md` — related grounding principle.
- P026 / P035 / P040 / P041 / P043: also observed exercising their Fix Released fix paths this session without progressing toward Closed; candidates for the same detection surface.
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — any auto-annotation of problem files by the skill falls under ADR-014's commit discipline.
