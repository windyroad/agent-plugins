# Problem 191: JTBD edit gate misfires "no JTBD documentation exists" branch on bats fixture edits despite `docs/jtbd/` being present in session CWD

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 6 (Med) — Impact: 3 (Moderate, friction blocks legitimate edits) x Likelihood: 2 (Possible — fires intermittently on specific path patterns) (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The JTBD edit gate (`~/.claude/plugins/cache/windyroad/wr-jtbd/0.7.3/hooks/jtbd-enforce-edit.sh`) blocked multiple Edit-tool calls during the 2026-05-15 P038 fix session with the exact error:

> BLOCKED: Cannot edit '<file>' because no JTBD documentation exists. Run /wr-jtbd:update-guide to generate JTBD docs for this project, then delegate to wr-jtbd:agent for review.

This is the `JTBD_PATH=""` empty-branch message from `jtbd-enforce-edit.sh` line 80-82. However `docs/jtbd/` WAS present in the session CWD `/Users/tomhoward/Projects/windyroad-claude-plugin` and contained content (verified inline via `ls docs/jtbd/`). The hook's `[ -d "docs/jtbd" ]` check must be evaluating relative to a runtime CWD that differs from the session's `$PWD` in some Edit-tool transport paths.

## Symptoms

- Edit-tool calls to `packages/risk-scorer/hooks/test/external-comms-gate.bats` blocked twice with the empty-JTBD-PATH branch despite `docs/jtbd/` being on disk.
- Edit-tool call to `packages/shared/test/sync-external-comms-gate.bats` blocked with the same branch.
- **Workaround that succeeded each time**: a Bash-tool python rewrite of the same file content. The Bash transport apparently does not pass through the JTBD edit gate the same way the Edit transport does (or the hook resolves CWD differently).
- **Recovery that succeeded**: invoke `wr-jtbd:agent` (succeeds, marker writes), THEN retry Edit — that retry sometimes succeeds, suggesting the hook resolves CWD correctly when fired in close temporal proximity to a successful marker write.

## Workaround

Two known workarounds:

1. **Bash-tool python rewrite** of the same file content — bypasses the Edit transport entirely. Fast but loses Edit's diff-aware safety.
2. **Marker refresh dance** — invoke `wr-jtbd:agent` to write a fresh marker, then immediately retry the blocked Edit. Slow but preserves Edit semantics. Brittle: subsequent Edit retries (without another marker refresh) may re-trip.

Both workarounds add friction to long fix-implementation sessions where many bats fixture edits are needed.

## Impact Assessment

- **Who is affected**: solo-developer (JTBD-001) during fix implementation sessions involving multiple bats fixture edits — the friction compounds linearly with the number of test fixtures touched.
- **Frequency**: observed at least 3 times in the 2026-05-15 P038 session; intermittent — not every bats Edit triggers it.
- **Severity**: Moderate — there is a workaround, but the workaround is non-obvious to a fresh agent and consumes user-facing turn time each retry.
- **Analytics**: deferred to investigation.

## Root Cause Analysis

### Confirmed root cause (2026-06-04)

**The activation check `[ -d "docs/jtbd" ]` (line 110) used a RELATIVE path resolved against the hook process's actual runtime CWD, not the session/project root.** Claude Code launches the PreToolUse hook with a working directory that can differ from the session/project dir while still exporting `CLAUDE_PROJECT_DIR` (and a `$PWD` env var) pointing at the project. The relative check then false-negatives even though `docs/jtbd/` is present at the project root, so `JTBD_PATH=""` and the fail-closed "no JTBD documentation exists" deny fires on a legitimate edit.

This is confirmed by the membership-check evidence: the file_path matched `case "$FILE_PATH" in "$PWD"/*` (the hook reached the JTBD-detection block, so `$PWD` env var WAS the project root) yet `[ -d "docs/jtbd" ]` still failed — meaning the hook's real CWD ≠ the `$PWD` env value. Witnessed live 2026-06-04 (Edit to `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` blocked despite docs/jtbd present), reproducing the 2026-05-15 report. The Preliminary Hypothesis below was correct.

### Fix (shipped — fold-fix per ADR-022 P143, carried by RFC-020)

Anchor every project-relative check on `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` (mirrors `jtbd-oversight-nudge.sh:25`):

- `jtbd-enforce-edit.sh` — membership check `"$PWD"/*` → `"$PROJECT_DIR"/*`; detection `[ -d "$PROJECT_DIR/docs/jtbd" ]`; `JTBD_PATH="$PROJECT_DIR/docs/jtbd"` (absolute). Drift-hash is content-based → no marker invalidation.
- `jtbd-mark-reviewed.sh` — same anchor (marker-write symmetry: a false-negative there never stores the marker → enforce gate denies the next edit).
- `jtbd-project-root.bats` — behavioural reproduction (fire from a divergent CWD with `CLAUDE_PROJECT_DIR` set; assert NOT "no JTBD documentation exists" + IS "without JTBD review") + a regression guard preserving fail-closed on genuine docs/jtbd absence. Full jtbd hook suite 79/79 green.

Architect verdict `a86054e851a5d835a` PASS (routine bug-fix, no new ADR). JTBD verdict `a92d0229f592b7bd2` PASS.

### Phase 2 — architect-gate sibling (same root-cause class, NOT fixed here)

`packages/architect/hooks/architect-enforce-edit.sh` has the **identical** relative-path bug at line 28 (membership) + line 35 (`[ ! -d "docs/decisions" ]` activation) — but it fails **OPEN** (`exit 0`), so on the same CWD divergence the architect gate silently goes inactive and edits bypass architect review. This is a **governance hole strictly more severe** than P191's fail-closed nuisance (silent under-protection vs safe-but-annoying over-block). Folded into this ticket as Phase 2 per the same-root-cause-class principle (architect direction: track here, do not capture a sibling ticket).

### Phase 2 — SHIPPED 2026-06-04 (fold-fix; `@windyroad/architect` patch)

Applied the `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` anchor across the FULL architect-gate project-root surface (the complete root-cause class — partial would leave the bug in some paths):

- [x] `architect-enforce-edit.sh` — membership (`"$PWD"/*` → `"$PROJECT_DIR"/*`) + detection (`[ ! -d "$PROJECT_DIR/docs/decisions" ]`). The fail-OPEN governance hole.
- [x] `architect-plan-enforce.sh` — detection (same fail-OPEN on ExitPlanMode plan review).
- [x] `architect-detect.sh` — UserPromptSubmit detection (delegation-instruction injection).
- [x] `architect-mark-reviewed.sh` — marker-write hash (consistency).
- [x] `architect-refresh-hash.sh` — hash refresh (consistency).
- [x] `lib/architect-gate.sh` — `check_architect_gate` drift-hash (consistency).
- [x] Behavioural reproduction in `architect-project-root.bats` (fail-OPEN variant: gate stays ACTIVE / denies for missing marker when CWD diverges but docs/decisions present) + fail-open regression guard (genuine absence stays inactive). Full architect hook suite 77/77 green.

Carried by RFC-020 (Phase 2 task in the same RFC). `@windyroad/architect` patch changeset `.changeset/p191-architect-gate-project-root-resolution.md`.

**Related-but-distinct surface NOT fixed here**: `architect-oversight-marker-discipline.sh` (+ the jtbd sibling) use `"$PWD"/*` for membership but gate *oversight-marker edits*, not the main gate's activation — a tangential fail-open on a narrower surface. Noted for a future pass if it recurs; not part of the gate-activation root-cause class this ticket closes.

### Preliminary Hypothesis

The PreToolUse hook may inherit a different CWD than the session's `$PWD` in some Edit-tool transport contexts (e.g. when Claude Code's Edit transport is invoked via a path that doesn't honour CWD propagation). This would explain:

- Why the same content edit succeeds via Bash (Bash-tool transport always inherits $PWD from the session shell).
- Why immediate post-`wr-jtbd:agent` retries sometimes succeed (the agent's recent fork inherits $PWD; the marker file write resets some hook-context state that the next Edit picks up).
- Why the misfire is intermittent (transport-dependent).

The hook's `JTBD_PATH=""` empty-branch is intentional graceful-degradation for adopters who haven't run `/wr-jtbd:update-guide` — but the empty-branch should only fire when `docs/jtbd/` GENUINELY doesn't exist in the project. The current check is necessary-but-not-sufficient: it doesn't validate that the CWD it's checking from is the session's CWD.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P004 (gate path resolution; ancestor concern), P107 (TTL extension; same class of hook-stability work), P173 (BYPASS env vars don't propagate; same CWD-context / env-context family — hooks see different runtime context than the session expects)

## Verification

Fold-fix per ADR-022 P143. Release vehicle: `.changeset/p191-jtbd-gate-project-root-resolution.md` (`@windyroad/jtbd` patch). On release this ticket transitions `Verification Pending → Closed` and RFC-020 transitions `proposed → verifying`. Behavioural evidence: `packages/jtbd/hooks/test/jtbd-project-root.bats` (CWD-divergence reproduction + fail-closed regression guard; 79/79 jtbd hook suite green). NOTE: Phase 2 (architect-gate fail-OPEN sibling) remains open under this ticket after Phase 1 closes — Phase 1 closure does not close Phase 2.

## Related

- **RFC-020** (`docs/rfcs/RFC-020-p191-jtbd-gate-project-root-resolution.proposed.md`) — the RFC carrying this fix (ADR-071 unconditional RFC-first; thin, no independent decisions).
- `packages/jtbd/hooks/jtbd-enforce-edit.sh` + `jtbd-mark-reviewed.sh` — the fixed hooks (source of truth; the cache copy at `~/.claude/plugins/cache/windyroad/wr-jtbd/<ver>/hooks/` refreshes via `/install-updates` + restart).
- P004 (`docs/problems/closed/004-edit-gates-block-non-project-files.md`) — earlier work on gate path resolution; ancestor.
- P107 (`docs/problems/closed/107-architect-jtbd-edit-gate-markers-expire-mid-batch.md`) — TTL stability; related hook-quirk class.
- P173 — BYPASS env vars don't propagate from Bash subshell to PreToolUse hook context; same CWD/env-context family.
- Captured by `/wr-retrospective:run-retro` Step 4b Stage 1 + user direction "don't defer the stage 1 ticketing" (2026-05-15).
