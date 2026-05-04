---
risk_id: R002
slug: hook-regression-cascade
status: Active
category: operational
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [packages/*/hooks/*.sh, packages/*/hooks/hooks.json]
cascade_scope: every adopter Edit/Write/Bash/PreToolUse:Agent invocation across all gated tool calls until adopter updates the cached plugin
afk_class: both (worse AFK — orchestrator iters can compound the regression invisibly)
reversal_class: npm-published-permanent (until adopters run `claude plugin uninstall + install`); cache-coherence amplifies permanence
control_budget_class: free-hook (PreToolUse contract) at runtime; per-edit-llm at landing time (architect/JTBD review of hook changes)
dogfood_days: variable per held changeset (P085 = ~10 days; P064 = ~8 days; P159 = 1 day at time of writing)
authority_class: framework-resolved (regression detection is mechanical — bats coverage); user-direction for treatment changes
prompt_cache_window: ongoing
ci_a: availability (regression makes the gated tool call unusable); integrity (false-deny corrupts the trust-budget; false-allow lets through what should have been blocked)
agentic_category: cascade
---

# Risk R002: Hook regression cascades to installed adopter machines

## Description

Plugin hooks (`packages/*/hooks/*.sh`) fire on every gated tool call across every adopter session. A regression in a hook — false-deny that blocks legitimate work, false-allow that misses what it was meant to catch, syntax error that fail-opens, byte-budget overflow that truncates inject content — propagates to every installed user the moment they update the plugin cache. Until they uninstall + reinstall, the adopter machine runs the regressed hook on every invocation.

Distinct from a normal regression because: (a) the **cascade fan-out is high** — a single hook fires across thousands of tool calls per adopter per day; (b) the **detection latency is long** — adopters notice over days/weeks of "this gate is being weird", not minutes; (c) the **rollback path is slow** — npm publish + marketplace cache update + per-adopter reinstall window is days; (d) the **AFK amplification** — orchestrator iters can compound a regression for a full overnight run before user sees output.

**Source → event → consequence chain**: source = hook prose change (deny-message, regex, marker logic, deny-band budget) lands without paired bats coverage of the changed surface; event = adopter pulls plugin update via marketplace cache refresh; consequence = adopter's gated tool calls behave wrong (false-deny breaks workflow; false-allow leaks past the gate; budget overflow truncates context).

## Inherent Risk

- **Impact**: 4/5 (Significant) — installed-user workflow degraded across every gated tool call until reinstall; trust-budget consumed; P159 retro explicitly notes "first load-bearing commit-hook on wr-retrospective shipping with auto-fix path; release-side blast radius is standing risk for any new gate-class hook published to users" (this is the original RISK_REGISTER_HINT that produced R007 in the wiped iteration — same theme).
- **Likelihood**: 4/5 (Likely) — corpus evidence: P085 (assistant-output gate held for dogfood), P064 (external-comms gate held for dogfood), P159 (jtbd-currency hook held for dogfood), P141 (changeset-discipline gate prior). Three concurrent held changesets at time-of-writing all share this exact concern. Without dogfood-window discipline, hook regressions would ship same-day they're authored.
- **Inherent Score**: 16
- **Inherent Band**: High

## Controls

- **Held-changeset / dogfood-window pattern** (`docs/changesets-holding/`, blessed by ADR-042 Rule 7) — hook-bearing changesets land in the held area for in-repo dogfood before reinstating to `.changeset/` for adopter release. **Effectiveness**: high — ~3 holds active concurrently as evidence; reduces likelihood from 4 to 2 by surfacing in-repo false-positive/negative rates BEFORE adopter exposure.
- **Behavioural bats per ADR-052** (`packages/*/hooks/test/*.bats`) — TDD discipline requires bats coverage of new hook behaviour before commit; existing hooks have 15-71-test-suite coverage. **Effectiveness**: medium-high — catches regression on the tested surface; doesn't catch behavioural drift in regex matchers against unstructured text. Reduces likelihood from 2 to 1 for tested-surface regressions.
- **`packages/itil/hooks/itil-changeset-discipline.sh`** (P141) — meta-control: requires changeset for any `packages/*/source` edit, ensuring release coordination is explicit. **Effectiveness**: high — bypass requires explicit env-var; satisfies the "every plugin change is a deliberate release" invariant.
- **CLAUDE.md "Plugin hooks run from the marketplace cache, not from source"** briefing entry — reminds the agent that source-tree edits don't change behaviour until push + plugin update + restart. **Effectiveness**: low (advisory only); load-bearing for preventing test-on-source-but-not-on-cache confusion.
- **ADR-045 hook injection budget policy** — per-hook prose budget (≤300 bytes deny; ≤150 bytes additionalContext) prevents context-overflow regression class. **Effectiveness**: medium for the budget-overflow surface specifically.

## Residual Risk

- **Impact**: 3/5 (Moderate) — held-changeset pattern reduces consequence by giving the dogfood window time to surface false-positives in-repo; impact downgraded from Significant because the typical failure path is "in-repo dogfood reveals issue before adopter exposure" not "adopter discovers regression".
- **Likelihood**: 1/5 (Rare) — multiple independent control paths (held-changeset + bats + changeset-discipline gate) each reduce by ~1 band; combined with dogfood-window observation evidence, residual likelihood is the held-area's post-window false-positive rate, observed near zero across P085/P064/P141.
- **Residual Score**: 3
- **Residual Band**: Low
- **Within appetite?**: Yes (≤ 4/Low).

## Treatment

**Mitigate**. Continue the held-changeset / dogfood-window pattern as the load-bearing control. Do NOT accept the bare-residual without held-changeset discipline (would push residual to ~9/Medium). Active treatments:

1. **Hold all hook-bearing changesets** for ≥7 in-repo dogfood days OR until scorer downgrades residual below appetite OR until user signals comfort. Codified by `docs/changesets-holding/README.md`.
2. **Require behavioural bats coverage** of new hook surfaces per ADR-052 + TDD discipline.
3. **Track held-area inventory** as a leading indicator — concurrent holds >5 means the dogfood pipeline is bottlenecked.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: a hook regression reaches an adopter machine before being caught in-repo. Or: held-area inventory exceeds 5 concurrent (signals dogfood-pipeline congestion). Or: post-release adopter complaint about hook behaviour.
- **Metrics**: held-changeset count over time; days-in-hold per changeset (target ≥7 for hook-bearing minor bumps); count of post-release rollbacks requiring adopter reinstall; bats coverage % for newly-shipped hooks (target 100%).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P085 (assistant-output gate hold), P064 (external-comms gate hold), P141 (changeset-discipline gate; reaches end of hold lifecycle), P119 (manage-problem create-gate), P124 (SID drift across hook-vs-agent), P159 (jtbd-currency commit-hook hold), P162 (codify dogfood-graduation criteria — the meta-ticket for this risk class).
- **Treatment ADRs**: ADR-042 (auto-apply scorer remediations + held-area Rule 7), ADR-052 (behavioural-tests default), ADR-014 (single-commit grain), ADR-045 (hook injection budget), ADR-018 (release cadence), ADR-049 (plugin-bundled scripts via $PATH bin).
- **Personas affected**: plugin-user (every adopter pays the regression cost on cache refresh); plugin-developer (JTBD-101 "extend the suite without painted-into-corner"); plugin-maintainer (release coordination cost).

## Source Evidence

- `docs/changesets-holding/README.md` — three concurrent holds at time of writing, each with documented dogfood rationale.
- `.risk-reports/*.md` — "Hook regression in installed risk-scorer plugin breaks PostToolUse for adopters" (R-rel-1 risk item recurring).
- `docs/problems/162-codify-dogfood-graduation-criteria-with-counterfactual-risk-assessment-for-held-changesets.open.md` — the meta-ticket codifying the dogfood pattern.
- `docs/problems/085-assistant-output-gate-act-on-obvious-askuserquestion-for-ambiguous-never-prose-ask.verifying.md` — exemplar of the dogfood pattern in action.
- `docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md` Rule 7 — held-area authority.
- ITERATION_SUMMARY entries from `/wr-itil:work-problems` AFK loops — multiple instances of `move-to-holding` auto-apply triggered when push residual exceeded appetite after a hook-bearing iter.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe. The pre-wipe R002 ("Hook regression breaks installed users' workflow") covered this class but at residual 8/Medium with conservative scoring; the held-changeset pattern + bats discipline that have landed since drop residual to 3/Low when both controls fire.
