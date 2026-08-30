# Problem 426: wr-architect review agent lacks a "first-match on a non-unique collection" review heuristic (identity/auth/data-binding footgun)

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3
**Origin**: inbound-reported (#169)
**Effort**: S. WSJF = (12 × 2.0) / 1 = 24.0.
**WSJF**: 24 — (12 × 2.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

The `wr-architect:agent` reviewer has no standing heuristic to flag first-match selection (`.limit(1)`, array `[0]`, `.find()`, `.pop()`) on a non-unique collection that backs an identity / authorization / data-binding decision. Two production defects already slipped review this way (one bound a workspace to the wrong org).

## Symptoms

- Code selects the first element of a collection that is not guaranteed unique, and uses it for an identity/authz/data-binding decision; review passes it. Under real data with >1 match, the wrong entity is chosen.

## Workaround

Manual reviewer vigilance plus downstream regression tests (per the inbound report) — not a systemic control.

## Impact Assessment

- **Who is affected**: adopters relying on the architect reviewer to catch structural footguns; the reviewer misses a whole defect class.
- **Frequency**: whenever such code is reviewed (has already slipped ≥2 times).
- **Severity**: High — silent wrong-entity binding (auth/identity) is a serious class.

## Root Cause Analysis

### Root cause (confirmed 2026-07-15)

The review agent's checklist (`packages/architect/agents/agent.md` § What You Check) never encoded this defect class. The reviewer only flags what its prose names; with first-match-on-a-non-unique-collection unnamed, both reported instances (a `.limit(1)` identity lookup with no ordering key, and a `connections[0]` binding against a collection aggregating all past authorisation events) passed review and reached production. Verified in-session: no first-match/uniqueness heuristic anywhere in the agent prose, and no eval fixture in `packages/architect/agents/eval/promptfooconfig.yaml` exercises the class. Agent prose is the only viable surface — judging lookup-key uniqueness is semantic, not grep-able.

**Reproduction test**: the positive-fire promptfoo eval fixture specified in `## Fix Strategy` below — it fails against the current agent prose by construction (the class is unnamed) and passes once the heuristic lands.

### Investigation Tasks

- [x] Confirm the gap: no first-match/uniqueness heuristic in `packages/architect/agents/agent.md` § What You Check, and no eval fixture covering the class (2026-07-15, in-session read).
- [ ] Add the heuristic to the wr-architect agent checklist (cover `.limit(1)`, `[0]`, `.find()`, `.pop()` on non-unique collections backing identity/authz/data-binding); require a disambiguating key or an explicit multi-element error/selection step.
- [ ] Back it with a behavioural eval per P081 (behavioural over structural).

## Fix Strategy

Add a standing **First-Match on a Non-Unique Collection** heuristic to `packages/architect/agents/agent.md` § What You Check, with new issue type `[First-Match Footgun]` in the issue-types list:

- **Trigger shapes**: `.limit(1)`, array `[0]`, `.find()`, `.first()`, `.pop()`, `.shift()`, `LIMIT 1`, `fetchone()`, or equivalent first-match reads.
- **Fire when** the selected element feeds an identity, authorization, or data-binding decision (entity binding such as workspace→org, auth subject resolution, permission grants, tenant scoping, record ownership) AND the collection is not guaranteed unique for the lookup key.
- **Required remediations** (any one): a disambiguating unique key; explicit handling of the >1-match case (error out or surface a selection step); a cited uniqueness invariant (unique constraint/index) in the change.
- **Over-fire guard** (inverse-P078/P132, mirroring the [Unratified Dependency] guard): do NOT flag unique-by-construction lookups (primary key / unique index), code that explicitly asserts single-match, or order-insensitive display logic with no identity/authz/data-binding consequence.

Behavioural coverage per ADR-052/ADR-075 (harness exists, RFC-012/P324): two paired promptfoo eval tests in `packages/architect/agents/eval/promptfooconfig.yaml` — (a) **positive-fire**: a proposed change binding a workspace to an org via `.find()` on a memberships collection filtered by a non-unique field → Tier A `icontains: ISSUES FOUND` + Tier B llm-rubric asserting a first-match/non-unique finding is raised; (b) **over-fire guard**: a lookup by primary key with a unique index → Tier A `icontains: PASS` + Tier B llm-rubric asserting no [First-Match Footgun] flag fires. Ship with a patch-bump changeset for the architect package in the same commit.

RFC-084, the release row "A reviewer flags first-match selection against a non-unique identity, authorization, or data-binding key" on confirmed STORY-MAP-011, carries STORY-078. The row replaces the unconfirmed legacy RFC-048 document as the current fix vehicle.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P456 (AFK iter cannot progress a Known Error whose fix vehicle needs interactive story ratification — this ticket is a witnessing instance).

## Related

- Inbound issue #169.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-048 | proposed | Add a first-match-on-non-unique-collection review heuristic to the architect review agent |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-078 | STORY-078: A reviewer catches first-match binding when the key is not unique | accepted |
