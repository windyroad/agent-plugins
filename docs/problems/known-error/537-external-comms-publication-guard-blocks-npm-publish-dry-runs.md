# Problem 537: External-comms publication guard blocks npm publish dry runs

**Status**: Known Error
**Reported**: 2026-09-11
**Priority**: 10 (High) — Impact: 2 × Likelihood: 5 — a deterministic developer-tooling interruption whenever this diagnostic command is used
**Origin**: internal
**Effort**: S — one shared command classifier, synced consumers, and focused behavioural tests
**WSJF**: 20 — (10 × 2.0) / 1
**JTBD**: JTBD-001
**Persona**: developer

## Description

The external-comms gate classifies `npm publish --dry-run` as an outbound publication. A dry run only inspects the package that would be published, but both risk and voice review gates block it until publication markers exist.

Actual `npm publish` commands must remain gated. A compound command containing both a dry run and an actual publish must also remain gated.

## Symptoms

- `npm publish --dry-run` is denied as the `npm-publish` surface.
- The agent completes risk and voice reviews for an action that cannot publish anything.
- The diagnostic workflow can enter the same repeated marker-recovery cycle tracked by P402.

## Workaround

Use `npm pack --dry-run` when it provides equivalent package inspection. This is not equivalent for every npm publication check, so it does not remove the defect.

## Impact Assessment

- **Who is affected**: developers and release agents inspecting a package before publication.
- **Frequency**: deterministic for every matched `npm publish --dry-run` command.
- **Severity**: developer time and release-flow interruption; no package is published and installed users are unaffected.
- **Analytics**: one user-visible recurrence captured on 2026-09-11.

## Root Cause Analysis

`packages/shared/hooks/external-comms-gate.sh` matches the `npm publish` verb without classifying its boolean `--dry-run` option. The shared gate therefore treats a read-only diagnostic invocation as the same external side effect as a real publish.

### Investigation Tasks

- [x] Confirm the shared classifier matches `npm publish --dry-run`.
- [x] Preserve gating for plain, `--dry-run=false`, and mixed dry-run plus real publication commands.
- [x] Add focused behavioural tests in both evaluator suites.
- [x] Sync the canonical hook into both published consumer packages.

## Fix Strategy

RFC-091, *Inspect a package without starting publication*, carries STORY-087 on the existing ratified developer journey. The canonical gate will bypass publication review only when every matched `npm publish` command segment is provably dry-run-only. Any segment capable of publication remains gated.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P402, P405

## Related

- P405 is the nearest false-positive precedent, but it owns read-only `gh api` requests rather than npm command classification.
- The normal hang-off pre-filter surfaced more than five open or verifying candidates through JTBD-001 and the shared hook path, so its candidate-cap short-circuit deferred cluster re-evaluation rather than selecting a parent.

## RFCs

| ID | Title | Status |
|----|-------|--------|
| RFC-091 | Inspect a package without starting publication | proposed |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-087 | STORY-087: Inspect a package without triggering publication review | in-progress |
