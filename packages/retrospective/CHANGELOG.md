# @windyroad/retrospective

## 0.2.0

### Minor Changes

- f0de540: run-retro: generalise codification branch from skills to 12 shapes (P050)

  - **Step 2** superseded from "recurring workflow ... as a skill" to "recurring pattern ... better codified", with a shape sub-list naming 12 shapes (skill, agent, hook, settings, script, CI step, ADR, JTBD, guide, problem, test fixture, memory). "Skill" is retained as one worked example so the P044 muscle memory survives.
  - **Step 4b** now uses a single `AskUserQuestion` with flat shape-prefixed options (`Skill — create stub`, `Agent — create stub`, `Hook — create stub`, `ADR — invoke create-adr`, `JTBD — invoke update-guide`, ...). Dedicated codification skills are routed to rather than duplicated (`wr-architect:create-adr`, `wr-jtbd:update-guide`, `wr-voice-tone:update-guide`, `wr-style-guide:update-guide`, `wr-risk-scorer:update-policy`, `wr-itil:manage-problem`). Fallback to a two-question flow is documented for Claude Code versions where option-count limits bite.
  - **Step 4b non-interactive fallback (ADR-013 Rule 6)** extended: records each candidate as `flagged — not actioned (non-interactive)` with the identified Shape in the Step 5 summary.
  - **Step 5 summary** uses a unified "Codification Candidates" table with `Shape | Suggested name | Scope | Triggers | Decision` columns. Empty-table-omit rule retained.
  - **Backward compatibility**: `run-retro-skill-candidates.bats` assertions updated in place to accept either P044 phrasing or P050 phrasing. "Skill" remains a worked example in Step 2's shape list.
  - New parallel bats `run-retro-codification-candidates.bats` — 9 assertions covering the generalised surface. All 19 run-retro assertions GREEN.

  Deferred: P051 (improvement-axis sibling) — the shape taxonomy established here is the base for P051's extension.

## 0.1.6

### Patch Changes

- 66de931: retrospective: run-retro recommends new skills for recurring workflows (P044)

  The run-retro skill previously routed every observed friction into either
  BRIEFING.md notes or problem tickets. It had no branch for the third valid
  output: codifying a recurring multi-step workflow as a new skill.

  Changes to `packages/retrospective/skills/run-retro/SKILL.md`:

  - Step 2 gains a skill-candidate reflection category: "What recurring
    workflow did I (or the assistant) perform that would be better as a
    skill?" with criteria (multiple invocations, deterministic sequence,
    cross-project reuse) and examples distinguishing skill candidates from
    problem tickets and BRIEFING notes.
  - New Step 4b (Recommend new skills) walks each candidate through an
    `AskUserQuestion` per ADR-013 Rule 1 with three options: create a new
    skill (record suggested name, scope, triggers, prior uses), track as a
    problem ticket, or skip. Non-interactive fallback per ADR-013 Rule 6:
    record candidates as "flagged — not actioned" so they remain visible.
  - Step 5 summary gains a "Skill Candidates" slot so recommendations
    appear alongside BRIEFING changes and problem tickets in the session
    audit.

  Scaffolding itself is deferred — the skill records candidates only.

  Adds `packages/retrospective/skills/run-retro/test/run-retro-skill-candidates.bats`
  (10 assertions) covering Step 2 category, Step 4b branch, ADR-013
  compliance, Rule 6 fallback, and Step 5 summary slot.

  Closes P044 pending user verification.

## 0.1.5

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.1.4

### Patch Changes

- 6eeef94: Rename `@windyroad/problem` → `@windyroad/itil` (plugin `wr-problem` → `wr-itil`, skill `/wr-problem:update-ticket` → `/wr-itil:manage-problem`). Makes room for peer ITIL skills (incident, change) under the same plugin. Hard rename, no shim — per ADR-010.

  **Migration**: if you had `@windyroad/problem` installed, uninstall it (`npx @windyroad/problem --uninstall`) then install `@windyroad/itil`. The skill command changes from `/wr-problem:update-ticket` to `/wr-itil:manage-problem`. `@windyroad/retrospective`'s dependency is updated automatically.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
