---
"@windyroad/itil": patch
---

P324 Phase 1 — paired promptfoo Tier-A/B eval for the `/wr-itil:work-problems` SKILL surface. Extends the harness pattern established by the report-upstream reference slice (P355 / RFC-019) under ADR-075 Amendment 2026-06-02 + RFC-012, applying it to the AFK orchestrator's behavioural contracts.

Coverage (9 tests across 7 SKILL.md contracts, 9/9 GREEN on first run):

- **Step 0d outbound-responses pre-flight** (P220) — TTL-expired branch dispatches `/wr-itil:check-upstream-responses`; `fresh-within-ttl` silent-passes without `AskUserQuestion`.
- **Step 5 iter-prompt re-grounding** (P211) — per-iter reset against current ticket's identity only; no Fix Strategy inline; no prior-iter content leak across the iter boundary.
- **Step 5 changeset-required** (P206) — fixes touching shippable code (`packages/<plugin>/{src,bin,hooks,skills,scripts,lib,agents}` excluding test paths) MUST author paired `.changeset/*.md` in the same single ADR-014-grain commit; doc-only and test-only changes MAY omit.
- **Step 5 is_error transient HALT** (P214) — ordered exit-code → `is_error` → `ITERATION_SUMMARY` check; 529 Overloaded routes to HALT branch with `"API overloaded; retry when service recovers"` advisory (NOT the P261 SALVAGE branch when nothing staged; NOT the normal ITERATION_SUMMARY parse path).
- **Step 5 retro-on-exit iter-owned BRIEFING commit** (P212) — iter subprocess (NOT run-retro, NOT orchestrator main-turn) emits `chore(briefing): refresh from iter retro (P<NNN>)` per ADR-014 scope.
- **Step 6.5 K→V post-release auto-transition** (P228) — Drain action step 4 dispatches `/wr-itil:transition-problem <NNN> verifying` per shipped changeset; V→C stays maintainer-only per JTBD-006 persona constraint.
- **Queue-and-continue universal AFK default** (P352 — `@windyroad/itil` portion) — direction-class question mid-iter queues to `outstanding_questions` and continues; iter does NOT halt, does NOT fire `AskUserQuestion` mid-loop, does NOT invent auto-default.

Per ADR-061 Rule 4 evidence-floor: this paired-and-passing eval IS the per-class evidence flipping the R009 prose-surface modulator +1 → -1 for `work-problems`, dropping 6 work-problems-surface held changesets fully within appetite (P206 + P211 + P212 + P214 + P220 + P228) plus P352's `@windyroad/itil` portion (partial discharge; `@windyroad/architect` and `@windyroad/retrospective` P352 siblings remain held pending their own SKILL evals). Cohort discharge is staged through the next Step 6.5 cohort-graduation pre-check on interactive user return.

Eval files excluded from the published tarball per `packages/itil/.npmignore` `skills/*/eval/`. Architect PASS + JTBD PASS on the new files. Subscription auth — no API key.

Closes: P324 Phase 1 (extend the harness to one high-leverage surface).
Refs: RFC-012, ADR-075 (Amendment 2026-06-02), ADR-061 Rule 4, ADR-014.
