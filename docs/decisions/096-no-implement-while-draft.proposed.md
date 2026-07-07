---
status: "proposed"
date: 2026-07-07
human-oversight: confirmed
oversight-date: 2026-07-07
oversight-confirmed-date: "2026-07-07 — post-draft brief-and-confirm via AskUserQuestion (P357): maintainer confirmed the drafted ADR-096 faithfully captures intent. Decision substance was picked pre-draft; this marker records the SEPARATE post-draft confirmation of the drafted content."
oversight-note: "A draft story is never implementable — draft->in-progress auto-transition removed; implementation requires accepted; commit-trailer gate (Refs: STORY-NNN) is the primary enforcement locus. Sibling of ADR-095. Architect re-review 2026-07-07: change-3 PASS on substance."
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-07
amends: [ADR-060]
---

# A story cannot be implemented while in draft — implementation requires accepted

## Context and Problem Statement

ADR-060 auto-transitions a story `draft -> in-progress` on the first implementing commit trailer, and its working-the-problem traversal (line 315) already only works stories whose status is `accepted` or `in-progress`. The auto-transition is the anomaly: it lets a `draft` story be implemented directly, skipping the `draft -> accepted` gate where INVEST (I10), the RFC trace (I7), and ADR-090 human ratification fire. On 2026-07-05 the maintainer observed exactly this — the AFK flow authoring draft stories and implementing them without the accepted-transition gates ever firing (the P404 root-cause loophole). Maintainer directive (AskUserQuestion 2026-07-07): *"you should NEVER be able to implement a story that's in draft."*

Sibling **ADR-095** hardens the capture-time gates (map membership + content). This ADR closes the implementation-side loophole.

## Decision Drivers

- Nothing should be built from a story that has not passed its `accepted` gate (INVEST, I7 RFC trace, ADR-090 ratification).
- The gate must catch the exact bypass: a direct implementing commit against a `draft` story — whether via the orchestrator or by hand.
- Align the lifecycle with ADR-060's own traversal, which already presumes accepted-before-worked.

## Considered Options

- **A. Remove the `draft -> in-progress` auto-transition + a commit-trailer gate (primary) + dispatch preflight refuse-and-route (secondary).** A story reaches `in-progress` only via `accepted`; a commit whose `Refs: STORY-NNN` trailer names a story that is not `accepted`/`in-progress` is blocked.
- **B. Dispatch-preflight only** (work-problems/work-problem refuse-and-route on a draft story). Rejected as the sole guarantee: it misses a hand-written implementing commit outside the orchestrator — the exact bypass class.
- **C. manage-story transition guard only.** Rejected: redundant once the auto-transition is removed (`in-progress` becomes reachable only via `accepted`), and it does not catch a raw commit.

## Decision Outcome

Chosen option: **A.** Amends ADR-060:

1. **Remove the `draft -> in-progress` auto-transition.** `in-progress` is reachable only from `accepted`. The story lifecycle is `draft -> accepted -> in-progress -> done`, no skips.
2. **Commit-trailer gate (primary enforcement locus).** A hook parses the `Refs: STORY-NNN` trailer, resolves the story's status (subdir / frontmatter `status:`), and **blocks the commit** if the story is not `accepted` or `in-progress`, with a route directive ("accept STORY-NNN via `/wr-itil:manage-story <NNN> accepted` first"). This is the only locus that catches a direct implementing commit against a draft story regardless of path; it reuses the trailer-recognition infrastructure ADR-060 already describes.
3. **Dispatch preflight (secondary, fast-fail UX).** `work-problems`/`work-problem` change their existing silent skip of draft stories into a hard refuse-and-route so the AFK loop surfaces the block before wasting an iter. Under AFK this queues to `outstanding_questions` rather than blocking.
4. **Trailer vocabulary fixed.** ADR-060 is internally inconsistent (`Implements: STORY-NNN` line 218 vs `Refs: STORY-NNN` line 318). Standardise on **`Refs: STORY-NNN`** (the form the existing reverse-trace hook parses) and correct line 218 in lockstep.

Once the auto-transition is removed and I7/I10/ratification fire at `accepted` before any implementation, ADR-095's decision to keep I7 (and full INVEST) at `accepted` is sufficient — no malformed or unratified story can ever be implemented.

### Consequences

- Good: the P404 loophole is closed at its root; every story is accepted (gates + ratification passed) before any code lands; the lifecycle matches the traversal.
- Bad / cost: an implementing commit against a not-yet-accepted story is blocked — the author must accept the story first (one deliberate step); a new commit-trailer gate hook to maintain.
- Neutral: existing draft survivors (STORY-037/038) must be accepted before any further work.

### Confirmation

(a) ADR-060 lifecycle table: `draft -> in-progress` auto-transition removed; `in-progress` reachable only via `accepted`. (b) A commit-trailer gate hook blocks a commit whose `Refs: STORY-NNN` names a non-accepted story. (c) `work-problems`/`work-problem` dispatch preflight refuse-and-routes on a draft story. (d) Behavioural bats: a commit referencing a draft story is blocked with a route directive; a commit referencing an accepted story is allowed; the dispatch preflight refuse-and-routes a draft selection; the in-progress->done auto-transition (untouched) still fires.

## Pros and Cons of the Options

- **A** — Good: catches the exact bypass at the commit locus + fast-fail UX; lifecycle aligned. Bad: a new hook; a deliberate accept step before implementation.
- **B** — Good: cheap. Bad: misses hand-written commits (the bypass class).
- **C** — Good: minimal. Bad: redundant + misses raw commits.

## More Information

Amends ADR-060 (lifecycle auto-transition; trailer vocabulary). Composes ADR-089 / ADR-090 / **ADR-095** (capture-time gates). Driving problem: P404 Phase 3. Architect re-review 2026-07-07: change-3 PASS on substance; commit-trailer gate is the recommended primary locus.
