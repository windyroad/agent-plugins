---
risk_id: R004
slug: marketplace-prompt-cache-divergence
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [marketplace cache (~/.claude/plugins/cache/<org>/<plugin>/<version>/), prompt cache (Anthropic-side per session), npm install cache (npm view + npm install state), source tree (packages/*/)]
cascade_scope: every adopter session running a stale-cached version vs git HEAD; every agent invocation against a cached SKILL.md/agent.md older than the source-of-truth
afk_class: both
reversal_class: cache-coherence (recoverable via uninstall + install + restart, but adopters may not know to do it)
control_budget_class: free-runtime (no per-action cost); high one-time cost on release coordination + adopter education
dogfood_days: ongoing (briefing entries codify the discipline; no recent regression observed once briefing landed)
authority_class: framework-resolved (cache-coherence is mechanical when discipline holds); user-direction when adopters need explicit reinstall guidance
prompt_cache_window: ongoing (this risk is itself ABOUT cache windows)
ci_a: integrity (cached version executes pre-amendment behaviour); availability (cache-stale prompts can fail-fire if SKILL contract changed)
agentic_category: cache-coherence
---

# Risk R004: Marketplace / prompt-cache vs source divergence

## Description

Plugin hooks, skills, and agent prompts run from the **marketplace cache** (`~/.claude/plugins/cache/<org>/<plugin>/<version>/`), NOT from the source tree. Editing a hook file or SKILL.md does not change runtime behaviour until: (1) push to remote; (2) `claude plugin marketplace update`; (3) `claude plugin uninstall + install` (because `install` is a silent no-op when already installed at any version per P106); (4) Claude Code restart. The Anthropic-side prompt cache adds a second layer — agent prompts cached server-side until ~7-day refresh, so even after marketplace cache updates, in-flight agent invocations may emit pre-amendment output.

This is a structural property of the deployment model, not a bug. But it produces a class of subtle regressions where: agent reads cached SKILL.md (old contract); user reads source SKILL.md (new contract); the two diverge silently; the agent's behaviour matches neither what the user expects nor what the source documents.

**Source → event → consequence chain**: source = local edit to a runtime artefact (hook/skill/agent prompt) without paired marketplace-cache refresh; event = adopter session loads cached version while user-facing source has moved on; consequence = behavioural divergence (test on source passes, runtime on cache fails — or vice versa); secondary consequence = adopter sees behaviour the README no longer describes.

## Inherent Risk

- **Impact**: 3/5 (Moderate) — cached-version behaviour diverging from source produces support cost ("the docs say X but the plugin does Y"), trust erosion, and false-positive regression reports. Not Severe because per-session adopters can recover via reinstall once they know to.
- **Likelihood**: 4/5 (Likely) — the structural property fires on every release until the deployment chain (push → marketplace update → uninstall+install → restart) completes. The CLAUDE.md briefing has THIS as a top-tier item ("Plugin hooks run from the marketplace cache, not from source") — codified because it produced enough confusion to warrant briefing-level visibility.
- **Inherent Score**: 12
- **Inherent Band**: High

## Controls

- **CLAUDE.md briefing entry** — top-tier reminder: "Plugin hooks run from the marketplace cache, not from source. Editing a hook file does not change hook behaviour until push + claude plugin marketplace update + reinstall + restart." **Effectiveness**: medium — surfaces the issue so the agent doesn't waste turns testing source-tree edits against cached behaviour. Reduces likelihood from 4 to 3 by setting expectations.
- **`/install-updates` skill (per ADR-030)** — repo-local skill that runs `claude plugin marketplace update` then per-sibling `uninstall + install` per ADR-047 + ADR-059's bootstrap pass. **Effectiveness**: medium-high — automates the cache-refresh chain that adopters might otherwise skip. Reduces likelihood from 3 to 2 when invoked at the right time.
- **ADR-030 + briefing's "claude plugin install is silent no-op"** — codifies the uninstall-before-install rule so cache refreshes actually replace the cached version. **Effectiveness**: medium — only effective when the user/agent knows to invoke it; otherwise the silent no-op produces the divergence.
- **Held-changeset / dogfood pattern (R002)** — indirectly mitigates by giving the in-repo cache time to converge with source before adopter exposure.
- **ADR-056 dual-parse contract** (3-column hint with 2-column legacy fallback) — pattern for handling cache-window backward-compatibility. **Effectiveness**: high for the specific case of pipeline.md prompt-cache lag (legacy 2-column hints from cached prompts continue to parse).

## Residual Risk

- **Impact**: 3/5 (Moderate) — controls don't change consequence shape; cache divergence still produces support cost when it occurs.
- **Likelihood**: 2/5 (Unlikely) — when `/install-updates` is run, the cache-refresh chain holds. Residual likelihood reflects the windows when adopters pull plugin source manually OR don't run install-updates after a marketplace update OR Anthropic-side prompt cache hasn't refreshed (~7 days for in-flight agent prompts).
- **Residual Score**: 6
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; structural fixes (Phase 4 install-updates auto-detect-and-prompt-cache-refresh) are deferred future work.

## Treatment

**Mitigate** — accept the structural property; invest in controls that surface divergence when it happens.

**Active mitigations**:
1. CLAUDE.md briefing keeps the issue visible to every session.
2. `/install-updates` automates the cache-refresh chain; encourage user invocation after upstream updates.
3. ADR-056-style dual-parse contracts for any new agent-prompt contract change so cached prompts continue to function during the cache-window.
4. P106-shaped tickets (cache-coherence regression class) get filed when divergence surfaces, providing learning evidence for future controls.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: an adopter reports plugin behaviour that diverges from current README/SKILL prose. Or: a release ships an agent-prompt change without dual-parse fallback and the in-flight cache-window produces observable regressions. Or: install-updates run-rate drops below 1/week per active adopter.
- **Metrics**: count of P106-shaped (cache-coherence) tickets filed / quarter; install-updates invocation count from telemetry; observed dual-parse fallback path activations / week (signals cached prompts still in flight).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P106 (claude plugin install is silent no-op — the canonical instance of this class), ADR-056 dual-parse contract was authored in part to mitigate the cache-window for pipeline.md changes.
- **Treatment ADRs**: ADR-030 (install-updates skill governance), ADR-047 (Phase 1 directory scaffold; bootstraps adopter governance state), ADR-049 (plugin-bundled scripts via $PATH bin — the cached version can host the canonical script body), ADR-056 (dual-parse contract pattern).
- **Personas affected**: plugin-user (every cache-divergent session experiences the support cost); plugin-maintainer (release coordination + adopter education cost); plugin-developer (JTBD-101 "extend the suite without painted-into-corner" — cache-coherence is part of "without painted-into-corner").

## Source Evidence

- `~/CLAUDE.md` (or project briefing) lines codifying "Plugin hooks run from the marketplace cache, not from source" — top-tier briefing entry.
- `docs/problems/106-claude-plugin-install-is-silent-no-op.*` (or current state) — driver ticket for the install-time class.
- `docs/decisions/056-risk-register-back-channel-write-contract.proposed.md` "DUAL-PARSE CONTRACT" section — concrete pattern application.
- `docs/decisions/030-install-updates-skill.*.md` — control authority for install-updates.
- `scripts/repo-local-skills/install-updates/SKILL.md` — control implementation.

## Change Log

- 2026-05-04: Bootstrapped from briefing-codified discipline + P106 evidence + ADR-056 dual-parse pattern. The pre-wipe R006 ("Marketplace cache lag delivers stale plugin behaviour") covered a subset of this class but at residual 8/Medium with imprecise scoping; this entry expands the asset_path to include the prompt-cache (Anthropic-side) and npm-install-cache layers, and grounds the residual in observed install-updates discipline.
