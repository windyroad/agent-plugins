# Ask Hygiene — Session 7 Orchestrator Wrap

**Session**: 2026-05-18 / `/wr-itil:work-problems` orchestrator main turn
**Scope**: orchestrator main-turn AskUserQuestion calls (excludes the 5 iter subprocesses' own hygiene trails — those live in `2026-05-18-session-7-iter-{1..5}-*-ask-hygiene.md`).

## Calls

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Reconcile gap | direction | `Gap: Step 0 README reconciliation surfaced false-positive drift (script's section-detection lacks ## Inbound Upstream Reports awareness — pre-existing P252 bug encountered against cached 0.32.1 script). Three valid routings exist (capture-and-proceed, halt-fix-first, proceed-no-ticket); framework did not prescribe one. User direction-set "capture script-bug ticket, proceed AFK".` |
| 2 | Loop routing + P252/P264 dupe | direction + deviation-approval | `Gap: 5 iters complete + tier-change point (4.5 K→V tier exhausted; next 3.0 tier is P087 implementation work); pipeline residual 2/25 within appetite per SKILL.md but P250's fix (in Verifying) says drain whenever releasable material exists. Two outstanding deviation-candidates queued: P250 Step 6.5 framing + P252/P264 dupe-merge. User direction-set "drain push + release, then stop loop" + "P252 → Verifying, close P264 as duplicate". FFS-correction class-of-behaviour signal (P078) triggered P266 capture.` |
| 3 | K→V helper + P165 scope + compound-render gap | direction + direction + direction (3 questions, 1 call) | `Gap: 3 queued outstanding-questions from iter 1 retro (K→V wrong-release-cite class) + orchestrator observation (P165 hook substring-match scope) + iter 5 outstanding-question (compound-render gap architect-design Q1). All three are direction-setting candidates per ADR-044 category 1 (new tickets to capture / not codified by existing framework). User routed all three: capture P267 / capture P268 / amend populate-side write (P269).` |

**Lazy count: 0**
**Direction count: 3** (one call covered 3 direction questions per ADR-013 Rule 1 cap)
**Deviation-approval count: 1** (P252/P264 dupe-merge)
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

- All 3 calls fired at framework-prescribed user-interaction halt points per P130 / ADR-044 (Step 0 preflight friction → user direction-set; Step 2.5 loop-end emit; post-Step-2.5 follow-on routing for the 3 outstanding questions). No mid-iter asks.
- Call 2's FFS-correction class-of-behaviour signal triggered P266 capture per P078 mandatory.
- Call 3 batched 3 direction questions into 1 AskUserQuestion call within the 4-option cap per ADR-013 Rule 1.
- No lazy classifications — every call resolved a framework-unresolved direction or deviation-approval decision per ADR-044 narrowing.

## Cross-session trend (advisory)

Iter 1-5 hygiene trails per `2026-05-18-session-7-iter-{1..5}-*-ask-hygiene.md` all report lazy count 0. This orchestrator-main-turn trail also reports lazy=0. Session 7 aggregate: 6 hygiene files / lazy=0 across all. R6 numeric gate condition (lazy ≥2 across 3 consecutive retros) NOT met.
