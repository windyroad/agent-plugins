---
status: draft
story-id: fix-titled-commit-lifecycle-drift-advisory
reported: 2026-07-05
decision-makers: [tomhoward]
problems: [P345]
jtbd: [JTBD-006]
rfcs: [RFC-044]
story-maps: []
estimated-effort: deferred
---

# STORY-038: Fix-titled commits surface a lifecycle-drift advisory

**Reported**: 2026-07-05
**Problems**: P345
**JTBD**: JTBD-006
**RFCs**: RFC-044
**Story Maps**: (none — populate at accepted transition per I8)
**Estimated effort**: deferred (populate at accepted transition per I10 INVEST Estimable)

## User value (required, INVEST Valuable)

In order to trust that the problem backlog reflects lifecycle reality when I return from AFK work, as a developer, I want every fix-titled commit that names a still-Open ticket to surface a post-commit advisory nudging the paired lifecycle transition — advisory-only, never blocking (ADR-092).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A `git commit` whose HEAD subject is `fix(<pkg>): ... P<NNN> ...` while `docs/problems/open/<NNN>-*.md` exists emits a stderr advisory naming the ticket and the transition path, exit 0.
- [x] The same commit shape is silent when the named ticket is in `known-error/` / `verifying/` / `closed/` / `parked/` or does not exist.
- [x] Non-`fix`-typed subjects naming a `P<NNN>` are silent (the signal is the fix type, not the token).
- [x] Total stderr emission stays ≤300 bytes even when the subject names multiple still-Open tickets (ADR-045).
- [x] `BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1` suppresses the advisory; every path (including malformed input, missing docs/problems, non-git cwd) exits 0.
- [x] The hook is registered in `packages/itil/hooks/hooks.json` under PostToolUse matcher `Bash`.

## Driving problem trace (required — I6 invariant)

- P345 (`docs/problems/known-error/345-fix-titled-commits-do-not-transition-ticket-lifecycle.md`) — fix-titled commits land code while the named ticket stays Open across release + CI-verify + N intervening commits; no surface maps the commit-title signal to the lifecycle. This story ships the ratified advisory surface (a).

## JTBD trace (required — I9 invariant)

- JTBD-006 (Progress the Backlog While I'm Away, developer persona) — the advisory feeds AFK orchestrators and returning maintainers the missing transition signal, keeping WSJF ranking and the post-release K→V enumeration truthful ("every action taken during AFK mode should be traceable").

## Implementation notes (optional)

Copy-and-retarget of `packages/itil/hooks/itil-commit-trailer-transition-advisory.sh` (P378 detect-then-advise precedent): source `$SCRIPT_DIR/lib/command-detect.sh`, guard with `command_invokes_git_commit`, parse `git log -1 --format='%s'`, extract `P[0-9]{3}` tokens from fix-typed subjects, glob `docs/problems/open/<NNN>-*.md`. The hook DETECTS; a skill or human PERFORMS the transition (ADR-014 / ADR-092 binding rule).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- ADR-092 — advisory-only posture (binding rule: never auto-fire or gate on a knowledge claim).
- RFC-044 — fix vehicle; this story is its load-bearing decomposition (ADR-089).
- Captured via /wr-itil:capture-story on 2026-07-05 (AFK work-problems iter); expand at next /wr-itil:manage-story invocation.
