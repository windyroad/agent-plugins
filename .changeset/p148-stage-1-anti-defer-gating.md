---
"@windyroad/retrospective": patch
---

Close P148 (agent defers ticket creation to retro summary instead of immediately invoking `/wr-itil:manage-problem`). Architect-picked Fix 1+2 hybrid:

- **Fix 1 (prose tightening)**: `run-retro` SKILL.md Step 4b Stage 1 AFK-branch rewritten to name `cause: skill_unavailable` as the only valid fallback gate, require every Tickets Deferred entry carry an explicit `cause:` field, enumerate the four named anti-pattern rationalisations the agent must NOT use (session-length pressure, lifecycle weight, retro-summary-defer preference, fabricated subcommands), cite the user's verbatim correction phrase, and cite ADR-044 framework-mediated surface + P145 sibling pattern. Step 5 retro summary template gains a `### Tickets Deferred` section with `Observation | Cause | Citation` columns.
- **Fix 2 (advisory check script)**: new `packages/retrospective/scripts/check-tickets-deferred-cause.sh` walks `docs/retros/*.md` retro summaries and emits per-file plus TOTAL violation counts; exit 0 always (advisory per ADR-040 declarative-first / ADR-013 Rule 6); Cause allowlist is single-source `{skill_unavailable}`.

23 behavioural bats added per ADR-037 + P081 (20 in `check-tickets-deferred-cause.bats` + 3 in `run-retro-stage-1-fallback-gating.bats`); 23/23 green; full retrospective suite 127/127 green confirming no regression.
