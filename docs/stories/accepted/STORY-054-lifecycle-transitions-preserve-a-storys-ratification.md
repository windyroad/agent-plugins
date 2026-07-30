---
status: accepted
story-id: lifecycle-transitions-preserve-a-storys-ratification
reported: 2026-07-29
decision-makers: [Tom Howard]
problems: [P474]
jtbd: [JTBD-001, JTBD-006, JTBD-009]
rfcs: [RFC-059]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: confirmed
oversight-hash: d09a9356c890691096778bc060ac430814b233ec6070a14856721705fb40d7cc
---

# STORY-054: Lifecycle transitions preserve a story's ratification

**Reported**: 2026-07-29
**Problems**: P474
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I'm Away), JTBD-009 (Migrate Adopter Artefacts When a Plugin Layout Evolves)
**RFCs**: RFC-059
**Story Maps**: STORY-MAP-002 (Decompose a Fix Into Coordinated Changes)
**Estimated effort**: M

<!-- No `**Status**:` body line, deliberately. Duplicating the frontmatter
     `status:` here is the defect this story fixes: the oversight fingerprint
     excludes the frontmatter key but hashed the body copy, so advancing a story
     un-ratified it. See the ADR-090 amendment 2026-07-29. -->

## User value (required, INVEST Valuable)

In order to trust that ratifying a story still means something after I advance it, as a developer accepting a story so it can be implemented, I want a lifecycle transition to leave my ratification intact — so accepting the story I just approved does not silently un-approve it and then block its own implementing commit.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] The story template carries no body line duplicating the frontmatter `status:`, and an inline note records why it must not be reintroduced.
- [x] A migration removes the duplicate from existing story artefacts and re-points each artefact's fingerprint, without ever writing `human-oversight`.
- [x] The migration leaves an already-drifted artefact drifted rather than reviving it — verified against the real corpus, where all 12 confirmed-but-drifted stories were drifted at `HEAD` before the migration ran.
- [x] The migration skips and reports any artefact whose body line disagrees with its frontmatter, because such a line carries information the frontmatter does not.
- [x] `oversight-basis:` survives the migration, so the ADR-101 post-hoc drain still surfaces AFK-accepted stories.
- [x] The migration is idempotent, and reports every artefact it touches so the re-fingerprint set is auditable from the commit that ran it.
- [x] A genuine substance edit still drifts the fingerprint after the change — the fix narrows what counts as substance, it does not weaken drift detection.
- [x] The migration ships PATH-shimmed per ADR-049 so an adopter corpus can run it, not only this repo's.

## Driving problem trace (required — I6 invariant)

**P474** — story lifecycle state was stored twice (frontmatter `status:` and a `**Status**:` body line) and the oversight fingerprint excluded only the first. So a `draft → accepted` transition changed hashed content: the story read as unratified immediately after being ratified, and `itil-no-implement-draft-gate` denied its own implementing commit. Both hash functions carried the omission. Shipped in `@windyroad/itil@0.60.0`; hit live 2026-07-29 when STORY-047 had to be re-ratified purely to clear it.

## JTBD trace (required — I9 invariant)

Serves **JTBD-001** (Enforce Governance Without Slowing Down): a gate that blocks legitimate work is the "manually police the framework" friction this job exists to prevent. The ratification step was doing real work — and then immediately undoing itself, so the developer paid the ratification cost twice per story and the second payment bought nothing.

Secondary **JTBD-006** (Progress the Backlog While I'm Away): an unattended loop cannot re-ratify, so the same defect turned every accepted story into a hard stop. Sharper still, it nullified an outcome JTBD-006 had gained three days earlier — the AFK-accept carve-out is justified on the grounds that the gate it relaxes "was not slowing the loop down, it was stopping it", and a machine-accepted story failed the no-implement gate at the very moment it was accepted. Acceptance criterion 5 (preserving `oversight-basis:`) is what keeps that outcome reachable.

Also **JTBD-009** (Migrate Adopter Artefacts When a Plugin Layout Evolves): adopter story corpora carry the mirror too, so the fix is not complete until an adopter can remove it from their own artefacts. Criterion 8 is that leg — the migration ships PATH-shimmed per ADR-049 rather than source-repo-only. This is the intra-file-contract case that job's scope was amended to cover — amended 2026-07-29, re-ratified 2026-07-30: a body line the plugin's own tooling now reads differently, which is neither a structural move nor a content-currency update.

## Implementation notes

Removal over normalisation was the maintainer's call on 2026-07-29, against both alternatives. The deciding argument was class-vs-instance: this was the fourth lifecycle mirror in a family of three with a fifth anticipated, so normalising means one rule per mirror indefinitely. The consequence that made it cheaper as well as cleaner is that no hash function changes, so no already-stored fingerprint is invalidated when the fix reaches an adopter.

The migration's safety rests on re-fingerprinting never being re-ratifying: `human-oversight: confirmed` asserts a human event and is never written; `oversight-hash` asserts none, identifying only which content that event covered. That argument is narrow, not general — it holds because the removed line is a mechanical mirror of an already-excluded field, so the delta is information-free. Both guards exist to keep it that way.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P474** (driving problem), **RFC-059** (fix vehicle), **STORY-MAP-002** (the map), **ADR-090** (the corrected fingerprint contract), **ADR-101** (`oversight-basis` preservation), **ADR-049** (the PATH shim).
- **P465** made the defect observable; **P404 / RFC-037** introduced the machinery and is deliberately not reopened (it is `verifying`, an irreversible state per ADR-060).
