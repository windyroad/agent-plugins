# Problem 372: ADR-043 context-budget delta-trigger lacks an absolute-byte floor — fires deep-layer on negligible deltas

**Status**: Open
**Reported**: 2026-06-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The ADR-043 `run-retro` Step 2c combined auto-fire trigger (calendar-elapse >14 days OR delta >20% any bucket) lacks an absolute-byte floor on the delta-breach axis, so it fires the deep-layer `/wr-retrospective:analyze-context` on negligible absolute changes to small buckets.

Observed P314 iter 3 (2026-06-17): the trigger fired because the `project-claude-md` bucket grew 4277→5897 bytes (+37.9%), a 1620-byte absolute change from a single CLAUDE.md MANDATORY-block addition. The percentage tripped the 20% rule though the absolute delta is negligible. Small buckets (`project-claude-md`, `jtbd`) will trip this routinely on tiny edits, firing the deep layer (a committed report + several subagent calls) more often than the trigger's intent (catch *meaningful* growth).

Concrete fix: add an absolute-byte floor to the delta-breach check in `run-retro` Step 2c (and/or `measure-context-budget` / the snapshot-comparison logic) so a bucket must change by both >20% AND >some-absolute-threshold (e.g. >10 KB) to fire. Keep the calendar-elapse axis unchanged.

Note: this run still produced value (the deep layer surfaced 4 P097 SKILL.md >50KB breaches), so this is a low-severity refinement of an otherwise-working trigger, not a defect.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P295

## Related

(captured via /wr-itil:capture-problem during P314 iter 3 run-retro Step 2c; expand at next investigation)

- **P295** (`docs/problems/verifying/295-adr-043-deep-context-analysis-needs-automatic-cadence-not-on-demand-only.md`) — introduced the ADR-043 auto-cadence trigger this ticket refines. P295 is in `verifying/` (its fix shipped, awaiting verification), so it cannot absorb this new scope; this ticket is the distinct absolute-floor refinement. This iter's trigger-firing is also positive evidence P295's fix works (the trigger fired).
- **P182** — `measure-context-budget` flat-glob coverage (sibling context-budget-script ticket; surfaced as a duplicate-grep title match).
- **P091** — session-wide context budget from plugin hook stack (parent context-budget concern; distinct — aggregate budget vs. trigger-threshold refinement).
- **Hang-off-check dispatch skipped**: the mechanical pre-filter surfaced 10 candidates (>5 cap), so per the capture-problem latency short-circuit the fresh-context `wr-itil:hang-off-check` subagent was not dispatched; candidate context recorded here for `/wr-itil:review-problems` re-evaluation. Most-relevant candidates: P295 (parent decision), P182 (sibling script).
- **ADR-043** — Progressive context-usage measurement; the trigger amendment 2026-06-08 (P295 settlement) is the surface to refine.
