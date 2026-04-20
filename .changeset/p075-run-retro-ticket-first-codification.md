---
"@windyroad/retrospective": minor
---

run-retro Step 4b flips to ticket-first codification (closes P075)

Every codify-worthy observation flows through a two-stage flow: Stage 1
mechanically creates a problem ticket (no user decision on ticketing);
Stage 2 records the proposed fix strategy on that ticket via a 4-option
AskUserQuestion. The legacy 19-option flat list is removed — it
presented ticketing as one choice among many, but in practice the
ticketing axis had a foregone answer every time. Flipping the flow
removes the redundant question and keeps codification as a single
structured prompt per ticket.

- Stage 1: delegates to `/wr-itil:manage-problem` (or
  `/wr-itil:capture-problem` once the ADR-032 background sibling ships);
  applies P016 concern-boundary split before ticketing; fires
  mechanically in AFK mode.
- Stage 2: per-ticket AskUserQuestion with header "Proposed fix" and
  four architect-pinned options — `Skill — create stub`, `Skill —
  improvement stub`, `Other codification shape` (free-text Fix Strategy
  capture, not cascading AskUserQuestion per architect lean), and
  `Self-contained work — no codification stub` (with Rule 6 audit note
  preventing silent-skip). Records a `## Fix Strategy` section on the
  ticket.
- AFK branch: Stage 2 defers via the ADR-032 deferred-question
  contract; Stage 1 ticketing is unaffected by AFK mode.

Interaction notes: P044's recommend-new-skills intent rides in Stage 2
Option 1; P050's shape generalisation rides in Stage 2 Option 3
free-text capture; P051's improvement axis rides in Stage 2 Option 2
for skill shape (non-skill improvements ride in Option 3). P068 Step 4a
unaffected. P074 pipeline-instability signals feed Stage 1 naturally.

ADR-032 Confirmation section amended with the
foreground-spawns-N-background-fanout case so Stage 1's per-observation
capture invocations have an explicit contract home.
