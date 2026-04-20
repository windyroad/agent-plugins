---
"@windyroad/itil": minor
---

**manage-problem + work-problems**: wire the external-root-cause detection surface so `manage-problem` prompts for `/wr-itil:report-upstream` invocation when root cause points upstream (closes P063).

New behaviour:

- `manage-problem` Step 7 (Open → Known Error transition) scans Root Cause Analysis for strict external markers: explicit `upstream` / `third-party` / `external` / `vendor` labels, or scoped-npm pattern `@[\w-]+/[\w-]+`. On hit, fires `AskUserQuestion` with three options: invoke `/wr-itil:report-upstream` now, defer and note in ticket, or mark false positive.
- Parked lifecycle gains a pre-park hook: parking with `upstream-blocked` reason runs the same detection.
- AFK non-interactive fallback (per ADR-013 Rule 6) appends the stable marker `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` to the ticket's `## Related` section. The skill is NOT auto-invoked (its Step 6 security-path is interactive per ADR-024 Consequences).
- `work-problems` `upstream-blocked` skip category now runs the AFK fallback before skipping so accumulated upstream dependencies surface in the ticket body when the user returns.
- Already-noted grep check prevents duplicate marker lines on subsequent runs.

No new public skill or command; no ADR changes. Closes a discoverability gap between `manage-problem` (caller) and `/wr-itil:report-upstream` (callee, shipped in 0.8.0).
