---
"@windyroad/itil": patch
---

work-problems Step 5 dispatch robustness (P089): two bounded refinements within the shipped 0.13.0 `claude -p` subprocess dispatch + 0.14.0 cost-metadata extraction contract — no ADR amendment, no CLI change.

**Gap 1 — stdin-warning redirect.** The canonical Step 5 dispatch command now ends with `< /dev/null` to suppress the `claude -p` 3-second stdin-wait warning. The warning is emitted to stderr, which is fine when streams are consumed separately; under the orchestrator's `2>&1` merge (required to keep stderr prose from interleaving between chained invocations) the warning prefixed stdout and broke `jq` / `json.load` / `JSON.parse` extraction of `.result` and cost metadata. The redirect is the Anthropic CLI help's own suggested workaround. First observed AFK-iter-7 iter 1 (2026-04-21); iter 2-7 used the workaround.

**Gap 2 — authority hierarchy for cost vs usage.** Added an Authority hierarchy paragraph to the Per-iteration cost metadata block and a matching Authority note to the Output Format Session Cost section. `.total_cost_usd` is cumulative-authoritative by CLI contract and is the trusted dollar signal; `.usage.*` is a per-turn response envelope and can reflect only the final-turn ack when the subprocess exits via a background-task completion notification — observed AFK-iter-7 iter 5 where a 1071s wall-clock / 60+ tool-use run reported `duration_ms: 8546, num_turns: 1, usage.* ≈ 137K tokens, total_cost_usd: 6.08` (cost correct, tokens final-turn-only). Session Cost output now renders the cost column as authoritative and labels token totals best-effort. Detection criterion (final-turn-sized usage alongside wall-clock-orders-of-magnitude-larger-than-`duration_ms`) stated descriptively; no change to the named-field extraction list.

No SKILL.md contract break; no runtime behaviour change in the orchestrator. Tests: 6 new assertions in `work-problems-step-5-delegation.bats` (30/30 passing).
