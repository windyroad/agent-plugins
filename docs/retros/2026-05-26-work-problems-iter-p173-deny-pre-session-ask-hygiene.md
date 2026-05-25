# Ask Hygiene — 2026-05-26 work-problems AFK iter (P173 gate-deny env-bypass pre-session)

Surface: AFK `/wr-itil:work-problems` iteration subprocess (P086 retro-on-exit). No interactive user present (ADR-013 Rule 6); `AskUserQuestion` is structurally unavailable mid-loop (P135 / ADR-044).

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | No `AskUserQuestion` calls this iteration. All decisions framework-resolved: deny-message wording (ADR-045 deny-band + architect APPROVED), the SID-mismatch split call (manage-problem Step 2 duplicate-check → matched P142/P260, no split), status handling (ADR-022 Known-Error-pending-release), external-comms changeset recovery (P073 documented in-flight escape-hatch). |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Notes: the design choice between three deny-message wordings (Philosophy A vs B; held-area pointer vs pre-session annotation) was resolved by the ADR-045 byte-budget constraint + architect review (APPROVED Q2), NOT surfaced as a user ask — correct per ADR-044 framework-resolution boundary. The SID-mismatch "split vs cross-reference" decision was resolved by the Step 2 duplicate-check grep (matched existing P142/P260) — a framework-mediated mechanical outcome, not a user judgement call. R6 numeric gate (lazy ≥2 across 3 consecutive retros): NOT fired — trend lazy_last=0.
