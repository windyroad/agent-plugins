---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

external-comms gate: require synchronous reviewer dispatch (P402)

The external-comms leak-review mark hook is a PostToolUse:Agent hook that fires
only when the reviewer agent is dispatched synchronously (run_in_background:
false); a background-launched reviewer never persists its marker, so the gate
re-blocked and forced a habitual BYPASS. The canonical deny message now
instructs synchronous dispatch (synced to both consumers per ADR-017; ADR-028
amended).
