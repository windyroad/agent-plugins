---
"@windyroad/itil": patch
---

P293: work-problems SKILL.md Step 0 prose reframing to match ADR-019's amended 3-branch clean-state preflight (Pull / Commit / AskUserQuestion-or-AFK-halt). Branch 1's existing fetch/divergence path and Branch 3's existing P109 session-continuity detection pass are unchanged in mechanism; the change is prose framing + Non-Interactive Decision Making table tagging + a new Branch 2 (deferred) row. No bats changes — the P109 5-signal enumeration is preserved verbatim per architect Condition 2 so existing contract-assertion bats continue to hold.
