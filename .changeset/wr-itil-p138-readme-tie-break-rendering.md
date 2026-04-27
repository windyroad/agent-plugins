---
"@windyroad/itil": minor
---

`/wr-itil:manage-problem` + `/wr-itil:review-problems` + `/wr-itil:work-problems`: render `docs/problems/README.md` WSJF Rankings table in tie-break-ladder order with a `Reported` date column so the rendered top-to-bottom row order matches the orchestrator's tie-break selection 1:1 (P138).

Multi-key sort spec `(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)` documented at all five render-block sites (`manage-problem` SKILL.md Step 5 P094 + Step 7 P062 + Step 9c presentation + Step 9e template, `review-problems` SKILL.md Step 3 + Step 5 README template, `work-problems` SKILL.md Step 1) with stable greppable cross-coupling marker `<!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->` at each site so future tie-break ladder changes know to update every render block. New behavioural + structural bats coverage `manage-problem-readme-tie-break-order.bats` 13/13 green covers marker presence, sort spec verbatim, Reported column in templates, drift-warning prose, AND a behavioural fixture sort with 4 same-WSJF tickets differing by Status/Effort/Reported asserting post-sort row order matches the tie-break ladder result. `docs/problems/README.md` re-rendered against the new sort: the WSJF 6.0 tier now shows P123 → P135 → P082 instead of P135 → P123 → P082, matching `/wr-itil:work-problems` Step 3 selection 1:1 (the exact case that triggered this ticket — user saw orchestrator pick P123 while README showed P135 on top, assumed orchestrator was broken).

Closes P138 (Open → Verification Pending per ADR-022).
