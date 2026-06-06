# Problem 203: architect-enforce-edit + jtbd-enforce-edit hooks should add docs/retros/ to their exclusion paths

**Status**: Verifying (Fix Released)
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Fix

`packages/architect/hooks/architect-enforce-edit.sh` and
`packages/jtbd/hooks/jtbd-enforce-edit.sh` now include a `*/docs/retros/*` case
in the exclusion list, mirroring the existing peer-plugin-policy pattern for
`docs/problems/`, `docs/jtbd/`, `docs/briefing/`, `docs/story-maps/`, and
`docs/stories/`. Behavioural bats coverage added in
`packages/architect/hooks/test/architect-enforce-scope.bats` and
`packages/jtbd/hooks/test/jtbd-enforce-scope.bats` — three cases per gate
asserting `assert_path_allowed` for ask-hygiene / analyze-context /
retro-narrative filename shapes. 41/41 bats pass.

The voice-tone and style-guide enforce hooks are extension-gated
(`.html`/`.jsx`/`.tsx`/`.vue`/`.svelte`/`.ejs`/`.hbs` for voice-tone, `.css` for
style-guide) and do not fire on `.md` retros files — no change needed there.

Changeset: `.changeset/p203-retros-exclusion.md` — patch bumps for both
`@windyroad/architect` and `@windyroad/jtbd`.

Verification: next retro write under `docs/retros/` lands without either gate
firing BLOCKED on the receiving session (verifies after release + global cache
refresh).

## Description

The architect + JTBD edit-enforce hooks (`packages/architect/hooks/architect-enforce-edit.sh` + `packages/jtbd/hooks/jtbd-enforce-edit.sh`) fire gate delegations on routine writes to `docs/retros/*.md` ask-hygiene trail files. The sibling exclusion paths already cover `docs/problems/`, `docs/briefing/`, `docs/jtbd/`, `docs/PRODUCT_DISCOVERY.md`, `docs/VOICE-AND-TONE.md`, `docs/STYLE-GUIDE.md`. `docs/retros/` is the ask-hygiene trail per ADR-019 — routine appends should not fire gates.

## Workaround

Tolerate the gate delegations on retro append writes (adds friction to ask-hygiene logging without security benefit since retros are read-only narrative).

## Impact Assessment

- **Who is affected**: every retro append (run-retro Step 2d ask-hygiene pass + every retro session's narrative writes).
- **Frequency**: every retro write.
- **Severity**: Low (friction, not block).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Add `docs/retros/` to exclusion path lists in `packages/architect/hooks/architect-enforce-edit.sh` and `packages/jtbd/hooks/jtbd-enforce-edit.sh`.
- [x] Behavioural test asserting writes to `docs/retros/*.md` do not fire either gate.

## Dependencies

- **Composes with**: ADR-019 (ask-hygiene trail); sibling exclusion paths.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/120
- **Pipeline classification**: JTBD-aligned (JTBD-001); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/architect + @windyroad/jtbd.
- **Recurrence 2026-05-26** (verifying-queue-review retro): both gates fired on the FIRST `docs/retros/2026-05-26-verifying-queue-review-ask-hygiene.md` write of a fresh session — architect `BLOCKED` then JTBD `BLOCKED`, forcing two subagent round-trips (architect PASS + jtbd PASS) for a Step 2d-mandated trail artifact before the write succeeded. Likelihood data point: this fires on EVERY retro's trail write, not the "Likelihood 1" the deferred rating assumes — consider re-rating likelihood upward at next review.
