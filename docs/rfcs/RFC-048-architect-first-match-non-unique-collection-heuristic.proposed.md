---
status: proposed
rfc-id: architect-first-match-non-unique-collection-heuristic
reported: 2026-07-15
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P426]
adrs: [ADR-052, ADR-075]
jtbd: [JTBD-002]
stories: []
---

# RFC-048: Add a first-match-on-non-unique-collection review heuristic to the architect review agent

**Status**: proposed
**Reported**: 2026-07-15
**Problems**: P426
**ADRs**: ADR-052 (behavioural-tests-default), ADR-075 (promptfoo agent-prose verdict eval harness)
**JTBD**: JTBD-002 (Ship AI-Assisted Code with Confidence)

## Summary

Add a standing first-match-on-non-unique-collection review heuristic (issue type `[First-Match Footgun]`) to the architect review agent prose, with paired behavioural promptfoo evals per ADR-052/ADR-075. Fix design architect-PASSed 2026-07-15 and recorded verbatim in the driving ticket's Fix Strategy.

## Driving problem trace

- P426 (wr-architect review agent lacks a "first-match on a non-unique collection" review heuristic): two identity/data-binding defects in a downstream project passed architect review — a `.limit(1)` identity lookup with no ordering key, and a `connections[0]` binding against a collection aggregating all past authorisation events (bound a workspace to the wrong org in production) — because the reviewer prose never names the class. Root cause confirmed 2026-07-15: no first-match/uniqueness heuristic in `packages/architect/agents/agent.md` § What You Check, and no eval fixture exercises the class.

## Scope

Encode the defect class as a standing review heuristic in `packages/architect/agents/agent.md` § What You Check, with `[First-Match Footgun]` added to the issue-types list. The heuristic fires when a proposed change selects a single element via a first-match read — `.limit(1)`, array `[0]`, `.find()`, `.first()`, `.pop()`, `.shift()`, `LIMIT 1`, `fetchone()`, or equivalents — from a collection not guaranteed unique for the lookup key, AND the selected element feeds an identity, authorization, or data-binding decision (entity binding such as workspace→org, auth subject resolution, permission grants, tenant scoping, record ownership). The flag names the required remediations (any one suffices): a disambiguating unique key; explicit handling of the >1-match case (error out or surface a selection step); or a cited uniqueness invariant (unique constraint/index). An explicit over-fire guard mirrors the existing [Unratified Dependency] guard (inverse-P078/P132): the heuristic MUST NOT fire on unique-by-construction lookups (primary key / unique index), code that explicitly asserts single-match, or order-insensitive display logic with no identity/authz/data-binding consequence.

Behavioural coverage rides the existing architect agent eval harness (`packages/architect/agents/eval/promptfooconfig.yaml`, RFC-012/P324): two paired Tier-A/Tier-B tests — (a) positive-fire: a proposed change binding a workspace to an org via `.find()` on a memberships collection filtered by a non-unique field → Tier A `icontains: ISSUES FOUND` + Tier B llm-rubric asserting a first-match/non-unique finding is raised (this fixture is also the P426 reproduction test — it fails against the current agent prose by construction); (b) over-fire guard: a lookup by primary key with a unique index → Tier A `icontains: PASS` + Tier B llm-rubric asserting no [First-Match Footgun] flag fires. A patch-bump changeset for the architect package ships in the same commit as the agent-prose + eval change.

Agent prose is the only viable surface for this control — judging lookup-key uniqueness is semantic, not grep-able — so no hook or script component is in scope.

## Stories

The fix's story leg is captured on a story map per ADR-089/ADR-095 (STORY-046 on STORY-MAP-011, draft, born `human-oversight: unconfirmed`). Per ADR-090 an RFC lists only ratified stories in its `stories:` frontmatter, so the wiring is deferred: the draft story carries the story-side `--rfc` trace to this RFC; the RFC-side `stories:` listing lands when the story is ratified and accepted at the next interactive drain (the P456 held-at-gate composition — no AFK carve-out invented, per P311).

## Commits

(rendered from `git log --grep "Refs: RFC-048"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no commits yet.)

## Related

- Inbound issue #169 (the adopter report driving P426).
- P456 (AFK iter cannot progress a Known Error whose fix vehicle needs interactive story ratification) — this RFC's implementation hold is a witnessing instance.
- Architect pre-edit review 2026-07-15: heuristic substance + eval design PASS; capture-and-hold sequencing PASS.
