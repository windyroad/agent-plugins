# Problem 367: `architect-compendium-update-entry` hook truncates `docs/decisions/README.md` tail when re-authoring an edited ADR's entry

**Status**: Open
**Reported**: 2026-06-16
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The `architect-compendium-update-entry.sh` PostToolUse hook (ADR-078 Option 9 / RFC-014 Phase 1 Stories A+B+D) re-authors an edited ADR's `docs/decisions/README.md` compendium entry via a `claude -p` subprocess on every ADR body Edit. During the P358 fix (iter-29, 2026-06-16), after a body Edit to `docs/decisions/032-...proposed.md`, the **staged** `docs/decisions/README.md` (written by the hook) showed the ADR-032 entry correctly re-authored with an updated `**Decides:**` line BUT the file's **tail was truncated** — `git diff --cached` reported `@@ -306,93 +306,3 @@`, dropping ~93 lines including the ADR-073 and ADR-074 entries (and the historical-ADR tail). The ADR-032 entry update was correct; the rest of the file was lost. This is **silent governance-artifact data loss**: a single ADR edit can drop unrelated compendium entries, and because the hook stages the result, an unwary commit would ship a truncated compendium.

**Uncertainty / needs reproduction confirmation**: the observation was made once, during a session in which the deprecated full-render backstop (`wr-architect-generate-decisions-compendium`) was also run several times and the working tree was reset/regenerated, so there is a non-zero chance the truncation was an artefact of the interacting regen/reset sequence rather than a clean single-fire of the hook. Investigation must reproduce a clean single ADR body Edit → hook fire → inspect whether the staged README is complete (79 ADRs) or truncated, before asserting the root cause.

**Why this matters even if intermittent**: the compendium is the architect agent's primary read surface (ADR-066/ADR-078); a truncated compendium silently removes "current rules" the architect relies on. A re-authoring hook that does not preserve the full file is a correctness hazard for the whole governance loop.

## Symptoms

(deferred to investigation)

- Observed once: `git diff --cached docs/decisions/README.md` after an ADR-032 body Edit showed the ADR-032 entry updated (`**Decides:**` added) AND a 93-line tail deletion (`@@ -306,93 +306,3 @@`) dropping ADR-073/074+ entries.
- The deprecated full-render `wr-architect-generate-decisions-compendium` produced a complete 79-ADR file (70 in-force + 9 historical) with no diff vs HEAD — so the complete content is recoverable; the loss is specific to the hook's incremental re-author path.

## Workaround

(deferred to investigation)

- `git checkout HEAD -- docs/decisions/README.md` to discard the hook's truncated staged version, then `wr-architect-generate-decisions-compendium` (deprecated backstop) to regenerate the complete file. The complete file was committed; the truncated version was NOT shipped.
- Always inspect `git diff --cached docs/decisions/README.md` for unexpected tail deletions before committing an ADR body edit until the root cause is confirmed.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — maintainers editing ADR bodies; the architect agent reading the compendium.
- **Frequency**: (deferred to investigation) — observed once; reproduction not yet confirmed.
- **Severity**: (deferred to investigation) — potentially High (silent governance-artifact data loss) if confirmed reproducible.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Reproduce** a clean single ADR body Edit → `architect-compendium-update-entry.sh` fire → inspect the staged `docs/decisions/README.md` for completeness (79 ADRs) vs truncation. Confirm or refute the hook-truncation hypothesis before asserting root cause.
- [ ] If confirmed: investigate whether the `claude -p` re-author subprocess regenerates the whole file (and can truncate on long output / token limits) vs surgically patching the single entry. A surgical sed/awk patch of only the target entry would eliminate the whole-file-regeneration truncation risk.
- [ ] Consider a hook-side post-condition guard: assert the re-authored README still contains the same ADR-entry count as before the edit (±1 for the edited entry); fail-closed (do not stage) if the count drops.
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P337 (RFC-014 Phase 1 — the ticket that shipped this hook; a truncation bug would be a regression on its work), P334 (deprecated full-render awk portability — the backstop used as workaround).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P337** (`docs/problems/verifying/337-...md`) — RFC-014 Phase 1 driver; shipped `architect-compendium-update-entry.sh` (Stories A+B+D) in `@windyroad/architect@0.17.0`. This truncation is a candidate regression on that shipped hook, captured separately because it is a distinct data-loss defect (not the decision-outcome-extraction-completeness concern P337 addresses).
- **P334** (`docs/problems/.../334-...md`) — deprecated `wr-architect-generate-decisions-compendium` awk portability; that script is the full-render backstop used as the workaround here.
- **P349** (`docs/problems/.../349-...md`) — ADR-040 confirmation-field-stale needing compendium regen; same compendium surface, different concern (content staleness vs structural truncation).
- **ADR-078** (Option 9 — architect-authored compendium on every ADR edit) + **RFC-014** — the design this hook implements.
- Hang-off check (PROCEED_NEW): the surfaced compendium candidates (P334/P337/P349) all concern compendium *content* (extraction quality, awk portability, stale fields); this ticket is a distinct *structural truncation / data-loss* defect on the hook's write path. Re-evaluate absorb-vs-sibling at next /wr-itil:review-problems.
