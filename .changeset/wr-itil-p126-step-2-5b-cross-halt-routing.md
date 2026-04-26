---
"@windyroad/itil": patch
---

work-problems: extracted Step 2.5's surfacing routine into a reusable `Step 2.5b — Surface accumulated user-answerable skips` sub-step that every halt path cross-references before emitting its final AFK summary (P126).

P122 fixed the routing at Step 2.5 stop-condition #2 — when ≥1 user-answerable skip is accumulated, default to `AskUserQuestion`-when-available, fall back to the Outstanding Design Questions table only when the structured-question primitive is unavailable per ADR-013 Rule 6. P126 extends the same contract to the remaining halt paths: Step 0 session-continuity halt, Step 0 fetch-failure halt, Step 6.5 Failure handling (CI / publish failure), Step 6.5 ADR-042 Rule 5 above-appetite halt, Step 6.75 dirty-for-unknown-reason halt. Each halt path now names a one-paragraph cross-reference pointing at Step 2.5b, gated on `≥1 accumulated user-answerable skip`. Step 2.5 itself now delegates to Step 2.5b — single source of truth for the surfacing logic.

The Rule 5 cross-reference carries an architect-FLAG guard: Step 2.5b surfaces *prior-iter accumulated user-answerable skips only* — it does NOT ask the user how to remediate the above-appetite state itself. The halt-causing scorer-gap remains a halt with bug-signal per ADR-042 Rule 5 invariant ("never release above appetite"; the scorer is the decision surface, not the user). The same `prior-iter only` framing is documented for the Failure-handling halt (CI failure remains user-investigation-on-return) and the Step 6.75 dirty-unknown halt (dirty-state recovery remains a Rule 6 user-input requirement on return).

The Decisions Table at the bottom of `SKILL.md` gains a `Halt-path final summary with accumulated user-answerable skips` row naming the cross-halt routing. The `Unexpected dirty state between iterations` row is amended to mention the Step 2.5b call before the halt summary.

`docs/briefing/afk-subprocess.md` adds a `halt-paths-must-route-design-questions-through-Step-2.5b` entry alongside the existing P122 entry, traceable across the principle's evolution.

15 behavioural contract assertions in `packages/itil/skills/work-problems/test/work-problems-step-2-5b-cross-halt-routing.bats` pin the contract per ADR-037 + P081 — Step 2.5b heading present, gating clause named, AskUserQuestion default branch preserved, Rule 6 table fallback preserved, each halt path cross-referenced (5 paths × 1 each = 5 assertions), Rule 5 guard prose present, Decisions Table row present, briefing entry cross-references P122. Full work-problems suite 136/136 green.

JTBD-001 (Enforce Governance Without Slowing Down) primary — extends interactive-question routing to every halt path that accumulates skipped user-answerable design questions. JTBD-006 (Progress the Backlog While I'm Away) — the AFK return ritual is enhanced not disrupted; empty-skip halts skip the routine via the gating clause, so users who hit Step 0 fetch-failure with no iters run see no question prompt. The cross-skill principle paragraph in Step 2.5b generalises to any future AFK orchestrator that hits the same surface — defer the AFK persona to the subprocess boundary, not to the orchestrator's question-surfacing branch.

No new ADR — extension of P122's already-documented routing principle under ADR-013 Rule 1 / Rule 6 + ADR-032 subprocess-boundary contract.
