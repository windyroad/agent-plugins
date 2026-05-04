---
risk_id: R005
slug: cross-package-release-coordination-drift
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [.changeset/*.md, docs/changesets-holding/*.md, packages/*/CHANGELOG.md, packages/*/package.json (version field), .github/workflows (changesets-action), npm publish surfaces]
cascade_scope: every release that ships multiple coupled plugins; every held-area-managed delay between in-repo landing and adopter exposure
afk_class: both (orchestrator AFK loops can auto-apply move-to-holding under ADR-042 Rule 2)
reversal_class: changesets-recoverable in-repo (git mv between .changeset/ and docs/changesets-holding/); npm-permanent post-release (CHANGELOG entries land in every published tarball)
control_budget_class: free-hook (PreToolUse:Bash on `git commit` for changeset-discipline gate); per-release-coordination LLM cost
dogfood_days: P141 changeset-discipline gate has been live for ~14 days; held-area pattern blessed by ADR-042 ~10 days
authority_class: framework-resolved (ADR-042 auto-apply for above-appetite); user-direction (Case 1 multi-slice WIP holds are user-authored)
prompt_cache_window: ongoing
ci_a: integrity (versions advertised must match versions shipped); availability (changeset misalignment can block release pipeline)
agentic_category: cascade
---

# Risk R005: Cross-package release coordination drift

## Description

The monorepo ships ~10 plugins across `packages/*/` via Changesets. Each plugin is independently versioned but often coupled — a contract change in one plugin (e.g., ADR-056 hint format in `wr-risk-scorer`) requires consumer updates in others (`wr-itil` orchestrator drain step). Coordination drift takes several forms: (a) changeset queued for plugin A without coupled changeset for dependent plugin B; (b) plugin A ships before plugin B leaving adopters with mismatched contracts; (c) accumulated `.changeset/*.md` files trigger release-PR for an unintended subset; (d) Case-1 multi-slice WIP changesets that should be held leak into `.changeset/` and auto-publish.

Distinct from a generic "release management" risk because **agentic compositions span plugin boundaries** — a SKILL.md in `wr-itil` invokes an agent in `wr-risk-scorer` invokes a hook in `wr-risk-scorer/hooks/` which writes a queue file consumed by another `wr-itil` skill. Cross-plugin contract drift is structurally common.

**Source → event → consequence chain**: source = contract change in one plugin (agent prompt, hook regex, skill invocation pattern) without paired changeset for consuming plugin OR with held-area placement that the next agent doesn't honor; event = release pipeline runs OR adopter pulls update; consequence = adopters run mixed-version cohort where coupled-but-mismatched plugins produce subtle errors (false-deny, false-allow, schema mismatch, queue-file shape divergence).

## Inherent Risk

- **Impact**: 4/5 (Significant) — mixed-version cohorts are hard to debug at adopter sites because the failure presents as plugin-A behaving wrong when the actual cause is plugin-A-version-N talking to plugin-B-version-N-1. Trust-budget cost is high; reproduction requires knowing the version pair.
- **Likelihood**: 3/5 (Possible) — held-changeset count was 3 concurrent at time of writing (P085, P064, P159), each a multi-slice fix. ADR-014 single-commit grain partially mitigates by keeping each commit's coupled-changes together, but cross-commit coupling (a feature spans 2-3 commits) still requires changeset discipline.
- **Inherent Score**: 12
- **Inherent Band**: High

## Controls

- **`packages/itil/hooks/itil-changeset-discipline.sh`** (P141) — PreToolUse:Bash gate denies `git commit` when `packages/*/source` is staged without `.changeset/*.md`. **Effectiveness**: high — every plugin source change is forced to declare a changeset OR explicit BYPASS_CHANGESET_GATE=1. Reduces likelihood from 3 to 2 by making change-without-changeset unauthorised.
- **`docs/changesets-holding/`** (ADR-042 Rule 7) — held-area for multi-slice WIP changesets that aren't ready to ship. Per-changeset row in README documents reinstate trigger. **Effectiveness**: medium-high — provides a place for "this changeset exists but should NOT release yet"; prevents the leak-to-.changeset/ failure mode. Reduces likelihood from 2 to 1 for multi-slice WIP class.
- **ADR-042 auto-apply remediations** — orchestrator auto-applies `move-to-holding` when push residual exceeds appetite. **Effectiveness**: medium — automation closes the hand-discipline gap; observed firing across ~3 holds in past 2 weeks.
- **ADR-014 single-commit grain** — pairs source change with its changeset in one commit. **Effectiveness**: medium-high for intra-commit coupling; lower for cross-commit coupling (deliberate multi-slice work).
- **`docs/changesets-holding/README.md` "Currently held" + "Recently reinstated" tables** — audit trail for which changesets are held and when reinstated. **Effectiveness**: medium — makes the held-state visible to release-time review; doesn't enforce, only surfaces.
- **P162 dogfood-graduation criteria** (open ticket) — codifies counterfactual risk assessment for held changesets to formalise the reinstate decision. **Effectiveness**: pending (ticket open); codification expected to reduce held-area discipline ambiguity.

## Residual Risk

- **Impact**: 3/5 (Moderate) — held-area + changeset-discipline gate prevent the most common failure modes; remaining risk is cross-commit coupling that the gate can't see.
- **Likelihood**: 1/5 (Rare) — multiple independent control paths (gate + held-area + ADR-014 grain + auto-apply) each contribute reduction; observed false-positive rate on the gate is near zero in dogfood window.
- **Residual Score**: 3
- **Residual Band**: Low
- **Within appetite?**: Yes (≤ 4/Low).

## Treatment

**Mitigate**. Continue P141 changeset-discipline gate + held-area + ADR-014 grain as the core controls. Land P162 codification when ticket reaches its appetite-prioritised slot.

**Active mitigations**:
1. P141 gate fires on every `git commit` touching `packages/*/source`.
2. Held-area README maintained with reinstate triggers per changeset.
3. ADR-042 Rule 2 auto-apply for above-appetite push residuals.
4. P162 graduation-criteria ticket prioritised when codification need surfaces.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: held-area inventory exceeds 5 concurrent (signals dogfood pipeline congestion). Or: a release ships mismatched plugin versions that produce adopter-observable errors. Or: BYPASS_CHANGESET_GATE=1 invocation rate exceeds 1 per 10 commits (signals the gate is too noisy and being routed around).
- **Metrics**: held-changeset count over time (target ≤3 concurrent); average days-in-hold per changeset; count of post-release rollbacks due to mismatched-version coupling; BYPASS_CHANGESET_GATE=1 invocation count + per-invocation rationale audit.

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P141 (changeset discipline driver), P162 (codify dogfood graduation criteria — meta-ticket), P085 + P064 + P159 (concurrent holds at time of writing — exemplars of multi-slice WIP), P104 ("painted into a corner" hazard cited by ADR-042 line 38).
- **Treatment ADRs**: ADR-014 (single-commit grain), ADR-018 (release cadence for AFK loops), ADR-020 (governance auto-release for non-AFK), ADR-042 (auto-apply scorer remediations + Rule 7 held-area blessing).
- **Personas affected**: plugin-user (mixed-version cohorts produce support-call cost); plugin-developer (JTBD-101 "extend the suite without painted-into-corner"); plugin-maintainer (release coordination overhead).

## Source Evidence

- `docs/changesets-holding/README.md` — three concurrent holds + their reinstate triggers.
- `packages/itil/hooks/itil-changeset-discipline.sh` — control implementation.
- `packages/itil/hooks/lib/changeset-detect.sh` — detection logic.
- `docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md` Rule 7 — held-area authority.
- `docs/problems/162-codify-dogfood-graduation-criteria-with-counterfactual-risk-assessment-for-held-changesets.open.md` — codification meta-ticket.
- `.risk-reports/*.md` — recurring "Three changeset bundle to npm + marketplace", "Push triggers changeset-release/main PR with three pending bumps", "Changeset queue drift" risk items.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe. The pre-wipe R004 ("Cross-package version drift or publish failure breaks install") covered a subset; this entry expands to the full coordination class including held-area dynamics + cross-commit coupling. Residual lowered from 6/Medium to 3/Low under the corrected `## Control Composition` rule given the multiple independent control paths.
