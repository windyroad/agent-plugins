# Problem 278: renderer-package-counts-the-readme-changes convention scope vs P141 per-package source change discipline (ADR-021 boundary clarification)

**Status**: Verification Pending
**Reported**: 2026-05-19
**Released**: 2026-06-03 (docs-only convention clarification — no published-package change)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)

## Description

During session 8 iter 2 (P269), the single-package `@windyroad/itil` changeset initially failed P141 changeset-discipline because plugin.json modifications across 11 plugins count as per-package source changes. The precedent (P0 hotfix `3cfa6fc`) declared all 11 plugins. The "renderer-package-counts" convention only covers README content shifts, not plugin.json field modifications.

The boundary needs clarification in ADR-021 (or .changeset/ conventions document):

- **README content changes** (e.g. compound-rendering output shifts) can ride the renderer's package bump — one changeset entry under the renderer's package suffices.
- **plugin.json field additions / removals** (e.g. populate writes new `rollup_invocations_30d` field on plugin root) MUST declare per-package patches — each modified plugin gets its own changeset entry.

Without this clarification, every populate rerun repeats the changeset-iteration cycle: agent proposes single-package, P141 rejects, agent expands to multi-package.

## Symptoms

(deferred to investigation) — iter 2 (P269) cycle: 4 changeset rewrites before P141 + risk-scorer-external-comms gates both PASSed.

## Workaround

Agent learns the convention by hitting P141 and expanding manually. Repeating cost ~$0.30-0.50 per cycle (multiple re-reviews).

## Impact Assessment

- **Who is affected**: any maintainer + AFK orchestrator iter writing a multi-plugin populate-time field change.
- **Frequency**: every populate rerun on `plugin.json` shape changes.
- **Severity**: (deferred to investigation) — initial: low.

## Root Cause Analysis

The "renderer-package-counts" convention was informal — captured only in retros (2026-05-18-iter-2-p269.md) and ticket bodies, not in any source-of-truth surface that an agent reads at changeset-author time. The convention's content-based boundary (README content vs `plugin.json` field shape) is implicit in `packages/itil/hooks/lib/changeset-detect.sh` — README is allow-listed (continue), `plugin.json` is not — but the AFK orchestrator iter dispatch prompt doesn't cite the hook's allow-list reasoning, so the agent infers the wrong scope.

ADR-021 governs plugin manifest version sync; it is not the right home for changeset-author guidance. The fix lands the rule in `.changeset/README.md` (the canonical changesets meta-doc location), where it is visible to anyone composing a changeset and aligned with the discipline hook's behaviour.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems _(deferred — current rating preserved; this fold-fix does not re-rate)_
- [x] Investigate root cause — read ADR-021 and ADR-058 _(ADR-021 is plugin-manifest-version-sync, not changeset-author conventions; ADR-058 is semver classification, also not the right home)_
- [x] Amend ADR-021 (or write a new convention document) with the boundary clarification _(adopted Option A: docs-only `.changeset/README.md` — no ADR amendment needed)_
- [x] Update `.changeset/` conventions documentation if separate _(created `.changeset/README.md` with the per-package vs renderer-package boundary rule, precedent citation, and ADR/ticket cross-references)_
- [ ] Create reproduction test _(deferred — the rule is documentation-as-contract; the existing `itil-changeset-discipline.bats` suite already exercises the underlying hook behaviour. A behavioural test asserting "an agent reading `.changeset/README.md` will choose the right scope" requires an LLM-in-the-loop harness; deferred to a future iter)_

## Fix Applied

**2026-06-03 (AFK orchestrator iter — Option A path, docs-only):**

Created `.changeset/README.md` documenting:

1. The canonical changesets meta-doc scaffolding (pointer to changesets-action, frontmatter shape).
2. **The per-package vs renderer-package boundary rule** — three branches:
   - README content shifts → renderer's package suffices (one changeset entry).
   - `plugin.json` field additions/removals/value changes → per-package changeset entry.
   - Other source code under `packages/<slug>/` not allow-listed by P141 → per-package changeset entry.
3. The 3cfa6fc precedent (P0 hotfix declared all 11 plugins for plugin.json shape change).
4. Why the rule matters — prevents the agent-proposes-single → P141-denies → agent-rewrites cycle.
5. Cross-references to ADR-021, ADR-058, P141, P278.

No ADR amendment required — Option A explicitly excludes the ADR-021 surface (ADR-021 governs version sync, not changeset-author conventions). No changeset queued — this is a docs-only meta-doc creation, not a published-package change.

External-comms gates (risk-scorer + voice-tone) both PASSed on the draft body (single-fire each).

## Dependencies

- **Composes with**: P141 (changeset-discipline hook), ADR-021 (changeset conventions), ADR-058 (semver classification), the renderer-package-counts convention (currently undocumented as a formal ADR).

## Related

(captured 2026-05-19 from /wr-itil:work-problems session 8 iter 2 (P269) deviation-approval queue, user-directed via AskUserQuestion at Step 2.5)

- P141 — changeset-discipline hook
- ADR-021 — changeset conventions (amendment target)
- ADR-058 — semver classification
- 3cfa6fc — P0 hotfix that established the multi-package-declaration precedent
