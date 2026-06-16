---
status: proposed
rfc-id: p358-work-problems-preflight-subprocess-failure-handling
reported: 2026-06-16
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P358]
adrs: [ADR-032]
jtbd: [JTBD-006]
stories: []
---

# RFC-024: work-problems pre-flight subprocess failure handling — non-blocking revert-and-proceed

**Status**: proposed
**Reported**: 2026-06-16
**Problems**: P358
**ADRs**: ADR-032
**JTBD**: JTBD-006

## Summary

`/wr-itil:work-problems` Step 0b / Step 0c / Step 0d each dispatch a `/wr-itil:review-problems` (or `/wr-itil:check-upstream-responses`) **pre-flight subprocess** "same shape as Step 5". The prose imports the Step 5 dispatch *mechanism* (the `claude -p` wrapper + idle-timeout SIGTERM poll loop) but never states the pre-flight's failure *semantics*. Step 5's exit-code semantics HALT the loop on non-zero exit / `is_error: true` — correct for an iter (the iter IS the loop body unit), but wrong for a pre-flight (a non-load-bearing cache-refresh dependency). This RFC scopes the contract that a failed pre-flight subprocess is **non-blocking**: revert any unstaged partial cache write, log a one-line annotation, proceed to Step 1 with the existing (possibly slightly-stale) README.

## Driving problem trace

- **P358** — `claude -p` subprocess dispatch fails with API "socket connection closed unexpectedly" (`is_error: true`). The socket-closed shape is just another `is_error: true` instance already taxonomised by the Step 5 SALVAGE (P261) / HALT (P214) branches; the orthogonal, undocumented gap P358 surfaces is the Step 0b/0c/0d **pre-flight** subprocess `is_error: true` / non-zero-exit handling. The orchestrator improvised the correct behaviour (reverted the dirty `.upstream-cache.json` write, proceeded to Step 1); this RFC makes that contract explicit.

## Scope

The fix amends `packages/itil/skills/work-problems/SKILL.md` (a shared "Pre-flight subprocess failure handling" subsection after Step 0d + thin forward-pointers in each 0b/0c/0d dispatch-shape paragraph) and `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` (an additive amendment in the AFK-iteration-isolation-wrapper series documenting the iter-vs-pre-flight failure-semantics distinction). Behavioural bats fixture + changeset accompany. Full populate at `/wr-itil:manage-rfc accepted` transition.

## Tasks

- [x] Amend SKILL.md Step 0b/0c/0d with the non-blocking revert-and-proceed pre-flight failure contract (shared subsection + forward-pointers).
- [x] Amend ADR-032 with the pre-flight-vs-iter failure-semantics distinction (P358 amendment).
- [x] Add behavioural bats fixture `work-problems-preflight-failure-handling.bats`.
- [x] Author `@windyroad/itil` patch changeset.
- [ ] Populate Scope / advance to accepted at next `/wr-itil:manage-rfc` invocation.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)

- **ADR-032** — governance skill invocation patterns; AFK-iteration-isolation-wrapper amendment series this fix extends.
- **P261 / P214** — the `is_error: true` SALVAGE / HALT taxonomy scoped to iters; this RFC's pre-flight contract is the orthogonal axis.
- **P358** — driver problem ticket.
