---
status: proposed
rfc-id: rfc-lifecycle-self-maintenance
reported: 2026-06-25
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P378]
adrs: []
jtbd: []
stories: []
---

# RFC-030: RFC lifecycle self-maintenance

**Status**: proposed
**Reported**: 2026-06-25
**Problems**: P378
**ADRs**: (none yet — a thin ADR for Piece 1 lands in its slice)
**JTBD**: (none)

## Summary

Make the RFC framework self-maintaining so updating an RFC never leans on human memory (P378). Architect design-reviewed; user decisions locked 2026-06-25.

**Three pieces** (each its own ADR-014 commit carrying `Refs: RFC-030`):

1. **`## Commits` is a derived view** (locked: Option A). Rendered from `git log --grep "Refs: RFC-NNN"` by `manage-rfc` (every transition/review) + `reconcile-rfcs.sh` — like `docs/problems/README.md` is a rendered index (ADR-031). Nothing written per-commit → no ADR-014 grain problem. A thin ADR records the "in-body section = git-log projection + skill-side render trigger" decision (cites ADR-031/014/084). Fixes capture-rfc's false "maintained automatically" claim (P234/P375 fictional-defer class).
2. **Auto-transition** via a SHARED commit-trailer-trigger (architect: `manage-story`'s auto-transition is *also* unbuilt — same false-auto claim). A PostToolUse:Bash detector recognises `Refs: RFC-NNN` / STORY trailers and advises/enqueues the transition; the skill performs the `git mv` + commit (ADR-014: hook detects, skill commits). manage-rfc mirrors manage-story's state machine (ADR-060 line 292). Retro-fits manage-story's false-auto claim in the same pass.
3. **RFC-oversight nudge** — a SessionStart class-B self-surfacer cloning `architect-oversight-nudge.sh` / `jtbd-oversight-nudge.sh` (ADR-066/068): surfaces RFCs with `human-oversight: unconfirmed` so ratification is auto-surfaced, not remembered. No new ADR.

## Driving problem trace

- **P378** — RFC lifecycle is not self-maintaining (Commits section never auto-populated, no auto-transition, no oversight nudge); it leans on human memory. This RFC builds the self-maintenance.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

- `2863308e` feat(itil): RFC-030 Piece 3 — RFC-oversight SessionStart nudge (P378) — 2026-06-25
- `96b0c903` docs(rfcs): capture RFC-030 RFC lifecycle self-maintenance — 2026-06-25

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
