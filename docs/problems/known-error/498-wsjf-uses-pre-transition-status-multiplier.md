# Problem 498: WSJF uses the pre-transition status multiplier

**Status**: Known Error
**Reported**: 2026-08-14
**Priority**: 9 (Medium) - Impact: 3 x Likelihood: 3
**Origin**: inbound-reported (#413)
**Effort**: S
**WSJF**: 18 - (9 x 2.0) / 1
**JTBD**: JTBD-006, JTBD-001
**Persona**: developer

## Description

The two problem-review flows calculate WSJF before they automatically transition an Open problem to Known Error. The persisted score therefore uses the Open multiplier of 1.0 after the ticket has acquired the Known Error multiplier of 2.0, leaving it ranked at half its correct value.

## Symptoms

- A transitioned ticket can retain the Open multiplier indefinitely.
- The same stale value is written to the ticket and the problem index, so index-consistency checks do not detect it.
- Issue #413 records a downstream instance where an Effort re-rate and status transition produced 3.0 instead of 6.0.

## Workaround

After every Open to Known Error transition, manually recalculate WSJF from the ticket's post-transition status and current Effort.

## Root Cause Analysis

`review-problems` Step 2 and `manage-problem` Step 9b calculate and persist WSJF before their automatic status transition. The three transition checklists mention the Effort re-rate but not the simultaneous status-multiplier change.

### Investigation Tasks

- [x] Confirm the calculation precedes the transition in both review flows.
- [x] Confirm all three Open to Known Error checklists omit the multiplier re-rate.
- [x] Confirm the existing index reconciler trusts the value stored in the ticket.

## Fix Strategy

Move the transition ahead of the calculation in both review flows, require the post-transition multiplier in all three checklist copies, and add focused Promptfoo workflow evaluations covering both review paths and transition behaviour. Do not add a second diagnostic command: fixing and testing the shared workflow is sufficient.

## Dependencies

- **Blocks**: none.
- **Blocked by**: none; STORY-062 derives approval from confirmed STORY-MAP-002.
- **Composes with**: ADR-010, ADR-022, ADR-052, ADR-071, ADR-072, ADR-073.

## Story Maps

- STORY-MAP-002 - Take a problem from noticed to resolved

## RFCs

- RFC-068 - Keep problem ranking correct across status transitions
## Related

- GitHub issue [#413](https://github.com/windyroad/agent-plugins/issues/413)
- Pull request [#415](https://github.com/windyroad/agent-plugins/pull/415) contains the stale initial implementation.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-062 | STORY-062: Keep problem ranking correct after a status transition | accepted |
