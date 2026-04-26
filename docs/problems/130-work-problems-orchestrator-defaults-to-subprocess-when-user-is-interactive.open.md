# Problem 130: `/wr-itil:work-problems` orchestrator defaults to subprocess dispatch even when the user is observably interactive — loses real-time presence advantage

**Status**: Open
**Reported**: 2026-04-27
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3)
**Effort**: M — `packages/itil/skills/work-problems/SKILL.md` Step 5 amendment to introduce a dual-mode dispatch (subprocess for AFK presence-absent; main-turn skill invocation for presence-present), plus a presence-signal detector (e.g. "user message received during loop" or "AskUserQuestion answered within last N minutes"), plus an ADR-032 amendment formalising the dual-mode contract, plus matching contract bats per ADR-037.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-27 by direct user correction during an interactive session of `/wr-itil:work-problems`: "I'm not sure why you did that as a background non-interactive run. We could of just done it here. create a problem for that". P078 contradiction-signal pattern. Triggering iter: iter 9 = P081, dispatched as `claude -p` subprocess immediately after the user answered an `AskUserQuestion` next-step decision at the orchestrator's main turn — the user-presence signal had flipped from absent to present, but the orchestrator's Step 5 dispatch shape did not adapt.

## Description

`/wr-itil:work-problems` Step 5 mandates `claude -p --permission-mode bypassPermissions --output-format json` subprocess dispatch for every iteration. The contract evolved from inline Skill-tool invocation (P077 — context-bloat failure mode) to Agent-tool dispatch (P077's amendment) to `claude -p` subprocess dispatch (P084 — Agent-tool subagents lack Agent themselves, breaking governance gate markers). The subprocess-boundary variant under ADR-032 is the canonical AFK iter shape; it correctly serves JTBD-006 (progress the backlog while I'm away).

But the dispatch decision is **monomodal** — every iter is dispatched as a subprocess regardless of whether the user is observably present. When the user shifts from AFK back to interactive mid-loop (e.g. answers an `AskUserQuestion` at the orchestrator's main turn, sends a new directive message, or responds to a task notification), the orchestrator's Step 5 still dispatches the next iter as an isolated subprocess. The user can no longer:

- Watch architect / JTBD / risk-scorer verdicts unfold in real-time
- Intervene on design surface in-flight (e.g. when the architect asks for ADR-shape input)
- See partial commits as they land
- Course-correct mid-iter without waiting ~15-30 min for the subprocess to complete

The orchestrator's main turn IS interactive by construction — Agent tool is natively available, gates fire at full depth, governance reviews land directly in the visible turn. The subprocess dispatch was added (P084) to make AFK iters feasible, not because main-turn iters are wrong. The current SKILL.md defaults to subprocess unconditionally; the absent-presence assumption is baked in as the only dispatch path.

## Symptoms

- During an interactive session where the user has answered an `AskUserQuestion` and is still at the keyboard, the next iter dispatches as a subprocess. The user sees only the periodic background-task notifications — they can't watch the iter's architect verdict, can't intervene when the iter hits a design ambiguity, and have to wait for the iter's `ITERATION_SUMMARY` block before they can react.
- The user explicitly observed (2026-04-27): "I'm not sure why you did that as a background non-interactive run. We could of just done it here."
- Subprocess overhead — each `claude -p` invocation pays ~$5-15 cost + 12-45 min wall (cumulative session totals at iter 9 dispatch: ~$63 / ~3.7 hrs across 8 prior iters). Main-turn iters would amortise the orchestrator's already-loaded SKILL.md context and the existing architect / JTBD markers, reducing per-iter cost.
- The dispatch decision is invisible to the user — they don't see "I am about to subprocess this iter; the next visible signal will be the completion notification in ~20 min." There's no opt-out at decision time.
- Composes-with adjacent gaps: P122 (now closed) fixed the inverse class — orchestrator was defaulting to AFK fallback table at stop-condition #2 even when `AskUserQuestion` was available. P130 is the same shape on a different surface — orchestrator is defaulting to AFK subprocess at Step 5 even when main-turn skill invocation is available.

## Workaround

The user explicitly tells the orchestrator to NOT subprocess (e.g. "just do it here"). Without that signal the orchestrator subprocesses by SKILL contract.

## Impact Assessment

- **Who is affected**: every user of `/wr-itil:work-problems` who shifts from AFK to interactive mid-loop. The AFK-to-interactive transition is the common case — users start a loop before stepping away, then return mid-loop to check progress and stay engaged. Solo-developer persona (JTBD-001) and especially the AFK-orchestration persona (JTBD-006) which the skill primarily serves.
- **Frequency**: every interactive AFK loop session where the user returns mid-loop and the orchestrator dispatches another iter. Observed every session this week.
- **Severity**: Moderate — degrades user experience without losing correctness. The work still completes and commits correctly; the user just can't watch / intervene. Higher than Minor because the inability-to-intervene cuts off in-flight design corrections that would otherwise save iters.
- **Likelihood**: Possible — depends on whether the user is engaged at iter dispatch time. For a fully-AFK session it doesn't fire; for any interactive session it does.
- **Analytics**: 2026-04-27 session — iter 9 dispatch was the trigger event. The user answered an `AskUserQuestion` immediately before iter 9 dispatch; orchestrator subprocess-dispatched iter 9 anyway; user corrected within ~30 seconds.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit work-problems SKILL.md Step 5 — current contract reads as monomodal subprocess dispatch with no branch for presence-detection.
- [ ] Define the presence-signal detector. Candidates:
  - `AskUserQuestion answered within last N minutes` (timestamp on tool result)
  - `User message received during loop` (any new user-prompt UserPromptSubmit hook fired since loop start)
  - `Wall-clock time since last user activity` (heuristic threshold — e.g. 5 min idle = AFK)
  - Multiple combined (best-of-N)
- [ ] Decide the dual-mode contract shape: how does Step 5 branch on the signal? Subprocess-by-default with main-turn-on-presence, or main-turn-by-default with subprocess-on-absence?
- [ ] Evaluate whether the orchestrator should ANNOUNCE its dispatch decision to the user before dispatching, with an opt-out window. e.g. "About to subprocess iter 10 (AFK mode). Reply within 30s to switch to main-turn." This trades latency for visibility.
- [ ] ADR-032 amendment to formalise the dual-mode contract. Likely a new sibling subsection alongside the existing subprocess-boundary variant ("interactive-presence variant").
- [ ] Behavioural bats for the detector (when the signal fires) and for the dispatch branch (subprocess vs main-turn).

### Preliminary hypothesis

The dispatch monomodality is a **historical artefact** of P084's adoption of subprocess dispatch. P084 closed a real gap (Agent-tool subagents can't satisfy gates) by requiring `claude -p` subprocess. P077's prior amendment addressed Skill-tool inline invocation (context bloat). Neither P077 nor P084 considered the case where the user is present and main-turn invocation would work fine — both assumed AFK as the operating mode.

The fix is to **make presence-awareness explicit at Step 5** rather than baking AFK assumption into the dispatch contract.

## Fix Strategy

**Shape**: SKILL.md Step 5 amendment + presence-signal detector + ADR-032 amendment + bats.

**Target files**:
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dual-mode dispatch (subprocess for absent-presence, main-turn skill invocation for present-presence). Detector logic inline or via shared helper.
- `packages/itil/hooks/lib/presence-signal.sh` (new shared helper) — function `is_user_presently_interactive()` returning 0/1 based on the chosen detector heuristic. Reuses ADR-038 once-per-session marker conventions.
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` — amendment adding the "interactive-presence variant" alongside the existing subprocess-boundary variant.
- `packages/itil/skills/work-problems/test/work-problems-step-5-presence-aware-dispatch.bats` — behavioural bats (NOT structural greps per P081 direction once P081 lands) covering presence-absent → subprocess, presence-present → main-turn, signal-decay, opt-out.
- `.changeset/wr-itil-p130-*.md` — patch (or minor if the dispatch contract is observably different to consumers).

**Out of scope**: extending presence-awareness to other orchestrator skills (`/wr-itil:transition-problems` batch grain, `/wr-retrospective:run-retro`, etc.). If the pattern generalises after P130 lands, a follow-up codification ADR can lift the helper into `packages/shared/`.

**Compose with `--max-turns` / `--input-format json` flags** if Anthropic CLI evolves to support presence-passing from parent session to subprocess (would let subprocess inherit parent's interactivity level).

## Dependencies

- **Blocks**: (none — P130 is a UX improvement; nothing strictly waits on it)
- **Blocked by**: (none — implementation can proceed standalone)
- **Composes with**: P122, P084, P077, P078, P083, P081, P124

## Related

- **P122** (`docs/problems/122-...closed.md`) — orchestrator main-turn defaults at stop-condition #2. P130 is the same shape on a different surface (Step 5 dispatch).
- **P084** (`docs/problems/084-...closed.md`) — established `claude -p` subprocess as the canonical iter dispatch. P130 builds on P084 by adding presence-awareness.
- **P077** (`docs/problems/077-...closed.md`) — established Agent-tool dispatch (later superseded by P084). P130 continues the dispatch-shape evolution.
- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction. P130's own creation was triggered by P078's pattern (user direct contradiction → ticket capture).
- **P083** (`docs/problems/083-...verifying.md`) — iter prompt forbids ScheduleWakeup. P130's main-turn variant inherits the same forbidden-primitives list (no self-rescheduling whether subprocess or main-turn).
- **P124** (`docs/problems/124-...verifying.md`) — `session-id.sh` `shopt-under-zsh` regression. P130's presence-signal detector likely reads session-scoped markers via the same helper, so P124 fix is a soft prerequisite. Observed in this very capture: `get_current_session_id:33: command not found: shopt` on zsh; helper still returned a valid SID via fallback scrape — but the SID it returned was STALE, not the orchestrator's actual SID. The marker had to be re-written by brute-forcing every recent SID before the create-gate hook would unlock. This is fresh evidence of the P124 regression's user-facing impact and confirms iter 4's flag.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — taxonomy parent. P130 amendment adds the interactive-presence variant alongside the existing subprocess-boundary variant.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 (interactive default) and Rule 6 (non-interactive fail-safe). P130's dual-mode dispatch directly serves both rules.
- **ADR-038** (`docs/decisions/038-progressive-disclosure-for-governance-tooling-context.proposed.md`) — once-per-session marker pattern. P130's presence-signal detector reuses the same marker conventions.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — primary persona served. P130 doesn't break the AFK contract — it adds an opt-in interactive-presence path.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — composes; main-turn dispatch reduces "slowdown" perception when the user is present.
- 2026-04-27 session evidence: iter 9 dispatch immediately after user answered `AskUserQuestion` next-step decision; user corrected within ~30 seconds: "I'm not sure why you did that as a background non-interactive run. We could of just done it here. create a problem for that". This ticket is the captured response.
