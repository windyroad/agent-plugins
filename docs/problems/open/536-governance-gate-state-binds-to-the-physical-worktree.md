# Problem 536: Governance gate state binds to the physical worktree, blocking commits from a linked worktree and silently disabling the WIP gate inside one

**Status**: Open
**Reported**: 2026-09-08
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-001, JTBD-006
**Persona**: developer

## Description

Two independent defects in the same class — governance state keyed to a *physical working tree* rather than to the repository or to a repo-relative path — both fire when an agent works inside a linked git worktree (the harness creates these under `.claude/worktrees/<name>/`).

**Symptom 1 — the risk verdict does not travel to the worktree.**
`packages/risk-scorer/hooks/lib/gate-helpers.sh::_checkout_id` hashes `st_dev:st_ino` of `git rev-parse --show-toplevel`. A linked worktree has a different toplevel inode from its main checkout, so `_checkout_matches` fails and `check_risk_gate` denies with category `drift` — even though the assessment was minted seconds earlier against identical content in the same repository. Observed 2026-09-08: an agent holding a valid Low-risk verdict could not commit from an isolated worktree and resorted to stashing the unrelated edits in the original checkout, applying the patch there, committing, and restoring the stash. That dance is the workaround, and it risks losing uncommitted work.

`packages/risk-scorer/hooks/codex-agent-completion.mjs::checkoutId` mirrors the same `dev:ino`-of-toplevel computation and must move in lockstep, or the bash and JS identities diverge (`codex-agent-completion.bats` asserts parity).

**Symptom 2 — the WIP risk gate goes dark inside a worktree.**
`_is_doc_file` classifies runtime-config and governance files as non-application "docs" by matching the *absolute* file path against `*.claude/*` (plus the `_doc_exclusions` patterns). Inside a harness worktree every absolute path contains `/.claude/worktrees/<name>/`, so **every** file matches and is classified as a doc. Its only caller, `packages/risk-scorer/hooks/wip-risk-gate.sh:23`, uses that as a skip list — so the WIP risk gate never fires for any edit made inside a worktree. Silent, not loud: nothing surfaces. Two such worktrees are live on disk at capture time.

The same absolute-path matching also misclassifies any repository that merely happens to be cloned beneath a path containing `.claude/`, and any worktree created outside `.claude/worktrees/`. The general defect is that every pattern in `_doc_exclusions` (`docs/`, `.changeset/`, `governance/`, `CLAUDE.md`, …) is repo-relative by construction, but the classifier is fed an absolute path.

## Symptoms

- `check_risk_gate` denies with `RISK_GATE_CATEGORY=drift` and "checkout binding … does not match" when committing from a linked worktree that holds a freshly scored, content-identical tree.
- `wip-risk-gate.sh` exits 0 for every `Edit`/`Write` inside `.claude/worktrees/<name>/`, so no WIP assessment is ever demanded there.

## Workaround

Stash the worktree's edits, apply the change in the main checkout, commit there, restore the stash. Dangerous and manual — this is the behaviour the fix removes, not a recommendation.

## Impact Assessment

- **Who is affected**: any developer or AFK loop whose agent works in a linked git worktree — the harness's own isolation mechanism.
- **Frequency**: deterministic whenever a worktree is used; two worktrees live on disk at capture time.
- **Severity**: symptom 1 blocks the commit path and pushes the agent toward stash gymnastics that can lose work; symptom 2 disables a governance gate *silently*, which is the worst failure shape for this persona (`docs/jtbd/developer/persona.md` names "agents skip steps" and silent corruption as pain points).
- **Analytics**: none collected.

## Root Cause Analysis

Marker identity conflates two different questions that the rest of the gate already separates:

1. *Which repository was assessed?* — answered correctly by the common git dir (`git rev-parse --path-format=absolute --git-common-dir`), identical across every linked worktree, distinct across clones.
2. *Which working tree was assessed?* — answered by the toplevel inode, and genuinely needed only where a marker is **mutated** without a content re-check.

Binding gate *consumption* to (2) is what breaks worktrees. Content binding for consumption is already carried independently by `state-hash` (a full conceptual-tree hash from `pipeline-state.sh --hash-inputs`), so a worktree whose content differs still trips drift detection.

The one place (2) remains load-bearing is `risk-hash-refresh.sh`: its only authorisation to overwrite `state-hash` is `_checkout_matches`. Widening identity without also binding that hook to the assessed toplevel would let a `git add` in worktree B silently re-bind a score assessed in worktree A to a tree it was never assessed against — a strictly larger hole than the one being closed. Flagged by the architect review 2026-09-08.

### Investigation Tasks

- [ ] Key `_checkout_id` on the common git dir; keep a separate `_worktree_id` for mutation-path binding.
- [ ] Move `codex-agent-completion.mjs::checkoutId` in lockstep (realpath-resolved, to match the bash side on symlinked checkouts).
- [ ] Bind `risk-hash-refresh.sh` to the assessed worktree (fail-open only for markers minted before the binding exists).
- [ ] Normalise `_is_doc_file` to the repository-relative path before classification.
- [ ] Behavioural bats: worktree/main share identity; separate clones do not; a main-checkout marker clears the gate from a worktree; differing content in a worktree still re-fires the gate; a `git add` in a second worktree does not mutate the stored hash; `wip-risk-gate` denies on a source file inside a worktree and still skips genuine `.claude/` config.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P499 (architect ADR-pairing hook read the task checkout instead of the command checkout — same "which checkout is authoritative" family, resolved on the declared-cwd axis).

## Related

- Captured via `/wr-itil:capture-problem`.
- Hang-off pre-filter surfaced 7 candidates (> 5), so the `wr-itil:hang-off-check` dispatch was skipped per the SKILL's candidate-cap short-circuit. Candidates for review-time re-evaluation: P096 (hook injection volume), P131 (`.claude/` user-space writes), P213 (risk TTL), P192 (repeat rescoring round-trips), P377 (appetite override), P402 (background review agents), P353 (hash-marker brittleness umbrella). None of them owns the worktree-binding axis; P353 is the nearest umbrella and is worth checking at the next `/wr-itil:review-problems`.
- Title-only duplicate grep matched P499 (closed) and P115 (parked, stale plugin installs in worktrees) — neither absorbs this scope.
- Architect review 2026-09-08 raised two governance items this ticket does not itself resolve: the marker-binding scope is not pinned in any ADR (`risk-gate.sh` carries it only as a code comment plus P477's released "persist only for the assessed checkout" requirement), and the five hand-synced `gate-helpers.sh` copies have no sync script or CI drift check as ADR-017 requires.
