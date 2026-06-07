# Problem 225: Docs-only changes should not invoke risk scorer or trigger drift detection

**Status**: Closed (superseded by P203)
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

> **safe-high-fix-risk flag** (per dual-axis-risk classifier): "skip the gate when path matches `*.md`" is a classic load-bearing-safety-check-bypass shape. An over-broad allowlist could let ADR-text changes (which materially affect framework behaviour) or hook-adjacent READMEs escape review. Maintainer must adjudicate the precise allowlist scope (which docs? including `docs/decisions/`?) before merge.

## Description

The risk-scorer hooks treat documentation-only changes (problem tickets, decision records, risk reports, markdown files in `docs/`) the same as code changes. This causes: (1) wasted scoring, (2) false drift detection on architect / jtbd / style-guide gates for routine docs writes.

## Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] **Architect call (safe-high-fix-risk)**: define the docs-only allowlist precisely. `docs/decisions/` changes are NOT docs-only — they materially affect framework behaviour. Likely scope: `docs/problems/*.md`, `docs/retros/`, `docs/audits/`, `docs/briefing/`, ticket READMEs. Excludes: `docs/decisions/`, `docs/jtbd/`, `RISK-POLICY.md`, `STYLE-GUIDE.md`, `VOICE-AND-TONE.md`, hook-adjacent READMEs.
- [ ] Each gate hook adds the docs-only short-circuit at the top: `is_docs_only_change && exit 0`.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/58
- **Pipeline classification**: **safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag); route=safe-and-valid + flag.
- **Affected plugin**: all gate plugins.
- **Evidence (2026-05-23, work-problems iter 1 / P073 close)**: `/wr-retrospective:run-retro`'s mechanical Step 2d ask-hygiene trail write under `docs/retros/` tripped BOTH the architect AND JTBD `PreToolUse` edit gates, forcing 2 subagent round-trips (architect agent `a50c2e466` PASS + jtbd agent `a0ded4a3` PASS) for a pure advisory artefact. `docs/retros/` is named in this ticket's proposed docs-only allowlist (task above) but is **absent from both the architect and JTBD gate exclusion lists** today, though 70+ identically-shaped sibling retro-trail files already exist. Concrete per-iter cost: 2 agent dispatches on every AFK retro-on-exit. Surfaced as a deviation-approval at work-problems loop end; user direction 2026-05-23: append the evidence here rather than open a distinct exclusion-list-gap ticket. Quantified witness for the `docs/retros/` row of the allowlist task.
- **Evidence (2026-05-25, run-retro Step 2d, LIVE RECURRENCE)**: writing the Step 2d ask-hygiene trail `docs/retros/2026-05-25-work-problems-release-149-fix-ask-hygiene.md` again tripped BOTH gates in the same retro (architect agent `ac53ce1e6` PASS, then jtbd agent `a84f29ba1` PASS — 2 dispatches for one advisory write). **Both agents independently confirmed the gap from source this time**: architect read `architect-enforce-edit.sh` (no `docs/retros/` in the exclusion `case`, lines 42-96) and jtbd read `jtbd-enforce-edit.sh` (excludes `docs/jtbd/`, `docs/problems/`, `docs/briefing/`, `docs/story-maps/`, `docs/stories/` at lines 56-104 — but NOT `docs/retros/`). Precedent for treating `docs/retros/` as a managed skill-owned surface already exists (`itil-fictional-defer-detect.sh` P234 + `check-tickets-deferred-cause.sh` both reference `docs/retros/`). **Fix shape (architect-confirmed, ADR-amendment-worthy)**: add `docs/retros/` to BOTH `architect-enforce-edit.sh` and `jtbd-enforce-edit.sh` exclusion lists (alongside the existing `docs/problems/` / `docs/briefing/` entries), synced per the copy-sync contract; route the gate-scope change through an amendment to the gate-scope ADR. Note the safe-high-fix-risk flag above still applies — the exclusion must be scoped to `docs/retros/` exactly (not a broad `docs/*` allowlist).

## Closed as superseded by P203

**Closed on**: 2026-06-08 (via `/wr-itil:work-problems` AFK iter)

**Superseding ticket**: [P203](../verifying/203-architect-jtbd-enforce-edit-hooks-should-add-docs-retros-to-exclusion-paths.md) (Verifying — Fix Released 2026-06-06, commit `b13b9e9`).

**Evidence shape** (ADR-079 Phase 2 shape 3 — duplicate-of-X / shape 2 — ADR-shipped-confirmed; ADR-026 cite + persist + uncertainty):

- **Cite**: `packages/architect/hooks/architect-enforce-edit.sh` lines 108–114 + `packages/jtbd/hooks/jtbd-enforce-edit.sh` lines 114–120 — both files contain `*/docs/retros/*|docs/retros/*)` exclusion case statements with comment `# P203` (committed `b13b9e9` 2026-06-06 `fix(architect,jtbd): exempt docs/retros/ from enforce-edit gates (P203)`).
- **Cite**: P203 body line 8 confirms identical fix shape: "Add docs/retros/ to BOTH architect-enforce-edit.sh and jtbd-enforce-edit.sh exclusion lists" — exact match for the architect-confirmed fix shape pinned in P225 Evidence 2026-05-25.
- **Cite**: P203 references both 2026-05-15 and 2026-05-26 evidence dates plus behavioural bats coverage (`packages/architect/hooks/test/architect-enforce-scope.bats` + `packages/jtbd/hooks/test/jtbd-enforce-scope.bats`, 41/41 pass).
- **Persist**: this closure section + the cited commit SHA + P203 link form the durable audit trail. Reversibility: re-open by `git mv` back to `docs/problems/known-error/` and remove this section if the docs/retros/ exclusion is later reverted (P203 itself becomes the regression signal).
- **Uncertainty**: P225 carried broader original framing ("docs-only changes should not invoke risk scorer") beyond the docs/retros/ exclusion. The orchestrator-narrowed scope (docs/retros/ exclusion in architect + jtbd) is the only architect-confirmed fix shape on this ticket; any residual broader concerns (e.g. `docs/audits/` exclusion gap, risk-scorer short-circuit on docs-only diffs) would require fresh evidence + fresh tickets — they are not in scope for P225's body.

The two evidence sections above (2026-05-23 + 2026-05-25) are the same incidents that drove P203 — both Evidence sections cite the architect+jtbd gate firing on docs/retros/ writes; P203 shipped the exact architect-confirmed fix shape. No further work on P225 advances the system state beyond what P203 already delivered.
