# Risk Catalogue

Memory aid for the risk-scorer agent: known risk classes + their typical controls + inherent/residual scoring per `RISK-POLICY.md`. Reading the catalogue at scoring time saves re-deriving them and reduces the chance of forgetting a class previously surfaced. The inherent → residual gap shows where additional controls would pay back the cost.

## Entries

| ID | Class | Inherent | Residual | Gap |
|----|-------|----------|----------|-----|
| [R001](R001-confidential-disclosure-in-outbound-prose.md) | Confidential / business-metric disclosure in outbound prose | 12 (High) | 6 (Medium) | -6 |
| [R002](R002-documentation-and-index-drift.md) | Documentation / index / cross-reference drift across docs | 12 (High) | 6 (Medium) | -6 |
| [R003](R003-hook-regression-shipped-to-adopters.md) | Hook regression / behaviour change ships to adopters | 16 (High) | 4 (Low) | -12 |
| [R004](R004-ambient-unstaged-state-in-commits.md) | Ambient unstaged state included in commits | 6 (Medium) | 2 (Very Low) | -4 |
| [R005](R005-release-coordination-changeset-drift.md) | Release-coordination / changeset queue drift | 9 (Medium) | 3 (Low) | -6 |
| [R006](R006-published-package-vs-source-tree-divergence.md) | Published-package references source-tree-only paths and IDs | 20 (Very High) | 8 (Medium) | -12 |
| [R007](R007-user-stated-preconditions-paired-capability.md) | User-stated preconditions / paired-capability check | 12 (High) | 4 (Low) | -8 |
| [R008](R008-credentials-in-committed-files.md) | Credentials / secrets in committed files | 15 (High) | 5 (Medium) | -10 |
| [R009](R009-functional-defects-in-shipped-behaviour.md) | Functional defects in shipped plugin behaviour (bedrock) | 16 (High) | 8 (Medium) | -8 |
| [R010](R010-semver-or-backward-compatibility-violation.md) | Semver / backward-compatibility violation on plugin contracts | 12 (High) | 4 (Low) | -8 |

## Within appetite (residual ≤ 4/Low)

R003, R004, R005, R007, R010 — controls stack working; further reduction has diminishing returns.

## Above appetite — where we need more controls

| ID | Residual | Next mitigation milestone |
|----|----------|----------------------------|
| **R001** | 6 (Medium) | A 3rd independent control path on outbound prose (semantic-similarity / content-classifier / second-pass review by a different agent) drops residual to 3/Low. |
| **R002** | 6 (Medium) | Drift-class generalisation (P161 observation) — additional load-bearing detectors for the un-covered sub-classes (ADR-vs-ADR; sort-spec across N render-block sites). |
| **R006** | 8 (Medium) | Phase-2 promotion of the namespace-prefix detector + npm-pack detector from advisory to commit-blocking (per the load-bearing-from-the-start pattern P159 / ADR-051). |
| **R008** | 5 (Medium) | At Impact 5 (Severe) the Impact floor caps residual; Likelihood is already at Rare. Treatment is rotation-runbook readiness for the WHEN-not-IF case. |
| **R009** | 8 (Medium) | Bedrock class — defect-free is impossible. ADR-052 Migration retrofit + Phase-2 `tdd-review-test` promotion + harness-maturity (P012) drop residual incrementally; floor ~6 stays. |

## Adding to the catalogue

Identifying a new class during scoring? Author it via `/wr-risk-scorer:create-risk` (interactive) or `/wr-risk-scorer:create-risk --slug <slug>` (orchestrator-driven from an ADR-056 hint).

The catalogue is self-pruning: when a class stops surfacing in `.risk-reports/` (controls have made it rare), retire its entry by renaming `R<NNN>-<slug>.md` to `R<NNN>-<slug>.retired.md`. Git history preserves the prior content.
