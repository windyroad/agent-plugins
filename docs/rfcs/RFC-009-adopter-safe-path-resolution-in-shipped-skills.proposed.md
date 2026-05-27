---
status: proposed
rfc-id: adopter-safe-path-resolution-in-shipped-skills
reported: 2026-05-27
decision-makers: [Tom Howard]
problems: [P317]
adrs: [ADR-049]
jtbd: []
stories: []
---

# RFC-009: Adopter-safe path resolution in shipped SKILLs (P317 — 24 repo-relative references)

**Status**: proposed
**Reported**: 2026-05-27
**Problems**: P317 (+ recurring class P151 / P153 / P219)
**ADRs**: ADR-049 (plugin script resolution via bin on PATH — amended by KIND A residue if any)
**JTBD**: (none)

## Summary

Fix the 24 shipped-SKILL references to repo-relative `packages/...` paths that resolve only in this source monorepo and break in adopter installs (P317 scope finding). Plus the structural-prevention lint so the class never recurs ("never happens again"). Design confirmed via the ADR-074 substance-confirm-before-build flow: architect Needs-Direction → user confirmed **Option C (hybrid)** for the KIND A surface, 2026-05-27.

## Driving problem trace

- **P317** — capture-problem/capture-rfc/manage-problem (and others) `source` repo-relative `packages/itil/{lib,hooks/lib}/*.sh` and invoke `$(wr-itil-script-path || echo packages/itil/scripts)/*.sh` where the shim never existed. Both break in adopter trees. Recurring class with P151/P153/P219. Evidence: voder-mcp-hub, 2026-05-27.

## Scope

Two reference kinds (architect verdict 2026-05-27):

- **KIND B — 17 invoked-script refs** (framework-resolved, pure ADR-049 conformance): the `$(wr-itil-script-path 2>/dev/null || echo packages/itil/scripts)/<x>.sh` sites across manage-story, reconcile-stories, capture-story, manage-rfc, manage-story-map, capture-rfc, capture-story-map. Fix: give the 5 `update-*.sh` scripts ADR-049 exec-shims (`wr-itil-update-*`), rewrite the 17 sites to call by name, DELETE the phantom `wr-itil-script-path` fallback.
- **KIND A — 7 sourced-library refs** (design-confirmed **Option C hybrid**): `source packages/itil/{lib,hooks/lib}/*.sh` (session-id.sh, create-gate.sh, migrate-problems-layout.sh, check-upstream-cache-staleness.sh). Convert each to a standalone PATH-invoked `wr-itil-*` command WHERE the work internalises (no function-export needed); add a `wr-itil-lib-path` resolver shim (+ ADR-049 amendment) ONLY for genuine function-export residue.
- **Structural prevention** (framework-resolved, ADR-049 reassessment clause 3 pre-authorises): extend `packages/shared/test/no-repo-relative-script-paths-in-skills.bats` to catch `source +packages/...` and `\|\| +echo +packages/...`, with the blessed forms (`wr-itil-*` by name; `source "$(wr-itil-lib-path)/X"` if Option-A residue) as negative cases. Composes-with (not covered-by) P263.

Out of scope: re-deciding Option C; P263's manifest-validation gate (separate layer).

## Tasks

- [x] **T1 DONE** — `wr-itil-mark-create-gate` + `wr-itil-mark-rfc-capture-gate` standalone commands (`scripts/mark-create-gate.sh` + `mark-rfc-capture-gate.sh` + bin shims) internalise the candidate-SID marker writes, resolving sibling libs via `$(dirname)`. Rewrote the 3 marker sites (capture-problem, manage-problem) AND added the missing marker step to capture-rfc (latent gap — it had none). 4 behavioural bats GREEN (`test/mark-create-gate.bats`).
- [x] **T2 DONE (Option C → fully Option B)** — both `migrate-problems-layout.sh` + `check-upstream-cache-staleness.sh` internalised cleanly into `wr-itil-migrate-problems-layout` + `wr-itil-check-upstream-cache-staleness` commands (side-effect / stdout-capture; no function-export residue). **No `wr-itil-lib-path` shim and NO ADR-049 amendment needed.** Rewrote the 3 `source` sites (manage-problem, work-problems ×2). 3 behavioural bats GREEN (`test/kind-a-commands.bats`).
- [x] **T3 DONE** — 4 `wr-itil-update-*` exec-shims (`update-{problem-references,jtbd-references,rfc-references,problem-rfcs}-section`); rewrote all 17 call sites across 7 SKILLs to invoke by name; deleted the phantom `wr-itil-script-path || echo` fallback. Shim dispatch verified.
- [x] **T4 DONE** — extended `no-repo-relative-script-paths-in-skills.bats` with 2 new line-anchored guards (`^source packages/...` + `|| echo packages/...`); 15 bats GREEN. Structural prevention live: any future repo-relative ref in a shipped SKILL fails CI.
- [x] **T5 DONE** — fixed the 4 comment-only repo-relative examples in `hooks/lib/{session-id,runtime-sid}.sh` to the sibling-relative form + a "never source repo-relative from a SKILL" note.

**Implementation status (2026-05-27): COMPLETE.** All 24 broken refs fixed; 105 affected bats GREEN; structural-prevention lint live. Remaining: RFC lifecycle transition + release (this commit + changeset).

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P317** — driving problem (24-ref scope finding recorded there).
- **P151 / P153 / P219** — the recurring class; this RFC's lint (T4) is the structural prevention for all of them — review-problems should consider folding them into this RFC's trace.
- **ADR-049** — the PATH-shim decision; KIND B is conformance, KIND A residue may amend it (echo-a-path shim shape).
- **P263** — composes-with (manifest-validation CI gate, orthogonal layer).
- **ADR-074** — this RFC's design (Option C) was confirmed via the substance-confirm-before-build flow ADR-074 establishes (architect Needs-Direction → user AskUserQuestion confirm, 2026-05-27).

(captured via /wr-itil:capture-rfc; Scope + Tasks populated at capture — design confirmed, ready to build. Advance via /wr-itil:manage-rfc.)
