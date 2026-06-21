---
"@windyroad/itil": patch
---

P363 — consume `**Origin**: inbound-reported (#NN)` field so inbound-reported
tickets get a fix-released verdict on the originating issue at the K → V
transition.

Symmetric to the existing outbound `## Reported Upstream` dispatch:
`update-upstream` SKILL grows a new Inbound-origin verdict dispatch leg
(I1–I7); `transition-problem` Step 7b + `manage-problem` Step 7 pre-checks
extend in lockstep to grep the inbound Origin field alongside the outbound
section. Idempotency-guarded against duplicate comments; same external-comms
+ voice-tone gates as outbound; P229 anti-leakage preserved. Own-repo close
on Verifying → Closed transitions.

Witnessed live 2026-06-22: `@windyroad/risk-scorer@0.13.5` shipped P164
Phase 2 + P374 fixes (both inbound-reported via #273); fix-released verdict
did not auto-post (P374 had no `## Reported Upstream` section because
ADR-062 inbound intake records the originating issue in the `**Origin**`
field only). User had to post the verdict manually. This fix closes that
asymmetry; next inbound ticket's K → V transition will auto-dispatch.

Recorded as an ADR-024 amendment (architect ruling — adds a direction, not
a new schema). RFC-028 traces the fix (I13 gate).
