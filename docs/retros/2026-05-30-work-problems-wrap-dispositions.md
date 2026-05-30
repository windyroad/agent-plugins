# /wr-itil:work-problems wrap-up dispositions — 2026-05-30

Loop-end Step 2.5 dispositions recorded via two batched `AskUserQuestion` calls on the user's return after the AFK loop completed. Authority class column matches the same-session retro precedent at `docs/retros/2026-05-30-ask-hygiene.md` per the ADR-044 6-class taxonomy.

## Deviation-approval

| # | Existing decision | ADR-044 class | Disposition | Next action |
|---|---|---|---|---|
| 1 | ADR-022 K→V at release time (P228 KE recurred via prior-session iter s8-1-P177: @windyroad/itil@0.35.13 commit a8823be) | deviation-approval | **Approve + amend P228 + add belt-and-braces** | Append recurrence evidence to P228; consider whether run-retro Step 4a or transition-problem release-path should belt-and-braces the K→V transition |
| 2 | ADR-061 Rule 5 silent cohort-graduation (Rule 4 evidence floor is LLM-side; 3 held this session p288/p248/p166-p163 would have false-graduated) | deviation-approval | **Prioritize P308 fix** | Evaluator should check Rule 4 deterministically; lift LLM-judgement to the script |
| 3 | run-retro Step 3 Tier 3 silent rotation in BOTH modes (iter retros surface 4 OVER files unrelated to iter scope; rotations compound) | deviation-approval | **Amend SKILL: defer Tier 3 to parent retro when iter-invoked** | Add iter-scope clause so iter-mode retros skip cross-cutting briefing rotations; parent session retro handles them once-per-session |

## Direction

| # | Question | ADR-044 class | Disposition | Next action |
|---|---|---|---|---|
| 4 | Ratify ADR-063 (Plugin maturity presentation layer)? | direction | **SUBSTANCE WRONG** — user direction verbatim: *"The maturity was supposed to be at the tool level, not the plugin level"* | Capture P330 for the substance correction; supersede ADR-063 (already rejected-pending-supersede per P300); track Phase 3a/3b/3c/3d rework scope. The ADR-074 substance-confirm-before-build guard fired correctly on iter 3 — that skip prevented landing F9/P244 on wrong-substance Phase 3 work. |
| 5 | P087 compound-rendering gap (a vs b) | direction | **Moot under substance correction** | Phase 3a/3b plugin-level shape is wrong; canonical-vs-derived details depend on the reworked tool-level shape. |
| 6 | P087 Option 4 telemetry (keep deferred / ship / strike) | direction | **Moot under substance correction** | Same as #5 — depends on the reworked tool-level shape. |
| 7 | P097 + P081 Layer B unblock strategy | direction | **Prioritize building Layer B primitives broadly** | Build the skill-invocation harness end-to-end so any skill can retrofit; unblocks P097 + future behavioural-test work generally. Consider new umbrella ticket for the Layer B build effort. |
| 8 | Author NEW ADR for agent-inference-vs-literal-SKILL-template precedence? | direction | **Author the new ADR via `/wr-architect:create-adr`** | Codify the precedence rule as a sibling ADR (NOT an ADR-031 amendment); closes the suite-wide drift class P281 + P329 exposes. |
| 9 | Tier 3 briefing-budget OVERs (4 files, 4th consecutive flag) | direction | **Resolve P322 first, then split** | Tackle the archive-sink proliferation hazard so split-by-date safe default is appropriate for the archives too. |

## Substance correction load-bearing finding

The user's direction on item #4 invalidates ADR-063's substance at the level the Phase 3 work was built on. Phase 3a + 3b + 3c + 3d shipped under the plugin-level rollup contract (one maturity score per plugin, with per-surface evidence rollup). The user's intent is tool-level (per-skill / per-agent / per-hook each carry their own maturity score; no plugin-level rollup).

This is the canonical case the **ADR-074 substance-confirm-before-build** guard exists to prevent. Iter 3 (P087 work attempt) skipped landing F9 (P244 `wr-itil-plugin-maturity-list`) because it would extend the unconfirmed-build chain. That skip was correct, and the user's correction on return validates the contract: the substance was indeed wrong, not just unratified.

When the new ADR is drafted superseding ADR-063, it MUST surface the tool-level substance via `AskUserQuestion` per ADR-074 before any dependent work builds on it (per the architect's review note for this retro).

- **ADR-063 tracker**: P300 (rejected-pending-supersede)
- **New ADR scope**: tool-level maturity taxonomy + populate + render + bootstrapping; supersede ADR-063 entirely
- **Phase 3 rework**: re-derive Phase 3a populate, Phase 3b render, Phase 3c badge, Phase 3d retroactive at tool-level; F9/P244 deferred until new substance is confirmed

## Next-session actions queue

For the next `/wr-itil:work-problems` AFK loop:

1. **Capture P330** — ADR-063 substance correction (tool-level vs plugin-level): create problem ticket; update P300 with the substance direction; track Phase 3a/3b/3c/3d rework scope; defer F9/P244.
2. **Update P228** — append recurrence evidence (iter s8-1-P177 cite); design belt-and-braces transition shape.
3. **Bump P308 priority** — promote so the evaluator's Rule 4 evidence-floor check lands soon.
4. **Capture run-retro SKILL amendment ticket** — defer Tier 3 to parent retro in iter-mode (iter 2 deviation cite).
5. **Capture broad Layer B priority direction** — promote per-need Layer B work to a sustained build effort; consider umbrella ticket on or composing with P081.
6. **Run `/wr-architect:create-adr`** — for agent-inference-vs-literal-SKILL-template precedence rule (P281 descendant; closes P329 class).
7. **Bump P322 priority** — must resolve before Tier 3 split-by-date can safely apply to archive files.

## Session totals

| Metric | Value |
|---|---|
| Iterations dispatched | 11 (1 preflight + 10 substantive/skip) |
| Iterations committed | 10 |
| Iterations skipped | 1 (iter 3 P087 — ADR-074 substance-confirm fired correctly) |
| Tickets transitioned to Verifying | 5 (P267, P316, P282, P281, P302) |
| Tickets Open → KE | 1 (P325; CI-verified on push) |
| Tickets spun off | 1 (P329 — sibling SKILL drift) |
| Plugin releases | 6 versions across 5 release events (itil 0.37.0+0.37.1, architect 0.12.0+0.12.1, jtbd 0.9.0, retrospective 0.21.4) |
| Total subprocess cost (USD) | ~$69 |
| Mean cost per iter | ~$6.27 |
| Total subprocess duration | ~150 min (~2.5h) |
| Wall-clock elapsed | ~5.5h |

## Related

- `docs/decisions/063-plugin-maturity-presentation-layer.proposed.md` — superseded substance; awaiting new ADR
- `docs/decisions/074-confirm-decision-substance-before-building.proposed.md` — guard that fired correctly on iter 3
- `docs/problems/known-error/300-*.md` — ADR-063 supersession tracker
- `docs/retros/2026-05-30-ask-hygiene.md` — same-session retro precedent for the table format
