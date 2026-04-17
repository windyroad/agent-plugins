---
status: "proposed"
date: 2026-04-17
decision-makers: [tom-howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-07-17
---

# WIP Risk Scorer — COMMIT Verdict for Completed Governance Work

## Context and Problem Statement

The WIP risk scorer (`packages/risk-scorer/agents/wip.md`) emits two verdict types: `RISK_VERDICT: CONTINUE` (within appetite, keep editing) and `RISK_VERDICT: PAUSE` (above appetite, stop and remediate). Neither verdict handles the case where uncommitted changes are **completed governance work** (finished problem fixes, SKILL.md updates, closed problem transitions) that should be committed immediately to reduce WIP risk and feed the lean release pipeline (ADR-014).

Since ADR-014 (P023 fix) requires governance skills to auto-commit, leaving completed governance work uncommitted represents a pipeline gap — either the auto-commit was skipped, or the user manually completed governance work outside a skill. A third verdict type, `RISK_VERDICT: COMMIT`, would signal this state and encourage the user or calling skill to commit immediately.

## Decision Drivers

- Lean release principle (ADR-014): completed work should move through the pipeline without sitting in the working tree
- ADR-013 Rule 2: scoring agents remain pure output-only; they emit structured verdicts rather than taking actions themselves
- The detection heuristic must be conservative (low false-positive rate): encouraging a commit is only appropriate when there is high confidence the work is done, not mid-flight

## Considered Options

1. **Advisory-only COMMIT verdict** — the scorer emits `RISK_VERDICT: COMMIT` when it detects completed governance work within appetite; the calling skill (`assess-wip`) surfaces this as a prominent suggestion; no hook action taken
2. **Hook-driven auto-commit** — `risk-score-mark.sh` (PostToolUse hook) parses `RISK_VERDICT: COMMIT` and automatically runs `git commit`; removes user action but risks committing incomplete work if the detection heuristic fires incorrectly

## Decision Outcome

Chosen option: **Option 1 (Advisory-only COMMIT verdict)**, because:
- Option 2 requires a hook to parse `RISK_VERDICT: COMMIT` and execute `git commit` — an irreversible action driven by a heuristic that will have false positives. A single false-positive auto-commit is more damaging than a missed encourage-to-commit signal.
- Option 1 keeps the scorer pure (no action, only structured output) and lets the user decide to commit. This is consistent with ADR-013 Rule 2.
- The `assess-wip` skill already has `AskUserQuestion` and can surface the COMMIT suggestion as a prominent, actionable nudge without being automatic.

## Consequences

### Good

- WIP scorer now distinguishes three states: `CONTINUE` (in-progress, risk OK), `PAUSE` (risk too high, stop), `COMMIT` (done, commit now)
- Completed governance work is flagged for commit instead of sitting silently in the working tree
- Pure scorer pattern preserved: scorer emits, skill interprets, user acts

### Neutral

- `assess-wip/SKILL.md` Step 4 must be updated to check for `RISK_VERDICT: COMMIT` and surface it as a prominent suggestion (not just buried in the output)
- `risk-score-mark.sh` does NOT need updating — it ignores `RISK_VERDICT` for WIP mode (existing behaviour); no hook-side effect is needed for Option 1

### Bad

- The detection heuristic is imperfect: governance-artefact-only detection will miss cases where the user has mixed completed governance changes with in-progress source changes (the heuristic fires conservatively — only when ALL uncommitted changes are governance artefacts)
- Adds a third verdict type to the WIP scorer contract; any future consumer of wip output must handle three cases

## Governance-Artefact Detection Heuristic

Uncommitted changes are classified as "completed governance work" when ALL of the following hold:

1. **Risk is within appetite**: cumulative risk ≤ 4/25 per RISK-POLICY.md. Above-appetite changes are always PAUSE regardless of artefact type.
2. **Governance-artefact-only diff**: all uncommitted file changes are in these paths:
   - `docs/problems/*.md` (problem file transitions or updates)
   - `packages/*/skills/**/*.md` (SKILL.md updates or new tests)
   - `packages/*/skills/**/*.bats` (structural BATS tests)
   - `docs/decisions/*.md` (ADR creation or updates)
3. **Completion signal present** (any of):
   - A problem file contains "Fix Released" text in the diff
   - A problem file shows a status transition (`.open.md` → `.known-error.md` or `.known-error.md` → `.closed.md` appearing in `git status`)
   - A SKILL.md was modified alongside a problem file update

**False-positive safeguard**: if any uncommitted file falls outside the governance paths above (e.g., any `.ts`, `.js`, `.sh`, `.mjs`, `package.json`), the heuristic does NOT fire. CONTINUE or PAUSE is emitted normally.

## Verdict Contract (Updated)

| Verdict | Meaning | Appetite |
|---------|---------|---------|
| `RISK_VERDICT: CONTINUE` | Within appetite, in-progress changes — keep editing | ≤ 4 |
| `RISK_VERDICT: PAUSE` | Above appetite — stop and remediate before continuing | > 4 |
| `RISK_VERDICT: COMMIT` | Within appetite, completed governance work detected — commit now | ≤ 4 |

When emitting `RISK_VERDICT: COMMIT`, also emit a reason:
```
RISK_VERDICT: COMMIT
RISK_COMMIT_REASON: <one-line description of the completed work detected>
```

## Confirmation

- `packages/risk-scorer/agents/test/risk-scorer-commit-verdict.bats` — structural BATS test asserting: (a) `wip.md` defines `RISK_VERDICT: COMMIT`; (b) `wip.md` defines `RISK_COMMIT_REASON:`; (c) `wip.md` includes governance-artefact detection heuristic; (d) `assess-wip/SKILL.md` Step 4 handles `RISK_VERDICT: COMMIT` distinctly from CONTINUE/PAUSE
- `assess-wip/SKILL.md` Step 4 updated to check for `RISK_VERDICT: COMMIT` and surface it as a prominent commit suggestion
- `risk-score-mark.sh` is NOT updated — COMMIT verdict is advisory only

## Pros and Cons of the Options

### Option 1 (Advisory-only COMMIT verdict)

- Good: pure scorer preserved; user retains control; no risk of false-positive auto-commits
- Good: the skill can use `AskUserQuestion` to make the COMMIT suggestion actionable (a single "Commit now" option)
- Bad: requires manual user action to commit; not fully automated

### Option 2 (Hook-driven auto-commit)

- Good: fully automated; zero user action required; closes the loop with ADR-014's auto-commit intent
- Bad: irreversible action on a heuristic; a single false-positive corrupts git history with a premature commit
- Bad: the detection heuristic can never be 100% reliable; governance artefacts can be legitimately mid-flight

## Reassessment Criteria

Revisit if:
- The detection heuristic produces frequent false-positives (> 1 per 10 sessions) — consider restricting the heuristic further
- P023 (auto-commit) is extended to 100% coverage — this ADR may become redundant if skills always commit automatically
- Hook infrastructure gains a reversible commit mechanism (e.g., `git stash` + `git commit` + rollback on failure) — Option 2 becomes safe to reconsider
