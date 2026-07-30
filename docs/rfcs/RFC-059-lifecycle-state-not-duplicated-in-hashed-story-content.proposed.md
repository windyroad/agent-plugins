---
status: proposed
rfc-id: lifecycle-state-not-duplicated-in-hashed-story-content
reported: 2026-07-29
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P474]
adrs: [ADR-090, ADR-101, ADR-049]
jtbd: [JTBD-001, JTBD-006, JTBD-009]
stories: [STORY-054]
---

# RFC-059: Lifecycle state is not duplicated inside hashed story content

**Status**: proposed
**Reported**: 2026-07-29
**Problems**: P474
**ADRs**: ADR-090, ADR-101, ADR-049
**JTBD**: JTBD-001, JTBD-006, JTBD-009

## Summary

Story lifecycle state was stored twice — once in frontmatter `status:`, once in a `**Status**:` body line — and the oversight fingerprint excluded the first but hashed the second. Remove the duplicate rather than teach the fingerprint to ignore it, and migrate existing artefacts without manufacturing any ratification.

## Driving problem trace

**P474** (Open) — the fingerprint's exclusion of lifecycle state was half-implemented: it covered the frontmatter key and criterion ticks but not the body mirror, so advancing a story from `draft` to `accepted` changed hashed content. A story the maintainer had ratified minutes earlier read as unratified, and the no-implement gate then denied that story's own implementing commit. Both hash functions carried the omission. Shipped in `@windyroad/itil@0.60.0`; hit live 2026-07-29 when STORY-047 had to be re-ratified purely to clear it. Two detectors read the same fingerprint, so both reported a story as needing ratification seconds after it got it.

## Scope

Remove the mirror. Lifecycle state lives in frontmatter `status:` only and is never duplicated inside content-hashed body prose. The `**Status**:` line comes out of the story template with an inline note recording why it must not return, and out of the existing corpus.

The alternative — adding a normaliser rule so the fingerprint ignores the body line — would also have worked, and was the reviewing architect's initial lean. It was rejected on the maintainer's direction (2026-07-29) because this was the fourth lifecycle mirror in a family of three with a fifth already anticipated: normalising means one rule per mirror, indefinitely, while removal ends the class.

Removal has a property the normalise path lacked. Because no hash function changes, no already-stored fingerprint is invalidated when the fix reaches an adopter — only artefacts still carrying the mirror need migrating at all.

Migration ships as `wr-itil-migrate-story-status-mirror`, PATH-shimmed per ADR-049 so adopter corpora can run it; a source-repo-only migration would be the P151/P317 dogfooding blind spot, since adopter stories carry the mirror too. It removes the line and carries each artefact's existing ratification forward by **re-fingerprinting, never re-ratifying**: `human-oversight: confirmed` records that a human confirmed something and is never written, while `oversight-hash` records no event at all and only identifies which content that confirmation covered. Recomputing the pointer over content whose sole delta is a mechanical mirror of an already-excluded field removes zero ratified substance. That argument is not a general licence for hash changes — it holds here only under two guards: a per-artefact validity gate, so an artefact whose stored hash no longer matches is left drifted rather than revived; and a mirror-agreement precondition, so a body line disagreeing with its frontmatter is skipped and reported for a human rather than deleted, because such a line is carrying information the frontmatter does not.

Deliberately out of scope, and recorded on P474 instead: extracting the duplicated grep/sed filter the two hash functions share. It is real duplication and it is why the omission occurred twice, but neither filter is touched under the chosen approach, so claiming it here would overstate what this change does.

### Adopter migration — two documented deviations from JTBD-009

This carries **JTBD-009** (Migrate Adopter Artefacts When a Plugin Layout Evolves), because the migration exists for adopter corpora rather than only this repo's — `reconcile-stories.sh` reads the adopter's own `docs/stories/README.md`, so an adopter left on the old template would hand-author the mirror straight back in and re-trigger P474. The case sits at the edge of that job's stated scope: JTBD-009 scoped itself to an artefact's *structural* shape (one file vs. many, flat vs. nested, legacy filename vs. new directory) and this is an intra-file contract change, none of those three. Rather than exclude it on a technicality, the job's scope was amended (2026-07-29, re-ratified 2026-07-30) to cover intra-file contract alongside structure, and to demote the three structural cases to illustrations rather than an exhaustive test. Two deviations from its outcomes remain, both recorded there and repeated here:

- **No `/wr-itil:migrate-<artefact>` skill wrapper.** The migration ships as a script plus PATH shim only. It takes no decisions and has no interactive branch, so a skill wrapper would add a governance surface with nothing to govern. The amended outcome now makes the carrier conditional on there being a decision to govern — and attaches an obligation this RFC discharges: because a shim does not surface in autocomplete the way a slash command does, the release notes MUST carry the invocation. A prior wrapper-less migration (`wr-itil-migrate-problems-layout`) had already shipped against this job unrecorded, which is what let the job text drift behind its own realisations.
- **No legacy-artefact preservation.** JTBD-009 expected the pre-migration artefact retained on disk. For a line-level edit that is not merely redundant but wrong: git preserves it exactly, and a retained duplicate story file would share a `story-id` with the original, so both copies would be fingerprinted and both would drift — the preservation outcome would work against the very contract this RFC establishes. The amended outcome now conditions preservation on the artefact not being recoverable from git.

## Confirmation

Corpus run 2026-07-29: 31 mirrors removed, 7 re-fingerprinted with ratification preserved, 3 skipped and hand-resolved (two stories whose body line carried provenance or a transition date, plus `README.md`, which documents the template and is now outside the scan). The 12 confirmed-but-drifted stories were verified drifted at `HEAD` **before** the migration ran, so the validity gate demonstrably revived nothing. A re-run is a no-op. Both template carriers are clean — `grep -rn '^\*\*Status\*\*:' docs/stories/` returns zero across artefacts and the README, and the `capture-story` template carries zero.

Verified end-to-end on a real ratified story: the accept transition preserves ratification, criterion ticks preserve it, and a genuine substance edit still drifts — the fix narrows what counts as substance without weakening drift detection, which is the `developer` persona's "the plugins must carry the guardrails regardless" constraint.

67 tests green across the migration suite, the oversight lib, the marker shim, the AFK-accept predicate and `capture-story`.

## Commits

(rendered from `git log --grep "Refs: RFC-059"` per ADR-085 — at capture there are no commits yet.)

## Related

- **P474** — the driving problem.
- **ADR-090** — the oversight fingerprint this corrects. Carries the 2026-07-29 amendment, plus a separate retroactive record: the 2026-07-03 narrowing of "any change" to "any substance change" had never been recorded in the decision, nor put to the maintainer as a decision at all. It was ratified 2026-07-30 in an isolated ask with both options in view, and the Decision Outcome text reconciled in the same commit — so the rule of record and the rule in force finally agree.
- **ADR-101** — `oversight-basis:` must survive the migration, or the post-hoc drain stops surfacing AFK-accepted stories.
- **P404 / RFC-037** — delivered the fingerprint machinery on 2026-07-03; where the omission originated. Deliberately NOT reopened: RFC-037 is `verifying`, which ADR-060 classifies as an irreversible transition, and adding implementation scope would make the artefact its verifier is verifying a moving target.
- **P465** — made the latent defect observable by requiring a matching hash at the implementing commit. Did not cause it.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
