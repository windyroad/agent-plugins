---
status: proposed
rfc-id: p355-promptfoo-discharges-r009-bedrock-floor-for-prose-surfaces
reported: 2026-06-04
decision-makers: [Tom Howard]
problems: [P355]
adrs: [ADR-075, ADR-052, ADR-056, ADR-059, ADR-071, ADR-074]
jtbd: [JTBD-001, JTBD-006]
stories: []
---

# RFC-019: P355 — promptfoo Tier-A/B eval discharges the R009 bedrock floor for SKILL/agent-prose surfaces

**Status**: proposed
**Reported**: 2026-06-04
**Problems**: P355
**ADRs**: ADR-075 Amendment 2026-06-02 (promptfoo + SKILL-prose scope — the load-bearing decision; this RFC carries the catalog/agent consequence), ADR-052 (behavioural-tests default — promptfoo Tier-A/B IS the prose-surface behavioural shape), ADR-056 (standing-risk catalog write contract — R009 amendment lands as a catalog entry update), ADR-059 (consume-catalog protocol — pipeline.md is the consumer this RFC extends), ADR-071 (every fix goes through an RFC — why this RFC exists), ADR-074 (substance-confirm-before-build — N/A; no leaf substance to defer, the discharge mechanism is mechanical once ADR-075 + ADR-052 are accepted)
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down — unnecessary holds slow delivery; this RFC removes the floor that justifies them), JTBD-006 (Progress the Backlog While I'm Away — AFK loops accumulated holds on a now-discharged floor)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P355 fix under the RFC-first framework per ADR-071. It carries **no independent architectural decisions** — the substantive choice is already pinned by ADR-075 Amendment 2026-06-02 (SKILL.md prose IS the harness scope; promptfoo IS the harness implementation). What was missing was the catalog/agent acknowledgement that the harness DISCHARGES the R009 prose-surface floor — a mechanical catalog/agent-vocabulary update, not a new decision. Pattern modelled on RFC-015 (P333 retro-fit) and RFC-016 (P344 retro-fit). Status transitions `proposed → in-progress → verifying` alongside the P355 ticket per ADR-022 fold-fix.

## Summary

P355: the risk-scorer agent + R009 standing-risk catalog entry continued to cite "no behavioural harness for the LLM-prose surface (P012)" as an irreducible 8/25 residual floor, even AFTER RFC-012 shipped the promptfoo harness (S6 closed P012) and ADR-075 Amendment 2026-06-02 extended scope to SKILL.md prose. Result: every orchestrator-layer SKILL/ADR-prose change this session (P344, P351, P308, P270) hit 8/25 and got moved-to-holding on a floor the project ELIMINATED. The user's FFS-class correction 2026-06-04: *"FFS we built the harness. Have you forgotten?"*

The fix is mechanical:

1. **R009 catalog amendment** — name promptfoo Tier-A/B as a control row + per-action modulator pair (WITH/WITHOUT paired eval) + discharge clause in the Residual-risk Floor section.
2. **`packages/risk-scorer/agents/pipeline.md` amendment** — extend the R009 control vocabulary for SKILL/agent-prose surfaces with promptfoo Tier-A/B crediting semantics.
3. **Reference slice as discharge evidence** — `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` (this commit's promptfoo Tier-A eval covering the ADR-024 external-comms-gated AFK branching) IS the discharge evidence for the P270 changeset's R009 score. Reinstating the held P270 changeset from `docs/changesets-holding/` is the immediate first application.

## Driving problem trace

- **P355** (`docs/problems/open/355-agent-and-scorer-fail-to-leverage-promptfoo-harness-to-discharge-r009-bedrock-floor-for-agent-prose.md`) — agent + scorer fail to leverage the promptfoo harness (RFC-012/ADR-075) to discharge the R009 bedrock floor for agent/skill-prose changes. Symptom: the floor stays at 8/25 because the catalog text + scorer vocabulary still cite the pre-RFC-012 "no behavioural harness for the LLM-prose surface" justification; result: P344/P351/P308/P270 all moved to holding on a discharged floor. Status: Open → Known Error in the same commit as this RFC's fold-fix per ADR-022 P143.

## User-ratified principle

User FFS-class correction 2026-06-04 (verbatim): *"FFS we built the harness. Have you forgotten?"*

Operational reading: the catalog + agent vocabulary must credit promptfoo Tier-A/B as the behavioural-harness control for the SKILL/agent-prose subset of R009. The floor that justified holding P270 (and any future prose-surface change with paired promptfoo coverage) is no longer load-bearing.

## Scope

(populated; thin RFC carries no leaf substance — see Tasks below for the mechanical surfaces)

- `docs/risks/R009-functional-defects-in-shipped-behaviour.active.md` — Controls table row 2 (promptfoo Tier-A/B) + per-action modulator pair (prose surface WITH/WITHOUT paired eval) + Floor section discharge clause + See-also references to P355/RFC-019/ADR-075 Amendment 2026-06-02.
- `packages/risk-scorer/agents/pipeline.md` — new "R009 control vocabulary — SKILL/agent-prose surfaces (P355 / RFC-012 / ADR-075)" subsection under Control Discovery.
- `docs/problems/open/355-*.md` → `docs/problems/known-error/355-*.md` (fold-fix transition).
- `.changeset/wr-itil-p355-*.md` + `.changeset/wr-risk-scorer-p355-*.md` — paired patch changesets for the two packages whose prose this RFC updates.
- `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` + `run-skill-eval.sh` — first reference slice applying the discharge (lands in the P270 commit grain; cited here as the worked example).

## Decisions carried (none — all choices pinned)

1. **R009 discharge mechanism = promptfoo Tier-A/B** — pinned by ADR-075 Amendment 2026-06-02 (SKILL.md prose IS the harness scope) + RFC-012 (promptfoo IS the implementation). No new decision; this RFC carries the consequence into the catalog + agent vocabulary.
2. **Catalog amendment grain (not new ADR)** — pinned by architect review 2026-06-04 ("the R009 control extension is a within-axis catalog amendment fully scoped under ADR-059 / ADR-056 — no new ADR required"). Catalog + agent prose updates land as catalog/agent refinements, not new ADRs.
3. **Open vocabulary for the modulator** — pinned by ADR-052's broad behavioural-default scope (promptfoo Tier-A AND Tier-B both count) + ADR-042's open-vocabulary precedent (do not enumerate a closed set of "promptfoo eval shapes that count").

## Tasks

- [x] User-ratified principle captured 2026-06-04 (FFS-class correction verbatim above).
- [x] R009 catalog amendment landed (`docs/risks/R009-*.active.md`).
- [x] `packages/risk-scorer/agents/pipeline.md` extended with R009 prose-surface control vocabulary.
- [x] `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` first reference slice authored (lands with P270 commit grain).
- [ ] P355 ticket transitioned Open → Known Error.
- [ ] `.changeset/wr-itil-p355-*.md` + `.changeset/wr-risk-scorer-p355-*.md` patch changesets created.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc with substantive body; mid-iter expansion is permitted under ADR-074 mechanical-stage carve-out since all decisions are pinned by ADR-075 + RFC-012 — no leaf substance to defer)
