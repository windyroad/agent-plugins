---
risk_id: R001
slug: documentation-runtime-drift
status: Active
category: brand
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [README.md (per-plugin), SKILL.md (per-skill), agent.md (per-agent), ADR-NNN.md (per-decision), CLAUDE.md]
cascade_scope: every adopter session that reads documentation; every agent invocation that consults a SKILL; every architect/JTBD review; ISO 31000/27001 audit trail
afk_class: both
reversal_class: git-recoverable (in-repo) / npm-published-permanent (in adopter caches until next plugin update)
control_budget_class: free-hook (commit-time PreToolUse:Bash) + per-edit-llm (architect/JTBD review)
dogfood_days: 1 (P159 Phase 1 commit-hook landed 2026-05-04 commit de4ece2; held changeset awaiting dogfood-window before adopter release)
authority_class: framework-resolved (drift detection is mechanical; resolution requires human edit per ADR-051 amendment)
prompt_cache_window: ongoing
ci_a: integrity (documentation IS the contract agents and adopters read; drift is integrity loss)
agentic_category: drift
---

# Risk R001: Documentation-runtime drift

## Description

Documentation files (READMEs, SKILL.md, agent.md, ADRs, CLAUDE.md) are runtime-active configuration in agentic systems — agents read them every invocation to determine behaviour, and adopters read them to understand what plugins do. When prose drifts from runtime behaviour (skill landed but README still describes prior state; ADR amended but consumers read pre-amendment cache; SKILL.md describes Step N that the implementation actually skipped), agents act on stale contract and adopters trust a model that no longer holds.

This is the most-frequently-surfaced risk class in the project's corpus. Distinct from traditional documentation-staleness because agents *consume the prose at runtime* — the README is not a reference manual but a load-bearing input that drives the next action.

**Source → event → consequence chain**: source = local edit to runtime artefact (skill / hook / agent prompt) without paired README/ADR update; event = agent or adopter reads now-stale doc; consequence = agent acts on outdated contract OR adopter trusts a description that overstates / understates / misframes shipped behaviour.

## Inherent Risk

- **Impact**: 4/5 (Significant) — README-stated contracts ARE what adopters install; drift between published prose and published runtime degrades the brand promise the plugin makes. ISO 27001 integrity dimension.
- **Likelihood**: 4/5 (Likely) — corpus evidence: P051 (run-retro 6 improve shapes), P158 (advisory detector shipped but not wired), P159 (jtbd-currency detector should be load-bearing, not retro-advisory), P051+P159 retro signals reference "stale documentation state" / "README render drift from ticket body" / "ADR-045 documents patterns inconsistent with ADR-038" — all in the same week. Without a load-bearing detector, drift accumulates monotonically because every PR can introduce it and only retro-time review catches it.
- **Inherent Score**: 16
- **Inherent Band**: High

## Controls

- **`packages/retrospective/hooks/retrospective-readme-jtbd-currency.sh`** (P159 Phase 1, commit `de4ece2`) — load-bearing PreToolUse:Bash commit-hook denies `git commit` when README JTBD-anchor drift is detected; auto-fix path mitigates without halt. **Effectiveness**: high for JTBD-anchored README drift; 19/19 bats green; dogfood started 2026-05-04 (1 day in-repo before adopter release per the held-changeset pattern). Reduces likelihood from 4 to 3 for the JTBD-anchored README class specifically.
- **`packages/architect/agents/agent.md`** + **`packages/jtbd/agents/agent.md`** — architect/JTBD review fires on every Edit/Write to project files; reviewers flag drift between proposed change and existing decisions/jobs. **Effectiveness**: medium — depends on reviewer thoroughness; fires per-edit not per-commit; doesn't catch drift introduced in commits the reviewer signed off on. Reduces likelihood from 3 to 2 for ADR/JTBD-bearing files.
- **ADR-051 amended** (P159) — codifies "load-bearing-from-the-start for drift class" as architecture principle; mandates commit-hook surfaces for drift detectors. **Effectiveness**: medium — sets future-detector contract but doesn't retroactively cover existing drift surfaces (skill-inventory drift, ADR-cross-reference drift, etc. — see Reassessment Criteria).
- **Retro Step 2b advisory** — backup advisory check at retro time; surfaces residual drift the commit-hook missed. **Effectiveness**: low for prevention (post-hoc); load-bearing for catching commit-hook regressions.
- **CLAUDE.md MANDATORY rules** (architect/JTBD/TDD gates fire on every Edit/Write) — gates require agent delegation before edit; reviewers see proposed change before it lands. **Effectiveness**: medium-high; cites the same review surface as the architect/JTBD agent control above.

## Residual Risk

- **Impact**: 4/5 (Significant) — controls don't change consequence shape; drift that escapes controls still degrades brand promise.
- **Likelihood**: 2/5 (Unlikely) — JTBD-anchored README drift covered by load-bearing hook; ADR/JTBD drift covered by review gates. Other drift classes (skill-inventory, ADR-cross-reference, prose-style) currently have only retro-time advisory coverage; load-bearing hooks for those are P161 deferred work.
- **Residual Score**: 8
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; P161 expansion to other drift classes is the next mitigation step.

## Treatment

**Mitigate**. Continue the load-bearing-from-the-start hook pattern (P159's contract) for additional drift classes per P161's deferred-class list (skill-inventory drift, ADR-cross-reference drift, prose-style drift). Do NOT accept the residual at 8/Medium because the corpus shows drift surfaces accumulating faster than retro-cadence catches them.

**Plan**: ship one load-bearing detector per drift class as evidence accumulates. P161 tracks the meta-decision; per-class tickets file from P161 when corpus shows ≥3 occurrences of a class.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: any week with ≥2 retro entries naming a new drift class not covered by an existing load-bearing detector. Or: dogfood-window for P159's commit-hook reveals false-positive rate >5% on legitimate commits (signal to adjust the detector before extending the pattern).
- **Metrics**: count of `drift` keyword instances in retro outputs / month; count of new load-bearing detectors landed / quarter; dogfood false-positive rate on existing detectors.

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as** (problems caused by this risk class): P051 (run-retro 6 improve shapes), P158 (advisory detector not wired), P159 (commit-hook not retro-advisory), P161 (drift-class generalisation observation).
- **Treatment ADRs**: ADR-051 (jtbd-anchored README with drift advisory; amended by P159 with load-bearing-from-the-start clause).
- **Personas affected**: plugin-user (`docs/jtbd/plugin-user/persona.md`) — adopters trust README to describe shipped behaviour; tech-lead (`docs/jtbd/tech-lead/persona.md`) — JTBD-202 audit trail integrity; plugin-developer (`docs/jtbd/plugin-developer/persona.md`) — JTBD-101 "clear patterns, not reverse-engineering".

## Source Evidence

Aggregated from corpus across 2026-04-26 through 2026-05-04:

- `.risk-reports/2026-05-03T*-commit.md` retro signals: "README render drift from ticket body", "Stale documentation state", "SKILL.md sort-spec drift across the 5 render-block sites", "ADR-045 documents patterns inconsistent with ADR-038".
- `docs/problems/051-run-retro-6-improve-shapes.*` — improve-shape pattern that surfaces drift class.
- `docs/problems/158-adr-051-phase-1-detector-shipped-but-not-wired-into-retro-step-2b.closed.md` — Phase 1 advisory detector.
- `docs/problems/159-jtbd-currency-detector-should-be-load-bearing-commit-hook-with-auto-fix-not-retro-advisory.verifying.md` — load-bearing detector that supersedes P158.
- `docs/problems/161-advisory-then-escalate-may-be-over-applied-as-the-default.open.md` — drift-class generalisation observation.
- `docs/decisions/051-jtbd-anchored-readme-with-drift-advisory.proposed.md` — control authority.
- `docs/changesets-holding/wr-retrospective-p159-readme-jtbd-currency-hook.md` — held for dogfood per the established pattern.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe of pre-correction R001-R006. Inherent / Residual estimated from `.risk-reports/` corpus + retro frequency + held-changeset pattern; controls cite actual artefacts; treatment is Mitigate continuing per ADR-051 amendment direction.
