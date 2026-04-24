---
"@windyroad/itil": minor
---

P109: work-problems Step 0 preflight detects prior-session partial-work state

`/wr-itil:work-problems` Step 0 (AFK orchestrator preflight) gains a **session-continuity detection pass** after the existing `git fetch origin` + divergence check. This closes the gap where an AFK loop restarted after a quota (429) / error / user-cancel would silently iterate past partial work left in the working tree.

**Signals enumerated** (each maps to one `git status --porcelain` / filesystem / `git worktree` probe):

- Untracked `docs/decisions/*.proposed.md` — drafted but unlanded ADRs from a prior iter.
- Untracked `docs/problems/*.md` — drafted but unlanded problem tickets.
- `.afk-run-state/iter-*.json` files with `"is_error": true` OR `"api_error_status" >= 400` — prior iteration hit quota or API error (ADR-032 subprocess artefact contract). Success files (`"is_error": false`) are ignored.
- Stale `.claude/worktrees/*` directories + matching `git worktree list` entries on `claude/*` branches — prior subagent worktrees not cleaned up. Detection only — mutation/cleanup is out of scope and would require a separate ADR.
- Uncommitted modifications to `packages/*/skills/*/SKILL.md`, `packages/*/hooks/*`, `docs/decisions/*.proposed.md`, or other source paths the prior session was mid-authoring.

**Routing per ADR-013 Rule 1 / Rule 6**:

- **Interactive**: `AskUserQuestion` with 4 options — **Resume the prior work** (land drafted files as iter 1), **Discard the draft**, **Leave-and-lower-priority** (skip the dirty paths), **Halt the loop**.
- **Non-interactive / AFK** (default for this skill per JTBD-006): halt the loop with a structured Prior-Session State report in the AFK summary. Matches Step 6.75's "dirty for unknown reason → halt" stance at the Step 0 layer — the orchestrator does not silently proceed past partial work.

**Surfaces**:
- `packages/itil/skills/work-problems/SKILL.md` Step 0 — adds the session-continuity detection subsection plus a decision-matrix row in the Non-Interactive Decision Making table.
- `docs/decisions/019-afk-orchestrator-preflight.proposed.md` — extended (within its 2026-07-18 reassessment window); no new ADR created. Confirmation criterion 5 added for the contract-assertion bats.
- `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats` — 16 contract-assertion tests per ADR-037 covering signal enumeration, interactive/AFK routing, and the decision-matrix row.

Closes P109 → Verification Pending.
