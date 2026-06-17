---
status: proposed
rfc-id: derive-release-vehicle-defacto-released-graduated-holding-changesets
reported: 2026-06-18
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P361]
adrs: []
jtbd: [JTBD-006]
stories: []
---

# RFC-026: derive-release-vehicle de-facto-released exit-0 path for graduated holding changesets

**Status**: proposed
**Reported**: 2026-06-18
**Problems**: P361 (derive-release-vehicle exit-3 "unreleased" false positive on ADR-061 graduated holding changesets)
**ADRs**: (none)
**JTBD**: JTBD-006 (Progress the backlog while AFK — the false-positive forces a manual override in the K→V routing the orchestrator depends on)

> **Auto-created 2026-06-18 by the I13 fix-time RFC-trace gate (RFC-005 B8 forward-dogfood).** P361's fix shipped in commit `28c0d026` *before* the I13 gate landed (2026-06-16), so the Known Error carried a `## Fix Strategy` with no RFC trace. Touching P361 under the gate (`wr-itil-check-fix-rfc-trace`) fired `no-rfc-trace: P361`; with no existing fix-vehicle to wire (the P371 precondition does not hold — no RFC's `problems:` array claims P361 or its compose-with parent P330, and no RFC body scopes `derive-release-vehicle`), ADR-073 auto-create is the framework-correct branch. This RFC is the problem-traced skeleton vehicle that auto-create produced; its scope is written retroactively against the already-shipped diff. Carries no independent decisions (ADR-070).

## Summary

`wr-itil-derive-release-vehicle` reported exit-3 ("changeset still present in working tree — unreleased") as a false positive when the referenced changeset was an ADR-061 holding-graduation reinstate whose code had already de-facto shipped with a sibling release (the P359 holding-does-not-withhold-shipment class). The exit-3 guard tested only presence-in-`.changeset/`, conflating "changelog entry not yet drained" with "code not yet released" — two conditions that diverge under the ADR-061 Rule 5 graduation flow. The fix teaches the helper a third check before exiting 3: find the commit that originally added the changeset (`git log --diff-filter=A … | tail -1`, robust to the hold→graduate rename) and test whether it is an ancestor of the latest `chore: version packages` commit (`git merge-base --is-ancestor`). If so, the fix code shipped → emit a `de-facto-released (attribution pending)` citation block and exit 0; a genuinely-unreleased fresh changeset has its add-commit newer than the last bump, so the test is false and it correctly stays exit 3. Read-only (ADR-014 preserved).

## Driving problem trace

- **P361** (`docs/problems/known-error/361-derive-release-vehicle-exit-3-unreleased-false-positive-on-graduated-holding-changesets.md`) — the exit-3 false positive forced manual ancestry overrides in `transition-problem` Step 6 K→V routing during AFK `/wr-itil:work-problems` iterations. This RFC scopes the `de-facto-released` exit-0 branch that closes it. Composes with P330 (the derive-release-vehicle helper + seed contract) and P359 (holding ships code). JTBD trace: JTBD-006. Persona: developer.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
