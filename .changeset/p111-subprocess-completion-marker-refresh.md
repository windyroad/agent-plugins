---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
"@windyroad/risk-scorer": patch
---

Gate markers now survive long-running Agent and Bash subprocesses (P111).

A new PostToolUse hook (`*-slide-marker.sh`) fires on Agent and Bash tool
completion in the parent session. If the parent already holds a valid gate
marker, the hook touches it — sliding the TTL window forward — so the wall-
clock time spent inside an Agent-tool subagent or a `claude -p` iteration
subprocess no longer counts against the parent's TTL.

The slide is bounded:

- The hook only TOUCHES an existing marker. It NEVER creates one — creation
  still requires a real gate review with verdict parsing in
  `*-mark-reviewed.sh`.
- The hook skips the touch when `tool_response.is_error` is true. A failed
  subprocess does not extend the parent's trust window.
- For risk-scorer, only the score files (`commit`, `push`, `release`) are
  slid. The `*-born` markers are deliberately invariant under sliding so
  the 2×TTL hard-cap from P090 still bounds total marker life.

This replaces the symptom-treatment of P107 (TTL bumped 1800s → 3600s) with
the architectural fix per ADR-009's new "Subprocess-boundary refresh"
subsection. Adopters who configured a non-default `ARCHITECT_TTL` /
`REVIEW_TTL` / `RISK_TTL` envvar do not need to change anything.
