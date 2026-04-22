---
"@windyroad/itil": patch
---

P093 — resolve `/wr-itil:transition-problem` ↔ `/wr-itil:manage-problem` circular delegation for `<NNN> <status>` args.

`/wr-itil:transition-problem` now hosts the Step 7 transition block inline: pre-flight checks per destination (Open → Known Error / Known Error → Verifying / Verifying → Close), P063 external-root-cause detection with the AFK fallback, `git mv` + Status edit + P057 explicit re-stage, `## Fix Released` section write on the `.verifying.md` destination, P062 README refresh, and the ADR-014 commit through the risk-scorer pipeline gate. The skill no longer re-invokes `/wr-itil:manage-problem` — the round-trip clause that created the infinite-delegation cycle has been stripped from `manage-problem`'s Step 1 `<NNN> <status>` forwarder paragraph.

Per architect guidance, the fix follows a "copy, not move" shape: the in-skill Step 7 block on `manage-problem` stays intact for in-skill callers (Step 9b auto-transition, the Parked path, Step 9d closure inside review). The split skill carries a scoped inline copy for the user-initiated transition path only.

ADR-010 amended with a new **"Split-skill execution ownership"** sub-rule (2026-04-22) codifying the "copy, not move" principle so the same trap does not recur in future clean-split skills.

Existing `transition-problem-contract.bats` test 7 inverted in place to assert no round-trip; test 8 added for inline Step 7 mechanics. Full itil sweep: 736/736 green.
