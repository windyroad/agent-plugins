---
"@windyroad/itil": patch
---

Fix `reconcile-readme.sh` false-positive that mis-attributed `## Inbound Upstream Reports` rows as Verification Queue entries.

The script previously sliced VQ as `[VQ_START, CLOSED_START)`, swallowing the Inbound section (ADR-062 / RFC-004) and miscounting its `Matched local ticket` cross-refs as VQ rows. Pre-fix this produced 31 false-positive `STALE verification-queue` entries every preflight, blocking Step 0 in `/wr-itil:capture-problem`, `/wr-itil:manage-problem`, `/wr-itil:work-problems`, and `/wr-itil:review-problems`.

Closes P252.
