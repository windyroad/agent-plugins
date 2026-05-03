---
"@windyroad/retrospective": minor
---

P137 Phase 1 — plugin-published artefacts use namespace-prefixed permalinks for internal IDs (ADR-055).

Adds `check-internal-id-leaks.sh` at
`packages/retrospective/scripts/check-internal-id-leaks.sh` — a read-only
advisory script that walks shipped-artefact surfaces under
`<root>/packages/<plugin>/` (skills/<skill>/SKILL.md, agents/*.md,
hooks/*.sh, CHANGELOG.md) and reports each artefact carrying bare
internal-ID tokens (`ADR-NNN` / `JTBD-NNN` / `PNNN`) that lack the
`WR-` namespace prefix.

The detector emits `OVER <plugin>/<file> bare_count=<N>` lines for each
file with leaks plus a final `TOTAL packages=<N> with_leaks=<M>
drift_instances=<K>` summary. Output is empty when no shipped artefact
carries bare tokens — silent-on-pass per the hook injection budget
discipline. Always exits 0 (advisory only); exit 2 only on root-dir
parse error.

REFERENCE.md sibling files are excluded from the scan per the SKILL.md
runtime budget policy — they are intentionally lazy-loaded
maintainer-facing content, not adopter-runtime. Lines beginning
`# @adr` / `# @jtbd` / `# @problem` are also excluded so docstring
structured annotations on script bodies don't false-fire (those
annotations are maintainer source comments, never expanded into
adopter agent context).

ADR-055 (proposed in this release at
`docs/decisions/055-plugin-published-namespace-prefixed-internal-ids.proposed.md`)
codifies the resolution strategy. The chosen rule is **namespace-prefix
as primary** (`ADR-014` written as `WR-ADR-014`, `JTBD-101` as
`WR-JTBD-101`, `P137` as `WR-P137`) with **GitHub permalinks as
progressive enhancement** — `[WR-ADR-014](https://github.com/windyroad/agent-plugins/blob/main/...)`.

Rationale — only namespace-prefixing closes the wrong-resolution failure
path. Adopter agents pattern-match on the visible token, not the URL
host. `[ADR-014](https://github.com/windyroad/...)` still presents
`ADR-014` as the human-readable token; an adopter project that has its
own `ADR-014` will conflate them at the agent's pattern-match stage.
Only a token-level disambiguator (`WR-`) closes failure mode 3 (adopter
agent applies UNRELATED ADR-014 from its own tree).

Five candidate strategies were considered (per the driver ticket §RCA);
ADR-055 explicitly rejects strip (lossy — kills institutional
cross-references), disclaimer-at-top (brittle — disclaimer fades from
agent working memory by tool-result expansion), and build-step rewrite
(premature — adds publish-pipeline coupling to solve a problem
namespace + opportunistic-sweep solves at lower cost).

A bin shim at `packages/retrospective/bin/wr-retrospective-check-internal-id-leaks`
follows the bin/-on-PATH grammar so adopters running
`npx @windyroad/retrospective` can invoke the detector via
`wr-retrospective-check-internal-id-leaks` once their plugin install
wires it onto `$PATH`.

The bats fixture at
`packages/retrospective/scripts/test/check-internal-id-leaks.bats` is
behavioural-default — asserts script *output* on temp-fixture trees,
never script source content. 23 tests covering bare-ID detection across
all 4 surfaces, WR-prefix exclusion, docstring-annotation exclusion,
REFERENCE.md exclusion, deterministic ordering, count accuracy, TOTAL
summary aggregation, and error path.

**Baseline measurement** (2026-05-03 against the windyroad-claude-plugin
source repo): `TOTAL packages=13 with_leaks=81 drift_instances=2880`.
This is the reassessment-anchor count. Phase 2 opportunistic sweep
proceeds when files are touched for other reasons; Phase 3 (promotion
to blocking PreToolUse hook) triggers when `drift_instances ≤ 100` and
three consecutive monthly retros confirm no regression.

ADR-055 completes the adopter-context cluster of ADRs landed
2026-04-28..2026-05-03: bin/-on-PATH (executable correctness),
JTBD-anchored README (currency), behavioural-tests-default
(test-discipline), maturity taxonomy (battle-hardening signal), SKILL.md
runtime budget (size), and now namespace-prefixed internal IDs
(semantic correctness). Six ADRs unified by the plugin-user
"trust adopter-facing artefacts" frame.

This release ships Phase 1 only — the advisory detector + the strategy
ADR. Mechanical replacement across the 2,880 baseline drift instances
follows opportunistically, no big-bang rewrite.
