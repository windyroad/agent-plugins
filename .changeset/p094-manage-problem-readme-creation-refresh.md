---
"@windyroad/itil": patch
---

P094 — `/wr-itil:manage-problem` now refreshes `docs/problems/README.md` on new-ticket creation (Step 5, unconditional) and on ranking-changing updates (Step 6, conditional on Priority / Effort / WSJF line changes). Step 11's staging language extends the single-commit rule from Step 7 transitions to cover Step 5 creation and Step 6 ranking-change updates so README.md rides every commit that alters on-disk ticket ranks. Closes P094.
