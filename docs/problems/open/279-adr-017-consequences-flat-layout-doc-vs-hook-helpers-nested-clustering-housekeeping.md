# Problem 279: ADR-017 § Consequences documents flat layout under `packages/shared/`, but hook-helpers cluster under nested `hooks/lib/` — housekeeping clarification

**Status**: Open
**Reported**: 2026-05-19
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

Session 8 iter 6 (P273+P274+P275 batched sibling sweep) shipped the `command_invokes_git_commit` shared helper at `packages/shared/hooks/lib/command-detect.sh` per architect verdict 2026-05-19. The architect cited existing precedent — `session-marker.sh` / `leak-detect.sh` / `external-comms-key.sh` already live under nested `packages/shared/hooks/lib/`. So nested-under-hooks/lib/ is the established pattern for hook helpers.

But ADR-017 § Consequences currently documents the flat layout under `packages/shared/` per the `derive-first-dispatch.sh` precedent (which lives at `packages/itil/lib/derive-first-dispatch.sh`, not under `packages/shared/`). The two coexisting conventions are:

- **Cross-cutting libs** (e.g. `derive-first-dispatch.sh`) — flat under each package's `lib/` directory; sync'd across packages via ADR-017's sync script + CI gate.
- **Hook helpers** (e.g. `session-marker.sh`, `leak-detect.sh`, `external-comms-key.sh`, now `command-detect.sh`) — clustered under `packages/shared/hooks/lib/`; each package's hooks source from there directly.

**Proposed fix**: amend ADR-017 § Consequences with a one-line note acknowledging both clustering patterns. Hook helpers cluster under `packages/shared/hooks/lib/` for proximity to their consumers; cross-cutting libs stay flat per the existing convention. Architect flagged this as "useful housekeeping but not gate-required" — defer-friendly.

## Symptoms

(deferred to investigation)

- ADR-017 § Consequences description doesn't fully match the on-disk shape of `packages/shared/`.
- Future contributors reading ADR-017 may not know about the hook-helper sub-convention.

## Workaround

None needed currently — the iter-6 commit message + architect verdict both document the verdict shape inline. Future contributors who need the convention should be able to derive it from the on-disk pattern.

## Impact Assessment

- **Who is affected**: future contributors reading ADR-017 to author new shared helpers.
- **Frequency**: per-author one-off; once read, the convention is internalised.
- **Severity**: (deferred to investigation) — initial: low. Housekeeping only.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause — ADR-017 § Consequences may need explicit two-pattern documentation
- [ ] Amend ADR-017 § Consequences with the hook-helper nested-clustering convention
- [ ] Consider whether to add a `packages/shared/README.md` listing the conventions inline

## Dependencies

- **Composes with**: ADR-017 (cross-package sync convention parent), P268 (helper that triggered the layout decision), P273+P274+P275 (siblings that landed Option B)

## Related

(captured 2026-05-19 from /wr-itil:work-problems session 8 iter 6 (P273+P274+P275 batched sibling sweep) deviation-approval queue, user-directed via AskUserQuestion at Step 2.5)

- ADR-017 — cross-package sync convention parent
- `packages/shared/hooks/lib/` — actual nested-cluster location
- iter 6 architect verdict — "Option B at packages/shared/hooks/lib/ matching the existing session-marker.sh / leak-detect.sh / external-comms-key.sh precedent there. ADR-017 covers the shape; no new ADR required"
