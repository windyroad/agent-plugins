---
status: proposed
rfc-id: p191-jtbd-gate-project-root-resolution
reported: 2026-06-04
decision-makers: [Tom Howard]
problems: [P191]
adrs: [ADR-008, ADR-052, ADR-071]
jtbd: [JTBD-001, JTBD-101]
stories: []
---

# RFC-020: P191 — JTBD edit gate resolves docs/jtbd from the project root, not the hook runtime CWD

**Status**: proposed
**Reported**: 2026-06-04
**Problems**: P191
**ADRs**: ADR-008 (JTBD directory layout — the fix restores conformance to ADR-008's "detect docs/jtbd, no legacy fallback, inactive only on truly-unmigrated projects" Confirmation), ADR-052 (behavioural-tests default — the bats reproduction fires the hook and asserts emitted deny strings), ADR-071 (every fix goes through an RFC — why this RFC exists)
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down — the false-block is friction with zero governance value), JTBD-101 (Extend the Suite — a misfiring shipped gate degrades the installed-plugin experience)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P191 fix under the RFC-first framework. It carries **no independent architectural decisions**: anchoring on `CLAUDE_PROJECT_DIR` is the only correct fix and mirrors the in-codebase precedent at `packages/jtbd/hooks/jtbd-oversight-nudge.sh:25`; the architect verdict (PASS) recorded it as "single viable option / obvious choice", below the Needs-Direction bar (ADR-064). Status transitions `proposed → verifying` alongside the P191 ticket on `@windyroad/jtbd` release per ADR-022 fold-fix.

## Summary

P191: the JTBD PreToolUse edit gate (`packages/jtbd/hooks/jtbd-enforce-edit.sh`) misfired its fail-closed "no JTBD documentation exists" deny on legitimate edits even when `docs/jtbd/` was present. Root cause: the activation check `[ -d "docs/jtbd" ]` used a **relative path** resolved against the hook process's actual runtime CWD. Claude Code can launch a PreToolUse hook with a working directory that differs from the session/project dir while still exporting `CLAUDE_PROJECT_DIR` (and a `$PWD` env var) pointing at the project; the relative check then false-negatives and the gate blocks the edit. The misfire was witnessed live on 2026-06-04 (an Edit to `packages/itil/skills/report-upstream/eval/promptfooconfig.yaml` blocked despite docs/jtbd present), reproducing the original 2026-05-15 report.

The fix anchors every project-relative check on a project-root signal:

1. **`packages/jtbd/hooks/jtbd-enforce-edit.sh`** — derive `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"`; the project-membership check migrates `"$PWD"/*` → `"$PROJECT_DIR"/*`; the detection becomes `[ -d "$PROJECT_DIR/docs/jtbd" ]` with `JTBD_PATH="$PROJECT_DIR/docs/jtbd"` (absolute). The drift-hash is content-based, so the absolute path yields the same hash as the prior relative path — no marker invalidation.

2. **`packages/jtbd/hooks/jtbd-mark-reviewed.sh`** — same `PROJECT_DIR` derivation + absolute `docs/jtbd` detection. Necessary for symmetry: if the marker-write side false-negatives on docs/jtbd it never stores the marker, and the enforce gate then denies the next edit for lack of a marker.

The pattern mirrors `jtbd-oversight-nudge.sh:25` (`PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"`), the established project-root resolution idiom in this codebase.

## Driving problem trace

- **P191** (`docs/problems/verifying/191-*.md`) — JTBD edit gate misfires "no JTBD documentation exists" despite docs/jtbd present. Status: Verification Pending (fold-fix per ADR-022 P143 lands the verifying transition in the same commit as the fix).

## Scope

Single-commit landing (this RFC's capture commits alongside the fix per ADR-014):

- `packages/jtbd/hooks/jtbd-enforce-edit.sh` — PROJECT_DIR anchor (membership + detection).
- `packages/jtbd/hooks/jtbd-mark-reviewed.sh` — PROJECT_DIR anchor (marker-write symmetry).
- `packages/jtbd/hooks/test/jtbd-project-root.bats` — behavioural reproduction + fail-closed regression guard.
- `docs/problems/verifying/191-*.md` — fold-fix ticket transition + Phase 2 (architect-gate sibling) investigation task.
- `.changeset/p191-jtbd-gate-project-root-resolution.md` — `@windyroad/jtbd` patch changeset.

## Decisions carried (none — routine shape resolved architect-PASS)

Architect review verdict `a86054e851a5d835a` (PASS):

- ADR-008 (PASS) — detection still keys on docs/jtbd only (now absolute); no legacy fallback; the regression-guard test proves true-absence still fail-closed denies. The fix narrows a false-negative without weakening fail-closed.
- ADR-052 (PASS) — the new test fires the hook from a divergent CWD with CLAUDE_PROJECT_DIR set and asserts on emitted deny strings, not source structure.
- ADR-049 (PASS) — `${CLAUDE_PROJECT_DIR:-$PWD}` is the in-codebase precedent; no repo-relative path shipped.
- ADR-071 (PASS) — routes through this thin problem-traced RFC; no new ADR.
- P004 (PASS) — project-membership case migrated consistently; semantics unchanged when CLAUDE_PROJECT_DIR is absent (falls back to $PWD).

JTBD review verdict `a92d0229f592b7bd2` (PASS):

- JTBD-001 aligned (false-block is friction with zero governance value; fix removes overhead while the regression guard preserves the genuine-absence fail-closed safety).
- JTBD-101 aligned (a misfiring shipped gate degrades the installed-plugin experience; fix keeps the hook correct in adopter installs).
- Both jobs + both governing personas (developer, plugin-developer) ratified — no Unratified Dependency flag.

## Phase 2 — architect-gate sibling (same root-cause class, tracked NOT fixed here)

The architect review flagged that `packages/architect/hooks/architect-enforce-edit.sh` has the **identical** relative-path bug at line 28 (`"$PWD"/*` membership) and line 35 (`[ ! -d "docs/decisions" ]` activation), but it fails **OPEN** (`exit 0`) rather than fail-closed. On the same CWD divergence the architect gate silently goes inactive and edits bypass architect review — a **governance hole strictly more severe** than P191's fail-closed nuisance (silent under-protection vs safe-but-annoying over-block). Per the same-root-cause-class principle (and the hang-off-existing-ticket discipline), this is folded into **P191 as Phase 2** rather than captured as a sibling ticket. The fix is scoped to JTBD here (one RFC = one problem trace per ADR-071, smaller blast radius); Phase 2 will apply the same `PROJECT_DIR` anchor to the architect gate (+ `architect-mark-reviewed.sh` if it shares the pattern) with its own behavioural reproduction, and must be ranked higher than a fail-closed nuisance because it is an active governance-bypass hole.

## Tasks

- [x] `jtbd-enforce-edit.sh` PROJECT_DIR anchor (membership + detection).
- [x] `jtbd-mark-reviewed.sh` PROJECT_DIR anchor (marker-write symmetry).
- [x] `jtbd-project-root.bats` behavioural reproduction + fail-closed regression guard (79/79 jtbd hook suite green).
- [x] P191 fold-fix transition (Open → Verification Pending) + Phase 2 architect-gate investigation task.
- [x] `.changeset/p191-jtbd-gate-project-root-resolution.md` `@windyroad/jtbd` patch.
- [ ] Release the changeset → P191 `Verifying → Closed` (release-gated; this RFC `proposed → verifying`).
- [ ] **Phase 2**: apply the same fix to the architect gate (fail-OPEN governance hole) — separate change under P191 Phase 2.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Verification

The `@windyroad/jtbd` changeset `p191-jtbd-gate-project-root-resolution` is the release marker. On release, P191 transitions `Verifying-by-fold-fix → Closed-by-release-evidence` per ADR-022 and this RFC transitions `proposed → verifying`. Behavioural evidence: `packages/jtbd/hooks/test/jtbd-project-root.bats` — firing the hook from a divergent CWD with `CLAUDE_PROJECT_DIR` set to a project containing docs/jtbd no longer emits "no JTBD documentation exists" (gate stays active, denies for missing review marker instead); genuine docs/jtbd absence still fail-closed denies. User-side: editing a project file in any session where the hook's runtime CWD diverges from the project root should no longer false-block.

## Related

- **P191** — driving problem ticket (Verification Pending; fold-fix landed alongside this RFC; carries the Phase 2 architect-gate sibling).
- **ADR-008** — JTBD directory layout; the fix restores conformance.
- **ADR-052** — behavioural-tests default.
- **ADR-071** — every fix goes through an RFC; this is the unconditional-trace instance for the P191 fix.
- **P004** (closed) — gate path-resolution ancestor (edit gates block non-project files).
- **JTBD-001 / JTBD-101** — the jobs this fix serves.
