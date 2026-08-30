# Problem 514: The JTBD gate reviews edits but not recommendations, so option-sets reach the user unvalidated

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture. Impact 3: the failure lands on the user directly rather than on an artefact — a recommendation that contradicts a documented desired outcome costs a decision cycle and shifts the JTBD check onto the person the corpus exists to serve. Likelihood 4: no control on the path at all; the gate fires on writes, and a recommendation is not a write.
**Origin**: inbound-reported (adopter-repo P042)
**Effort**: M
**WSJF**: 12 — (12 × 2.0) / 2 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The JTBD gate is a `PreToolUse` hook on Edit and Write. It reviews **changes to files**. It does not fire when the assistant proposes an option-set, recommends a capability, or argues for a direction in prose — and those reach the user first, before any file is touched.

So the framework validates the implementation against documented jobs and leaves the decision that chose the implementation unvalidated.

**Reported by an adopter** from a user-confirmed correction: while choosing between integration stopgaps, the assistant put forward a manual-import option that a documented desired outcome for that persona already ruled out.

Their ticket names the class rather than the instance — proposing options or recommendations for user-facing capability before validating them against the documented desired outcomes — and states the consequence as the user becoming the JTBD check instead of the assistant.

That is the corpus being used backwards. A documented desired outcome exists so the assistant can discard an option without spending the user's attention on it; when validation happens only after the user objects, the corpus has cost more than it saved.

## Symptoms

- An option-set is presented in which one or more options contradict a documented desired outcome for the persona in question.
- The user is the first check — they recognise the mismatch and correct it.
- No gate fired, because nothing was written.
- The correction cycle is spent on a candidate the corpus already ruled out.

## Workaround

The user reads every recommendation against the jobs themselves. That is the failure, described as a workaround.

## Impact Assessment

- **Who is affected**: the user, on every option-set for user-facing capability. Adopters identically — their jobs corpus is equally uninvolved in their assistant's recommendations.
- **Frequency**: every recommendation for user-facing capability. Unmeasured because nothing observes the path.
- **Severity**: a wasted decision cycle, eroded trust, and the risk of building the wrong thing if the mismatch is not caught. The adopter names all three.
- **Analytics**: none.

## Root Cause Analysis

The gate is bound to a tool-call surface — `PreToolUse` on Edit and Write — and a recommendation is not a tool call. Everything downstream inherits that boundary: the reviewer agent is only ever invoked with a proposed *change*, so its contract has no shape for "here is an option I am about to put to the user".

Two things follow, and only the first is obvious:

1. **No trigger exists** for the recommendation path.
2. **The reviewer has no verdict vocabulary for it.** `wr-jtbd:agent` returns alignment findings against a diff. Judging whether an option-set serves a job needs a different question — "does any option here contradict a desired outcome, and is the set complete against them?" — which is not a narrower version of the existing review.

This is the same boundary class P503 records for the edit gates: a gate bound to a tool matcher does not cover the paths that reach the same outcome without that tool. There the bypass was Bash-routed writes; here it is prose.

### Investigation Tasks

- [ ] Decide the trigger: a `UserPromptSubmit` injection when the turn is heading for a recommendation, a self-check the assistant runs before emitting an option-set, or a check inside `AskUserQuestion` authoring
- [ ] Decide whether this is enforcement or discipline — a hook cannot see a recommendation forming, so the honest options may be prose-plus-a-retro-metric rather than a gate
- [ ] Give the reviewer a verdict shape for option-sets: contradicts / does not serve / incomplete against the outcomes, rather than diff alignment
- [ ] Check the sibling gates for the same hole — the architect gate reviews decision *files*, not decisions argued in prose, which is the same shape
- [ ] Behavioural test: an option-set contradicting a documented desired outcome is caught before it reaches the user

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P503

## Related

- **Adopter ticket P042** — the adopter ticket this traces to; carries the user-confirmed correction and names the class.
- **P503** — edit gates bound to the Edit/Write matcher miss Bash-routed writes. Same boundary class: a gate tied to a tool surface misses every path to the same outcome that avoids that tool.
- `packages/jtbd/hooks/` — the `PreToolUse` binding.
- `packages/jtbd/agents/agent.md` — the reviewer whose contract is diff-shaped.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-079 | STORY-079: Review only options consistent with documented desired outcomes | draft |
