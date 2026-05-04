# R010: Semver / backward-compatibility violation on plugin contracts

Each `@windyroad/*` plugin is independently versioned via Changesets; bump class (patch / minor / major) is declared in the changeset frontmatter. Semver violations occur when the bump class understates the breaking-change content: a behaviour change labelled "minor" that's actually breaking for adopters consuming the prior contract. Adopters under `^` semver range pull the upgrade non-breakingly and discover the break later. Trust-budget impact is high because the semver promise is a load-bearing adopter expectation.

The agentic context amplifies the risk: SKILL.md prose IS the contract adopters consume by reading (their user prompts invoke skills by their documented Step-N flow); an agent prompt change that shifts behaviour silently is a contract change adopters won't notice until they hit the new behaviour. Prompt-cache lag (R006-adjacent) extends the divergence window.

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 4 (Significant) — adopter pulls under `^` semver expecting non-breaking; gets break; their downstream code/SKILL/automation fails. Per L64.
- **Likelihood**: 3 (Possible) — bump-class miscategorisation is uncommon but real; without controls, hook-prose-as-patch case is recurring.
- **Inherent score**: 12
- **Inherent band**: High

## Residual risk

Per `RISK-POLICY.md` `## Control Composition`:

- **Likelihood after controls**: 1 (Rare) — three independent paths: changesets bump-class declaration field (forces author to classify); P141 changeset-discipline gate (forces every plugin source change to declare); ADR-056 dual-parse contract pattern (preserves backward-compat for the in-flight cached-prompts sub-class). Architect review + held-changeset are 4th + 5th paths but the first three are sufficient for capped reduction. 3 → 2 → 1 → 1.
- **Residual score**: 4
- **Residual band**: Low

**At appetite** (= 4/Low). Could drop further with automated breaking-change detection (CI surface diffing published-surface signatures and recommending bump class) but doesn't currently exist; deferred until evidence justifies the cost.

## Controls

- **Changesets bump-class declaration** — every changeset declares patch / minor / major; consumed by `changesets-action` to compute the new version. Author honesty is the load-bearing element; reviewers catch obvious miscategorisations.
- **`packages/itil/hooks/itil-changeset-discipline.sh`** (P141) — gates `git commit` on `packages/*/source` change without `.changeset/*.md`; ensures the bump-class field exists for classification.
- **ADR-056 dual-parse contract pattern** — when an agent-prompt or hook contract changes shape, ship the new shape AND a backward-compat fallback in the same release so in-flight cached prompts continue to function. Concrete pattern, applied successfully on the `RISK_REGISTER_HINT:` 2-column → 3-column transition.
- **Architect review on every SKILL/agent/hook edit** — reviewer assesses whether change shifts published contract; flags candidates for major bump.
- **Held-changeset / dogfood-window pattern** — gives in-repo time to discover semver-violation symptoms before adopter exposure.
- **`/wr-itil:report-upstream` skill** (ADR-024) — bidirectional cross-reference for adopter-reported issues; surfaces semver violations adopters discover post-release.

## Watch-out

- Sub-class of R005 (release coordination) but distinct: R005 is about the **changeset queue shape** (multiple bumps coordinating); R011 is about the **bump-class semantic accuracy** (is `minor` actually correct for THIS change?).
- Hook prose changes that ship under `patch` but actually shift behaviour are a recurring under-classification mode. If a hook's deny message changes wording, that's patch. If it changes deny BEHAVIOUR (gating new file types, blocking a previously-allowed bypass), that's minor or major depending on adopter impact.
- Agent prompt changes are particularly prone — they ARE the contract adopters consume. Adding a new mandatory step in a SKILL.md flow is at minimum minor; removing or reordering steps is major.
- Automated breaking-change detection (CI surface that diffs published-surface signatures and recommends bump class) would drop residual further but doesn't currently exist in this project.
- ADR-056's dual-parse pattern is the in-flight-cached-prompts mitigation — apply it whenever an agent prompt contract changes shape, even under a major bump, because adopters' cached prompts won't refresh until ~7-day TTL.
