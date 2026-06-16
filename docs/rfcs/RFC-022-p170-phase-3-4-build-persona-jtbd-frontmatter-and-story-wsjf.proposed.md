---
status: proposed
rfc-id: p170-phase-3-4-build-persona-jtbd-frontmatter-and-story-wsjf
reported: 2026-06-16
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P170]
adrs: [ADR-060, ADR-071, ADR-074, ADR-052, ADR-049]
jtbd: [JTBD-008, JTBD-001]
stories: []
---

# RFC-022: P170 Phase 3 + Phase 4 build — `persona:`/`jtbd:` problem frontmatter + story-level WSJF tie-break

**Status**: proposed
**Reported**: 2026-06-16
**Problems**: P170 (Known Error — problem tickets strain as fixes decompose; need RFC framework. Phase 1 + Phase 2 shipped; Phase 3 + Phase 4 are the remaining in-scope phases per user direction 2026-05-13.)
**ADRs**: ADR-060 (Problem-RFC-Story framework — the ratified Phase 3 + Phase 4 design this RFC sequences; `human-oversight: confirmed`, ratified twice: 2026-05-13 in-scope amendment + 2026-06-02 P287/I12 derive-then-ratify amendment), ADR-071 (every fix goes through an RFC — why this RFC exists; I13 propose-fix-on-Known-Error gate), ADR-074 (confirm decision substance before building — the design substance is already human-confirmed, so the remaining build is authorised, not blocked), ADR-052 (behavioural tests — the persona-enum / jtbd-ID commit-gate validator is an ADR-052 fixture, not a new hook), ADR-049 (PATH shim — any new validator script ships a bin shim)
**JTBD**: JTBD-008 (Decompose a Fix Into Coordinated Changes — primary; P170 is JTBD-008's driver problem; this RFC is the canonical first-class sub-workstream entity for the remaining phased build), JTBD-001 (Enforce Governance Without Slowing Down — secondary; the commit-gate validator is change-set-level governance per the JTBD-review finding-2 composition boundary)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries P170's remaining Phase 3 + Phase 4 build under the RFC-first framework per ADR-071 / ADR-072 / ADR-073 (RFC required at the propose-fix step on a Known Error; auto-created when missing). It carries **no independent decisions** (per ADR-070): every substantive choice — the `persona:` closed enum (`developer | tech-lead | plugin-developer | plugin-user`, scalar, commit-gate-validated), `jtbd:` required on all problems via the I12 derive-then-ratify contract, the `## Related problems` one-way reverse-trace (parallel-existence, no directory merge), and story-level WSJF as a within-RFC tie-break ONLY (stories do NOT join `/wr-itil:work-problems` Step 3 cross-RFC selection) — is already fixed and human-ratified in ADR-060's 2026-05-13 + 2026-06-02 amendments (Decision Outcome P3.2 / P4.1 / P4.2 / P4.3 + § "Phase 3 + Phase 4 commit-grain decomposition"). RFC-022 owns only the dependency-ordered sequencing of the two genuinely-outstanding slices. Pattern modelled on RFC-016 (P344 thin retro-fit). Status transitions `proposed → in-progress → verifying` alongside P170.

## Summary

P170's Phase 3 + Phase 4 are the remaining in-scope phases of the RFC-framework build (Phase 1 RFC tier + Phase 2 story tier shipped 2026-05-12). An actuals sweep on 2026-06-16 found **four of ADR-060's six Phase 3/4 commit-grain slices already shipped uncredited** (P3.1, P4.1, P4.4, P4.5 — largely via the P287 2026-06-02 type-axis-retirement session). This RFC owns only the two genuinely-outstanding slices: **P4.2/P4.3** (`persona:`/`jtbd:` problem-ticket frontmatter + capture-side write + ADR-052 commit-gate validator) and **P3.2** (story-level WSJF within-RFC tie-break). All design is ratified in ADR-060; this RFC adds no decisions, only dependency-ordered sequencing.

## Driving problem trace

- **P170** (Known Error) — the strain pattern: problem tickets buckle as fixes decompose into coordinated multi-change workstreams. Phase 3 (capture-time JTBD-trace + persona anchoring; story-level WSJF) and Phase 4 (JTBD/problem unification via parallel-existence reverse-trace + `persona:`/`jtbd:` frontmatter) are the remaining surfaces that close the unification gap named in the RCA. This RFC is the I13-required propose-fix artefact for that remaining build.

## Reconciliation finding (why this RFC is narrow)

ADR-060's "Phase 3 + Phase 4 commit-grain decomposition" lists six sub-slices. An actuals sweep on 2026-06-16 (P170 work-problems iter) found **four already shipped uncredited**:

- **P3.1 — DONE.** `packages/itil/skills/capture-problem/SKILL.md` Step 1.5b implements the full I12 derive-then-ratify dispatch (lexical `\bJTBD-[0-9]+\b` detection, `--jtbd=` / `--persona=` / `--no-prompt` flags, REJECT/CORRECTION/ACCEPT semantics, AFK halt-with-stderr-directive).
- **P4.1 — DONE (dormant).** `packages/itil/scripts/update-jtbd-references-section.sh` lines 41–54 carry the `Related problems` lookup-table row (`# P170 Phase 4 P4.1 — Related problems reverse-trace from problem`); lazy-empty render preserves one-way coupling. Dormant only because no problem ticket yet carries `jtbd:` frontmatter (waits on Slice 1 below).
- **P4.4 — DONE.** `JTBD-001` + `JTBD-002` both carry `secondary-persona: tech-lead` (oversight-date 2026-05-31).
- **P4.5 — DONE.** `JTBD-301` line 25 carries the maintainer-side complement (added 2026-05-13, amended 2026-06-02).
- **P4.3 I2 regression guard — DONE.** `packages/itil/scripts/test/no-type-regression-guard.bats` asserts no classification-keyed control-flow branch.

The P170 ticket body's Phase 3 + Phase 4 task lines still carry the now-stale "Architect review of ADR-060 § Phase 3/4 amendment required before implementation" gate — that review **is done**; it produced the ratified 2026-05-13 + 2026-06-02 amendments (architect AMEND closed, JTBD PASS). This RFC discharges that framing and owns only the two outstanding slices.

## Scope / Tasks — remaining build (dependency-ordered)

### Slice 1 — P4.2 + P4.3 + I12: `persona:` + `jtbd:` problem-ticket frontmatter + commit-gate validator (foundational)

Builds first because P4.1's reverse-trace (already on disk) is dormant until problem tickets carry `jtbd:` frontmatter.

- [ ] **Frontmatter schema** — extend the problem-ticket frontmatter spec (`docs/problems/README.md` schema section) with a **scalar** `persona:` field drawn from the closed enum `developer | tech-lead | plugin-developer | plugin-user`, an optional scalar `secondary-persona:` (same enum), and a `jtbd:` ORDERED array of `JTBD-NNN` IDs. Required on ALL problems via the I12 derive-then-ratify contract (no type-keyed gating; the type axis is retired).
- [ ] **Capture-side write** — `capture-problem` Step 1.5b already *derives* `persona_value` + `jtbd_trace_value` via **derive-then-ratify (I12 amended 2026-06-02 — NOT the retired hard-block)**; this slice wires the resolved values into the emitted frontmatter so the ticket persists them. (P3.1 resolved the values; this closes the write path.)
- [ ] **Commit-gate validator** — ADR-052 behavioural bats fixture (NOT a new PreToolUse hook per ADR-060 P4.2 "validation fires at commit-gate via ADR-052 behavioural test") asserting: every committed `docs/problems/**/*.md` carries a `persona:` in the enum + a non-empty `jtbd:` array of well-formed `JTBD-NNN` IDs. If a helper script is needed, ship it under `packages/itil/scripts/` with an ADR-049 `bin/` PATH shim regenerated via `scripts/sync-shim-wrappers.sh` (ADR-080).
- [ ] **I2 field-presence uniformity** — extend the preserved `no-type-regression-guard.bats` (or a sibling) to assert the `persona:` field is schema-validation only, never a control-flow key.
- [ ] **JTBD-301 firewall preserved** — the validator gates `docs/problems/**` frontmatter only; it MUST NOT reach into the plugin-user-side `.github/ISSUE_TEMPLATE/problem-report.yml` intake surface (maintainer triage owns persona/JTBD assignment per JTBD-301's maintainer-side complement).
- [ ] **Backfill discipline** — existing problem tickets lack `persona:`/`jtbd:`. Default to grandfather-new-only (validator applies to newly-captured/edited tickets) to keep the slice atomic; capture the one-shot bulk-derive-and-ratify pass as a tracked follow-on. (Grandfather-vs-bulk is pure sequencing of already-decided schema — no new decision.)

### Slice 2 — P3.2: story-level WSJF tie-break key (independent)

- [ ] **`manage-story` SKILL.md extension** — optionally write a `wsjf:` field into story frontmatter; promote I11 from "no WSJF leak" to "story-level WSJF as a **within-RFC tie-break ONLY**". `work-problems` Step 3 traversal stays unchanged — cross-RFC and cross-problem selection remains at problem-level + RFC-level granularity (JTBD-006 AFK orchestrator protection; I5 no-WSJF-leak at the story-map tier preserved).
- [ ] **Behavioural bats** — assert the tie-break fires only within a single RFC's `stories:` array and never surfaces a story into Step 3 cross-RFC selection.
- [ ] **Reassessment Criterion (k)** (ADR-060) governs deprecation if within-RFC tie-break demand never materialises after N=4+ multi-story RFCs.

## Decisions carried (none)

Per ADR-070, this RFC records **no independent decisions**. Every substantive choice listed in Scope is pinned by ADR-060's ratified amendments (Decision Outcome P3.2 / P4.1 / P4.2 / P4.3, I12, and the commit-grain decomposition). Only pure sequencing/breakdown of already-decided work lives here. ADR-074 enforcement-surface-3 (build-on-unratified-ADR) passes: ADR-060 carries `human-oversight: confirmed` and is not superseded.

## Confirmation / verification

- Slice 1 verifies when: a freshly-captured problem ticket persists `persona:` + `jtbd:` frontmatter; the ADR-052 commit-gate fixture fails a ticket with an out-of-enum persona or malformed `jtbd:` ID and passes a well-formed one; P4.1's `## Related problems` reverse-trace renders non-empty for a JTBD once ≥1 problem cites it; the JTBD-301 plugin-user firewall is asserted untouched.
- Slice 2 verifies when: `manage-story` writes `wsjf:` on demand; the behavioural fixture asserts within-RFC-only tie-break and no Step 3 leak.
- **Phase 3 + Phase 4 ride a held-changeset window per ADR-042 / P162** until end-of-chain user verification; the window stays paused per ADR-042 auto-apply until both slices land + P170 reaches its Known Error → Verification Pending transition.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12.)

## Related

- **P170** — driver problem ticket (`docs/problems/known-error/170-...md`); RFC-022 owns its remaining Phase 3 + Phase 4 build.
- **ADR-060** — the ratified design; this RFC adds NO design, only sequencing.
- **RFC-001 / RFC-002 / RFC-003** — prior P170-lineage RFCs (Phase 1 retro-migration, Phase 1 forward-dogfood, Phase 2 story-tier framework). RFC-022 is the Phase 3 + Phase 4 sibling.
- **JTBD-008** — `## Related problems` lists P170 as its driver; RFC-022 closes the capture-time decomposition loop the job declares.

Run `/wr-itil:manage-rfc RFC-022` next to advance to `accepted` (substance-confirm + INVEST/scope pass) and refresh `docs/rfcs/README.md`.
