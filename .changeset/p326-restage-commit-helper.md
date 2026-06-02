---
"@windyroad/risk-scorer": patch
"@windyroad/itil": patch
---

Land `wr-risk-scorer-restage-commit` helper closing P326 — the Agent-tool delegation to `wr-risk-scorer:pipeline` can silently clear the parent index, forcing a re-`git add` before `git commit` lands. The new helper bundles `git add <paths>` + non-empty-staging assertion + `git commit "${-m-args}"` into a single atomic bash call, eliminating the silent re-add round-trip.

Surface: `wr-risk-scorer-restage-commit -m "<msg>" [-m "<trailer>"] -- <path1> [<path2>...]`. Trailer paragraphs ride as repeated `-m` flags (e.g. `RISK_BYPASS: capture-deferred-readme`).

SKILL.md surfaces updated to use the helper in the post-Agent-delegation commit step: `manage-problem` Step 11, `capture-problem` Step 6, `transition-problem` Step 8. The ADR-014 commit-gate flow is preserved — same gate, same ordering, same primitives, atomic landing.

ADR-049 PATH shim at `packages/risk-scorer/bin/wr-risk-scorer-restage-commit` generated from the ADR-080 canonical template via `scripts/sync-shim-wrappers.sh`. ADR-052 behavioural coverage at `packages/risk-scorer/scripts/test/restage-commit.bats` (12/12 GREEN).
