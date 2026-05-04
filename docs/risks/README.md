# Risk Register

> ISO 31000 / ISO 27001 standing-risk inventory for the Windy Road Agent Plugins suite.
> Last reviewed: 2026-05-04 (post-wipe re-bootstrap from corpus evidence per P167 + P168 + ADR-059)

## Purpose

The persistent risk register for agentic AI software delivery. Distinct from:

- `RISK-POLICY.md` — defines criteria (impact / likelihood scales, appetite, treatment principles, confidential information classes).
- `.risk-reports/` — ephemeral per-change pipeline reports auto-deleted after 7 days.
- `docs/problems/` — ITIL problem management (concrete defects).

The register captures **standing risk classes** — recurring patterns observed across the corpus that warrant ongoing treatment with named controls and explicit treatment decisions.

**There is intentionally no `TEMPLATE.md` in this directory.** The entry shape lives in `/wr-risk-scorer:create-risk` (interactive authoring) and `extract-risks-from-reports.sh` (extractor). Adding a `TEMPLATE.md` would create a third source of truth that drifts (per user direction 2026-05-04).

## ISO Mapping

| ISO Clause | Artefact |
|------------|----------|
| ISO 31000 § 6.4.2 — Risk identification | Each entry's `## Description` (source → event → consequence chain) |
| ISO 31000 § 6.4.3 — Risk analysis | `## Inherent Risk` with rationale citing corpus evidence |
| ISO 31000 § 6.4.4 — Risk evaluation | `## Residual Risk` + `Within appetite?` |
| ISO 31000 § 6.5 — Risk treatment | `## Treatment` (Accept / Mitigate / Transfer / Avoid) |
| ISO 31000 § 6.6 — Monitoring and review | `## Monitoring` + `next_review` frontmatter |
| ISO 31000 § 6.7 — Recording and reporting | `## Change Log` + structured frontmatter |
| ISO 27001 § 6.1.2 — Risk assessment | Risks tagged `category: infosec`; `ci_a` frontmatter |
| ISO 27001 § 6.1.3 — Risk treatment / SoA | `## Controls` cite implementation paths |

## Agentic-AI Augmentations to ISO

Beyond ISO 31000/27001, each entry's frontmatter carries agentic-context attributes:

- **`asset_path`** — agents/hooks/skills/tools whose runtime is at stake (the agentic analogue of "asset").
- **`cascade_scope`** — downstream surfaces affected by a regression in this class.
- **`afk_class`** — interactive-only / afk-only / both. AFK risks compound invisibly until session end.
- **`reversal_class`** — git-recoverable / npm-permanent / cache-coherence / config-corrupting / leak.
- **`control_budget_class`** — cost of running the controls (free-hook / per-edit-llm / per-session-llm).
- **`dogfood_days`** — in-repo dogfood maturity for time-aged controls (held-changeset window).
- **`authority_class`** — ADR-044 6-class taxonomy (framework-resolved / direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction).
- **`prompt_cache_window`** — ongoing / window-bounded for risks tied to prompt-cache lag.
- **`ci_a`** — confidentiality / integrity / availability dimension(s) per ISO 27001.
- **`agentic_category`** — judgement / context-economy / determinism / cascade / drift / cache-coherence.

## Register

| ID | Title | Category | Inherent | Residual | Treatment | Owner |
|----|-------|----------|----------|----------|-----------|-------|
| [R001](R001-documentation-runtime-drift.active.md) | Documentation-runtime drift | brand | 16 (High) | 8 (Medium) | Mitigate | plugin-maintainer |
| [R002](R002-hook-regression-cascade.active.md) | Hook regression cascades to installed adopter machines | operational | 16 (High) | 3 (Low) | Mitigate | plugin-maintainer |
| [R003](R003-confidentiality-leakage-via-outbound-prose.active.md) | Confidentiality leakage via outbound prose | infosec | 15 (High) | 4 (Low) | Mitigate | plugin-maintainer |
| [R004](R004-marketplace-prompt-cache-divergence.active.md) | Marketplace / prompt-cache vs source divergence | delivery | 12 (High) | 6 (Medium) | Mitigate | plugin-maintainer |
| [R005](R005-cross-package-release-coordination-drift.active.md) | Cross-package release coordination drift | delivery | 12 (High) | 3 (Low) | Mitigate | plugin-maintainer |
| [R006](R006-authority-delegation-confusion.active.md) | Authority-delegation confusion | brand | 12 (High) | 6 (Medium) | Mitigate | plugin-maintainer |
| [R007](R007-ambient-state-leaks-into-commits.active.md) | Ambient / unstaged state leaks into commits | operational | 6 (Medium) | 4 (Low) | Mitigate | plugin-maintainer |

## Within Appetite

- **R002** (3/Low) — held-changeset + bats discipline drives residual well below appetite.
- **R003** (4/Low) — at boundary; external-comms gate dogfood drives convergence.
- **R005** (3/Low) — changeset-discipline gate + held-area + ADR-014 grain stack to Rare.
- **R007** (4/Low) — at boundary; gitignore + per-commit discipline.

## Above Appetite

- **R001** (8/Medium) — drift-class generalisation (P161) is the next mitigation milestone.
- **R004** (6/Medium) — accept structural property; invest in dual-parse contracts + install-updates discipline.
- **R006** (6/Medium) — ADR-044 alignment audit (P136) is the next mitigation milestone.

Above-appetite is intentional for these risk classes — see each entry's `## Treatment` for the rationale. Per RISK-POLICY.md `## Risk Catalog`: "A catalog-documented residual above appetite IS a real signal — baseline controls are not sufficient for the typical action that triggers this risk class."

## Retired

(none — the pre-wipe R001-R006 entries that previously occupied these IDs were authored under pre-correction conservatism per P167 and were wiped via `git rm` in commit `8edaf7b` per user direction 2026-05-04. Git history preserves their content.)

## How to Add a Risk

- **On demand**: `/wr-risk-scorer:create-risk` (interactive authoring against the inlined entry shape).
- **Orchestrator-driven prefilled**: `/wr-risk-scorer:create-risk --slug <slug> --prefill <prose>` per ADR-059 — orchestrator drains the ADR-056 hint queue.
- **From the corpus** (one-shot bootstrap): `/wr-risk-scorer:bootstrap-catalog` — walks `.risk-reports/` corpus, dedupes by slug, writes per-theme entries with grounded scoring + cited controls + treatment decisions. NOT per-report paraphrasing.

## How to Review

On `next_review` date or trigger event:
1. Re-read corpus evidence cited in `## Source Evidence`.
2. Re-assess Likelihood (especially: did frequency change?).
3. Re-assess Controls effectiveness (any controls retired? any new ones landed?).
4. Recompute Residual.
5. Update `## Change Log` with the review's findings.
6. If treatment changes (e.g., Mitigate → Accept), document the rationale.

## Relationship to Other Artefacts

```
RISK-POLICY.md        ──▶ defines impact/likelihood criteria, appetite, confidential classes
      │
      ▼
docs/risks/R<NNN>.*.md ──▶ standing risk classes with grounded scoring
      │                        │
      │                        ├──▶ controls cite packages/*/hooks/, packages/*/skills/, ADR-NNN
      │                        ├──▶ realised-as links to docs/problems/P<NNN>
      │                        └──▶ treatment rationale + monitoring triggers + change log
      ▼
.risk-reports/*.md    ──▶ per-action pipeline snapshots (ephemeral; 7-day cleanup); RISK_REGISTER_HINT bullets feed back into the register via /wr-risk-scorer:bootstrap-catalog + ADR-056 hint-and-drain
```
