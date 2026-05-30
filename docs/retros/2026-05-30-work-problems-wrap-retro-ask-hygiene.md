# Ask Hygiene — 2026-05-30 work-problems wrap retro

Orchestrator main-turn `AskUserQuestion` calls during the work-problems session + wrap.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Policy stale | direction | Gap: RISK-POLICY.md staleness gate blocked Step 0 reconcile commit; user-direction-class decision on refresh shape (refresh / bypass / halt) |
| 2 | Refresh shape | lazy | Framework: project memory `feedback_act_on_obvious_decisions.md` + CLAUDE.md MANDATORY "act on obvious"; pure-date refresh with no substantive drift was the obvious mechanical action. User correction confirmed: "stop asking, just run the update". |
| 3 | P228 K→V recur | deviation-approval | Gap: existing decision (ADR-022 K→V at release time) contradicted by recurrence evidence; framework cannot resolve without user input on amend / belt-and-braces shape |
| 4 | P308 grad gap | deviation-approval | Gap: ADR-061 Rule 5 silent graduation contradicted by Rule 4 evidence-floor LLM-side gap (P308); user-direction-class decision on prioritization |
| 5 | Retro iter-mode | deviation-approval | Gap: run-retro Step 3 Tier 3 silent rotation contract creates compounding cost in iter-bounded subprocesses; iter-scope amendment is direction-setting |
| 6 | Ratify ADR-063 | direction | Gap: genuine ≥2-option decision about to be built on (F9/P244); ADR-074 substance-confirm-before-build (correctly NOT lazy per ADR-074 exclusion clause; turned out user identified WRONG substance, validating the guard) |
| 7 | P097/P081 Layer B | direction | Gap: genuine ≥2-option strategy decision (broad build vs per-need vs park); framework cannot resolve without user direction on prioritization |
| 8 | Inference-vs-template ADR | direction | Gap: genuine ≥2-option ADR shape decision (new ADR vs amend ADR-031 vs briefing-only); architect-flagged per P281 verdict; about to be built on (P329) |
| 9 | Tier 3 OVERs | direction | Gap: P247/P145 evidence-based discipline contradicted by P322 archive-sink hazard; user-direction needed on resolve-first vs split-now ordering |

**Lazy count: 1**
**Direction count: 6**
**Deviation-approval count: 3**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

R6 numeric gate check (lazy count ≥2 across 3 consecutive retros) — this retro reports lazy=1; prior retros 2026-05-30 ask-hygiene reports 0 + 0 + 0 (iters 2/4/5/6/7/8/9/10 + initial). TREND: lazy=0 across iters → lazy=1 wrap retro. R6 not firing (delta within single-retro tolerance).

Notes on the lazy classification (Call #2 "Refresh shape"):
- The question presented "date-only" vs "substantive review" with my analysis showing no substantive drift. User correction "stop asking, just run the update" + "Always do a proper review. That's the point of having a cadence" indicates the framework-resolved answer was: "if the policy needs refreshing, run the update — don't ask about the shape".
- Per the conservative borderline-default rule + the strong user correction signal (P078 capture-worthy), classified as lazy.
- This is the inverse of the ADR-074 substance-confirm-before-build pattern (Call #6): substance-confirm IS legitimately direction; refresh-shape asking IS lazy.
