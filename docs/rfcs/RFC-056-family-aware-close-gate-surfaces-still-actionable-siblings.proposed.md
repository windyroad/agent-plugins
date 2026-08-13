---
status: proposed
rfc-id: family-aware-close-gate-surfaces-still-actionable-siblings
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P433]
adrs: [ADR-013, ADR-014, ADR-022, ADR-049, ADR-052, ADR-071, ADR-080, ADR-089, ADR-096]
jtbd: [JTBD-006, JTBD-001]
stories: []
---

# RFC-056: Family-aware close gate — surface still-actionable composes-with siblings

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P433
**ADRs**: ADR-013 (Rule 6 queue-and-continue), ADR-014 (commit grain), ADR-022 (problem lifecycle), ADR-049 + ADR-080 (`bin/` shim on `$PATH`, generated wrapper), ADR-052 (behavioural tests), ADR-071 (unconditional RFC-first), ADR-089 (every RFC has ≥1 story), ADR-096 (a draft story is not implementable)
**JTBD**: JTBD-006 (primary — progress the backlog while I'm away), JTBD-001 (secondary — enforce governance without slowing down)

## Summary

Teach the close paths to read the family graph they already carry. Every problem ticket's
`## Dependencies` section may record `**Composes with**: P<NNN>` edges; 212 such edges are authored
across the open, known-error and verifying corpus. No script parses them. Consequently a ticket can
close while a sibling it is recorded as composing with is still actionable, and nobody makes that
call — 29 already-closed tickets are in exactly that state today.

This RFC scopes an advisory scan that runs at each close gate, lists the still-actionable family
members, and — per ADR-013 Rule 6's queue-and-continue default — queues the disposition rather than
either blocking the close or printing into a transcript nobody reads.

## Driving problem trace

- **P433** (`docs/problems/known-error/433-transition-review-run-retro-lack-sibling-family-completeness-scan-before-close.md`)
  — Known Error, inbound-reported as issue #187. Its confirmed root cause: the close-gate pre-flight
  contracts on `/wr-itil:transition-problem` Step 4 (`close`), `/wr-itil:review-problems` Step 4
  Bucket 1 + Step 4.6, and `/wr-retrospective:run-retro` Step 4a are per-ticket invariant lists with no
  family-level invariant, and the family-edge data such an invariant would read has no mechanical
  consumer anywhere in the plugin scripts. The ticket's `## Workaround` is the manual forward/reverse
  grep this RFC automates.

## Scope

**A single advisory script, three one-line call sites, and a queue entry.**

`packages/itil/scripts/scan-sibling-family.sh` takes a problem-ticket path and emits one line per
still-actionable family member. It resolves two directions: **forward** edges (the `P<NNN>` references
on the ticket's own `**Composes with**` line) and **reverse** edges (tickets whose `**Composes with**`
line names this ticket's ID). Results are filtered to siblings currently living under
`docs/problems/open/` or `docs/problems/known-error/`. Siblings under `verifying/`, `parked/` or
`closed/` contribute nothing — the same upstream-status carve-out the transitive-effort rule already
applies, where closed, verifying and parked upstreams contribute zero.

The script is reached as `wr-itil-scan-sibling-family` on `$PATH` per ADR-049. Its wrapper is
**generated** by `scripts/sync-shim-wrappers.sh` from
`packages/shared/lib/shim-wrapper-template.sh` — the highest-version-wins resolver mandated by the
ADR-049 amendment (ADR-080), not the three-line `exec` shape the ADR-049 body still shows. Call sites
invoke the shim name only; a repo-relative `packages/...` path from a SKILL resolves in this monorepo
and nowhere else.

**Gate strength: advisory-plus-queue, never blocking.** The script exits 0 unconditionally. Two
distinct claims sit behind that, and both are load-bearing:

- *It must not halt.* The nearest precedent that does halt is the conditional-deferral check on the
  Known Error → Verifying transition, whose carve-out is earned by an irreversible failure mode —
  silently losing deferred work. A close is not irreversible: `/wr-itil:transition-problem <NNN>
  known-error` reopens it, and both `run-retro` Step 4a and `review-problems` Step 4 already document
  that recovery path. The halt justification does not transfer. Halting would also break an AFK loop,
  which JTBD-006 requires to stop only when nothing actionable remains or a real blocker fires.
- *Advisory alone is not enough either.* P433's root cause is that family-edge data is authored for
  humans and read by nobody. A line printed into an AFK iteration's close report has no human reader
  either — that would reproduce the defect one layer up, which is why the 29 measured cases read as
  "never surfaced" rather than "invisible". So on a non-empty scan the calling skill takes ADR-013
  Rule 6's **queue-and-continue** default: it appends one `outstanding_questions` entry naming the
  closing ticket, each still-actionable sibling, and the three dispositions P433's workaround already
  enumerates — the sibling closes with this ticket, gets re-linked, or is knowingly left open — and the
  close proceeds. Interactively the finding renders in the close report; on the `review-problems`
  Bucket 1 batch-close path it surfaces as ONE batched question across all closes with stranded
  siblings, never one question per ticket. Queue-and-continue is framework-resolved, so no new
  architecture decision is required — each call site carries an inline
  `per ADR-013 Rule 6 (queue-and-continue)` citation.

**Call sites** (one line each, no new surface):

- `/wr-itil:transition-problem` Step 4, in the `close` pre-flight.
- `/wr-itil:review-problems` Step 4 Bucket 1 and Step 4.6, before each `git mv` to `closed/`. These two
  paths perform their own rename rather than dispatching through `transition-problem`, so a gate wired
  only into `transition-problem` would miss them.
- `/wr-retrospective:run-retro` Step 4a, before it dispatches `/wr-itil:transition-problem <NNN> close`.

Cross-plugin invocation of an itil-owned shim from a retrospective SKILL is established practice —
`run-retro` Step 4a already dispatches `/wr-itil:transition-problem` under its documented cross-plugin
dispatch contract, and `packages/retrospective/hooks/hooks.json` already declares `wr-itil` as a
SessionStart dependency. Ownership sits with itil because the script parses `docs/problems/`, which is
itil's domain.

**Verification** is behavioural per ADR-052: bats drive the script against fixture ticket trees and
assert on its emitted lines — forward-edge-only, reverse-edge-only, both directions, sibling-in-
verifying suppressed, no-edges-emits-nothing. No structural grep of SKILL.md prose.

### Deferred second phase — clustering by friction class

P433 as filed names two signals: authored `Composes with` edges **and** friction-class keyword overlap.
This RFC scopes the first only. The second is deferred to Phase 2, not dropped, for two reasons. The
authored-edge half is deterministic and already has 212 edges of day-one coverage. The keyword half is
inference, and inference at a close gate is precisely the over-firing failure mode recorded against the
relevance-close evaluator, which reads a citation as a fix-shipped signal (P463 — itself an authored
`Composes with` edge on P433). Landing an inferential scan at a higher-stakes gate before the
deterministic one has demonstrated a miss rate would repeat that mistake.

Phase 2 is an ordered phase of this RFC, not a body TODO — it competes for attention as a first-class
entity and gains its own story on STORY-MAP-011 when Phase 1's miss rate is observed. Its pre-filter
should reuse the mechanical shared-signal pre-filter already built for the capture-time hang-off-check
arbiter rather than minting a second implementation; hang-off-check answers the same family-signal
question at the opposite end of the lifecycle.
<!-- cadence: packages/retrospective/hooks/retrospective-deferral-census.sh (SessionStart) -->

The deferral above is counted and reported on every interactive session start by the retrospective
deferral-census SessionStart hook, which scans authoring surfaces for deferred-work markers. That is
the self-firing trigger; nothing here waits on someone remembering to re-read this RFC.
## Commits

(rendered from `git log --grep "Refs: RFC-056"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per
ADR-085 — at capture there are no commits yet.)

## Related

- **P076** — the sibling half of the same unread dependency graph: it wants `**Blocked by**` edges to
  propagate effort into WSJF, this RFC wants `**Composes with**` edges to surface at close. Whichever
  ships a parser first should shape it so the other can reuse it.
- **P463** — the relevance-close evaluator over-firing on an inferred signal; the cautionary precedent
  behind the Phase 1 / Phase 2 split above.
- **P346 / RFC-013 Phase 3** — the capture-time inflow twin (`wr-itil:hang-off-check`). Same
  family-signal question, opposite end of the lifecycle.
- **P184** — the conditional-deferral check on the Known Error → Verifying transition: the shape
  precedent for a body-scanning pre-flight, and the contrast case for why this gate does not halt.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-052 | STORY-052: Surface still-outstanding family members before a close | draft |
