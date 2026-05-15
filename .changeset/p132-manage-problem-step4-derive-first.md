---
"@windyroad/itil": patch
---

manage-problem Step 4 derive-first refactor — second declaration-skill surface (P132 Phase 2a-ii)

Rewrites `/wr-itil:manage-problem` Step 4 (new-problem create flow) from a single "Use `AskUserQuestion` for anything not in `$ARGUMENTS`" instruction to a derive-first dispatch table. Second declaration-skill surface to ship the pattern after `/wr-itil:manage-incident` Step 4 (commit b7cc645, Phase 2a-i) and `/wr-itil:capture-problem` Step 1.5 (P185 worked example).

The dispatch:

- **Title**: derived silently — kebab-case the first 8-10 non-stopword tokens of the user's prose description. Stderr advisory cites the source token sequence. Cat-4 silent-framework.
- **Description**: pulled verbatim from `$ARGUMENTS` prose into the Step 5 `## Description` section. Fallback to `AskUserQuestion` ONLY when `$ARGUMENTS` carries no prose at all — without prose there is literally nothing to capture. This is the ONLY genuine cat-1 direction-setting surface in Step 4.
- **Priority** (Impact × Likelihood): derived silently when description signals map to a clear `RISK-POLICY.md` cell. Impact signals (service-disruption / latency / cosmetic keywords) + likelihood signals (reproducibility vocabulary) + named anchors (`Impact: <label>` / `Likelihood: <label>` / `Priority: <score>` mentions) cross-reference the matrix; clear-cell maps silently with stderr advisory citing the cell + named evidence. Ambiguous-evidence fallback fires `AskUserQuestion` as the genuine ADR-044 category-5 (taste) surface.
- **Reported date / Status / Symptoms / Workaround**: already inferred (today's date / `Open` / verbatim-from-prose / `None identified yet.` default).

Three declaration-skill surfaces now share the I2-isomorphic stderr advisory shape (`<skill>: derived <field>=<value> from <source>; <reversibility-clause>`): `/wr-itil:capture-problem` Step 1.5, `/wr-itil:manage-incident` Step 4, `/wr-itil:manage-problem` Step 4. Architect verdict 2026-05-15 flagged this triplet as the pattern-lock point — the stderr advisory format is now established across three skills before Phase 2a-iii (`/wr-architect:create-adr` argument-collection) extends the same pattern to a fourth.

ADR-026 cost-source grounding: each silent derivation emits a single-line stderr advisory citing the source. AFK fail-safe per ADR-013 Rule 6 preserved — Description-when-absent is the rare halt path under AFK orchestration; the typical AFK manage-problem call carries prose in `$ARGUMENTS` and resolves Title + Priority silently.

Step 4 surface taxonomy: cat-4 silent-framework (Title + Priority-when-evidence-present) + cat-1 direction-setting (Description-when-prose-absent fallback) + cat-5 taste (Priority-when-ambiguous fallback).

Behavioural bats coverage in new file `packages/itil/skills/manage-problem/test/manage-problem-adr-044-step4-derive-first.bats` — 10 assertions:

- cat-4 silent-framework cross-reference
- cat-1 direction-setting fallback cross-reference (Description)
- Title derive-from-prose contract
- Priority derive-from-RISK-POLICY-matrix contract
- Description-retains-AskUserQuestion negative-of-negative guard (regression resistance)
- P132 audit traceability
- ADR-026 stderr advisory shape contract
- cross-skill consistency cross-reference (P185 + manage-incident)
- Step 4b multi-concern AskUserQuestion preservation guard (architect verdict — not touched by Phase 2a-ii)
- Step 2 duplicate-check AskUserQuestion preservation guard (architect verdict — not touched by Phase 2a-ii)

All 10 file-local assertions green; all 168 manage-problem-suite bats green (RED → GREEN flow demonstrated; 7 of 10 RED before the SKILL.md refactor).

Composes with P132 Phase 2a-i (manage-incident Step 4) + P185 (capture-problem Step 1.5) + P136 ADR-044 alignment audit master. Phase 2a-iii (`/wr-architect:create-adr` argument-collection) deferred to a subsequent iter per ADR-014 commit-grain discipline.

Closes P132 Phase 2a-ii (does NOT fully close P132 — Phase 2a-iii stays open as known-error).
