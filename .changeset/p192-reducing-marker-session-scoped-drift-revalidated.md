---
"@windyroad/risk-scorer": patch
---

P192: reducing-bypass markers become session-scoped with drift-revalidation

The risk-scorer pipeline previously consumed `reducing-commit`,
`reducing-push`, and `reducing-release` bypass markers on first use
(`rm -f` then `exit 0`), so every commit / push / release in a
multi-step session had to re-invoke `wr-risk-scorer:pipeline` to re-mint
the marker — even when the work and its risk profile were unchanged.
Three or more rescore round-trips per session were the norm in iterative
work.

The reducing markers now persist across multiple gate invocations within
the standard `RISK_TTL` window AS LONG AS the pipeline-state hash still
matches what was scored. Drift (tree changed beyond the P054 tree-stable
+ doc-excluded inputs) or TTL expiry consumes the marker and forces a
fresh rescore — the drift-detection safety contract is preserved.

`incident-release` is intentionally left single-use — it remains a
deliberate one-time override, regression-guarded by a new bats fixture
asserting it is consumed on use even when the tree hash matches.

This mirrors the in-repo precedent of the `clean` marker, which already
persists until drift. The change extends ADR-009's marker lifecycle
contract to the within-appetite / reducing family.

10 new behavioural bats in
`packages/risk-scorer/hooks/test/reducing-marker-persistence.bats` cover
the full lifecycle (persistence on hash match, consumption on drift,
consumption on TTL expiry, consumption when no state-hash exists, and
the incident-release single-use regression guard). Full risk-scorer
hook suite green at 142/142 (was 132).
