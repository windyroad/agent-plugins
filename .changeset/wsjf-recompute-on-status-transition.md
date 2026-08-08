---
"@windyroad/itil": patch
---

Recompute WSJF after a status transition, so the Open multiplier no longer persists

WSJF is `(Severity × Status Multiplier) / Effort Divisor`, and the multiplier changes with status: Open 1.0, Known Error 2.0. Both re-score surfaces calculated WSJF *before* they auto-transitioned a ticket to Known Error, and nothing recomputed afterwards — so the value written to disk kept the Open multiplier and the ticket ranked at half its real value for as long as it sat in the queue. The wrong number went consistently into both the ticket body and `docs/problems/README.md`, so membership reconciliation passed and nothing downstream noticed.

`/wr-itil:review-problems` Step 2 and `/wr-itil:manage-problem` Step 9b now run the auto-transition first and take the multiplier from the status the ticket holds afterwards. The three Open → Known Error pre-flight checklists — in `/wr-itil:transition-problem`, `/wr-itil:transition-problems`, and `/wr-itil:manage-problem` Step 7 — mandate the multiplier re-rate alongside the Effort re-rate they already required. Re-rating the divisor without the multiplier is the failure mode: the divisor doubles with nothing to offset it and the stored value halves.

A new diagnose-only check catches the value that is wrong in both places. Both re-score surfaces now end by running it, and you can run it yourself at any time:

```
wr-itil-check-wsjf-arithmetic docs/problems
```

It recomputes each open and known-error ticket's WSJF from that ticket's own Severity, status and Effort fields and reports any disagreement with the stored value. Read-only, and wired into no gate — it reports, it never blocks. Tickets missing one of the three input fields are counted on stderr rather than reported, so an existing backlog does not read as broken on first run. Verification Pending and Parked tickets carry multiplier 0 and are excluded, per the lifecycle rules that already keep them out of the dev-work ranking.

One result is worth knowing before you run it. A transition that also re-rates Effort M → L legitimately leaves the number unchanged, because the divisor and the multiplier both double and cancel. That is correct, not a skipped step — but an unchanged value is only right if you actually recomputed it.

Reported to us by a downstream user and tracked as [windyroad/agent-plugins#413](https://github.com/windyroad/agent-plugins/issues/413).
