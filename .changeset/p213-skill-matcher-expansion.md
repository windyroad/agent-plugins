---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
"@windyroad/risk-scorer": patch
---

P213: PostToolUse:Skill matcher coverage for the slide-marker hook (ADR-009
Option D — P111 matcher expansion).

Long-running SKILL invocations (the `/wr-risk-scorer:assess-{release,wip,
external-comms,inbound-report}` sibling-assessor SKILLs run by the
`/wr-itil:work-problems` AFK orchestrator) previously did not refresh the
parent session's gate markers on completion. The slide-marker hook was
registered on the `Agent|Bash` PostToolUse matcher list only, so a SKILL
that ran longer than the gate TTL window could push the parent's marker
mtime past TTL between SKILL boundaries even when the parent was actively
orchestrating throughout. The symptom: a fresh subagent re-delegation
forced after the SKILL returns, just to satisfy the gate.

This release widens the matcher list to `Agent|Bash|Skill` across the
five review plugins. The slide helper
(`slide_marker_on_subprocess_return` in each plugin's
`hooks/lib/gate-helpers.sh`) is matcher-agnostic — it reads
`tool_response.is_error` and `tool_response.content` from
`_HOOK_INPUT`, both of which are present in Claude Code's uniform
PostToolUse JSON contract regardless of which tool fired. No helper code
change; ADR-017 byte-identity across the four shared lib copies
preserved.

User-visible impact: fewer "gate denied — please re-delegate to
architect/JTBD/risk-scorer" friction events during AFK loops and
interactive sessions that chain multiple SKILL invocations.

ADR-009 2026-06-08 amendment records the contract. The 2×TTL hard-cap
from `<action>-born` continues to bound total marker life; the wider
matcher coverage does not defeat the hard-cap, only makes marker
freshness more reliable within the cap window.

6 new behavioural bats (5 across the byte-identical
`slide-marker-on-subprocess-return.bats` files + 1 hook-level
integration test in `architect-slide-marker.bats`). Full hook suite:
420/420 green (no regression).

Closes P213 on the substance dimension; verification moves to the next
AFK orchestrator session. Architect PASS + JTBD PASS 2026-06-08.
