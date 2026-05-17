---
"@windyroad/itil": patch
---

P234 Phase 1 — wr-itil PostToolUse:Write|Edit hook detecting fictional-defer rationales in retro outputs

Add `packages/itil/hooks/itil-fictional-defer-detect.sh` — a PostToolUse advisory hook that fires on Write / Edit / MultiEdit calls targeting `docs/retros/*.md` and scans the written file for defer-rationale phrases (`next retro`, `next session`, `defer pending`, `defer with cause:`, `deferred per`) lacking a SCHEDULED-FUTURE-SURFACE citation in the +/-5 line context window.

A SCHEDULED-FUTURE-SURFACE is one of: ticket ID (`P\d{3}` / `STORY-\d{3}` / `R\d{3}` / `RFC-\d{3}`), named skill invocation (`/wr-[a-z-]+:[a-z-]+`), hook / script path (`*.sh`), CI workflow path (`.github/workflows/`), or a dated ADR reference (`ADR-\d{3}` + `\d{4}-\d{2}-\d{2}` both present in the window). The allowlist carves out `deferred per Branch B` (the run-retro Step 3 Branch B path carries the next-retro `check-briefing-budgets.sh` trigger as the scheduled surface inside the SKILL contract itself).

Advisory only — never blocks. Emits a single stderr advisory naming file + line number + detected phrase + remediation pattern. Mirrors the `itil-rfc-trailer-advisory.sh` PostToolUse precedent (stderr + exit 0) and the just-shipped `itil-mid-loop-ask-detect.sh` (P132 Phase 2b) per-surface configuration shape (`DEFER_RATIONALE_RE` / `SCHEDULED_FUTURE_SURFACE_RE` / `EXEMPT_PHRASES_RE` at the top so extending coverage to other accumulator-doc surfaces is a copy-and-retarget operation).

Closes the under-do half of the ADR-044 framework-resolution-boundary inverse-correctness pair (P132 = over-ask / P234 = under-do). The fictional-defer pattern recurs across `/wr-retrospective:run-retro` Step 3 Tier 3 budget rotation, Step 1.5 Signal-vs-Noise pass, and Step 4b Stage 1 Tickets Deferred section — the hook surfaces all three at file-write time with a uniform structural enforcement rather than per-skill prose rules. Behavioural bats fixture in `packages/itil/hooks/test/itil-fictional-defer-detect.bats` (14 tests) pins the detection signal + allowlist + crash-safety + ADR-045 honour-system budget.

Sibling shape to P132 Phase 2b (commit 841db68, @windyroad/itil@0.30.3) — same advisory budget envelope (target ~600 bytes, hard ceiling <1000), same per-surface-config + copy-and-retarget extensibility, same behavioural-tests-default per ADR-052 + P081.
