# Problem 087: No maturity / battle-hardening signal on plugins, skills, agents, or hooks — READMEs don't tell users which features are stable vs experimental

**Status**: Open
**Reported**: 2026-04-21 (AFK iter-7 post-run, user observation)
**Priority**: 12 (High) — Impact: Significant (3) x Likelihood: Almost Certain (4)
**Effort**: L — requires: (a) an ADR defining the maturity taxonomy (Experimental / Alpha / Beta / Stable / Deprecated, or similar), promotion/demotion criteria, and where the signal lives (README badge, plugin.json frontmatter, manifest field, or runtime); (b) a measurement mechanism that actually computes the signal from observable evidence (not self-report); (c) surfacing the signal in every plugin's README, `claude plugin list` output, and the marketplace listing; (d) retroactive assessment for the 11 existing `@windyroad/*` plugins and every skill/agent/hook within them. Cross-cutting — touches every plugin, the marketplace manifest, and likely a new shared telemetry/metrics convention.
**WSJF**: 3.0 — (12 × 1.0) / 4 — High severity (users currently cannot distinguish `manage-incident` which has never fired in anger from `manage-problem` which has shipped hundreds of tickets this repo alone — adoption decisions are made blind); L effort because it's ADR-level cross-cutting + retroactive assessment across 11 plugins.

## Description

Observed 2026-04-21 (user direction, verbatim): *"the readme files give no indication of how robust or battle hardened each skill plugin feature is. For instance the mitigate-incident skill has never been used in anger, but the run-retro skill and manage-problem skill and the architect controls have been used hundreds if not thousands of times. How might we determine this?"*

Every `@windyroad/*` plugin's README today reads as if the plugin were uniformly mature. `manage-incident`'s newly-split `mitigate-incident` / `restore-incident` / `close-incident` / `link-incident` skills — shipped this session in `@windyroad/itil@0.15.0`, with 600+/600+ bats green but **zero real-world invocations** — look identical to `manage-problem` (several hundred real invocations), `run-retro` (dozens of real retros across this session alone), and the architect / JTBD / risk-scorer hooks (fired on every edit in every project for weeks).

A user evaluating which plugin to adopt — or which skill to invoke — has no signal to calibrate trust against. The existing `@windyroad/*` suite ships:

- **High-usage, well-exercised**: `manage-problem`, `run-retro`, `create-adr`, `wr-architect:agent`, `wr-jtbd:agent`, `wr-risk-scorer:pipeline`, `/install-updates`, `/push:watch`, `/release:watch`, architect + JTBD + TDD + risk-scorer PreToolUse/PostToolUse gate hooks.
- **Shipped but low-usage**: `mitigate-incident`, `restore-incident`, `close-incident`, `link-incident` (all just split this session, never fired in practice), `list-incidents`, `/wr-itil:report-upstream`, `/wr-itil:capture-problem` (not yet shipped per ADR-032 but on roadmap), `/wr-retrospective:capture-retro`, `/wr-architect:capture-adr`.
- **Shipped but niche**: `/discord:configure`, `/wr-connect:setup`, `/wr-c4:generate`, `/wr-wardley:generate`.
- **Shipped but near-zero-signal**: ADRs (11 plugins × multiple ADRs, all `status: proposed`, none `accepted` despite heavy exercise).

Users cannot distinguish any of these categories today.

## Symptoms

- Plugin READMEs uniformly present features in feature-list shape. No "Stability: Stable / Beta / Experimental" indicator. No "Invocations logged this release: N" indicator. No "Known issues in this skill's area: M" indicator.
- `claude plugin list` output is version-only. No maturity column.
- The marketplace manifest (`marketplace.json`) has no maturity field. Adopters pick plugins by title alone.
- `docs/problems/` backlog has ticket IDs but no aggregation per skill — a user scanning "how buggy is `manage-incident`?" has to eyeball titles.
- ADR `status: proposed` is binary and stale — everything is proposed; nothing gets promoted to `accepted` even when heavy exercise would warrant it.
- Newly-shipped skills (e.g. slice 6b/c/d shipped 20 minutes ago at the time of this ticket) look identical to skills that have been bullet-proofed over weeks.
- Users reading a 648/648 bats-green signal may mistake **structural doc-lint PASS** for **behavioural robustness**. The test count increases look impressive but don't distinguish "the skill has been exercised 1000× without bug" from "the skill has a well-formed SKILL.md".

## Workaround

User manually inspects git log / commit history / problem ticket citations to build a mental model of which features are mature. Defeats the signal-on-the-tin promise.

## Impact Assessment

- **Who is affected**:
  - **Plugin adopters (JTBD-101 Extend the Suite with Clear Patterns)** — "clear patterns" includes clarity about which features are safe to bet on. Without maturity signal, every plugin looks equally mature/unproven.
  - **Solo-developer persona (JTBD-003 Compose Only the Guardrails I Need)** — composing the suite requires knowing which features are stable enough to depend on. No signal = defensive over-compose or accidental under-compose.
  - **Contributors (JTBD-101)** — no signal for where to invest hardening effort. Low-usage features accumulate surface-level quality (tests pass) without real-world exercise.
  - **Tech-lead persona (JTBD-201 Restore Service Fast with an Audit Trail)** — audit trail requires knowing the runtime confidence level of every guardrail the audit depends on. Uniform presentation undermines audit confidence.
- **Frequency**: every plugin installation, every skill invocation decision, every architectural decision about which skill to rely on. Compounds as the suite grows.
- **Severity**: High. The plugin suite's credibility rests on users trusting the guardrails — and trust requires signal.

## Root Cause Analysis

### Structural

Plugin READMEs are authored from a "feature inventory" stance. There's no convention (no ADR, no shared template, no CI assertion) that requires a maturity indicator, a usage count, or an exercise-evidence cite. The marketplace manifest has no such field either. There's no telemetry layer — neither local nor opt-in — that would enable the signal to be computed rather than self-reported.

This is a **design-level gap**, not a single-plugin bug. The whole suite ships without a convention for "how battle-tested is this?" — so every new plugin inherits the gap and every existing plugin masks its own maturity.

### Measurement candidates

The core question from the user ("How might we determine this?") decomposes into (a) what to measure, (b) how to collect it, (c) how to surface it. Six candidate approaches, ranked by signal fidelity × implementation cost:

1. **Claude Code session-transcript analysis (observational, high-fidelity)** — parse `~/.claude/projects/*/sessions/*.jsonl` for `Skill` / `Agent` / `Bash npm run ...` tool invocations, grouped by skill name. Aggregate across all user sessions on the host. Pros: retrospective (works for already-shipped skills), real usage (not self-report), opt-in by definition (user owns the logs), deterministic counts. Cons: host-local only (won't aggregate across the plugin-user community), privacy-sensitive (transcripts contain user content), transcript format may change upstream. **Best fit for THIS repo's internal signal** — each adopter can run the analysis on their own history.

2. **Commit-history + problem-ticket heuristic** — count commits touching each plugin/skill's files (source + SKILL.md + bats + changesets) over the last N weeks; count closed problem tickets citing the skill; count days since first release. Emit a composite "exercise index". Pros: deterministic from git, no new infrastructure. Cons: commits-touching-the-file is a proxy for activity, not invocation; may over-credit skills that get churned vs skills that just work. **Good complement to option 1.**

3. **Explicit maturity badge in plugin.json frontmatter / README header** — per-plugin + per-skill "maturity: experimental | alpha | beta | stable | deprecated" with promotion criteria spelled out in an ADR. Each plugin owner maintains the badge. Pros: simple, immediately visible in `claude plugin list` if we extend the output. Cons: self-report is subjective; owners drift (everything becomes "beta" forever or everything becomes "stable" to avoid friction).

4. **Opt-in local telemetry hook** — PostToolUse hook on `Skill` invocations that writes a timestamped line to `~/.claude/metrics/windyroad-skill-invocations.jsonl`. A `/wr-itil:usage-report` skill aggregates. Pros: deterministic counts going forward, privacy-local. Cons: only forward-looking (doesn't help for already-shipped skills; option 1 does that), requires a new hook file per plugin that emits.

5. **GitHub Actions / CI-assertion signal** — a per-plugin CI job that asserts "this plugin has N% test coverage and at least M commits touching it in the last N days". Emits a badge in the README (shields.io-style). Pros: objective, automated, visible. Cons: CI coverage doesn't equate to battle-hardening; easy to game with test-churn.

6. **Community-usage signal** — count downloads from npm registry (weekly/monthly), stars on the repo, install-updates triggers per release. Pros: cross-community signal. Cons: npm download counts are noisy (CI runs, mirror traffic); stars aren't about usage. **Weakest on its own, useful as a multiplier.**

Recommended: **(1) + (2) + (3) combined**. Session-transcript analysis + commit-history heuristic gives retroactive and forward-looking deterministic signal; an explicit maturity badge (with promotion criteria tied to the objective signals) gives the user-facing presentation. Option (4) as a forward-looking complement once the infrastructure is drafted. Options (5) and (6) are optional multipliers, not primary.

### Promotion criteria (strawman, for the ADR)

An ADR defining the taxonomy should probably pin:

- **Experimental** — shipped within last 14 days; < 10 invocations observed; < 3 resolved problem tickets involving the skill's files.
- **Alpha** — 14-60 days shipped; 10-100 invocations; 3-10 resolved problem tickets; any breaking changes in the window.
- **Beta** — 60-180 days; 100-1000 invocations; 10+ resolved tickets; no breaking changes in last 30 days.
- **Stable** — 180+ days; 1000+ invocations; sustained low rate of new ticket creation (indicator of diminishing novelty); no breaking changes in last 90 days.
- **Deprecated** — author-declared; supersede-by path exists.

Thresholds tunable per plugin surface (e.g. AFK orchestrators accumulate invocations fast but ADRs accumulate slowly).

## Related

- **JTBD-003** (Compose Only the Guardrails I Need) — composing safely requires maturity signal.
- **JTBD-101** (Extend the Suite with Clear Patterns) — "clear patterns" includes clarity about stability.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — audit confidence depends on knowing runtime-exercise level of each guardrail.
- **P082** (no voice-tone or content-risk gate on commit messages) — adjacent plugin-suite gap on the commit surface.
- **ADR-010** (skill-split naming / deprecation-window) — deprecation has a lifecycle entry in the maturity taxonomy.
- **ADR-022** (problem verification pending) — parallels "status lifecycle" concept this ticket proposes for skills.
- `README.md` files under every `packages/*/` — targets for the retroactive assessment.
- `marketplace.json` — target for a potential manifest field.
- `~/.claude/projects/*/sessions/*.jsonl` — evidence source for option 1.
- `docs/decisions/` — needs a new ADR (candidate title: "Plugin / skill / agent maturity taxonomy") before implementation.

### Investigation Tasks

- [ ] Architect review on the fix shape: option taxonomy (which of the six to pursue), ADR-level vs SKILL.md-level assertions, retroactive assessment scope.
- [ ] Draft ADR defining the maturity taxonomy, promotion/demotion criteria, and the measurement mechanism.
- [ ] Prototype option 1 (session-transcript analysis) on this session's history to confirm signal fidelity. Produce a per-skill invocation count for the last 30 days and sanity-check against intuition ("manage-problem should be near the top; mitigate-incident should be near zero").
- [ ] Prototype option 2 (commit-history heuristic) via `git log --name-only` + grep for each plugin's path. Produce a composite exercise index.
- [ ] Design the presentation layer: README badge, `claude plugin list` column extension, marketplace manifest field, or a mix.
- [ ] Retroactive assessment for all 11 `@windyroad/*` plugins and every skill within them. Apply the promotion criteria. Update READMEs.
- [ ] Bats coverage: doc-lint each plugin's README for the maturity badge's presence.
- [ ] Decide whether/how to ship option 4 (opt-in local telemetry hook) as a forward-looking complement. Per-plugin hook file or suite-wide.

## Decision record

No ADR yet. This ticket closes when the ADR lands and every plugin's README carries the maturity signal (initial values set per the retroactive assessment). Likely breaks into multiple phases per P047's staged-landing pattern.
