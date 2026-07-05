---
status: "proposed"
date: 2026-07-06
human-oversight: unconfirmed
decision-makers: [Tom Howard (mechanism direction 2026-07-05), Claude (AFK-derived details 2026-07-06)]
consulted: [wr-architect:agent (pre-edit review 2026-07-06), wr-jtbd:agent (JTBD-006 alignment 2026-07-06)]
informed: []
reassessment-date: 2026-10-06
---

# AFK loops anchor completion with the native `/goal` external evaluator

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

The `/wr-itil:work-problems` AFK orchestrator emitted `ALL_DONE` while a dispatchable backlog remained (P390): the working agent invented a subjective stop ("the salient remainder is interactive-gated") the framework did not authorise. The first fix — Step 2.4 Gate (0), an objective backlog-empty re-scan, shipped in `@windyroad/itil@0.55.0` — is a **self-assessment**: the same agent prone to inventing a stop is also the one asked to forbid its own `ALL_DONE`. P390 was reopened 2026-07-05 with user direction pinning the mechanism: use Claude Code's native `/goal` command (*"the goal skill does exist https://code.claude.com/docs/en/goal. Fucking use it"*). How do AFK drain loops get a stop decision that does NOT belong to the working agent?

## Decision Drivers

- **Same-actor conflation** (P390 root cause): the working agent decides both "should I stop?" and "is stopping justified?" — Gate (0) alone cannot break this because it runs inside the same actor.
- **User-pinned mechanism**: verbatim direction 2026-07-05 selects native `/goal`; per ADR-074 the mechanism level is human-confirmed, this ADR derives the details (ratify-the-derived-details pass at the ADR-066 drain).
- **JTBD-006** (Progress the Backlog While I'm Away): a premature stop forces the user to babysit and re-prompt, defeating the job.
- **Empirical surface constraints** (probed 2026-07-06, Claude Code v2.1.201): no `--goal` CLI flag exists; the Skill tool rejects mid-session invocation with the harness message *"goal is a UI command, not a skill. Ask the user to run /goal themselves — it cannot be invoked via the Skill tool"*; headless `claude -p "/goal"` IS recognized (returned goal-status JSON, `is_error: false`). The anchor therefore cannot be set by the agent mid-session — only at launch or by the user.
- **ADR-044 loop-control boundary**: loop control is framework-resolved; any new surface must not introduce a mid-loop interactive gate or a new agent-invented stop path.

## Considered Options

1. **Native `/goal` external evaluator anchoring the orchestrator session (chosen)** — a per-turn evaluator (the configured small fast model, Haiku by default, wrapping a session-scoped prompt-based Stop hook) judges a completion condition against transcript evidence; the working agent can no longer rationalise a stop.
2. **Retain Gate (0) self-assessment alone** — rejected: shipped in 0.55.0 and empirically insufficient (P390 reopen); same-actor conflation is structural, not a prose-strength problem.
3. **Plugin-shipped always-on prompt-based Stop hook** — rejected: fires a model evaluation after every turn of every session in every adopter project that enables the plugin; cost/latency footprint without the session-scoping `/goal` gives; and the user direction pinned `/goal` specifically.
4. **User babysits the loop** (status-quo workaround) — rejected: defeats JTBD-006.

## Decision Outcome

Chosen option: **native `/goal` external evaluator**, because it moves the stop decision to an independent per-turn evaluator — the only option that structurally breaks the same-actor conflation — and it is the mechanism the user pinned. Derived details:

1. **Orchestrator session only.** The goal lives on the `/wr-itil:work-problems` orchestrator session, never on the `claude -p` iter subprocesses — iters end naturally after one ticket per ADR-032/P077/P084, and a backlog-empty goal there would push an iter past its one-ticket carve-out (the pre-P077 context-bloat failure).
2. **Anchor is set at launch.** No programmatic mid-session surface exists (probe above). The documented headless AFK launch shape is a copy-paste-complete one-liner: `claude -p "/goal <canonical condition> — achieve this by running /wr-itil:work-problems"` — the condition text itself carries the skill invocation so the anchored session actually enters the loop. On interactive invocation, the skill surfaces a one-line nudge with the exact `/goal` command at loop start and proceeds regardless.
3. **Canonical condition owned by work-problems SKILL.md (Step 0e).** Provable end state: the transcript's final summary contains a freshly PRINTED Step 2.4 Gate (0) re-scan table classifying every open/known-error ticket and showing zero dispatchable tickets, followed by `ALL_DONE` — OR a Hard-fail halt directive — OR reported quota exhaustion — with a generous turn-bound clause ("or stop after 100 turns"). P160/ADR-093 quota pacing stretches wall-clock *within* turns, not turn count, so the bound does not conflict.
4. **Printed evidence contract.** Gate (0)'s re-scan classification MUST be printed in turn output — the evaluator judges only surfaced transcript evidence (ADR-026 grounding). A computed-but-unprinted re-scan is invisible to the evaluator.
5. **One-directional anchor.** The goal forces continuation; it never authorises a stop. A goal cleared via the turn-bound clause does NOT discharge Gate (0) — `ALL_DONE` still requires the full Step 2.4 sequence. Gate (0) is retained as first-line defense-in-depth; `/goal` is the external check that the agent keeps turning until Gate (0) genuinely passes.
6. **Never a halt.** An unanchored loop still runs (nudge-and-proceed) — the anchor is defense-in-depth, not a precondition; halting on a missing anchor would itself defeat JTBD-006 and violate the don't-halt-AFK-loop contract.

## Consequences

### Good

- The P390 failure class (agent-invented subjective stop) is judged by a fresh model each turn instead of the actor that invented it; premature `ALL_DONE` cannot end an anchored session.
- Zero new gate machinery shipped: the evaluator is a native, maintained Claude Code primitive; the plugin ships only prose (condition + launch shape + evidence contract).
- Generalisation path for the sibling loop-control class (P332 run-retro skip rationalisation, P148, P175) once proven here.

### Neutral

- Evaluation tokens bill on the small fast model per turn — documented as typically negligible against main-turn spend.
- The goal is session-scoped native state restored on `--resume`/`--continue`; no new `.afk-run-state/` marker is needed.

### Bad

- The anchor is only *guaranteed* on the headless launch path; an interactively-started loop depends on the user acting on the loop-start nudge (the maximum available — no programmatic mid-session surface exists as of v2.1.201).
- `/goal` requires Claude Code ≥ v2.1.139, workspace trust accepted, and hooks enabled (`disableAllHooks` / `allowManagedHooksOnly` disable it); adopters below the floor silently fall back to Gate (0)-only behaviour.
- The condition text and the Step 2.4 Gate (0) table shape are now a coupled contract — reshaping the table requires updating the canonical condition in the same commit.

## Confirmation

- `packages/itil/skills/work-problems/SKILL.md` contains a Step 0e (`/goal` loop-anchor) section carrying the canonical condition verbatim, the headless launch one-liner, the interactive nudge fallback, and the orchestrator-session-only placement rule.
- Step 2.4 Gate (0) prose requires the re-scan classification be PRINTED in turn output.
- Paired promptfoo Tier-A/Tier-B eval cases in `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` assert the Step 0e nudge-and-proceed behaviour and the printed-evidence contract, GREEN per ADR-061 Rule 4.
- Empirical probe results (Skill-tool rejection message, headless recognition JSON) recorded in this ADR and in P390's ticket body.

## Pros and Cons of the Options

### Native `/goal` external evaluator (chosen)

- Good: independent evaluator breaks same-actor conflation structurally; native primitive, no bespoke machinery; session-scoped (no cost outside anchored runs); user-pinned.
- Bad: not settable by the agent mid-session, so interactive-start coverage is nudge-dependent; version/trust/hooks floor.

### Gate (0) self-assessment alone

- Good: already shipped; objective per-ticket classification; no dependencies.
- Bad: empirically insufficient (P390 reopen) — the enforcing actor is the failing actor.

### Plugin-shipped always-on prompt-based Stop hook

- Good: automatic in every session, no launch-shape dependency.
- Bad: per-turn model evaluation cost in every session of every adopter project; not session-scoped; contradicts the pinned mechanism.

### User babysits the loop

- Good: nothing to build.
- Bad: defeats JTBD-006; the exact friction P390 records.

## Reassessment Criteria

Reassess by 2026-10-06, or earlier if: (a) Claude Code ships a programmatic/agent-settable goal surface (the interactive nudge fallback then collapses into a direct set — simplify Step 0e); (b) an anchored AFK run still stops prematurely (evaluator judged a false "yes" — condition needs tightening); (c) the anchor is proven here and the sibling loops (run-retro P332 class) are ready for the generalisation pass; or (d) `/goal` semantics change upstream (it is a product surface outside this repo's control).

## Related

- **P390** (`docs/problems/known-error/390-agent-declares-all-done-prematurely-while-actionable-backlog-remains.md`) — driver ticket (reopen 2026-07-05).
- **ADR-032 / P077 / P084** — iter-subprocess dispatch contract that forces orchestrator-only goal placement.
- **ADR-044** — framework-resolution boundary; loop control is framework-resolved, and this ADR moves the stop *check* outside the agent entirely.
- **ADR-026** — output grounding; drives the printed-evidence contract and the empirical-probe requirement.
- **ADR-061 Rule 4 / ADR-075** — paired promptfoo eval evidence floor for the SKILL-prose surface.
- **ADR-093** — quota-pace throttle; interplay resolved via the turn-bound (not wall-clock) escape clause.
- **P332 / P148 / P175** — sibling agent-invented loop-control class; generalisation candidates.
- Claude Code `/goal` docs: https://code.claude.com/docs/en/goal (mechanics verified 2026-07-05/06).
