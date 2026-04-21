---
"@windyroad/itil": patch
---

P077 fix: work-problems Step 5 delegates iterations via the Agent tool

`/wr-itil:work-problems` Step 5 previously used an ambiguous "Invoke the
manage-problem skill" line that read as a Skill-tool (in-process) invocation.
That expanded manage-problem's 500+ line SKILL.md into the main orchestrator's
context every iteration, accumulated across the AFK loop, and caused silent
early-stop (`ALL_DONE` without a documented stop condition firing).

Step 5 now delegates each iteration to a `general-purpose` subagent via the
Agent tool. Option B per P077 — iteration work is general engineering, not
specialised domain expertise, so a typed iteration-worker subagent would just
re-export manage-problem's content. The AFK iteration-isolation wrapper
sub-pattern is documented in ADR-032 (amended 2026-04-21).

- `packages/itil/skills/work-problems/SKILL.md` Step 5 — rewritten with
  explicit Agent-tool delegation (`subagent_type: general-purpose`),
  self-contained prompt shape, and structured return-summary contract
  (`ticket_id` / `ticket_title` / `action` / `outcome` / `committed` /
  `commit_sha` / `reason` / `skip_reason_category` / `outstanding_questions` /
  `remaining_backlog_count` / `notes`). Architect R2: commit-state fields keep
  Step 6.75's Dirty-for-known-reason branch evaluable. JTBD extension:
  skip-reason category and outstanding-questions fields let Step 2.5 populate
  the Outstanding Design Questions table deterministically.
- `allowed-tools` frontmatter — adds `Agent` (closes the pre-existing latent
  bug where Step 6.5 already required Agent-tool delegation).
- Non-Interactive Decision Making table — new row documents iteration
  delegation default.
- `## Related` section — new; cites P077, P036, P040, P041, P053, and ADR-013
  / ADR-014 / ADR-015 / ADR-018 / ADR-019 / ADR-022 / ADR-032 / ADR-037.
- `packages/itil/skills/work-problems/test/work-problems-step-5-delegation.bats`
  — NEW, 10 contract assertions (ADR-037 pattern; `@problem P077` +
  `@jtbd JTBD-006` traceability).
- `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` —
  amended with the "AFK iteration-isolation wrapper (P077 amendment)"
  sub-pattern under foreground synchronous. No supersession.
- `docs/problems/077-...open.md` → `.verifying.md` with `## Fix Released`
  section per ADR-022.

Inter-iteration continuity preserved: Step 6.5 (release cadence / ADR-018)
and Step 6.75 (inter-iteration verification / P036) stay in the main
orchestrator's turn. The iteration subagent commits its own work per ADR-014
but MUST NOT run `push:watch`/`release:watch`.
