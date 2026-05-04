---
risk_id: R010
slug: semver-or-backward-compatibility-violation
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [packages/*/package.json (version), .changeset/*.md (bump-class), packages/*/skills/*/SKILL.md (skill contracts adopters consume), packages/*/agents/*.md (agent prompts adopters' SKILL.md may invoke), packages/*/hooks/hooks.json (hook event registrations)]
cascade_scope: every adopter consuming the changed contract via npm; every downstream plugin whose skill invokes the changed surface; every adopter SKILL.md that references the changed agent prompt by name
afk_class: both
reversal_class: npm-permanent-with-deprecate-cycle (semver violations are recoverable via deprecation + republish but the broken-version remains in the registry indefinitely)
control_budget_class: per-changeset-edit (changeset version-class field) + per-edit-llm at architect review
dogfood_days: changesets-action discipline ~ongoing project-wide
authority_class: framework-resolved (semver bump-class is mechanical given the change category); deviation-approval (treating a breaking change as minor requires explicit user approval)
prompt_cache_window: ongoing
ci_a: integrity (advertised version contract diverges from shipped behaviour); availability (semver violations break consumer expectations of compatible upgrade)
agentic_category: cascade (cross-plugin contract changes ripple through composition graphs)
---

# Risk R010: Semver / backward-compatibility violation on plugin contracts

## Description

Each `@windyroad/*` plugin is independently versioned via Changesets. Bump class — patch / minor / major — is declared in the changeset frontmatter and consumed by `changesets-action` to compute the new version. Semver violations occur when the bump class understates the actual breaking-change content of the release: a behaviour change the changeset author labelled "minor" is in fact a breaking change for adopters consuming the prior contract.

Distinct from generic software defects (R008) because the violation surface is specifically the **adopter contract**: SKILL.md that adopters' user prompts invoke; agent prompts that adopters' SKILL.md references by name; hook events whose triggers shift; CLI flag shapes that adopters' shell scripts depend on. Adopter trust in `@windyroad/foo@^0.5.0` upgrades non-breakingly is a semver promise; violations fracture that promise.

The agentic context amplifies the risk: SKILL.md prose is the *contract* adopters consume by reading; an agent prompt change that shifts behaviour silently (without a changeset bump-class signal) is a contract change adopters won't notice until they hit the new behaviour. Prompt-cache lag (R004) extends the divergence window.

**Source → event → consequence chain**: source = behavioural change to a published surface (SKILL.md flow, agent.md output contract, hook event, script CLI) without paired major bump (or without paired backward-compat fallback like ADR-056 dual-parse); event = adopter pulls update under `^` semver range expecting non-breaking; consequence = adopter's downstream code/SKILL/automation breaks against the upgraded plugin.

## Inherent Risk

- **Impact**: 4/5 (Significant) — adopter workflows break across upgrade window; trust-budget consumed; adopter must read CHANGELOG carefully or pin to prior version.
- **Likelihood**: 3/5 (Possible) — corpus evidence: ADR-056 dual-parse contract was authored specifically to preserve backward-compat for in-flight cached prompts (a near-miss for a violation); P099 / P100 retrospective-briefing-migration was multi-slice WIP that had to be coordinated across two slices precisely to avoid adopter-facing contract break.
- **Inherent Score**: 12
- **Inherent Band**: High

## Controls

- **Changesets bump-class discipline** — every changeset declares patch / minor / major; consumed by `changesets-action`. **Effectiveness**: medium — depends on author honesty in classifying the change; reviewer catches obvious miscategorisations. Reduces likelihood from 3 to 2.
- **`packages/itil/hooks/itil-changeset-discipline.sh`** (P141) — gates `git commit` on packages/* source change without `.changeset/*.md`. **Effectiveness**: medium-high — ensures EVERY plugin source change has an explicit changeset to classify. Eliminates the "no-changeset-at-all" failure mode (would reduce that sub-class from 2 to 1) but does NOT catch under-classification (a breaking change labelled `minor`). Project-wide residual likelihood reflects the under-classification gap, which the gate does not address.
- **Architect review on every SKILL/agent/hook edit** — reviewer assesses whether change shifts published contract; flags candidates for major bump. **Effectiveness**: medium — depends on reviewer's attention to backward-compat dimension.
- **ADR-056 dual-parse contract pattern** — concrete pattern for handling in-flight cached prompts when an agent contract changes. Codifies "ship backward-compat fallback in the same release as the new contract". **Effectiveness**: high for cases where the pattern is applied; low for cases where author doesn't recognise the need.
- **Held-changeset / dogfood-window pattern (R002 control)** — gives in-repo time to discover semver-violation symptoms before adopter exposure.
- **`/wr-itil:report-upstream` skill (ADR-024)** — bidirectional cross-reference for adopter-reported issues; surfaces semver violations the adopters discover post-release.

## Residual Risk

- **Impact**: 4/5 (Significant) — controls reduce probability but don't change consequence shape if a violation does ship.
- **Likelihood**: 2/5 (Unlikely) — changeset-discipline gate + bump-class field + dual-parse pattern + dogfood discipline each contribute reduction. Observed near-misses (ADR-056 dual-parse, P099/P100 multi-slice) suggest the pattern WORKS — violations are caught at design time rather than at adopter time.
- **Residual Score**: 8
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; would require automated breaking-change detection (CI surface) to drop residual further.

## Treatment

**Mitigate**. Continue changeset-discipline + bump-class field + dual-parse pattern as primary controls. Future mitigation: automated breaking-change detection (an architect/JTBD-bot that flags changes to published-surface signatures and recommends bump class). Deferred until evidence justifies the cost.

**Active mitigations**:
1. P141 changeset-discipline gate ensures every plugin source change has a changeset.
2. Bump-class declaration in every changeset.
3. ADR-056 dual-parse pattern for in-flight cached prompts.
4. Architect review on every SKILL/agent/hook edit.
5. Dogfood-window for hook/skill changes (R002 control).
6. Adopter reports surface via `/wr-itil:report-upstream` (ADR-024).

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: an adopter reports a breaking change shipped under a non-major bump (post-hoc trigger). Or: a changeset's bump class is corrected during review (signal: classification needs better tooling). Or: ADR-056-style backward-compat patterns are NOT applied where they should have been (signal: pattern needs more visibility).
- **Metrics**: count of bump-class corrections during review / month; count of adopter-reported breaking changes / quarter; count of dual-parse contracts shipped / quarter (signal: pattern adoption rate).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P099 / P100 (retrospective-briefing migration multi-slice), ADR-056 (dual-parse pattern; preserves backward-compat for cached prompts).
- **Generalisation-of**: R008 (functional defects). Specialises by focusing on the *adopter contract* surface specifically.
- **Treatment ADRs**: ADR-056 (dual-parse contract pattern), ADR-018 (release cadence), ADR-014 (single-commit grain — bumps and source changes ride together), ADR-024 (report-upstream skill — adopter-feedback channel), ADR-042 (auto-apply remediations including held-area for risky bumps).
- **Personas affected**: plugin-user (semver promise breakage breaks adopter workflows); plugin-developer (JTBD-101 — clear patterns for cross-plugin contract changes); plugin-maintainer (release-coordination + semver-correctness cost).

## Source Evidence

- `docs/decisions/056-risk-register-back-channel-write-contract.proposed.md` "DUAL-PARSE CONTRACT" section — concrete pattern that preserved backward-compat for an agent-prompt change.
- `.changeset/*.md` history — patch / minor / major declarations.
- `docs/changesets-holding/` — held-area pattern for high-risk bumps awaiting dogfood evidence.
- `packages/itil/hooks/itil-changeset-discipline.sh` — changeset-discipline gate.
- `docs/decisions/024-report-upstream-skill.*.md` — adopter-feedback channel.

## Change Log

- 2026-05-04: Bootstrapped post-wipe addressing user observation that the post-wipe register skipped the bedrock software-delivery surface. R010 specialises R008 by focusing on adopter-contract semver. Inherent / Residual estimated from corpus near-miss evidence (ADR-056 + P099/P100) + control inventory.
