---
status: "proposed"
date: 2026-05-03
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-08-03
---

# `@windyroad/*` plugin READMEs anchor on JTBD job IDs with declarative drift advisory

## Context and Problem Statement

The project has a dense pressure stack for keeping CODE in sync with documented decisions and contracts: `wr-architect:agent` enforces architecture compliance, `wr-jtbd:agent` enforces JTBD alignment, `wr-risk-scorer:pipeline` scores commit/push/release risk, the TDD enforcement hook gates implementation edits on red/green test state, the changeset-discipline hook (P141) gates `git commit` on changeset coverage, and `manage-problem` Step 0 reconciliation halts on README-vs-inventory drift. Every commit goes through gates that catch divergence early.

There is no equivalent stack for **doc-content drift**. The documentation that ships to npm under each `@windyroad/*` package — package-level READMEs, top-level project README, plugin marketplace listing copy — has no analogous gate, no analogous detector, no analogous advisory script. It is hand-maintained, drift-prone, and currently relies entirely on memory + occasional manual review. Empirical state on 2026-05-03: `@windyroad/itil` ships 16+ skills but the README documents 2; `@windyroad/retrospective` ships 2+ skills but the README documents 1; cross-cutting hooks and agents added across iters of the AFK loop (changeset-discipline, correction-detect, ADR-049 bin-shim grep-as-lint) are entirely absent from package READMEs. Drift count across 12 plugin READMEs at the time this ADR was authored: at least 12 instances of inventory drift and 0 instances of JTBD anchoring.

This is the driver of P152 (No pressure or nudge for documentation currency). The user's framing of the fix shape is load-bearing: *"leverage the JTBD pages so we can help the reader understand the value through the jobs it helps them do"*. JTBD framing is not just internal-persona accounting; it is the lens through which an adopter (human or AI agent) can quickly see "this skill exists because of THESE jobs". The plugin-user persona (`docs/jtbd/plugin-user/persona.md`) is defined by "low context on repo internals; AI agent as primary interface" — exactly the audience that benefits most from job-framed value description rather than raw capability enumeration.

The pressure-stack architecture in this project is **decision-anchored**: every gate cross-checks new edits against a canonical source of truth (`docs/decisions/`, `docs/jtbd/`, `RISK-POLICY.md`). For doc-content drift, the missing piece is no canonical source of truth that the README content must conform to. A README is hand-authored prose; without an anchor, even a hook firing on README edits has nothing to gate against.

The solution shape: **JTBD job files become the canonical source of truth for README narrative**. Per ADR-008's `docs/jtbd/<persona>/JTBD-NNN-<title>.<status>.md` layout, every JTBD job has a stable identifier (`JTBD-NNN`) with a known persona, status, and content. Anchoring README narrative on JTBD IDs makes drift detectable: the detector can grep for `JTBD-\d{3}` in the README, cross-reference the cited IDs against the current `docs/jtbd/` tree, and flag stale citations, missing anchors, or inventory drift between SKILL.md / hooks / agents and the README's coverage of them.

A normative rule is needed so future plugin authors do not author drift-prone READMEs, and a Phase 1 advisory detector is needed so the existing READMEs surface their drift to retros and release candidates without blocking CI on day one (per the established Phase 1 / Phase 2 trajectory in P099 / P134 / P145 / P148).

## Decision Drivers

- **Plugin-user persona's "low context on repo internals; AI agent as primary interface" constraint** (`docs/jtbd/plugin-user/persona.md`): adopters cannot verify README claims by reading source under `node_modules/`. The README's currency must be detectable without `node_modules/` archaeology. **JTBD-302 (Trust That the README Describes the Plugin I Just Installed)** names this job explicitly — primary driver.
- **Currency-pressure expansion from code to doc-content (JTBD-007)**: JTBD-007 (Keep Plugins Current Across Projects) currently frames currency as code-currency ("did the install pick up the latest code?"). This ADR extends the same persona's currency concern to README-content-currency. JTBD-007's scope is being **extended** (not reframed); JTBD-007 is a co-primary driver alongside JTBD-302.
- **Job-framed value description over raw capability enumeration**: per the user's framing of P152, READMEs that lead with "what jobs this plugin helps you do" outperform READMEs that lead with "what skills this plugin exposes" for an audience that doesn't already know which skills they need. The persona docs already use job-framing; READMEs should compose with that vocabulary.
- **Stable canonical anchor required for drift detection**: a hook firing on a README edit needs SOMETHING to gate against. JTBD job IDs (per ADR-008's per-job-file layout) are the project's most stable + most semantically-load-bearing identifier — more stable than skill names (P071 split precedent), more semantically-rich than ADR IDs (which describe decisions, not jobs).
- **Advisory-first per ADR-013 Rule 6 fail-safe**: Phase 1 ships a script that emits drift signal as data on stdout; exit code is always 0; no gate fires. Phase 2 (R6-gated escalation) only fires if drift accumulates across N consecutive releases without correction. Matches P099 / P134 / P145 / P148 precedent.
- **Plugin-developer persona's "clear patterns, not reverse-engineering" outcome (JTBD-101)** — composition driver: a future contributor authoring a new `@windyroad/*` plugin needs ONE place that says "this is how plugin READMEs are structured". This ADR is that place.
- **Tech-lead persona's pre-flight governance check (JTBD-202)** — composition driver: the advisory detector script is exactly the kind of release-time signal a tech-lead would consult before recommending a plugin to a team or client.
- **Solo-developer's enforce-governance job (JTBD-001)** — composition driver: extending the existing pressure-stack to README content composes with the documented-policy-checked-on-every-edit shape.
- **Plugin-user's report-without-pre-classifying job (JTBD-301)** — composition driver: better READMEs → better mental models → better intake.
- **Behavioural bats per ADR-005 + P081**: the detector's behaviour must be tested against synthetic fixtures (drift case, clean case, stale-ID case) — not against a structural grep on its own source. Drift detection is a behavioural property of the detector script.

## Considered Options

1. **Option D1 — "Plugin README MUST have a `## Jobs to be Done` section that lists JTBD job IDs"**: structurally force the addition. Every plugin README must contain a section with a fixed heading; the detector greps for the heading. Rigid; the section becomes a checklist tick rather than the canonical narrative anchor. Doesn't address the underlying problem that current READMEs do their value framing in `## What It Does`.
2. **Option D2 — "Plugin README MUST cite at least one current JTBD job ID; value framing SHOULD derive from JTBD" (chosen)**: the normative rule is that every `@windyroad/*` plugin README MUST contain at least one match for `JTBD-\d{3}` AND every cited JTBD ID MUST resolve to a current `docs/jtbd/<persona>/JTBD-NNN-*.md` file (any status suffix). Heading vocabulary is RECOMMENDED (see Recommended Section Structure below) but not normative. Detector is structurally simple (grep for the ID pattern + resolve to filesystem). Preserves authorial flexibility while making drift detectable. Composes with existing `## What It Does` headings while extending them.
3. **Option D3 — Status quo (do nothing)**: rely on hand-maintenance + occasional review. Drift continues to accumulate at observed rate (≥12 instances across 12 READMEs per 2026-05-03 audit). Rejected — this is the failure mode P152 surfaces.
4. **Option D4 — Generated READMEs from JTBD + SKILL.md + plugin.json**: produce the README mechanically from machine-readable inputs. Drift impossible by construction. Rejected for Phase 1 — bypasses the human narrative voice; loses the README's intended audience-framing value; would require a generator engine + per-plugin templates as net-new infrastructure. May reconsider at Phase 3+ if Phase 2 escalation surfaces persistent unfixed drift.

## Decision Outcome

Chosen option: **"Option D2 — Plugin README MUST cite at least one current JTBD job ID; value framing SHOULD derive from JTBD"**, because it (a) creates a stable, structurally-simple drift-detection anchor (JTBD ID grep + filesystem resolve) without rigidifying the README's narrative shape, (b) preserves the existing `## What It Does` value-framing section while requiring it to derive from JTBD job files, (c) leaves room for each plugin's narrative voice to evolve while keeping the JTBD anchor as the load-bearing detector signal, and (d) composes cleanly with ADR-008's per-job-file source-of-truth layout.

Sibling to ADR-049 (bin/-on-PATH script resolution) on the "plugin-published artefacts must work in adopter contexts" axis. ADR-049 addresses **executable correctness** in adopter sessions; this ADR addresses **content currency** in adopter README reads. Both are plugin-boundary leakage concerns of different kinds.

Composes with ADR-040 declarative-first / advisory-then-escalate pattern. Composes with ADR-013 Rule 6 fail-safe (Phase 1 advisory; exit-0 always). Composes with ADR-008 (JTBD directory structure) — the per-job-file layout is the load-bearing structural foundation that lets the detector resolve cited IDs deterministically.

**Normative rules** (Phase 1):

1. Every `@windyroad/*` plugin's `packages/<plugin>/README.md` MUST contain at least one match for the regex `JTBD-\d{3}`.
2. Every JTBD ID cited in a plugin README MUST resolve to a current file under `docs/jtbd/<persona>/JTBD-NNN-*.md` — ANY status suffix (`.proposed.md`, `.validated.md`, `.deprecated.md`, `.superseded.md`). Status suffix is surfaced in detector signal as `jtbd_status=<status>` sub-flag so a future Phase 2 can tighten without re-architecting the detector. A README citing a `.deprecated.md` or `.superseded.md` ID is a currency signal worth flagging in `drift_hints`, not a resolution failure.
3. The advisory detector MAY also flag inventory drift hints (skill defined in `packages/<plugin>/.claude-plugin/plugin.json` or `packages/<plugin>/skills/*/SKILL.md` but not mentioned in the README) as advisory signal — this is a soft heuristic, not a normative rule.

**Recommended Section Structure** (for plugin READMEs, non-normative):

- A `## Jobs to be Done` section — idiomatic match to repo's JTBD vocabulary; AI-greppable; familiar industry term.
- Persona-grouped subsections under the heading (one subsection per persona served), each listing the JTBD jobs the plugin helps with for that persona, with the JTBD ID + a one-sentence framing of how this plugin serves the job.
- Persona ordering reflects **primary readership** for that plugin (e.g. `@windyroad/itil` leads with plugin-user, `@windyroad/architect` leads with tech-lead).

**Out of scope for this ADR**:

- Generalisation to adopter project surfaces (marketing HTML, public docs, changelog narrative) — follow-on ticket. The user's framing of P152 mentions adopter surfaces; ADR-051's scope is `@windyroad/*` plugin READMEs only. Adopter-surface generalisation is a distinct decision because the source-of-truth anchor differs (adopter projects have their own JTBD structure or none at all).
- Retroactive refresh of the existing 12 plugin READMEs — follow-on iter (filed alongside this ADR as the validation pass that confirms the mechanism scales). Phase 1 ships the rule + the detector; the retroactive content pass IS the empirical validation.
- SKILL.md amendments wiring the detector into `/wr-retrospective:run-retro` Step 2b — follow-on iter, deferred until the detector is empirically validated against the existing READMEs.
- Extension to walk `.github/ISSUE_TEMPLATE/*.yml` per JTBD-lead's recommendation — surfaced as a Phase 1.5 candidate; current scope is plugin READMEs only.

### Consequences

#### Good

- Adopter agents reading a `@windyroad/*` plugin README can cross-reference cited JTBD IDs to the public repo's `docs/jtbd/` tree, giving the persona-defining "low context on repo internals" reader a path to value-frame understanding without source archaeology. JTBD-302's "trust the README" outcome becomes reliably servable.
- Future plugin authors have ONE place (this ADR) that says "this is how plugin READMEs are structured" — JTBD-101's "clear patterns, not reverse-engineering" outcome is served.
- Drift is detectable at retro time, release time, and (via Phase 2 escalation if needed) commit time. The pressure-stack asymmetry P152 surfaces is closed in two phases.
- README narrative anchors on stable identifiers (JTBD IDs) rather than skill names (which split per P071), ADR IDs (which amend per ADR-013 → ADR-044), or hook names (which churn per P124 / P141 / P144). JTBD IDs are the project's most stable + most semantically-load-bearing identifier.
- Composes with the `wr-jtbd:agent` review path — when a plugin README is edited, the JTBD agent's existing review surface naturally extends to "are the cited JTBDs still current?".

#### Neutral

- One new advisory script (`packages/retrospective/scripts/check-readme-jtbd-currency.sh`) + one new bin/ shim (`packages/retrospective/bin/wr-retrospective-check-readme-jtbd-currency`) + one new bats fixture set. The script body is one concern; the shim is 3 lines per ADR-049; the fixtures are synthetic markdown. Maintenance footprint is small.
- Plugin authors must include at least one JTBD citation in every README. For most plugins, the relevant JTBD already exists; for plugins that don't yet have a JTBD-anchored job (the plugin-user might say "this plugin doesn't help with any documented job"), the answer is to file the missing JTBD, not skip the citation.

#### Bad

- Phase 1 is advisory-only — the detector emits data, but no gate fires. Adopters of the rule rely on retro consumption + release-pre-flight habit, not deterministic enforcement. Phase 2 escalation is the controlled escape hatch for sustained non-compliance.
- The detector cannot semantically validate that a cited JTBD ID is the **right** job for the plugin — only that the cited ID exists. A README that cites JTBD-001 in every plugin would pass the detector but still be wrong. This is the residual judgement call that retros catch + the JTBD agent's read of the README content addresses — outside this ADR's scope.
- Plugin renames that change the README's JTBD section composition (e.g. removing a deprecated persona) require coordinated edits across multiple READMEs. This is rare and grep-able.

## Confirmation

This decision is honoured when:

1. **Behavioural bats test passes** under `packages/retrospective/test/check-readme-jtbd-currency.bats`, asserting:
   - **Drift fixture case**: a synthetic plugin README with no `JTBD-\d{3}` match produces detector output `has_jtbd_anchor=no` and a non-zero `drift_instances` count in the `TOTAL` line. Detector exit code is 0 (advisory).
   - **Clean fixture case**: a synthetic plugin README citing one or more current JTBD job IDs produces detector output `has_jtbd_anchor=yes cited_jobs=N known_jobs=N drift_hints=` (empty drift_hints). Detector exit code is 0.
   - **Stale-ID fixture case**: a synthetic plugin README citing a JTBD ID that does NOT resolve to any current `docs/jtbd/<persona>/JTBD-NNN-*.md` file produces detector output that flags the stale ID in `drift_hints` (e.g. `drift_hints=stale-jtbd-citation`). Detector exit code is 0.
2. **Detector emits the documented signal vocabulary**: per-package `README package=<name> has_jtbd_anchor=<yes|no> cited_jobs=<count> known_jobs=<count> drift_hints=<comma-list>` lines, plus a trailing `TOTAL packages=<N> with_jtbd=<M> drift_instances=<K>` summary. Per-citation status sub-flag emitted for tightening flexibility in Phase 2. Matches the value-pair convention of sibling detectors (P099 / P134 / P145 / P148).
3. **Bin/ shim resolves on `$PATH`**: `command -v wr-retrospective-check-readme-jtbd-currency` succeeds when the plugin is installed via the marketplace cache. Per ADR-049 normative rule + naming grammar.
4. **Changeset accompanies the script + ADR**: `@windyroad/retrospective` minor bump documenting the new advisory script + bin shim. Per ADR-014 + ADR-021 + P141 changeset-discipline.
5. **No SKILL.md amendment in Phase 1**: the detector ships as an invocable bin command; wiring into `/wr-retrospective:run-retro` Step 2b is deferred to a follow-on iter once the detector is empirically validated against current READMEs.
6. **Retroactive content refresh deferred to a follow-on ticket**: the 12 plugin READMEs are not refreshed in this iter. The retroactive pass is the validation that the mechanism scales and is filed as a separate ticket.
7. **Phase 2 escalation criterion documented + mechanically checkable**: if the advisory detector emits `drift_instances ≥ 2` across 3 consecutive `chore: version packages` releases without correction, escalate to a load-bearing hook per ADR-013 Rule 6 escalation pattern. The drift count is read from the detector's `TOTAL drift_instances=<K>` line at each release; the 3-consecutive-releases observation window is checked by sampling the last 3 release-tagged commits' detector output. Explicit threshold + observation window + mechanically-checkable counter source so escalation is mechanical, not subjective.

## Pros and Cons of the Options

### Option D1 — README MUST have a fixed `## Jobs to be Done` section

- Good: structurally rigid; trivial to grep for the heading.
- Good: forces the value-framing to live in a known place.
- Bad: rigid heading vocabulary discourages narrative evolution.
- Bad: doesn't address the underlying problem (`## What It Does` does the value framing today; D1 adds a section beside it without integrating).
- Bad: detector becomes brittle when an author uses synonymous heading phrasing.

### Option D2 — README MUST cite at least one current JTBD ID; value framing SHOULD derive from JTBD (chosen)

- Good: structurally simple detector (grep `JTBD-\d{3}` + resolve to filesystem).
- Good: preserves authorial flexibility — heading vocabulary is recommended, not mandated.
- Good: composes with existing `## What It Does` rather than adding a parallel section.
- Good: anchors on stable identifiers (JTBD IDs survive plugin renames, skill splits, ADR amendments).
- Neutral: requires every plugin to cite at least one JTBD; for plugins without a current JTBD-anchored job, the answer is to file the missing JTBD.
- Bad: cannot semantically validate the JTBD is the **right** one for the plugin — only that the citation exists and resolves.

### Option D3 — Status quo (do nothing)

- Good: zero new infrastructure.
- Bad: drift continues to accumulate; adopter trust continues to erode; the asymmetric pressure-stack persists.
- Bad: the failure mode P152 surfaces is the explicit reason this ADR exists.

### Option D4 — Generated READMEs from JTBD + SKILL.md + plugin.json

- Good: drift impossible by construction.
- Bad: bypasses the human narrative voice; loses audience-framing value.
- Bad: would require a generator engine + per-plugin templates as net-new infrastructure.
- Bad: composes adversely with existing per-plugin authorial voice; treating READMEs as machine output forecloses the persona-grouped narrative shape JTBD review recommends.
- May reconsider at Phase 3+ if Phase 2 escalation surfaces persistent unfixed drift after the rule + advisory + retroactive refresh have all shipped.

## Reassessment Criteria

Reassess if any of the following occur:

- The advisory detector emits `drift_instances ≥ 2` across 3 consecutive `chore: version packages` releases without correction. At that point, escalate to Phase 2 (R6-gated load-bearing hook) per ADR-013 Rule 6 escalation pattern.
- A plugin README cites a JTBD ID that resolves but is for the wrong persona (semantic drift the detector cannot catch). At that point, extend the detector to flag persona-mismatch as a `drift_hints=persona-mismatch` signal, OR add a `wr-jtbd:agent` review hook on README edits.
- Adopter-surface generalisation (marketing HTML, public docs, changelog narrative) becomes load-bearing for an adopter project. At that point, extend ADR-051 or author a sibling ADR for the adopter-surface mechanism (the source-of-truth anchor likely differs).
- A JTBD job is renamed or its status suffix changes during the per-release cadence. The detector resolves any-status-suffix matches per the established ADR-008 layout, so this is non-blocking; reassess if the resolution behaviour produces false positives or false negatives in practice.
- Generated READMEs (Option D4) become viable — e.g. an adopter's downstream tool generates READMEs from JTBD + SKILL.md and ships them. At that point, the detector should validate the generated content the same way it validates hand-authored content (the rule applies regardless of authorship).

## Related

- **P152** — driver problem (No pressure or nudge for documentation currency); this ADR's normative rule + Phase 1 advisory addresses the asymmetric pressure-stack the ticket surfaces.
- **JTBD-302** (newly filed alongside this ADR) — Trust That the README Describes the Plugin I Just Installed; co-primary plugin-user job served by this ADR's rule.
- **JTBD-007** — Keep Plugins Current Across Projects (currency expansion: code-currency → doc-content-currency); co-primary driver. JTBD-007's file is amended in the same commit as this ADR to add a Desired Outcome line for doc-content currency + a `Related decisions: ADR-051` line.
- **JTBD-301** — Report a Problem Without Pre-Classifying It (transitive: better READMEs → better mental models → better intake).
- **JTBD-101** — Extend the Suite with New Plugins (clear patterns, not reverse-engineering).
- **JTBD-001** — Enforce Governance Without Slowing Down (pressure-stack composition).
- **JTBD-202** — Run Pre-Flight Governance Checks Before Release or Handover (advisory-detector consumption surface).
- **ADR-002** — Monorepo with Independently Installable Per-Plugin Packages (per-package-README boundary).
- **ADR-003** — Marketplace-only distribution (READMEs ship via the marketplace cache; adopter sessions read them).
- **ADR-008** — JTBD directory structure (per-job-file layout that lets the detector resolve cited IDs deterministically).
- **ADR-013 Rule 6** — Non-interactive fail-safe / advisory-then-escalate pattern.
- **ADR-014** — Granular commits (this ADR ships in the same commit as the script + bats + bin shim + JTBD-302 + changeset + JTBD-007 amendment).
- **ADR-021** — Changesets for releases (Phase 1 ships under a `@windyroad/retrospective` minor bump).
- **ADR-040** — Session-start briefing surface (advisory-first / declarative-first precedent).
- **ADR-044** — Decision delegation contract (framework-resolution boundary informs whether Phase 2 escalation is silently agent-decided or surfaced via deviation-candidate).
- **ADR-049** — Plugin-bundled scripts via bin/ on `$PATH` (sibling adopter-context decision; executable correctness vs content currency).
- **P137** — Plugin-published artefacts reference internal IDs (sibling adopter-facing-content axis: semantic correctness).
- **P151** — Published skills reference repo-relative script paths (sibling adopter-facing-content axis: executable correctness; resolved 2026-05-02 via ADR-049).
- **P087** — No maturity / battle-hardening signal (sibling adopter-facing-content axis: maturity-label).
- **P099 / P134 / P145 / P148** — advisory-only-then-escalate precedents this ADR's Phase 1 detector follows.
- **P081** — behavioural-tests-over-structural-grep (the bats fixtures verify detector behaviour, not detector source structure).
