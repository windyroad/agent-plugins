<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: hook-exemption-globs
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: S
---

# STORY-001: Hook exemption globs for docs/story-maps + docs/stories

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred — Slice 14 BLOCKED on marketplace release of this very story)
**Estimated effort**: S

## User value (INVEST Valuable)

As a plugin maintainer building the Phase 2 story-tier framework, I want `docs/story-maps/**/*.html` and `docs/stories/**/*.md` paths exempted from the 4 enforce-edit hooks (architect / jtbd / style-guide / voice-tone) so that the story-map skill bats fixtures can write HTML files without being rejected, and so that the STORY-MAP-001 bootstrap migration can land its HTML scaffold.

## Acceptance criteria (INVEST Testable)

- [x] `docs/story-maps/**/*.html` exempted in architect-enforce-edit.sh case-statement
- [x] `docs/stories/**/*.md` exempted in architect-enforce-edit.sh case-statement
- [x] Same exemption pattern in jtbd-enforce-edit.sh
- [x] Exemption short-circuit BEFORE opt-in extension check in style-guide-enforce-edit.sh
- [x] Same short-circuit pattern in voice-tone-enforce-edit.sh (closes empirical block P170 line 297)
- [x] risk-policy-enforce-edit.sh NOT modified (only gates RISK-POLICY.md; never fires on story-maps/stories)
- [x] 23 new behavioural bats across 4 hook test suites; 159 total tests green; 0 regressions

## Driving problem trace (I6)

**P170** § Slice 14 task body documents the empirical block: STORY-MAP-001 bootstrap migration was attempted 2026-05-12 and BLOCKED by `voice-tone-enforce-edit.sh` on `.html` writes. The hook exemption globs unblock the bootstrap write path for sub-slices 1.5 + 14.

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. Hook exemption is the structural prerequisite for the Phase 2 story-tier framework to ship its bootstrap migration; without it, the framework cannot complete its own meta-recursive proof.

## Implementation notes

Ships across 4 hook source edits + 2 modified bats + 2 new bats (style-guide-enforce-scope.bats, voice-tone-enforce-scope.bats). Takes effect for adopters (including this repo) after the next marketplace release cycle + `/install-updates` + session restart. The exemption globs are NOT live in this session — Slices 3-6 + 14 remain blocked until release.

## Dependencies

- **Blocks**: Slices 3 (capture-story-map), 4 (manage-story-map), 5 (reconcile-story-maps), 6 (list-story-maps), 14 (STORY-MAP-001 bootstrap) — all need the exemptions to ship.
- **Blocked by**: (none)

## Related

- ADR-060 § Phase 2 amendment 2026-05-12 lines 481-496 (mandates the exemption globs).
- RFC-003 (parent RFC).
- P170 line 297 (empirical block documentation).
- Architect AMEND verdict 2026-05-12 finding 1 (load-bearing AMEND on Slice 3 design review).
- Commit `b60f576`.
