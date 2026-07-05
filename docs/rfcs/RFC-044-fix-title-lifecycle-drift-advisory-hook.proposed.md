---
status: proposed
rfc-id: fix-title-lifecycle-drift-advisory-hook
reported: 2026-07-05
human-oversight: unconfirmed
decision-makers: [tomhoward]
problems: [P345]
adrs: [ADR-092]
jtbd: [JTBD-006, JTBD-001]
stories: [STORY-038]
---

# RFC-044: Fix-title lifecycle-drift advisory hook

**Status**: proposed
**Reported**: 2026-07-05
**Problems**: P345
**ADRs**: ADR-092
**JTBD**: JTBD-006 (primary), JTBD-001 (secondary)

## Summary

Fix-time RFC for P345 (fix-titled commits do not transition the ticket lifecycle in the same commit grain). Ships the user-ratified fix surface (a) from the 2026-07-04 interactive decision drain: a PostToolUse:Bash post-commit ADVISORY hook that parses `fix(<pkg>): P<NNN>` commit titles in the just-landed HEAD commit and emits a stderr nudge when a named ticket is still Open on disk with no paired lifecycle transition. Advisory-only, never blocks — NOT auto-fire, NOT a hard gate, because Open → Known Error rests on a knowledge claim (root cause known + workaround documented), not an observable fact (ADR-092 records the binding rule). Sibling (copy-and-retarget) of `itil-commit-trailer-transition-advisory.sh` (P378 detect-then-advise precedent); different signal — commit-title `P<NNN>` vs `Refs:` trailer.

## Driving problem trace

- P345 (`docs/problems/known-error/345-fix-titled-commits-do-not-transition-ticket-lifecycle.md`) — fix-titled commits land code while the named ticket stays Open across release + CI-verify + N intervening commits; the O→KE seam has no commit-title-keyed surface (root cause confirmed 2026-06-16). This RFC is the fix vehicle; placement per ADR-072 (fix proposed after Known Error produces the RFC), authored before the hook implementation per ADR-073 RFC-first.
## Scope

Supplementary prose (the story is the load-bearing decomposition per ADR-089):

- NEW hook `packages/itil/hooks/itil-fix-title-lifecycle-advisory.sh` — PostToolUse:Bash; delegates command-shape detection to `lib/command-detect.sh::command_invokes_git_commit`; reads the HEAD subject; fires only on `fix`-typed conventional-commit subjects; extracts `P[0-9]{3}` tokens; advises (stderr, exit 0) for each token whose ticket is still in `docs/problems/open/`; TOTAL emission ≤300 bytes (ADR-045); bypass `BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1`; fail-open on every parse/lookup failure (ADR-013 Rule 6).
- NEW behavioural bats `packages/itil/hooks/test/itil-fix-title-lifecycle-advisory.bats` (ADR-052/ADR-005).
- EDIT `packages/itil/hooks/hooks.json` — register under the existing PostToolUse `Bash` matcher block.
- Housekeeping: append both commit-advisory hooks to the consumer-enumeration comment in `scripts/sync-command-detect.sh` (no CONSUMERS array change — itil is an existing consumer).
- Changeset: `@windyroad/itil` bump.

## Tasks

- [ ] Behavioural bats (RED-first) for the advisory/silent/bypass/fail-open matrix
- [ ] Hook implementation (copy-and-retarget of the P378 sibling)
- [ ] hooks.json registration + sync-command-detect.sh comment housekeeping
- [ ] Changeset + fix commit tracing STORY-038

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- ADR-092 — the ratified advisory-only posture this RFC implements (born-unconfirmed per P348; substance ratified 2026-07-04).
- P228 / P234 / P378 — sibling lifecycle seams and the detect-then-advise hook precedent.
- Captured via /wr-itil:capture-rfc (fix-time path) on 2026-07-05, AFK work-problems iter; expand at next /wr-itil:manage-rfc invocation.

