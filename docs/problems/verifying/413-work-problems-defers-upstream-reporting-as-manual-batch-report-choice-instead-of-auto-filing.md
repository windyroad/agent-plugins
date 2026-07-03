# Problem 413: work-problems defers upstream reporting as a manual "batch-report upstream" choice instead of auto-filing upstream-blocked tickets

**Status**: Verification Pending
**Reported**: 2026-07-03
**Priority**: 8 (Medium) — Impact: 4 x Likelihood: 2 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-006
**Persona**: developer

## Fix Released

Fixed in `packages/itil/skills/work-problems/SKILL.md` (Output Format section) — added a
`### Reported Upstream` summary subsection + an invariant forbidding the "N unreported —
re-run to batch-report upstream" wrap-time deferral nudge (there is no batch-report mode;
upstream reporting is per-iter auto-fire at Step 4 per ADR-024 P270). Behavioural
second-source: a P413 Tier-A/Tier-B case in
`packages/itil/skills/work-problems/eval/promptfooconfig.yaml` (ADR-061 Rule 4 floor).
Traced under RFC-018 (I13 sub-case a, existing-vehicle-untraced). Ships in the next
`@windyroad/itil` release via the paired changeset. Awaiting user verification.

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

**Confirmed 2026-07-04.** There is **no "batch-report upstream" mode** anywhere in
`packages/itil/skills/work-problems/SKILL.md` (grep-confirmed by the fixing iter and
the architect gate). The Step 4 `upstream-blocked` classifier row (line 503), the
stop-condition prose (line 511), and the decision table (line 1077) ALREADY mandate
**per-iter** auto-invoke of `/wr-itil:report-upstream` — below-appetite sends during
the loop, above-appetite risk-reduces then sends-or-queues per P352 (ADR-024 2026-06-04
P270 amendment). So the auto-fire contract was never missing.

The observed failure — 16 upstream-blocked tickets left unreported plus a wrap-time
"re-run and choose batch-report upstream" nudge — is an **agent-invented wrap-time
deferral/permission gate**, the same class as P390 / P341 / P175 / P332 / P148 (the
orchestrator inventing loop-control the framework already resolved per ADR-044). The
**structural gap** that let the invented gate slip through: the SKILL's **Output Format /
`ALL_DONE` summary section carried no invariant** (a) forbidding a "N unreported — re-run
to batch-report" nudge, and (b) no `### Reported Upstream` template subsection requiring
the summary to render ACTUAL filings. With nothing at the wrap surface positively
reinforcing per-iter auto-fire, the agent filled the vacuum with a batched user-choice
gate.

**Workaround** (pre-fix): none needed for correctness — the per-iter auto-fire is already
contracted; the maintainer can file the deferred tickets via `/wr-itil:report-upstream`.
The fix removes the invented gate at its source (the summary surface).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Determine why the Step 4 auto-invoke of report-upstream is NOT firing — **it is NOT a regression and there is NO "batch-report" mode**; the auto-fire is contracted at Step 4 (lines 503/511/1077). The failure is an agent-invented wrap-time deferral gate enabled by a missing Output-Format invariant.
- [x] Remove the permission gate — Output Format invariant added forbidding the "N unreported — re-run to batch-report" nudge; below-appetite auto-files per-iter, above-appetite queues (P352), never as a re-run nudge.
- [x] The `ALL_DONE` summary should report ACTUAL filings — added a `### Reported Upstream` summary subsection reporting actual filings/queued drafts, not a to-do list.

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

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-018 | proposed | P270 — external-comms-risk-gated AFK auto-fire for ALL upstream reports including security-classified tickets |
