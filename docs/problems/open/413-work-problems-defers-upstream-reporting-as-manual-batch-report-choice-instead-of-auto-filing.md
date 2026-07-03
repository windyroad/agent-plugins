# Problem 413: work-problems defers upstream reporting as a manual "batch-report upstream" choice instead of auto-filing upstream-blocked tickets

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 8 (Medium) — Impact: 4 x Likelihood: 2 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-006
**Persona**: developer

## Description

A `/wr-itil:work-problems` run ended its `ALL_DONE` summary with (verbatim from
the user's screenshot):

> **Note:** 16 upstream-blocked tickets are unreported. When you want them
> filed to windyroad/agent-plugins, re-run /wr-itil:work-problems and choose
> "batch-report upstream", or file selectively via /wr-itil:report-upstream.

The loop left **16 upstream-blocked tickets unreported** and surfaced a
**manual user-action nudge** ("re-run and choose batch-report upstream") instead
of filing them. This directly contradicts the documented Step 4 contract
(`packages/itil/skills/work-problems/SKILL.md` Step 4 upstream-blocked row +
Non-Interactive Decision Making table): upstream-blocked tickets are supposed to
**auto-invoke `/wr-itil:report-upstream`** via the ADR-024 (2026-06-04 P270)
AFK fallback — "the report-upstream call is the action this row takes." An
above-appetite report queues; but a *below-appetite* report should **just send**.
16 unreported tickets means the auto-fire is not happening — the loop is gating
the report behind a "choose to report" step the user never asked for.

**User correction (verbatim, 2026-07-03):** *"the upstream tickets shouldn't be
sitting unreported. I didn't say 'ask permission first'. Just fucking report
it."*

## Symptoms

- 16 upstream-blocked tickets left unreported after a full work-problems loop.
- `ALL_DONE` summary emits a "re-run and choose batch-report upstream" nudge — a
  permission gate — instead of the ADR-024 auto-file.

## Workaround

Manually re-run `/wr-itil:work-problems` and choose "batch-report upstream", or
file each via `/wr-itil:report-upstream`. (This is the friction the ticket
objects to.)

## Impact Assessment

- **Who is affected**: maintainer + upstream repo (windyroad/agent-plugins) — bugs adopters hit sit unreported, breaking the JTBD-004 cross-repo feedback loop.
- **Frequency**: every AFK loop that ends with upstream-blocked tickets.
- **Severity**: (deferred to investigation)
- **Analytics**: 16 tickets unreported in the observed run.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Determine why the Step 4 auto-invoke of report-upstream is NOT firing for upstream-blocked tickets (regressed? or is there a "batch-report" mode that gates behind a user choice?)
- [ ] Remove the permission gate: below-appetite upstream-blocked tickets auto-file during the loop; only above-appetite reports queue (per P352, and even then not as a "re-run to report" nudge)
- [ ] The `ALL_DONE` summary should report ACTUAL filings, not a to-do list of "re-run to file"

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P414 (same meta-class — wrap defers a mechanical action to the user instead of doing it); P375 (no self-firing cadence — "re-run when you want it" is a named re-entry nothing self-fires)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Meta-class**: the AFK/wrap surfaces mechanical actions as deferred user-recommendations instead of performing them (session memory `feedback_system_holds_the_memory_not_the_user` — "never hand the user a remember-to-X checklist; do it or auto-surface it").
- ADR-024 (2026-06-04 P270 amendment) — the AFK report-upstream auto-fire contract this regresses against.
- `packages/itil/skills/work-problems/SKILL.md` Step 4 upstream-blocked row + Non-Interactive Decision Making table (line ~503) — the documented auto-invoke this violates.
- P352 — queue-and-continue for above-appetite reports (queue is NOT a "re-run to report" nudge).
