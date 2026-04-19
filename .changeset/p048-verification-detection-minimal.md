---
"@windyroad/itil": minor
---

manage-problem Verification Queue detection (P048, minimal-scope).

- **Fast-path cache hit**: step 9d now explicitly fires even when
  `docs/problems/README.md` is fresh (candidate 1). Prevents the prior
  regression where verification prompts were suppressed on cache hit —
  which is exactly when the user is most likely to verify.
- **Verification Queue presentation**: step 9c now emits a
  `Likely verified?` column in the Verification Queue with
  `yes (N days)` / `no (N days)` values based on release age
  ≥ 14 days (candidate 4). 14-day default documented as a within-skill
  tunable (architect review confirmed not policy-level yet).
- Step 9d surfaces the highlighted (`yes`) tickets first in the
  verification prompt so the user can batch-close long-standing
  verifications.
- 5 new structural bats assertions in
  `manage-problem-verification-detection.bats`; full project suite
  269/269 green (+5).
- Candidates 2 (standalone `verify-fixes` op), 3 (exercise observation
  records — new file-level state dimension), and 5 (AFK-mode
  orchestrator hook) are deferred pending an architect ADR-scope
  decision.
