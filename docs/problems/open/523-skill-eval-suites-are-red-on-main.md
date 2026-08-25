# Problem 523: Skill eval suites are red on main, so a green run cannot discharge the prose-surface floor

**Status**: Open
**Reported**: 2026-08-25
**Priority**: 9 (Medium) — Impact: 3 (Moderate — ADR-075 discharge requires the paired eval to PASS on the commit, so a permanently-red suite denies every future change on that surface its strongest control) × Likelihood: 3 (Possible — fires on any commit touching those skills)
**Origin**: internal
**Effort**: M
**WSJF**: 4.5 — (9 × 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

Four eval cases fail on `main`, unrelated to any in-flight change. Measured 2026-08-24/25 with `--no-cache`:

| Suite | Failing case | Assertion |
|---|---|---|
| `manage-problem` | Step 9b auto-transition precedes WSJF persistence (P498) | `not-regex` on `persist(ed\|s)?[\s\S]{0,80}4\.5` |
| `manage-problem` | ADR-099 above-appetite remediation changes shipped behaviour, never changeset location | `regex` on the must-not-release alternation |
| `transition-problems` | Batch Open to Known Error re-rates the status multiplier (P498) | `not-contains` `2.25` |
| `work-problems` | Step 5 I13 exit 3, no story maps — queue ONE entry, never halt (P508) | rubric — output rejects the premise |

This matters beyond the four cases. ADR-075's evidence floor discharges a prose-surface change only when `npx promptfoo eval` **passes on that commit**. While a suite is red, every future change to those skills is denied its paired-eval control and scores higher than it otherwise would — the P519 commit hit exactly this, with the risk scorer crediting the eval control 0 for the affected surfaces.

## Symptoms

- `npx promptfoo eval -c packages/itil/skills/manage-problem/eval/promptfooconfig.yaml --no-cache` → 9 passed, 2 failed.
- `transition-problems` → 1 passed, 1 failed. `work-problems` → 26 passed, 1 failed.
- Failures are stable across runs and independent of the working tree.

## Workaround

Enumerate the failing cases before scoring and declare them pre-existing, so the scorer can distinguish them from regressions introduced by the change under review. This is what the P519 commit did, and it is manual and error-prone — one of the four went unaccounted for on the first pass.

## Impact Assessment

- **Who is affected**: anyone changing `manage-problem`, `transition-problems`, or `work-problems` prose; the risk scorer, which cannot credit a red suite.
- **Frequency**: every commit touching those three skills.
- **Severity**: no shipped behaviour is wrong; the cost is a denied control and manual accounting on every review.

## Root Cause Analysis

Not yet determined per case. The two P498 cases assert on WSJF re-rating arithmetic and ordering; the ADR-099 case asserts remediation scope; the P508 case is a rubric where the model rejects the scenario premise rather than performing the described behaviour. Each may be a genuine prose regression, an assertion that drifted from the current contract, or a scenario the skill no longer describes.

Note a live hazard found while working these: promptfoo compiles assertions with `new RegExp(value)` and **no flags**, so a `^`-anchored pattern anchors at output start rather than line start and can pass unconditionally. Any repair here must be verified non-vacuously in both directions under that semantics.

### Investigation Tasks

- [ ] Per case, determine whether the prose regressed or the assertion drifted, and record which
- [ ] Repair each, verifying non-vacuously under promptfoo's no-flag RegExp semantics
- [ ] Sweep the repo for other `^`-anchored `not-regex` assertions that may be silently inert for the same reason
- [ ] Decide whether eval suites should gate CI, so a red suite cannot persist unnoticed on main

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P498 (status-multiplier re-rating — two of the four cases), P508 (I13 exit-3 — one case)

## Related

- **P498** — the status-multiplier re-rating contract the two P498-tagged cases assert.
- **P508** — the I13 exit-3 queue-one-entry contract the `work-problems` case asserts.
- **ADR-075** — the evidence floor requiring a passing eval run to discharge a prose-surface change.
- **ADR-052 / P081** — behavioural-over-structural test policy these suites implement.
