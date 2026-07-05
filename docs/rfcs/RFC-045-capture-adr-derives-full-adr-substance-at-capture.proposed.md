---
status: proposed
rfc-id: capture-adr-derives-full-adr-substance-at-capture
reported: 2026-07-06
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P375]
adrs: [ADR-032]
jtbd: [JTBD-008]
stories: []
---

# RFC-045: capture-adr derives full ADR substance at capture

**Status**: proposed
**Reported**: 2026-07-06
**Problems**: P375
**ADRs**: ADR-032
**JTBD**: JTBD-008 (Decompose a Fix Into Coordinated Changes)
**Persona**: developer

## Summary

Eliminate the deferred-placeholder pattern from `/wr-architect:capture-adr`. Today the skill writes `(deferred to /wr-architect:create-adr canonical review)` into Decision Drivers / Considered Options / Consequences / Confirmation / Pros-Cons / Reassessment sections; nothing self-firing triggers that canonical review, so the sections rot (P375 rot test — a named re-entry point is not a self-firing cadence). This is the capture-adr leg of the capture-default fix, sibling to the ADR-067 silent-derivation fix that dropped the `Likelihood: 1 (deferred — re-rate…)` placeholders from capture-problem / capture-story.

New contract (user-directed 2026-07-05, substance confirmed via AskUserQuestion): at capture time the invoking agent derives real content for every MADR section — genuine Decision Drivers, ≥2 real Considered Options (chosen + actually-rejected alternatives from the decision context), real Good/Neutral/Bad Consequences, testable Confirmation criteria, real Reassessment Criteria — with no placeholder/pointer/sentinel strings of any kind. Zero-AskUserQuestion is preserved (ADR-044 category-4 silent derivation, AFK-safe per ADR-013 Rule 6); "lightweight" is redefined as zero-interaction + single-commit, not skimpy content. The only remaining deferral is the already-self-firing one: `human-oversight: unconfirmed` → SessionStart oversight nudge → `/wr-architect:review-decisions` drain per ADR-066, where the human ratifies or amends the derived substance.

Architect review 2026-07-06: substance approved; consequential-edit set fixed by the review (create-adr SKILL.md lines 13 + 64 become false and must be edited; cat-1-interactive vs cat-4-derived-then-ratified reconciliation prose goes in the ADR-032 amendment; compendium regen + P365 truncation check).

## Driving problem trace

- **P375** (Repo conflates a "named re-entry point" with a self-firing cadence — uncadenced deferrals rot): the `(deferred to /wr-architect:create-adr canonical review)` pointer string in capture-adr skeletons is a named re-entry point with no self-firing trigger; P375's audit confirms "the detecting consumer was never built". This RFC eliminates the deferral source; RFC-035 (authoring-time deferral-cadence gate) covers the enforcement half.

## Scope

- Dated amendment to ADR-032's "Foreground-lightweight-capture variant — capture-adr (P156 amendment)" section — derived-substance contract, P199-Option-2-style in-place amendment with dated attribution.
- `packages/architect/skills/capture-adr/SKILL.md` rewrite: template, Rule 6 audit table, composition table.
- `packages/architect/skills/create-adr/SKILL.md` consequential edits (lines 13 + 64 deferred-flagged-sections language).
- `packages/architect/skills/capture-adr/REFERENCE.md` consequential edit.
- `packages/architect/skills/capture-adr/test/capture-adr.bats` behavioural update: generated ADR fixture must match nothing in `DEFERRAL_MARKER_RE` (ADR-052).
- Changeset for `@windyroad/architect`.
- `docs/decisions/README.md` compendium regen (ADR-077) + P365 truncation check.

## Tasks

- [x] T1 — ADR-032 dated amendment (derived-substance contract + cat-1/cat-4 reconciliation prose)
- [x] T2 — capture-adr SKILL.md rewrite
- [x] T3 — create-adr SKILL.md consequential edits (lines 13 + 64)
- [x] T4 — capture-adr REFERENCE.md consequential edit
- [x] T5 — capture-adr.bats behavioural update (no DEFERRAL_MARKER_RE match)
- [x] T6 — changeset @windyroad/architect
- [x] T7 — compendium regen + truncation check
- [x] T8 — P375 task entry recording this leg

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **RFC-035** (Authoring-time deferral-cadence enforcement gate) — the enforcement half of P375; this RFC is a source-elimination sibling.
- **ADR-067** (silent derivation at capture) — the precedent this RFC extends to capture-adr.
- **ADR-066** (human-oversight markers) — the surviving, self-firing deferral channel.
- Residual skeletons ADR-079 / ADR-083 carry the old pattern and stay census-tracked (ADR-084) until expanded — deliberate, per architect note.

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
