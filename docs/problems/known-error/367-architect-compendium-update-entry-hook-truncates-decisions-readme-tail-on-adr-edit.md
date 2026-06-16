# Problem 367: `architect-compendium-update-entry` hook truncates `docs/decisions/README.md` tail when re-authoring an edited ADR's entry

**Status**: Known Error
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

### Findings (2026-06-17, iter-38)

**Root cause confirmed by empirical reproduction.** Investigation isolated the hook's two awk passes from the `claude -p` subprocess and exercised them directly against the live 79-ADR `docs/decisions/README.md`:

1. **The awk cannot truncate well-formed input.** Pass 1 (block deletion) was brute-tested for *every* one of the 79 ADR ids — each deletes exactly one block, no anomaly. Pass 2 (insertion) routes every input line to `print` — it is **purely additive and structurally incapable of dropping a line**. So a clean single ADR body Edit → hook fire on a clean README **does not truncate** (refuting the deterministic-awk-bug hypothesis and confirming the ticket's stated uncertainty: the witnessed tail loss in iters 24/35/36 came from the confounding deprecated-generator regen + tree-reset sequence run in the same sessions, not a clean single hook fire).
2. **But a malformed subprocess emit DOES corrupt the compendium.** Feeding the real hook a pathological `claude -p` result (an entry that also embeds an unrelated `### ADR-999` header and a spurious `## ` section) injected both into the compendium — additive pollution. A wrong-id emit (entry for ADR-049 while editing ADR-050) duplicates 049 and silently drops the edited id. These are the *real, reproducible* data-integrity hazards on the hook's write path.

**The data-loss class is therefore: the hook stages whatever the awk produces with no post-condition check.** Whether the corruption originates from a truncating backstop interaction, a malformed/wrong-id LLM emit, or a future awk regression, the hook had no invariant guard before staging.

### Fix (2026-06-17, iter-38) — committed, pending release verification

Added a **fail-closed structural post-condition guard** to `architect-compendium-update-entry.sh` (investigation task #4, generalised from count-preservation to set+section preservation). Before Pass 1 the hook snapshots the ADR-id set, the `## ` section-header count, and a full backup of the README. After Pass 2, before `git add`, it asserts: the post-state ADR-id set equals the pre-state set (plus exactly the edited id when the ADR is new), the edited id appears exactly once, and the `## ` section count is unchanged. On *any* deviation it restores the original README from the backup, emits a degraded-mode stderr warning, and does **not** stage — the same contract as the existing subprocess-failure path (ADR-078 criterion l): exit 0, never block the body edit; Story B's pre-commit pairing check surfaces the stale README for manual recovery via `wr-architect-generate-decisions-compendium`. A legitimate cross-section status move (e.g. `proposed` → `superseded`) preserves both the id-set and the `## ` count, so it is not misread as corruption (confirmed by the migration bats + architect review).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (Impact likely **High** — silent governance-artifact data loss on the architect's primary read surface — but Likelihood low given clean-input awk is sound)
- [x] **Reproduce** a clean single ADR body Edit → `architect-compendium-update-entry.sh` fire → inspect completeness — DONE: clean input is preserved (79→79); truncation not reproducible from clean state; malformed/wrong-id emit corruption IS reproducible.
- [x] Investigate whole-file-regen vs surgical-patch — DONE: the hook already surgically patches the single entry (claude -p re-authors only one entry; awk patches in place). The whole-file-regeneration risk lives only in the deprecated `wr-architect-generate-decisions-compendium` backstop (P334), not this hook.
- [x] Hook-side post-condition guard — DONE: implemented as a fail-closed set+section preservation guard (stronger than count-only); fail-closed restore-and-degrade, no staging on deviation.
- [x] Create reproduction test — DONE: two behavioural bats added to `architect-compendium-update-entry.bats` (spurious-injection restore + wrong-id restore), RED before the guard, GREEN after; all 14 hook tests pass.

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
