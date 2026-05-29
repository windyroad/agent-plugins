---
status: "proposed"
date: 2026-05-30
human-oversight: confirmed
oversight-date: 2026-05-30
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-08-30
---

# Generated `docs/decisions/README.md` compendium as token-cheap load surface for routine architect-agent compliance

## Context and Problem Statement

The `wr-architect:agent` reads every ADR body on every project-file edit to perform compliance review (`packages/architect/agents/agent.md` Step 1: *"Read all existing decisions in `docs/decisions/` (glob for `*.md`, skip `README.md`)"*). With 76 ADRs accumulated (top-5 bodies ranging 38–92 KB each — see P194), this load dominates session token usage in adopting projects. P327 (inbound report from external adopters; ADR-076 Tier 1) measures the cost at **>50% of total session tokens** in adopting-project sessions and tags it as the highest-priority token-burn issue.

The full ADR body is high-value for some surfaces — `/wr-architect:create-adr` authoring, `/wr-architect:review-decisions` ratification drain, `/wr-architect:capture-adr` skeleton + deep-dive review, an explicit body-grep on a specific ADR — but routine compliance only needs the **chosen option + binding constraints** of each prior decision. Loading full bodies for routine compliance is a wasteful default that the architect-agent load contract has carried since inception.

A scope correction sharpens the design: only `wr-architect:agent` body-reads ADRs. `wr-jtbd:agent` consumes `docs/jtbd/` (not `docs/decisions/`); `wr-risk-scorer:wip` enumerates `docs/decisions/*.md` as a **path-list** for governance-artefact diff-detection (not body reads). The architect agent is the **single dominant ADR-body consumer**, so designing a token-cheap load surface for it captures essentially all the win.

A decision is needed now because the inbound report has reached Tier 1 (ADR-076 routing), the user has marked it the highest-priority token-burn issue, and the work to design and ship a fix is in flight in the same session this ADR is being written.

## Decision Drivers

- **Customer-service / feedback-signal preservation** — P327 is a Tier 1 inbound report per ADR-076; ignored reporters stop reporting and churn. Shipping a token-cost fix demonstrates responsiveness.
- **Token efficiency in the architect-agent load path** — >50% of session tokens currently spent on `docs/decisions/` in adopting projects. Shipping a compact load surface is the single highest-leverage token-reduction action available.
- **Single source of truth on ADR substance** — the per-ADR body remains the authoritative record; the compendium is a derived/cached view (ADR-031 authoritative-state principle).
- **Drift safety via the marker-pattern precedent** — the codebase already has a load-bearing drift-tripwire shape (P138 tie-break ladder, P150 VQ-sort direction, P186 likely-verified cell shape). The compendium-vs-bodies coupling is the same shape; the same pattern applies (greppable marker + drift-detection bats + commit-time enforcement hook).
- **Architectural consistency** — ADR-031 already establishes `docs/problems/README.md` as a generated rendered index of per-ticket files. This decision applies the same pattern at the ADR-prose surface.
- **Auditable extraction** — MADR 4.0 mandates `## Decision Outcome` and `## Confirmation` sections; both are stable enough to extract programmatically from existing ADR bodies.
- **Migration tractability** — auto-generate a first cut from existing `## Decision Outcome` + `## Decision Drivers` + `## Confirmation` sections; hand-confirm each ADR's compendium entry via the `/wr-architect:review-decisions` drain (the canonical "interactive human-confirm sweep for ADR frontmatter"; per the MEMORY `feedback_lift_auto_decisions_to_human.md` discipline).
- **Enforcement, not honour-system** — the user has signaled the compendium must be **enforced** fresh, not relied on by convention. The P165 README-refresh-discipline hook precedent (`itil-readme-refresh-discipline.sh` that DENIES commits staging a problem ticket without a refreshed `docs/problems/README.md`) is the established enforcement shape; the same shape applies here.

## Considered Options

1. **Per-ADR `summary:` frontmatter field** — agents read frontmatter only by default; full body on deep-dive. Smallest migration touch-surface; mirrors ADR-066's grep-cheap frontmatter precedent.
2. **Generated `docs/decisions/README.md` compendium** — one generated file lists every ADR's chosen option + binding constraints. Direct precedent in ADR-031 problem-ticket README-as-rendered-index. Biggest single-load token win.
3. **Separate `<NNN>-<slug>.summary.md` sibling files per ADR** — sibling file alongside each ADR. Doubles file count (76 → 152); every glob site needs explicit include/exclude — largest migration touch-surface.
4. **`## Summary` section at the top of each ADR body** — markdown convention. Agent.md Read tool doesn't natively parse "read until first `##` after Summary" — largest agent-load mechanism change.

## Decision Outcome

Chosen option: **"Generated `docs/decisions/README.md` compendium"** (option 2), because it delivers the largest single-load token win (one file vs N), has a direct precedent in the codebase at a sibling surface (ADR-031's problem-ticket README), and the generated-artifact drift risk is fully addressable via the established marker-pattern precedent (P138 / P150 / P186 ladder drift contracts) plus the established commit-time enforcement precedent (P165 README-refresh-discipline hook).

**Amendment 2026-05-30 (substance refinements during Slice 1 / Slice 2 implementation):**

1. **Two-section format.** The compendium contains all ADRs split into two sections: **In-force decisions** (`proposed` + `accepted`) — the current rules to follow — and **Historical decisions** (`superseded` + `rejected` + `deprecated`) — direction for what NOT to do, useful when reviewing a proposed change that re-treads a path already tried or that conflicts with a superseded decision's still-valid intent. The status badge on each entry says which kind it is. (Initial cut filtered superseded out entirely; reverted on user direction — superseded entries are valuable as cautionary direction.)
2. **Skills and architect agent are PRIMARY; enforcement hook is SAFETY NET.** `/wr-architect:create-adr`, `/wr-architect:capture-adr`, `/wr-architect:review-decisions`, and the `wr-architect:agent` reviewer keep the compendium fresh by invoking `wr-architect-generate-decisions-compendium` at the right point in their flows (decision-time authoring, ratification, status transition). The commit-time PreToolUse hook `architect-compendium-refresh-discipline.sh` exists to catch edits that bypass the skill/agent flows (hand-edits via Edit/Write, off-skill bulk renames, direct file modifications) — it is the cracks-catcher, NOT the primary mechanism. See Confirmation items (d)–(h) below for the per-surface split.

**Compendium content (per-ADR entry).** Compact: ID + Title + Status + Chosen Option (one line) + Decision Drivers (short list) + Confirmation criteria (one line each) + Relationships (amends/extends/relates/composes — IDs only). **Excludes**: Considered Options bodies, Pros and Cons of the Options, Consequences narrative, Reassessment Criteria, full Context. Those stay in the per-ADR body for deep-dive surfaces.

**Architect agent load contract (amended).** `packages/architect/agents/agent.md` Step 1 changes from *"Read all existing decisions in `docs/decisions/` (glob for `*.md`, skip `README.md`)"* to: *"Read `docs/decisions/README.md` — the generated compendium of every ADR's chosen option, drivers, confirmation criteria, and relationships. Load a specific ADR's full body only when the routine compendium entry is insufficient for the current review (deep-dive on a contested change, evolving a decision, ratifying a new ADR)."*

**Generation.** A new script `packages/architect/scripts/generate-decisions-compendium.sh` reads every `docs/decisions/<NNN>-*.md` file, extracts the per-entry fields from frontmatter + `## Decision Outcome` + `## Decision Drivers` + `## Confirmation` + `## Related` sections, and emits the compendium. Distributed via the ADR-049 `$PATH` shim at `packages/architect/bin/wr-architect-generate-decisions-compendium` so skills/hooks invoke it without repo-relative paths.

**Enforcement (commit-time hook + CI bats).** Two layers, mirroring the established P138/P165 enforcement pattern:

1. **Commit-time PreToolUse hook** `packages/architect/hooks/architect-compendium-refresh-discipline.sh` — when `git commit` stages any `docs/decisions/<NNN>-*.md` file, the hook DENIES the commit unless `docs/decisions/README.md` is also staged AND matches the generator output for the staged ADRs. Mirrors `packages/itil/hooks/itil-readme-refresh-discipline.sh` (P165) for the decisions surface. Honour-system convention will drift; commit-time denial is the established enforcement shape in this codebase.
2. **CI drift-detection bats** `packages/architect/scripts/test/generate-decisions-compendium.bats` — fails CI when the committed compendium does not match the generator output for the committed ADR bodies. Defence-in-depth in case the hook is bypassed or fails open.

**Migration.** Auto-generate first-cut compendium entries for all 76 existing ADRs in the same change-set that ships this ADR. Subsequent `/wr-architect:review-decisions` drain passes confirm each entry alongside the existing `human-oversight: confirmed` marker — folding the summary-confirm into the same `AskUserQuestion` doubles the value of each interactive confirm without doubling the friction.

**Per-decision-time authoring.** `/wr-architect:create-adr` Step 4 + Step 5 extended to regenerate the compendium when a new ADR lands and to write the compendium update into the same commit as the new ADR file. `/wr-architect:capture-adr` extended similarly. The commit-time enforcement hook is the load-bearing safety net behind both.

## Consequences

### Good

- Architect-agent token spend on `docs/decisions/` drops from ~2 MB (76 full bodies) to ~10–50 KB (one compendium) — a >40× reduction in the routine load path.
- The compact compendium is itself an auditable, browsable index — adopters scanning "what decisions exist" get a useful one-file overview rather than 76 file links.
- Full ADR bodies stay authoritative; deep-dive surfaces (create-adr, review-decisions, capture-adr, explicit body-grep) keep their richness.
- The enforcement machinery prevents the predictable failure mode (compendium drifts from bodies and silently misleads the architect agent).
- Built-in mitigation for P194 (forward-chronology evidence accumulation in ADR bodies) — even when bodies grow, the routine load path no longer pays for it.

### Neutral

- The compendium is generated, not authored. Cross-references like *"per ADR-066"* in code still link to the per-ADR file, not the compendium entry — the compendium is for the architect-agent's routine load, not for human authorship.
- The compendium's per-entry format is intentionally compact and may discard nuance some reviewers want at-a-glance. Deep-dive surfaces close that gap by design.

### Bad

- A drift surface is introduced. Mitigated by the two enforcement layers (commit-time hook + CI bats), but anyone bypassing the hook AND skipping CI could ship a stale compendium.
- Migration touches every existing ADR (76 entries to seed + ratify). Mitigated by auto-generation of first cut + drain-based human confirm.
- One more script + one more hook + one more bats to maintain. Tolerable given the proven enforcement pattern (P165) is being mirrored.
- The new generator script needs to handle the full range of historical ADR formatting (some ADRs predate the strict MADR 4.0 template); fallback to "extract whatever's there + flag for hand-touch" is the safe shape.

## Confirmation

This decision amends the `wr-architect:agent` load contract and introduces a new drift-controlled rendered-index surface. Implementation is verified when ALL of the following are present in the same change-set (the drift contract holds when all surfaces move together; line numbers are source-verified anchors and may shift):

- [ ] **(a) Agent prompt amendment** — `packages/architect/agents/agent.md` Step 1 (~:20) carries the new load contract: read `docs/decisions/README.md` by default; full body only on deep-dive.
- [ ] **(b) Generator script** — `packages/architect/scripts/generate-decisions-compendium.sh` exists and is idempotent (running it twice produces identical output). Distributed via ADR-049 `$PATH` shim at `packages/architect/bin/wr-architect-generate-decisions-compendium`.
- [ ] **(c) Initial generated compendium** — `docs/decisions/README.md` exists, contains an entry for every `<NNN>-*.md` ADR, and matches the generator output (drift bats green).
- [ ] **(d) `/wr-architect:create-adr` integration** — Step 4 template authoring + Step 5 confirm extended to regenerate the compendium and include it in the same commit as the new ADR file.
- [ ] **(e) `/wr-architect:capture-adr` integration** — skeleton-write step extended to regenerate the compendium and include it in the capture commit.
- [ ] **(f) `/wr-architect:review-decisions` integration** — drain pass confirms the compendium entry alongside the human-oversight marker; ratification updates the entry where the human edits substance.
- [ ] **(g) CI drift-detection bats** — `packages/architect/scripts/test/generate-decisions-compendium.bats` asserts the committed compendium matches the generator output for the committed ADR bodies; green on the shipping change-set.
- [ ] **(h) Commit-time enforcement hook** — `packages/architect/hooks/architect-compendium-refresh-discipline.sh` registered as a PreToolUse hook on `git commit`; denies a commit that stages `docs/decisions/<NNN>-*.md` without a refreshed `docs/decisions/README.md`. Hook bats coverage proves the deny path fires.
- [ ] **(i) ADR-031 authoritative-state assertion** — implementation prose explicitly names the per-ADR body as authoritative and the compendium as derived; the new ADR's substance is NEVER edited compendium-side first.
- [ ] **(j) No existing ADR is silently regressed** — the load-contract change doesn't break any in-flight skill or test that depends on the prior "read all bodies" assumption (sweep skill suites + bats).

## Pros and Cons of the Options

### Option 1 — Per-ADR `summary:` frontmatter field

- Good: smallest migration touch-surface; strongest in-codebase precedent (ADR-066 frontmatter-grep, `detect-unoversighted.sh`); smallest agent-prompt change.
- Bad: still N file reads per architect-agent invocation (cheaper per read, but N reads vs 1). Smaller single-load token win than the compendium.
- Bad: multi-line prose inside YAML is awkward — needs a `>` block scalar or single-line cap.

### Option 2 — Generated `docs/decisions/README.md` compendium (chosen)

- Good: largest single-load token win (one file vs N); direct ADR-031 precedent at a sibling surface; auditable browsable index as a side benefit.
- Bad: introduces a generated-artifact drift surface (mitigated by the established marker-pattern precedent + commit-time enforcement hook).
- Bad: cross-references in code still need the per-ADR filename; the compendium is for the architect-agent load, not for human authorship.

### Option 3 — Separate `<NNN>-<slug>.summary.md` sibling files

- Good: clean per-ADR separation; sibling-file pattern has precedent (REFERENCE.md per ADR-054).
- Bad: doubles file count in `docs/decisions/` (76 → 152); every glob site (`detect-unoversighted.sh`, `measure-context-budget.sh`, `wip.md`, every bats test) needs an explicit `*-summary.md` include/exclude — largest migration touch-surface.
- Bad: drift surface same as the compendium, without the single-load token win.

### Option 4 — `## Summary` section at top of ADR body

- Good: no frontmatter / schema change; lives with the ADR; markdown-tooling-friendly.
- Bad: architect agent's Read tool doesn't natively parse "read until first `##` after Summary" — largest agent-load mechanism change (needs a custom loader script or behaviour change).
- Bad: per-paragraph discipline is honour-system; section can drift downward as ADRs amend.

## Reassessment Criteria

Revisit this decision if:

- Drift-detection bats fires frequently (signals the enforcement hook is failing-open or being bypassed; or the generator is unstable).
- Token measurements show the architect-agent load is still dominant in adopting projects after the change ships (signals the load contract amendment didn't take effect, or another body-reader surface emerged).
- A second heavy ADR-body consumer arrives (e.g. a new agent or skill that justifiably needs every full body); evaluate whether to extend the compendium's content or introduce a tiered load mechanism.
- The hand-confirm drain proves too painful (76 entries × interactive confirm + summary refinement); evaluate batching or auto-acceptance of high-confidence entries.
- P194 (forward-chronology evidence accumulation) is independently addressed and the per-ADR body shrinks enough that the routine load problem this ADR solves no longer fires.

## Related

- **Extends** [ADR-038](038-progressive-disclosure-for-governance-tooling-context.proposed.md) — progressive-disclosure parent; this is the ADR-prose surface specialisation (alongside SKILL.md + REFERENCE.md at the runtime-prose surface).
- **Specialises** [ADR-054](054-skill-md-runtime-budget-policy.proposed.md) — SKILL.md runtime budget policy applied at the ADR-prose surface (compendium ≈ SKILL.md, full body ≈ REFERENCE.md).
- **Relates to** [ADR-066](066-human-oversight-marker-and-review-decisions-drain.proposed.md) — shares the token-cheap-grep driver; the new compendium entry is born at decision time the same way the human-oversight marker is, via the `/wr-architect:create-adr` Step 5 confirm + `/wr-architect:review-decisions` drain.
- **Direct precedent** [ADR-031](031-problem-ticket-directory-layout.accepted.md) — `docs/problems/README.md` as the canonical rendered index from per-ticket files; this decision applies the same pattern at the decisions surface.
- **Relates to** ADR-026 (agent output grounding) — the compendium's per-entry fields must cite the ADR they were extracted from; the body remains the authoritative substance the compendium is grounded in.
- **Amends** `packages/architect/agents/agent.md` Step 1 load step — first agent-prompt amendment under this ADR's contract.
- **Mirrors** the P165 README-refresh-discipline enforcement pattern (`itil-readme-refresh-discipline.sh` for `docs/problems/README.md`) at the decisions surface — the commit-time hook is the same shape, different surface.
- **Mirrors** the P138 / P150 / P186 marker-pattern precedent for cross-surface drift coupling.
- **Composes with** P194 (ADRs accumulate forward-chronology evidence inline) — sibling problem at the same context-bloat class, different fix shape (history-archive sibling vs summary surface). Kept separate per architect verdict.
- **Closes** the load-bearing piece of P327 (ADR bodies dominate session token usage).
- **Commit grain** per ADR-014 — implementation lands across the synced surfaces in appropriately-grained commits (agent prompt + generator + initial compendium + drift bats + enforcement hook + skill integrations).
