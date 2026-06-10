# Problem 211: work-problems orchestrator carries prior-ticket Fix Strategy text into iter dispatch without re-grounding in design intent

**Status**: Known Error
**Reported**: 2026-05-15
**Origin**: inbound-reported (#97)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `/wr-itil:work-problems` AFK orchestrator builds each iteration's dispatch prompt by reading the target ticket's `## Fix Strategy` section and citing it verbatim to the iteration subprocess. Across iterations, prior-ticket Fix Strategy text leaks into subsequent dispatches without re-grounding in the new ticket's design intent. Iter subprocesses inherit stale context and may attempt fixes anchored on the wrong design rationale.

Reported from downstream bbstats P194.

## Workaround

User-in-the-loop verification after each iter: read the subprocess's commit and check whether it cites the correct ticket's design rationale.

## Impact Assessment

- **Severity**: Moderate — design-rationale drift could land fixes that miss the real intent; AFK trust degrades.

## Root Cause Analysis

The Step 5 "Iteration prompt body" section's opener `(self-contained — the subprocess has no prior conversation context)` named a subprocess-side property but did NOT name the symmetric orchestrator-side construction invariant. A future contributor (or the orchestrator agent itself, mid-AFK-loop) could read "self-contained" as a subprocess property only and leave the orchestrator-side prompt-construction code free to carry prior-iter content into the new iter's prompt body — specifically the prior ticket's `## Fix Strategy` text cited verbatim. The SKILL.md prose did not explicitly forbid the leakage class.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — deferred to next review-problems pass (placeholder Priority 3 / Effort M held)
- [x] Audit Step 5 iter dispatch prompt for verbatim cross-ticket Fix Strategy leakage. Likely fix: build the dispatch fresh per ticket; don't carry prior-iter context. — audited; fix landed via SKILL.md prose insertion (see Fix Strategy below)
- [x] Behavioural test asserting iter N dispatch references ticket N's Fix Strategy and ONLY ticket N's. — `packages/itil/skills/work-problems/test/work-problems-step-5-prompt-body-re-grounding.bats` (7 structural assertions, ADR-052 Surface 2 justification comment)

## Fix Strategy

SKILL-prose surface (R009 floor — no ADR signals; pure contract clarification of the existing iteration-isolation intent).

**Edit `packages/itil/skills/work-problems/SKILL.md` Step 5 "Iteration prompt body" section** to insert a new "Re-ground per iter (P211 — orchestrator-side construction invariant)" paragraph immediately after the "Iteration prompt body (self-contained — the subprocess has no prior conversation context):" opener. The paragraph names:

- The per-iter re-ground invariant against current-ticket-ID + title only
- Explicit prohibition on inlining `## Fix Strategy` verbatim into the dispatch prompt (the subprocess reads it from disk via `/wr-itil:manage-problem` inside its own context, where the design rationale stays anchored to the correct ticket)
- The cross-iter leakage class (prior ticket ID, prior Fix Strategy text, prior outcome reason, prior commit SHA, prior retro findings, prior outstanding-questions) that MUST NOT carry across the iter boundary
- The construction shape (template-driven, reset per iter, no global accumulator)
- Symmetry: "self-contained" is the subprocess-side property; re-grounding is the symmetric orchestrator-side property

**Add a behavioural second-source bats fixture** at `packages/itil/skills/work-problems/test/work-problems-step-5-prompt-body-re-grounding.bats` with 7 structural assertions (ADR-052 Surface 2 / structural-permitted with `tdd-review` justification comment citing P012 as the harness-gap ticket — synthetic `claude -p` iter dispatch harness sits outside the skill layer).

**Add P211 to SKILL.md Related section** with the standard self-documenting entry shape (driver, bug-shape one-liner, fix one-liner, composes-with cross-references).

## Fix Implemented

- 2026-06-07 — fix landed in single commit covering:
  - `packages/itil/skills/work-problems/SKILL.md` Step 5 re-grounding paragraph + Related-section P211 entry
  - `packages/itil/skills/work-problems/test/work-problems-step-5-prompt-body-re-grounding.bats` (7/7 assertions green)
- Architect review: PASS (no new ADR; R009 floor SKILL-prose refinement; corrected citation from ADR-037 to ADR-052 Surface 2)
- JTBD review: PASS (JTBD-006 load-bearing; @jtbd annotation added inline)
- Status: Known Error (transition to Verification Pending deferred to next release cadence per ADR-022)

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/97 (bbstats P194)
- **Pipeline classification**: JTBD-aligned (JTBD-006); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Composes-with**: ADR-032 (AFK iteration-isolation wrapper — re-grounding clarifies the orchestrator-side property of that isolation), P084 (subprocess-boundary dispatch — re-grounding is the symmetric orchestrator-side property of the subprocess's "no prior conversation context"), ADR-052 Surface 2 (structural-permitted bats fixture with `tdd-review` justification).
