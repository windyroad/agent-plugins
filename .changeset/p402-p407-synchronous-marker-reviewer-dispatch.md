---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

Dispatch marker-writing review agents synchronously so gate markers persist (P402/P407)

The risk and external-comms gate markers are written by a PostToolUse:Agent mark hook that fires reliably only for a synchronously-dispatched review agent. A background-launched reviewer's mark hook does not fire in time, so no marker persists and the gate re-blocks despite a PASS or within-appetite verdict. Codify synchronous dispatch (run_in_background: false) at the pipeline gate deny message and the reviewer-wrapper / assess skills, matching the external-comms gate deny message that already carried the instruction.
