---
"@windyroad/itil": patch
---

work-problems: document the `is_error: true` stream-timeout salvage carve-out in Step 5 exit-code semantics (P261). When an iter subprocess returns `is_error: true` (API stream idle timeout) after staging coherent work but before committing, the orchestrator may now salvage the staged work — commit it from the main turn with iter-attribution after a fresh commit-gate validation — instead of halting and losing it. Gated on staged files existing AND iter-authored bats passing; else halt per the existing contract. Distinct from the P121 SIGTERM, P147 stuck-before-emit, and P146 bash-polling classes.
