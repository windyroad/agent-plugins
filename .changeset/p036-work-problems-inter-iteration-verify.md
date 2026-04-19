---
"@windyroad/itil": patch
---

Add inter-iteration verification to `wr-itil:work-problems` AFK orchestrator (closes P036). After the release-cadence check and before the next iteration, the skill now runs `git status --porcelain` and halts the loop if the working tree is dirty for a reason not stated in the last iteration's report. This is defence-in-depth behind P035's fallback: it catches silent subagent commit failures (a failure inside the assess-release skill, a git conflict, a malformed commit message) that would otherwise accumulate across iterations and corrupt the final summary. Non-interactive default recorded in the decision table. Recovery is explicitly out of scope per ADR-013 Rule 6 — the check surfaces the bug, the user decides. Includes a 6-test doc-lint bats regression file.
