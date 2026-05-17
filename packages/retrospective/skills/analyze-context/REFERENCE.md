# analyze-context — Reference

Source-decision provenance and cross-references for `/wr-retrospective:analyze-context`. Loaded only when SKILL.md flags a situation needing this material (per ADR-054 § "Sibling REFERENCE.md pattern").

## Composition with sibling measurements

- **`P099`** (briefing bloat — `check-briefing-budgets.sh`) — the deep report cites P099's `OVER` rows verbatim under Policy Breaches when the briefing tree exceeds Tier 3.
- **`P105`** (signal-vs-noise pass) — the deep report cites P105 score totals from the most-recent retro under Per-Turn Attribution / Suggestions, when relevant.
- **`ADR-040`** (session-start briefing surface) — the deep report cites ADR-040's tier budgets when surfacing briefing-related suggestions.
- **`run-retro` Step 2c (cheap layer)** — the deep report's HTML-comment trailer is the snapshot run-retro Step 2c reads for delta-from-prior comparison. Bidirectional contract.

## ADRs cited

- **ADR-043** (Progressive context-usage measurement) — this skill's source decision.
- **ADR-026** (Agent output grounding) — `analyze-context/SKILL.md` is on the per-agent prompt amendments list (lines 94–101 of ADR-026, amended within reassessment window).
- **ADR-014** (Governance skills commit own work) — `docs(retros): context analysis YYYY-MM-DD` row added to the Commit Message Convention table; this skill commits its own report per the amended convention.
- **ADR-013** Rule 5 / Rule 6 — interactive AskUserQuestion path / AFK fallback.
- **ADR-038** (Progressive disclosure) — the methodology mirrors ADR-038's tiered disclosure pattern; report rows obey ≤150-byte budget per row.
- **ADR-040** (Session-start briefing surface) — HTML-comment trailer pattern precedent.
- **ADR-022** (Verification Pending lifecycle) — P101's transition path on this skill landing.
- **ADR-005** / **ADR-037** / **ADR-052** — bats fixture shape under `test/`. ADR-052 supersedes ADR-037 and re-defaults skill tests to behavioural; structural-grep on this SKILL.md is a Permitted Exception per ADR-005 narrowed scope.
- **ADR-054** (SKILL.md runtime budget policy) — this REFERENCE.md is the first empirical instance of ADR-054's sibling-file pattern. P097 driver ticket.
