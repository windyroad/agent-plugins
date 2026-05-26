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

- [ ] T1 — `wr-itil-mark-create-gate` + `wr-itil-mark-rfc-capture-gate` standalone commands (internalise the `get_candidate_session_ids | mark_step2_complete_candidates` / `mark_rfc_capture_complete` pipelines). Rewrite the 3 create-gate marker sites (capture-problem L159-161, manage-problem L340-342, capture-rfc) to call them. Behavioural bats. **(The screenshot bug — highest user value; land first.)**
- [ ] T2 — KIND A residue audit: can `migrate-problems-layout.sh` + `check-upstream-cache-staleness.sh` internalise into commands, or do they export functions the SKILL's later steps call? For genuine residue: add `wr-itil-lib-path` resolver shim + **ADR-049 amendment** (admit the echo-a-path shim shape; born-confirmed — Option C was user-ratified 2026-05-27). Rewrite the 4 `source` sites accordingly.
- [ ] T3 — KIND B: 5 `wr-itil-update-*` exec-shims for `update-{problem-references,jtbd-references,rfc-references,problem-rfcs}-section.sh` (+ any sibling); rewrite the 17 call sites to invoke by name; delete the `wr-itil-script-path || echo` fallback. Behavioural bats per shim.
- [ ] T4 — extend `no-repo-relative-script-paths-in-skills.bats` for `source packages/...` + `|| echo packages/...`; encode the blessed forms as negative cases. Must be GREEN only after T1-T3 land (it fails on the 24 refs until they're fixed).
- [ ] T5 — fix the 3 comment-only repo-relative examples in `hooks/lib/{session-id,runtime-sid}.sh` (copy-paste hazard) to show the blessed form.

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P317** — driving problem (24-ref scope finding recorded there).
- **P151 / P153 / P219** — the recurring class; this RFC's lint (T4) is the structural prevention for all of them — review-problems should consider folding them into this RFC's trace.
- **ADR-049** — the PATH-shim decision; KIND B is conformance, KIND A residue may amend it (echo-a-path shim shape).
- **P263** — composes-with (manifest-validation CI gate, orthogonal layer).
- **ADR-074** — this RFC's design (Option C) was confirmed via the substance-confirm-before-build flow ADR-074 establishes (architect Needs-Direction → user AskUserQuestion confirm, 2026-05-27).

(captured via /wr-itil:capture-rfc; Scope + Tasks populated at capture — design confirmed, ready to build. Advance via /wr-itil:manage-rfc.)
