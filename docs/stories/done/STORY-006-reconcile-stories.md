<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: reconcile-stories
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-001]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: M
---

# STORY-006: /wr-itil:reconcile-stories trio (skill + script + bin shim)

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-001
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred)
**Estimated effort**: M

## User value (INVEST Valuable)

As a plugin maintainer, I want a `/wr-itil:reconcile-stories` skill (and the underlying script + bin shim) that detects drift between `docs/stories/README.md` and on-disk story inventory + reverse-trace `## Stories` sections on driving problems / RFCs / JTBDs, so that drift is detectable + correctable when inline refresh contracts are missed.

## Acceptance criteria (INVEST Testable)

- [x] `packages/itil/scripts/reconcile-stories.sh` (~215 lines, executable, exit 0/1/2 per ADR-040)
- [x] `packages/itil/bin/wr-itil-reconcile-stories` (2-line bin shim per ADR-049)
- [x] `packages/itil/skills/reconcile-stories/SKILL.md` (~140 lines, agent-applied-edits wrapper)
- [x] FS truth across 5 lifecycle subdirs (draft / accepted / in-progress / done / archived)
- [x] Drift entries: DRIFT / STALE / MISMATCH / MISSING_REVERSE_TRACE / STALE_REVERSE_TRACE / STATUS_MISMATCH
- [x] Reverse-trace pass on problems / RFCs / JTBDs when those directories exist
- [x] 10 behavioural bats green covering script + bin existence + parse errors + clean run + drift detection cases

## Driving problem trace (I6)

**P170** Phase 2 implementation task list (Slice 9). Sibling pattern to `reconcile-rfcs.sh` (ADR-060 Phase 1 item 5) + `reconcile-readme.sh` (P118 / ADR-014).

## JTBD trace (I9)

**JTBD-008** — story tier reverse-trace integrity is load-bearing for the working-the-problem flow (STORY-005).
**JTBD-001** — drift detection is automated governance enforcement.

## Implementation notes

Differences from reconcile-rfcs: no WSJF column (I11 invariant); 5 lifecycle subdirs not 4; per-state subdir layout native (no dual-tolerant flat — story tier is post-RFC-002); no Verification Queue or Parked tier.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: STORY-002 (capture-story produces the stories this reconciles).

## Related

- ADR-060 amendment 2026-05-10 line 270 (reverse-trace contract authority).
- RFC-003 (parent RFC).
- Commit `2f3c220`.
