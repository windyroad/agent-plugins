# Problem 375: Repo conflates a "named re-entry point" with a self-firing cadence — deferrals not transitively reachable from an automatic trigger rot

**Status**: Open
**Reported**: 2026-06-23
**Priority**: 16 (High) — Impact: 4 (High) × Likelihood: 4 (Likely). **Rated at capture from observed evidence, NOT deferred** (re-rating this ticket "at next /wr-itil:review-problems" would itself be the bug — nothing self-fires review-problems). Impact 4: defeats the repo's central value proposition (feedback loops that build intelligence) AND ships the rot-generator into adopter projects via the deferral-emitting skills. Likelihood 4: ~12 observed instances (see Related cluster); structural and recurring.
**Origin**: internal
**Effort**: L — cross-package design (authoring-time enforcement check spanning architect/itil/retrospective) + rollup-parent decision + capture-skill default fix. WSJF = (16 × 1.0) / 4 = 4.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

Agent (and repo SKILL authoring) conflates a "named re-entry point" with a self-firing cadence. Deferrals like "deferred to `/wr-itil:manage-rfc` accepted transition" or "(deferred to `/wr-architect:create-adr` canonical review)" name a skill/transition but **nothing automatically fires that skill on the deferred artefact** — it waits for a human or AFK loop to *choose* to run it, which is on-demand, which per P291/P295 (memory: `feedback_automatic_cadence_or_it_doesnt_happen`) never happens. The deferred work rots.

**Correct rot test**: a deferral is only legal if its trigger chain is **transitively reachable from something SELF-FIRING** (hook / SessionStart nudge / cron / AFK loop), not just a named on-demand command. "Defers to `/wr-itil:manage-rfc`" is illegal *unless* something self-firing runs `manage-rfc` on that RFC. The test bottoms out in: does the chain terminate in an automatic event, or in a human who has to remember?

Surfaced 2026-06-23 when the agent defended these deferrals as "names the next event that pulls the work forward" and the user corrected: **"BUT NOTHING TRIGGERS THAT WORK!!!"**

## Symptoms

- Captured-but-never-expanded RFCs/ADRs sit with `(deferred to …)` placeholders indefinitely.
- The same uncadenced-deferral failure has been re-discovered ~12+ times as single-instance tickets (see `## Related`) rather than fixed once as a class.
- This very ticket's capture flow **defaulted** Priority/Effort to `Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)` — an uncadenced deferral *and* a false-low that buried the meta-ticket at WSJF 1.5. The capture skill is a rot-generator. Re-rated by hand at capture (the correct behaviour); fixing the skill default is an Investigation Task below.

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: maintainers (rotted governance backlog), and the repo's core ethos (feedback loops that build intelligence over time) — undermined when the loop's tail never fires.
- **Frequency**: structural / pervasive (see instance cluster).
- **Severity**: (deferred to investigation)
- **Analytics**: instance-ticket count is the running tally — ~12 single-site captures of this class to date.

## Root Cause Analysis

### Investigation Tasks

- [x] Rate Priority and Effort — done at capture (Impact 4 × Likelihood 4, Effort L, WSJF 4.0); NOT deferred
- [ ] Audit every deferral in shipped skills/hooks/agents: classify as self-firing-reachable / on-demand-only / ticket-backed (the 2026-06-23 audit — attach results here)
- [ ] Design the authoring-time enforcement: a check (hook or retro-step) that flags any deferral whose trigger chain is NOT transitively reachable from a self-firing event. Compare with existing `itil-fictional-defer-detect.sh`.
- [ ] Decide whether P375 becomes a rollup PARENT for the instance cluster (P295/P271/P234/P236/P184/P189/P110/P220/P253/P148) or a sibling that supersedes them.
- [ ] Fix the capture-problem (and manage-problem) deferred-placeholder default — `Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)` is both an uncadenced deferral and a false-low that buries captures; either rate at capture or make review-problems self-firing
- [ ] Create reproduction test (behavioural: a SKILL with an on-demand-only deferral fails the check; one with a self-firing trigger passes)

## Dependencies

- **Blocks**: (none yet)
- **Blocked by**: (none)
- **Composes with**: `itil-fictional-defer-detect.sh` hook (existing partial enforcement)

## Related

This is the **systemic / meta** ticket for a class previously captured only as single instances. Candidate rollup children (≥1 shared signal: P291/P295/cadence/self-firing/on-demand-only; >5 candidates so hang-off-check skipped per capture-problem sub-step 2b candidate-cap, recorded here for `/wr-itil:review-problems` re-evaluation):

- **P295** (verifying) — ADR-043 deep-context-analysis needs automatic cadence not on-demand-only. Direct instance.
- **P271** (verifying) — review-problems not auto-fired when needed; user has to remember. Direct instance.
- **P234** — agent defers framework-required mechanical work with rationalization; "defer is fictional". Behavioural instance.
- **P236** — iter queues proceed-vs-defer as direction when framework trigger already fired.
- **P189** — agent invents deferred framing on tracked phases without user deferral direction.
- **P184** — agent treats conditionally-deferred work as permanently out of scope.
- **P110** — risk register has no passive trigger; slash-command alone (partial JTBD-001).
- **P220** — manage-problem has no cadence for checking upstream-bound tickets.
- **P253** — no house-cleaning cadence for cruft/deprecation removal.
- **P148** — agent defers ticket creation to retro summary instead of immediately invoking manage-problem.
- **P291** — root-cause sibling to P295 (cadence-or-it-doesn't-happen).
- Memory `feedback_automatic_cadence_or_it_doesnt_happen` — the prior statement of this root cause.
- `packages/itil/hooks/itil-fictional-defer-detect.sh` — existing partial enforcement; the authoring-time check likely extends this.

(captured via /wr-itil:capture-problem; expand at next investigation)
