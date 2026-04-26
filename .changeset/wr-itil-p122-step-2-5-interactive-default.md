---
"@windyroad/itil": patch
---

work-problems: Step 2.5 stop-condition #2 routing now defaults to AskUserQuestion when available; Outstanding Design Questions table is the AskUserQuestion-unavailable fallback (P122).

The legacy prose ("JTBD-006's persona constraint makes the non-interactive path the default for this skill — AskUserQuestion is the exception, not the rule") conflated persona with runtime mode and caused the orchestrator's main turn to suppress AskUserQuestion in interactive sessions. The orchestrator IS always main turn (interactive by construction); JTBD-006's AFK persona is served by the iteration subprocess workers under the ADR-032 subprocess-boundary contract — they never reach stop-condition #2.

Cross-skill principle (architect FLAG): orchestrator main turns default to AskUserQuestion when available; AFK persona is served by the subprocess-boundary contract under ADR-032, not by suppressing AskUserQuestion at the orchestrator layer.

Step 6.5 Decisions Table row for "Stop-condition #2 with user-answerable skip-reasons" updated to match the flipped default. New `work-problems-step-2-5-routing.bats` (8 doc-lint contract assertions per ADR-037) pins the new contract. Full project bats green.

P103 anti-pattern boundary preserved: AskUserQuestion still scoped to `user-answerable` skip-reasons only; `architect-design` and `upstream-blocked` continue to skip without asking.
