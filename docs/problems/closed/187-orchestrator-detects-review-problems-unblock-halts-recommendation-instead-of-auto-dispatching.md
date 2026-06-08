# Problem 187: AFK orchestrator detects `/wr-itil:review-problems` would unblock its preflight but halts with a "recommended next step" instead of auto-dispatching the unblock

**Status**: Closed

## Closed as no longer relevant

- **Evidence shape**: ADR-shipped-confirmed, named-skill-or-feature-exists, driver-child-ticket-closed (ADR-079 Phase 2)
- **Closed on**: 2026-06-09
- **Closed by**: /wr-itil:review-problems Step 4.6 relevance-close pass
- **Cite (per-shape evidence)**: ADRs human-oversight-confirmed: ADR-013; feature surfaces exist: packages/itil/skills/review-problems/SKILL.md, work-problem/SKILL.md, work-problems/SKILL.md + /wr-itil: slash commands; drivers closed: P183
- **Caveat**: multi-phase-mixed-progress: 0/7 Investigation Tasks done — confirm umbrella scope before close. User confirmed close at interactive batch review 2026-06-09 (review-problems Step 4.6 surface-batch-confirm).
- **Persist**: this section is committed in the ticket file itself; `packages/itil/scripts/evaluate-relevance.sh` is the re-runnable verdict source per ADR-026
- **Uncertainty / reversibility**: reversible via `git revert` or `git mv` back to open/.
**Reported**: 2026-05-12
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

User observation 2026-05-12 (via screenshot of an AFK orchestrator session — `/wr-itil:work-problems` or sibling — Step 0 preflight): the orchestrator scanned the backlog, detected three blocking conditions, identified the single mechanical unblock, and halted with `ALL_DONE` + a "Recommended next step" footer instead of auto-dispatching the unblock skill.

Verbatim from the screenshot's `Recommended next step` block:

> The natural unblock is `/wr-itil:review-problems` — it rates Impact × Likelihood, estimates Effort, calculates WSJF for all 3 open tickets, and writes `docs/problems/README.md` with the ranked table. After that completes, `/wr-itil:work-problems` can open the loop cleanly.

User comment: "this was annoying that it just wasn't smart enough to run review-problems by itself".

The orchestrator already knew (a) the exact skill to invoke, (b) what that skill would do, (c) that running it was a pre-condition for its own loop opening. All three pieces of information are present in the same output. The halt-with-recommendation pattern leaves the user as a manual dispatcher for a mechanical-and-known next step — the same proxy-for-action anti-pattern P185 / P186 capture at SKILL surfaces, here re-surfacing at the orchestrator-control-flow surface.

This is a structural sibling of:
- **P126** (verifying) — `work-problems` failure handling halt bypasses Step 2.5 routing.
- **P140** (verifying) — `work-problems` Step 6.5 halt on CI failure instead of fix and continue.
- **P183** (open) — AFK orchestrator halts on transient API stream-idle-timeout instead of retrying transient classes.
- **P175** (open) — agent over-narrows scope-pin words into count constraints, halts AFK loop on agent-inferred scope.

The common pattern: orchestrator has enough information to act, but halts. The remedies for the sibling tickets all involve replacing the halt with a deterministic auto-dispatch (with stderr-advisory disclosure rather than a `recommended next step` footer that defers to the user).

Note: the screenshot shows "docs/problems/README.md missing" and "3 open tickets" — strongly suggests this was an adopter-side downstream project where the backlog was newly bootstrapped, NOT this repo (this repo has 40+ open tickets and a present README.md). The pattern is the AFK orchestrator behaviour itself, which ships in `@windyroad/itil` and therefore applies identically across all adopter projects.

## Symptoms

(deferred to investigation)

## Workaround

User manually invokes `/wr-itil:review-problems` after reading the recommendation, then re-invokes the orchestrator. Two manual round-trips for what should be one auto-dispatch.

## Impact Assessment

- **Who is affected**: maintainers running `/wr-itil:work-problems` (and siblings) against any project where pre-conditions aren't yet satisfied — especially adopter-side downstream bootstrap projects with deferred-marker tickets needing a first review pass.
- **Frequency**: every preflight-halt where the recommended-unblock skill is unambiguous and mechanical. New-bootstrap projects hit this every first invocation.
- **Severity**: friction-add; not a correctness defect. The user can always manually invoke the recommended skill, but the manual round-trip is precisely the friction the AFK orchestrator is supposed to eliminate.
- **Analytics**: count of orchestrator sessions ending with `ALL_DONE` + a `Recommended next step` block naming a single `/wr-itil:*` invocation. High ratio indicates the auto-dispatch path is under-used.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate which orchestrator(s) emit the "Recommended next step" footer — likely `/wr-itil:work-problems` Step 0 preflight, possibly `/wr-itil:work-problem` singular. Trace through the SKILL contract.
- [ ] Decide auto-dispatch policy. Proposal: when the preflight halt condition names a single unambiguous `/wr-itil:*` skill AND that skill's outputs are deterministically known to resolve the blocking condition, auto-dispatch via Skill tool invocation. Surface the auto-dispatch in stderr-advisory so the user knows what fired and why.
- [ ] Decide guardrails. Auto-dispatch SHOULD be limited to read-side / re-rate skills (`review-problems`, `reconcile-readme`, `list-problems`) — NOT write-side / state-machine-transition skills (`transition-problem`, `manage-story`) that would carry their own user-authority requirements.
- [ ] Decide retry shape. After auto-dispatching the unblock, re-run the orchestrator preflight. If still blocked, fall back to the current halt-with-recommendation (the auto-dispatch failed; user needed).
- [ ] Sweep sibling halts in `/wr-itil:work-problems` SKILL.md, `/wr-itil:work-problem` SKILL.md, and any other orchestrator with a `Recommended next step` footer. Capture (or fold into this ticket) each halt-instead-of-dispatch instance.
- [ ] Behavioural bats: preflight detects missing README + emits auto-dispatch + re-runs preflight + opens loop. Sibling assertions for preflight detects deferred-Effort markers + auto-dispatch `/wr-itil:review-problems` + re-runs preflight + opens loop.

## Dependencies

- **Blocks**: (none directly — but every adopter bootstrap project hits this on first invocation, so the fix unblocks a measurable user-friction class)
- **Blocked by**: (none)
- **Composes with**: P126 (work-problems failure handling halt bypasses routing — sibling halt-instead-of-act), P140 (work-problems Step 6.5 halt on CI failure — sibling), P183 (AFK orchestrator halts on transient API timeout — sibling), P175 (agent over-narrows scope-pin into halt — sibling), P185 (capture-problem over-asks instead of deriving — same proxy-for-action anti-pattern at a SKILL surface), P186 (VQ Likely verified? heuristic instead of evidence — same anti-pattern at a render surface)

## Related

- **P126** — `work-problems` failure handling halt bypasses Step 2.5 routing (verifying).
- **P140** — `work-problems` Step 6.5 halt on CI failure instead of fix and continue (verifying).
- **P183** — AFK orchestrator halts on transient API stream-idle-timeout (open).
- **P175** — agent over-narrows scope-pin words into halt (open).
- **P185** — `/wr-itil:capture-problem` over-asks classification instead of deriving — same proxy-for-action anti-pattern at SKILL surface.
- **P186** — VQ `Likely verified?` column uses age heuristic instead of session-evidence — same anti-pattern at render surface.
- **P078 / memory `feedback_capture_on_correction.md`** — capture-on-correction OFFER pattern; the user's "this was annoying" comment is the correction signal that triggered this capture.
- **memory `feedback_act_on_obvious_decisions.md`** — "When the decision is obvious (all-yes, pinned direction, policy-within-appetite), act and report — don't ask." The "recommended next step" footer is the orchestrator-side analog of asking-when-obvious.
- **ADR-013** Rule 5 + Rule 6 — silent-proceed contract; the auto-dispatch path is the orchestrator-control-flow application of Rule 5.
- **`packages/itil/skills/work-problems/SKILL.md`** + **`packages/itil/skills/work-problem/SKILL.md`** — primary fix surfaces.
- **`packages/itil/skills/review-problems/SKILL.md`** — the auto-dispatch target.

(captured via /wr-itil:capture-problem; expand at next investigation)
