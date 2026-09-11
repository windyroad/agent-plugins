# Problem 538: Problem creation is gated on the problem index existing

**Status**: Known Error
**Reported**: 2026-09-11
**Priority**: 20 (Very High) - Impact: Significant (4) x Likelihood: Almost certain (5)
**Origin**: internal
**Effort**: M - creation preflight shared by multiple problem-management skills plus focused behavioural coverage
**WSJF**: 10 - (20 x 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

An adopter repository's retrospective could not create problem tickets because the problem-capture skill's mandatory preflight halted when `docs/problems/README.md` was absent. Problem creation is the recovery path for defects in governance state, so a missing or inconsistent problem index must not make that recovery path unavailable.

The capture should preserve the report first, then repair or defer repair of the derived index without discarding the problem.

## Symptoms

- The retrospective reported that problem tickets were not created.
- The stated blocker was the capture skill's mandatory preflight halting because `docs/problems/README.md` did not exist.
- The lifecycle gate prevented the defect describing that gate from being recorded.

## Workaround

Create the ticket and repair or create `docs/problems/README.md` manually in the same commit. This preserves the report and satisfies the existing commit-time pairing rule, but bypasses the problem-creation skill that should own the workflow.

## Impact Assessment

- **Who is affected**: developers using problem-management skills in adopter repositories without a complete local problem index.
- **Frequency**: deterministic whenever creation reaches the current preflight with the index absent; no creation-safe fallback is documented.
- **Severity**: Significant. An installed governance skill fails to preserve a problem report and removes the normal recovery path.
- **Analytics**: one user-visible occurrence supplied as screenshot evidence on 2026-09-11.

## Root Cause Analysis

Both problem-creation entry points run `wr-itil-reconcile-readme` before preserving or classifying the requested report. The reconciler correctly exits 2 when `docs/problems/README.md` is absent. `capture-problem` conservatively routes that result to a halt, while `manage-problem` explicitly halts on any missing or malformed README before it knows whether the requested operation is a new capture or an existing-ticket update.

The callers therefore treat a derived navigation index as a prerequisite for creating its source ticket. This conflates safe creation recovery (missing index or parseable table drift) with the data-loss-sensitive case (an existing malformed README containing human-authored narrative). The strict reconciler is not defective; the creation callers fail to classify its result by operation and repair safety.

Reproduction on 2026-09-11: a temporary adopter fixture containing `docs/problems/open/001-fixture.md` but no `docs/problems/README.md` produced `PARSE_ERROR: README not found at docs/problems/README.md` and exit 2 from the installed `@windyroad/itil` 2.1.2 reconciler. The installed creation contracts then prescribe halting before the report is written.

### Investigation Tasks

- [x] Reproduce problem creation with an absent `docs/problems/README.md`.
- [x] Trace every creation caller through the README reconciliation preflight.
- [x] Identify the creation-only boundary where capture can preserve the report without weakening strict reconciliation elsewhere.
- [x] Document a safe workaround.
- [x] Create a focused behavioural regression test.
- [x] Create an INVEST story for the permanent fix.

## Fix Strategy

ADR-123 authorizes report-first problem creation. `capture-problem` and only the new-problem branch of `manage-problem` will continue over a missing index or parseable drift, then use their existing same-commit refresh step to create or repair the generated index sections. An existing malformed README, existing-problem operations, the reconciler, and all non-creation callers retain strict halt behavior.

**Release vehicle**: `.changeset/kind-reports-survive.md`

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P351, P065, P199

## Related

- P351 covers missing configuration preconditions that skip optional skill work. This ticket is narrower and stronger: an absent derived index blocks the act of recording a problem.
- P065 scaffolds downstream OSS intake files, not the local problem-management index.
- P199 covers same-session README drift after capture, not an index that is absent before creation starts.
- ADR-123 supersedes only the problem-creation preflight routing in ADR-014 and leaves its remaining commit discipline intact.
- The duplicate search found these related themes; the user selected a focused ticket rather than expanding P351.
- The hang-off candidate pre-filter exceeded its five-ticket cap because the shared skill and README paths are widely referenced, so the fresh-context arbitration was skipped per the workflow contract.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-088 | STORY-088: Capture a problem when its index is missing | in-progress |

## RFCs

| ID | Title | Status |
|----|-------|--------|
| RFC-092 | Capture a problem when its index is missing | proposed |
