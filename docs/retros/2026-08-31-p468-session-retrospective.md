# P468 Session Retrospective

## Briefing Changes

- Updated `docs/briefing/architect-gate-marker-mechanics.md`: removed the obsolete candidate-session marker workaround and recorded the strict bold/H2 verdict contract plus caller-bound completion transport.
- Updated `docs/briefing/README.md`: refreshed that topic's index summary.
- Scanned seven P468-relevant briefing observations; the iteration replaced one stale compound entry, corrected one stale pointer, kept five accurate entries, and left unrelated briefing entries unchanged.

## Signal-vs-Noise Pass

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|----------:|----------:|----------------|----------|
| Canonical architect verdict and supported completion path | `architect-gate-marker-mechanics.md` | 3 | 4 | signal | P468 source reproduction, focused hook tests, and implementation commit `a02e8d0d` replaced the stale manual-marker advice. |
| Candidate-SID enumeration is not oversight authority | `hooks-and-gates.md` | 0 | 1 | signal | The repair preserved exact caller binding and did not widen cross-session authority. |
| The hook must fail closed when parsing reviewer output | `hooks-and-gates.md` | 7 | 8 | signal | Both conflicting verdict orders and malformed, quoted, and narrative output created no markers in 14 focused cases. |
| Codex completion handshake binds the exact reviewer | `external-comms-gate.md` | 1 | 2 | signal | Every fresh reviewer used an exact-role prompt, and the iteration completed each reviewer once through the native transport. |
| A reviewer PASS is not authority to manufacture a marker | `afk-reviewer-spawn-failures.md` | 2 | 3 | signal | The iteration did not manufacture or alter hook JSON, marker files, live hooks, or runtime settings. |
| Lifecycle reconcilers do not catch every literal path | `agent-interaction-patterns.md` | 1 | 2 | signal | The first staged risk review found STORY-MAP-002 still linked P468 under `open/`; regeneration corrected both rendered and canonical references before commit `6a9475fe`. |

**Critical Points changes**: none; the updated architect-marker entry stays in its focused topic file.

## Problems Created or Updated

- P468 (architect-mark-reviewed misses a genuine PASS whose verdict line is a markdown heading rather than bold): moved to Known Error with confirmed RCA, supported workaround, RFC-089/STORY-083 trace, and release boundary. The iteration created no second ticket.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Installed story-map renderer rewrote a shared stylesheet comment while refreshing the P468 lifecycle link | Skill-contract violation | The installed 2.1.2 renderer changed the shared stylesheet; the current canonical template restored it, leaving no stylesheet diff. | The iteration recorded this only under the user's P468-only, no-second-ticket constraint. |
| Existing architect dispatcher suite has a baseline SessionStart assertion failure | Hook-protocol friction | `architect-hook-dispatch.bats` failed only the assertion that `systemMessage` contains both expected phrases; the P468 parser, completion transport, and extracted-package cases passed. | The iteration recorded this only; P468 left the unrelated behavior unchanged. |
| Installed context-budget shim emitted bucket rows without its documented `THRESHOLD` row | Skill-contract violation | `wr-retrospective-measure-context-budget` exited successfully after seven `BUCKET` rows and no threshold. | The iteration recorded this only and continued fail open. |

README inventory currency: clean (14 packages). Legacy RFC scope advisory remains at 7 previously known under-scoped skeletons; the iteration added no P468 artefact to that population.

## Context Usage (Cheap Layer)

Prior snapshot: `docs/retros/2026-08-29-context-analysis.md`. Measurement method: installed `wr-retrospective-measure-context-budget`, byte count on disk.

| Bucket | Bytes | % of measured total | Delta vs prior |
|--------|------:|--------------------:|---------------:|
| problems | 6,801,043 | 57.67% | +73,089 |
| decisions | 2,520,991 | 21.38% | 0 |
| skills | 1,374,322 | 11.65% | +6,189 |
| hooks | 729,181 | 6.18% | +63,416 |
| briefing | 241,257 | 2.05% | +1,852 |
| jtbd | 119,374 | 1.01% | +1,672 |
| project-claude-md | 7,272 | 0.06% | 0 |

Top five measured offenders: problems 6,801,043 bytes; decisions 2,520,991; skills 1,374,322; hooks 729,181; briefing 241,257. Each is an on-disk byte count from the installed diagnostic. No bucket changed by both more than 20% and more than 10 KB; the latest deep report is 2026-08-29, so the cadence trigger is inactive.

Per-plugin breakdown is available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| none | none | none | User direction and installed skill contracts resolved every stage. |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Cross-session trend after this retro: lazy first 0, lazy last 0, delta +0.

## Topic File Rotation

`wr-retrospective-check-briefing-budgets docs/briefing` emitted no `OVER` or `MUST_SPLIT` rows after the focused briefing correction.

## Verification Candidates

None. The source checkout and extracted package passed the focused parser and completion-transport tests, but this iteration did not push, release, refresh, restart, or exercise the package in an installed session. Source-only evidence did not close existing verification tickets that mention the same hook.

## No Action Needed

- The generated Codex completion transport already binds parent session, checkout, reviewer role, and target; P468 did not reimplement or broaden it.
- RFC-089 and STORY-083 already carry the repair, so P468 required no new ADR, job, map, RFC document, or second ticket.
