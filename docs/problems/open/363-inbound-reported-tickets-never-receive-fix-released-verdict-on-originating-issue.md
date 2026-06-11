# Problem 363: Inbound-reported tickets never receive fix-released verdict on originating issue

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

Inbound-reported tickets reaching fix-released never deliver the JTBD-301 verdict to the originating inbound issue. ADR-062's assessment pipeline defines intake-time branches only (acknowledge / pushback / policy-violation-close); /wr-itil:update-upstream owns the outbound axis only (consumes the `## Reported Upstream` section written by report-upstream). A ticket with `Origin: inbound-reported (#NN)` carries the inbound issue URL only as a `- **Reported Upstream**:` bullet under `## Related`, so even transition-problem Step 7b's unconditional update-upstream dispatch no-ops — the reporter never hears the fix shipped. Witnessed 2026-06-11 AFK iter 2: P220 K→V left #63 un-notified; P211 V→Closed left #97 un-notified (and unclosed). JTBD-301 line 31 promises every report is "eventually responded to with a verdict (fix released / parked / duplicate / won't-fix / policy-violation)" — no surface executes the fix-released verdict leg.

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
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check skipped — candidate-cap short-circuit (P346 sub-step 2b)**: mechanical pre-filter on shared signals (ADR-062 / /wr-itil:update-upstream / /wr-itil:report-upstream / JTBD-301) matched 31 open/verifying candidates (> 5 cap); subagent dispatch skipped per SKILL contract; re-evaluate absorption at next /wr-itil:review-problems. Nearest candidates by scope: P229 (inbound-discovery ack comments not verdict-shaped — intake-time ack shape, verifying), P249 (reporters can't check for responses — outbound polling axis, verifying), P129 (inbound pipeline lacks version-aware classification — intake-time classification, known-error), P079 (inbound discovery leg, closed), P080 (outbound lifecycle updates — /wr-itil:update-upstream, known-error). None covers the transition-time inbound-verdict leg this ticket names.
- **Witnesses**: P220 (manage-problem has no cadence for checking upstream-bound tickets) K→V 2026-06-11 commit 345880d8 — inbound issue #63 silent; P211 (work-problems iter-prompt re-grounding) V→Closed 2026-06-11 commit 6635120f — inbound issue #97 silent and still open upstream.
- **Counter-witness + contract gap (2026-06-11, AFK iter 3)**: P228 (inbound #42) DID receive its fix-released verdict at K→V — via `/wr-itil:update-upstream 228` in the manage-problem Step 7 P080 block — because the capture had recorded the originating issue as `- **Reported Upstream**: <url>` in `## Related`. Two findings: (a) the existing outbound surface CAN execute the inbound verdict leg whenever the originating-issue URL is recorded in Reported Upstream form, so one fix shape is "ADR-062 intake writes the originating issue into the Reported Upstream contract at ticket creation"; (b) `/wr-itil:update-upstream` Step 1's no-op exit checks for a `## Reported Upstream` SECTION only — the capture-time BULLET form (`- **Reported Upstream**:` in `## Related`, which manage-problem's already-noted check recognises) would no-op-exit. The agent proceeded on substance this iter; an adopter following the SKILL verbatim would have silently skipped the verdict. Fix should recognise both forms (mirror the already-noted check's dual-form grep).
