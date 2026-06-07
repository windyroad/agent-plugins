---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/voice-tone": patch
"@windyroad/style-guide": patch
---

P215: architect-gate deny-reason now carries an explicit recovery directive. `check_architect_gate` exposes `ARCHITECT_GATE_REASON` per failure mode (no marker / TTL expired / drift detected) mirroring the sibling `REVIEW_GATE_REASON` pattern; `architect-enforce-edit.sh` and `architect-plan-enforce.sh` append the reason to the BLOCKED deny message so the agent sees a clear "Re-delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') to refresh the marker." directive without having to read source. Sibling `REVIEW_GATE_REASON` messages in `@windyroad/jtbd`, `@windyroad/voice-tone`, and `@windyroad/style-guide` review-gate.sh sharpened from vague "Re-run the X agent" to the same explicit re-delegation form for symmetry. Marker mechanics unchanged per ADR-009. 7 new behavioural bats green covering the three failure-mode branches plus the enforce-edit deny output. RFC-021 carries the fix per ADR-071.
