---
"@windyroad/retrospective": minor
---

P099: Tier 3 budget enforcement for the briefing tree (advisory script + run-retro Step 3 rotation pass)

`@windyroad/retrospective` gains a Tier 3 budget enforcement mechanism for `docs/briefing/<topic>.md` files. Closes the P099 gap left after P100 slices 1+2 — Tier 1 (Critical Points) was already enforced via P105's signal-vs-noise pass, but Tier 3 (per-topic files) was honour-system and topic files had drifted to 1.3-3.4× over their 5 KB ceiling.

- New script `packages/retrospective/scripts/check-briefing-budgets.sh` — read-only advisory diagnostic. Walks `docs/briefing/*.md`, reports each topic file at or above the configured threshold (`OVER <basename> bytes=<N> threshold=<N>`). Default threshold 5120 bytes (upper bound of ADR-040 Tier 3 envelope), overridable via `BRIEFING_TIER3_MAX_BYTES`. Always exits 0 — overflow is signal, not failure (CI-fail-closed would block routine retros mid-session per JTBD-001). README.md excluded (Tier 2). Output sorted by basename for stable diffs. Mirrors `packages/itil/scripts/reconcile-readme.sh` placement and shape.
- New behavioural bats fixture `packages/retrospective/scripts/test/check-briefing-budgets.bats` — 14 tests covering existence + executable + empty-dir + under-threshold + over-threshold + boundary-exact + README-excluded + env-var-override + non-md-ignored + missing-dir-exit-2 + sort-stability. Behavioural, not structural grep on SKILL.md (per P081 / `feedback_behavioural_tests.md`).
- `run-retro` SKILL.md Step 3 — gains the **Tier 3 budget rotation pass** as its final action. Invokes the script after edits + Step 1.5 delete-queue persistence + README refresh. Interactive path: `AskUserQuestion` with four rotation shapes per ADR-013 Rule 1 (split-by-subtopic / split-by-date / trim-noise / defer). AFK fallback: defers to retro summary's new "Topic File Rotation Candidates" section per ADR-013 Rule 6. Step 5 summary template gains the matching Topic File Rotation Candidates table.
- ADR-040 amended — Tier 3 promoted from "informational" to advisory enforcement. New Reassessment trigger: ≥ 3 topic files exceed 2× the configured ceiling for ≥ 2 consecutive retro cycles → revisit threshold or promote to fail-closed. Reusable-pattern note (JTBD-101) names the advisory-script + bats + ADR-tier-budget-amendment triplet for future accumulator surfaces (risk register per P102, ADR index, problems index).

Closes P099 → Verification Pending.
