---
"@windyroad/itil": patch
---

P130 — `packages/itil/skills/work-problems/SKILL.md` Mid-loop ask discipline (orchestrator main turn). Tightens the orchestrator's ask discipline per the user-reframed Fix Strategy: presence-detection is unreliable and is not the goal; treat the user as transient (may answer one question and disappear for hours). The loop's purpose is progress + accumulation; mechanical-stage transitions between iters are framework-resolved.

The orchestrator MUST NOT call `AskUserQuestion` between iters except at framework-prescribed halt points: Step 0 session-continuity / fetch-failure; Step 2.5 / 2.5b loop-end emit; Step 6.5 above-appetite Rule 5 + CI-failure / release:watch halts; Step 6.75 dirty-for-unknown-reason. Continue iterating until quota exhausts or a stop-condition fires.

Accumulated user-answerable questions follow strict discipline at surface time:
- Direction-setting decisions only (no BUFD)
- No questions answerable by research / exploration / experimentation — the agent should prototype, read code, run experiments to answer those itself
- Each surfaced question must carry enough context for an informed decision (architect's recommended option, alternatives, trade-offs, concrete consequences of each path)

Files shipped:
- `packages/itil/skills/work-problems/SKILL.md` — new "Mid-loop ask discipline (orchestrator main turn)" subsection inside Non-Interactive Decision Making; framework-prescribed halt-point enumeration; transient-user framing; accumulated-question discipline; cross-references to Step 5's per-subprocess constraint.
- `packages/itil/skills/work-problems/SKILL.md` Step 5 iteration-prompt body — augmented with the transient-user framing.
- `packages/itil/skills/work-problems/test/work-problems-no-mid-loop-asking.bats` — 20 new behavioural assertions per ADR-037 + P081 covering the no-mid-iter-asks invariant and the framework-prescribed halt-point allow-list.

ADR-032 unchanged — the subprocess-boundary contract is preserved verbatim. Out of scope per the reframe: presence-signal helper (`packages/itil/hooks/lib/presence-signal.sh`), dual-mode dispatch, stream-json live-tail observation surface.

Composes with P132 (over-ask in interactive sessions — same family of agent-discipline gaps; P132's enforcement hook serves P130's reframed direction) and P135 / ADR-044 (decision-delegation contract — framework-resolution boundary).

Transitions P130 Known Error → Verification Pending per ADR-022.
