# Problem 411: no interactive oversight-drain skill for pending-review risk-register entries

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 2 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The risk-scorer SessionStart scaffold-nudge (ADR-047) now surfaces a count of
pending-review risk-register entries in `docs/risks/` (~51 as of 2026-07-03),
but points the user at **manual** curation of that directory — there is no
interactive drain skill to walk through the entries and confirm / amend /
reject each one.

This is asymmetric with the two governance surfaces that already have
oversight drains:

- `/wr-architect:review-decisions` drains unoversighted ADRs.
- `/wr-jtbd:confirm-jobs-and-personas` drains unoversighted jobs/personas.

The risk register has the same shape (auto-derived entries needing human
oversight) but no equivalent interactive drain. The nudge names a re-entry
point that nobody self-fires — a textbook instance of P375 (named re-entry ≠
self-firing cadence).

**Scope boundary vs the existing risk-register cluster** — this ticket is the
*review/oversight* lifecycle stage, distinct from the already-shipped
*create/populate* surfaces:

- P102 shipped `/wr-risk-scorer:create-risk` — the manual CREATE surface.
- P110 tracks a passive TRIGGER to create entries without remembering.
- P171 / P309 cover the `drain-register-queue.sh` script that materialises
  AFK-queued risk *hints* into register files.

None of those is an interactive confirm/amend/reject drain over
already-materialised pending-review entries. That is this ticket.

**User direction (2026-07-03 outstanding-questions drain):** build the drain
skill (a `/wr-risk-scorer:review-register` mirroring review-decisions /
confirm-jobs-and-personas) to standardise the process.

## Symptoms

- Scaffold-nudge reports ~51 pending-review risk-register entries with no
  cadenced interactive drain target; the count only grows.

## Workaround

Manual editing of `docs/risks/*.md` frontmatter by hand.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: ~51 entries pending as of 2026-07-03

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Design `/wr-risk-scorer:review-register` mirroring the review-decisions detector + AskUserQuestion drain + oversight-marker write
- [ ] Wire the ADR-047 nudge to point at the new skill instead of manual curation
- [ ] Confirm scope split vs P110 (passive-create-trigger) at review time — merge if the overlap is real
- [ ] Create behavioural test coverage per ADR-052

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P375 (named-re-entry vs self-firing cadence — this is an instance)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- P375 (`docs/problems/known-error/375-repo-conflates-named-re-entry-point-with-self-firing-cadence.md`) — parent class; the drain-skill gap surfaced during its iter11.
- **Risk-register cluster (hang-off candidates surfaced at capture, resolve at next review):**
  - P110 (`docs/problems/verifying/110-...`) — closest sibling: register needs a passive/self-firing trigger. P411 is the review-drain complement to P110's create-trigger.
  - P102 (`docs/problems/verifying/102-...`) — the CREATE invocation surface (shipped).
  - P171 / P309 (`docs/problems/verifying/`) — the `drain-register-queue.sh` materialisation script (different mechanism).
- ADR-047 — the scaffold-nudge that surfaces the pending count.
- ADR-056 / ADR-059 — risk-register write contract + pipeline catalog consumption (adjacent, not the drain surface).
- `/wr-architect:review-decisions` + `/wr-jtbd:confirm-jobs-and-personas` — the sibling drain skills this mirrors.
