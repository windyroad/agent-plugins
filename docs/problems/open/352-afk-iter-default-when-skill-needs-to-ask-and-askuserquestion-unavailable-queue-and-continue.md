# Problem 352: AFK iter default when a skill needs to ask a question and AskUserQuestion is unavailable — should queue the question and move to the next iteration (not halt, not silently skip)

**Status**: Open
**Reported**: 2026-06-03 (user direction generalising the P351 AFK fallback answer to a universal pattern: *"Generally speaking, the AFK behaviour when skill needs to ask a question and the AskUserQuestion is unavailable, then it should queue the question and move onto the next iteration."*)
**Priority**: 12 (High) — Impact: 4 (Significant — current behaviour across skills is inconsistent: some halt-with-stderr-directive, some silently fail-soft-skip, some auto-default. Inconsistency means iter loops can halt prematurely OR silently drop signal OR auto-decide things the user should rule on; standardising on queue-and-continue closes the inconsistency at the root) × Likelihood: 3 (Possible — fires on every AFK iter that hits a non-pre-resolved decision point in any skill with an AskUserQuestion surface)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-006
**Effort**: M (audit every skill surface that calls AskUserQuestion + amend AFK fallback prose to queue-and-continue + ensure outstanding_questions schema covers the cases + sibling SKILL/hook coverage)
**WSJF**: 6.0 (12 × 1.0 / 2)

## Description

User direction 2026-06-03 (verbatim): *"Generally speaking, the AFK behaviour when skill needs to ask a question and the AskUserQuestion is unavailable, then it should queue the question and move onto the next iteration."*

The principle: in AFK / non-interactive contexts (where `AskUserQuestion` is forbidden or unavailable per the iter contract — `/wr-itil:work-problems` Step 5 iter dispatch, subagent invocations, any caller-marked AFK path), the universal default when a skill encounters a decision point that would normally surface to the user is:

1. **Queue** the question (with full context: artefact, surface, candidate options, recommendation if any) into `outstanding_questions` for orchestrator-main-turn surfacing at loop end (Step 2.5 batched AskUserQuestion).
2. **Continue** to the next iteration / step — do NOT halt-with-stderr-directive, do NOT silently skip the dependent work, do NOT auto-default to a guess.

Current implementations across skills are inconsistent:

- `/wr-itil:capture-problem` Step 1.5b derive-then-ratify (per ADR-060 Amendment 2026-06-02): AFK + missing flags → halt-with-stderr-directive (no ticket created). This is HALT, not queue-and-continue.
- `/wr-itil:review-problems` Step 4.5 inbound-discovery (P351): AFK + missing config → silently fail-soft-skip. This is SKIP, not queue-and-continue.
- `/wr-architect:create-adr` Step 5 substance-confirm (per ADR-074): AFK is generally not supported; iter halts. HALT, not queue-and-continue.
- `/wr-itil:work-problems` Step 2.5b: already implements queue-and-continue at loop end via the accumulated-questions surface.
- `/wr-itil:manage-problem` Step 4b multi-concern split: AFK auto-splits per the SKILL's non-interactive default. AUTO-DECIDE, not queue.

The inconsistency means adopters running AFK loops get a mix of halt / skip / auto-decide depending on which skill they're in — friction class for JTBD-006 (Progress the Backlog While I'm Away).

## Symptoms

- AFK iter halts mid-loop with a stderr directive when a decision point hits (capture-problem derive-then-ratify shape).
- AFK iter silently skips a feature pass when its config is missing (review-problems inbound-discovery shape).
- AFK iter auto-decides things the user should have ruled on (multi-concern split shape).
- User returns to find a loop that stopped earlier than expected OR silent under-delivery OR decisions made without their input.

## Workaround

User audits skills individually, learns each skill's AFK behaviour shape, and either pre-resolves via flags (`--persona`, `--jtbd`, `--type`, `--no-prompt`) OR avoids AFK invocation of skills with the halt/skip shape.

## Impact Assessment

- **Who is affected**: every adopter running AFK loops (primary JTBD-006 persona constraint). Developers + tech-leads who installed plugins expecting consistent AFK behaviour get fragmented experience.
- **Frequency**: every AFK iter that hits an AskUserQuestion-bearing skill surface. Recurrent across every loop.
- **Severity**: High. Inconsistency erodes the AFK loop's "progress the backlog while I'm away" promise. The queue-and-continue default is what users expect; the current mix is what they get.
- **Analytics**: pattern is class-of-behaviour; fix is at the ADR / SKILL-template level + per-skill amend sweep.

## Root Cause Analysis

### Hypotheses

1. **Per-skill AFK fallback chose independently**: each skill author picked an AFK fallback based on local reasoning (capture-problem chose halt to preserve substance-confirm; review-problems chose fail-soft to not break orchestrator; create-adr chose halt to enforce ratification). No central principle declared one default.

2. **ADR-013 Rule 6 prose ambiguous**: ADR-013 Rule 6 says "non-interactive fail-safe" but doesn't specify the SHAPE of the fail-safe. Halt-with-directive, queue-and-continue, silent-skip, and auto-default are all "non-interactive" in some sense. The Rule needs amending to name queue-and-continue as the default with explicit narrow carve-outs.

3. **ADR-044 framework-resolution boundary doesn't pick the AFK fallback shape**: ADR-044 says "framework resolves when classification permits; user input for the 6-class authority taxonomy". It doesn't say what to do when classification = user-input-required AND user is absent.

4. **outstanding_questions schema scope**: the `outstanding_questions` queue file is owned by `/wr-itil:work-problems` orchestrator; other skills (review-problems standalone, capture-problem standalone) don't have a shared place to queue. Need either to scope the queue file to a shared lib OR each skill maintains its own queue + Step 2.5 reads union.

### Investigation Tasks

- [ ] Audit every SKILL.md surface that contains `AskUserQuestion` (grep all packages/*/skills/*/SKILL.md).
- [ ] For each, document the AFK fallback: HALT / SKIP / AUTO-DEFAULT / QUEUE.
- [ ] Decide: amend ADR-013 Rule 6 with explicit queue-and-continue default + narrow carve-outs (e.g. capture-problem MUST halt because no-ticket-created is the user-pinned protection per ADR-074; review-problems Step 4.5 MUST queue because the pass is incrementally valuable).
- [ ] Decide: per-skill outstanding-questions queue OR shared at lib level.
- [ ] Sweep all halt/skip surfaces → convert to queue-and-continue where the carve-out doesn't apply.

## Fix Strategy

**Kind**: prevent (codify universal default) + audit (per-skill amend sweep)

**Shape**:

1. **ADR-013 amendment**: add explicit "AFK queue-and-continue is the universal default; halt-with-directive and silent-skip are deviations requiring explicit ADR-level carve-out justification" to Rule 6.

2. **outstanding_questions schema generalisation**: lift the queue file from `/wr-itil:work-problems` ownership to a shared `packages/itil/lib/outstanding-questions.sh` helper. Any skill in any context can append. Step 2.5 / Step 2.4 gate (a) read the union.

3. **Per-skill amend sweep**: walk all SKILL.md surfaces; convert HALT and SKIP fallbacks to QUEUE-AND-CONTINUE except where a documented carve-out applies (capture-problem derive-then-ratify HALT for ADR-074 reasons; review-problems Step 4.5 currently SKIP becomes QUEUE per P351).

4. **Structural lint**: optional. PreToolUse hook that flags new SKILL.md prose containing `halt-with-stderr-directive` or `fail-soft skip` patterns without paired carve-out citation.

## Dependencies

- **Blocks**: trust + consistency of AFK loop experience across all skills.
- **Blocked by**: (none).
- **Composes with**: P351 (the witnessed driver — review-problems Step 4.5 fail-soft skip — is one instance of this broader class), P130 (orchestrator-main-turn ask discipline; this ticket extends the discipline DOWN to iter-subprocess + per-skill layers), ADR-013 Rule 6 (parent decision — needs amendment), ADR-044 (framework-resolution boundary — needs reference to this ticket as the AFK-fallback specialisation), JTBD-006 (Progress the Backlog While I'm Away — the persona whose experience is most fragmented).

## Related

- 2026-06-03 user direction (this capture's authoring context): *"Generally speaking, the AFK behaviour when skill needs to ask a question and the AskUserQuestion is unavailable, then it should queue the question and move onto the next iteration."*
- **P351** — sibling-instance ticket: `/wr-itil:review-problems` Step 4.5 fail-soft skip on missing `.upstream-channels.json`. P352 is the broader pattern; P351 is the witnessed instance.
- **P130** — mid-loop ask discipline at the orchestrator main-turn layer. P352 extends the discipline to per-skill / iter-subprocess layers.
- **ADR-013** — structured user-interaction for governance decisions; Rule 6 needs amendment to name queue-and-continue as the universal AFK default.
- **ADR-044** — decision-delegation contract; the 6-class authority taxonomy needs an AFK-fallback specialisation referencing this ticket.
- **ADR-060 Amendment 2026-06-02** — capture-problem derive-then-ratify HALT-on-AFK is a carve-out that P352 should preserve (capture-problem MUST halt because no-ticket-created is the user-pinned protection).
- **JTBD-006** — Progress the Backlog While I'm Away — the AFK persona whose experience this fragments.
