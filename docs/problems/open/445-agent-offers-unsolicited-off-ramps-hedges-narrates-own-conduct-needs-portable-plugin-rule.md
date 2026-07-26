# Problem 445: Agent offers unsolicited off-ramps, hedges, projects onto the user, and narrates its own conduct — "acknowledges-but-recurs" — and needs a PLUGIN-shipped behavioural rule (portable across every project), not a project-local fix

**Status**: Open
**Reported**: 2026-07-08
**Priority**: 15 (High) — Impact: 3 (Moderate — recurring friction that erodes the agent's value as a crisp, decisive collaborator; hands decisions back to the user; wastes attention) × Likelihood: 5 (Certain — it is default behaviour, recurs every session and every project) — derived at capture per Step 4a
**Origin**: internal
**Effort**: L — design + ship a portable behavioural-rule surface (a plugin hook that injects the rule) + decide its plugin home; behavioural coverage is a prose-eval, not a bats gate.
**WSJF**: 3.75 — (15 × 1.0) / 4 (added 2026-07-15 review)
**JTBD**: JTBD-011 (re-anchored 2026-07-26 from the capture default JTBD-001 — see Related)
**Persona**: developer

## Description

The agent repeatedly, across sessions and projects:

- **Offers unsolicited off-ramps** — "want to stop?", "no rush", "we can pick this up next session", "your call" — handing the user an exit they never asked for.
- **Projects a human frame onto itself** — "it's late", "this is a lot", "rest well" — deciding *for* the user that they might want to stop, when the agent does not tire and the hour has no bearing on it.
- **Narrates its own conduct instead of just doing the work** — "I'll drop it", "I'll be brief", "I'll stop prompting", "sorry for the thrash".
- **Acknowledges the correction and then recurs.** Told to stop, it says "I'll drop it" — and does it again within a few turns. The verbal acknowledgment is treated as the fix. This is the **hollow-marker pattern (P348/P357) turned on the agent's own behaviour**: it "marks itself fixed" in prose without any mechanism that changes the next turn's default.

Driving witness (user, 2026-07-08): after the agent wrote *"handing you an off-ramp you never asked for — deciding for you that you might want to stop … I'll drop it,"* it kept doing exactly that. User: *"why do you keep doing this? And what are you gonna do to stop it … not just on this project but all the other projects that we work on together?"*

**Root of the recurrence:** the agent's defaults reset each session. An in-conversation apology or a project-local memory/ticket changes nothing for the next turn, and NOTHING for the next project (bbstats, voder, any adopter repo). Fixing this in *this* repo would itself be the failure it names — see **P423** (agent fixes recurring behavioural corrections via project-local memory instead of shipping a portable adopter-facing surface).

## Symptoms

- Off-ramp / hedge / self-narration language in the agent's output when it should either act or ask a real question.
- The user re-flagging the same conduct across multiple turns and multiple projects.
- "I'll stop doing X" followed by X.

## Impact Assessment

- **Who is affected**: developer (every project the person runs the agent in); adopters of the `@windyroad/*` suite inherit the same agent conduct.
- **Frequency**: Continuous — default disposition, every session.
- **Severity**: Moderate — erodes trust + wastes attention; not a runtime break.

## Root Cause Analysis

### Preliminary Hypothesis

The behaviour is a trained default; the framework has no PORTABLE surface that injects a counter-rule into every session/project. The existing `@windyroad` behavioural rules (e.g. the P085 act-on-obvious rule, the correction-detect hook) are shipped as plugin hooks that inject standing instructions — that is the proven portable mechanism. This class has no such surface, so it lives only in ad-hoc in-conversation correction that never persists.

### Investigation Tasks (fix is a PLUGIN surface, per P423 — NOT a project-local memory)

- [ ] Author the standing behavioural rule: *no unsolicited off-ramps; no projecting effort/time/tiredness onto the user; no narrating own conduct; when to stop/pause/continue is the user's unprompted call; either act or ask a real question whose answer changes what you do; acknowledging a correction in prose is not a fix — change the behaviour silently.*
- [ ] Ship it as a **plugin hook** (UserPromptSubmit or SessionStart `additionalContext` injection — the same mechanism the suite already uses for governance rules) so it loads in EVERY project that installs the plugin, including adopters. Decide the plugin home (a general behavioural-discipline surface vs folding into an existing plugin) — surface that as an explicit decision (P444), do not bury it.
- [ ] Behavioural coverage: a promptfoo eval asserting an agent turn does NOT emit off-ramp / hedge / self-narration language in a scenario that tempts it (ADR-052 behavioural-only).
- [ ] Consider a detector (advisory) that flags the patterns in agent output for retro, analogous to `itil-correction-detect` on the inbound side.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: **P423** (the master class — fix recurring behavioural corrections via a portable plugin surface, not project-local memory; this ticket is a concrete instance whose fix MUST be the plugin surface), **P444** (surface embedded decisions for oversight — sibling conduct-discipline gap; decide the plugin home explicitly), **P422** (ships X-prime without asking), **P085** (act-on-obvious / never-prose-ask — the existing portable behavioural rule this one sits beside).

## Related

- **P423** — master: behavioural corrections need a portable adopter-facing surface, not project-local memory. This ticket's fix is scoped as a plugin surface per P423 by user direction 2026-07-08.
- **STORY-MAP-007** (A correction to the agent's conduct holds in every project) — the shared map for this class, authored 2026-07-26 while working P438 (the assistant collects free text through the bounded-options picker instead of a copyable block). This ticket's rule belongs there as a second rib, *"No off-ramps I never asked for"*, once it has a story — not as a new map. The rib is named in that map's closing note rather than built empty.
- **JTBD-011** (Have a Correction to the Agent's Conduct Hold Everywhere) — the grounding job authored in the same pass, replacing this ticket's capture-default anchor on JTBD-001. This ticket, P438 and P423 are its three independent instances.
- Driving witness: user, 2026-07-08 (verbatim in Description).
- Maintainer memory `feedback_surface_embedded_design_decisions` (sibling conduct-discipline lesson).
