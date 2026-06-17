# Work-Problems Session Retrospective — 2026-06-18

**Surface**: /wr-itil:work-problems orchestrator main turn (Step 2.4 gate (b) session-level retro per P341).

**Scope**: orchestrator-main-turn observations across 9 iters + Step 2.4 gates + post-iter gates + Step 0b pre-flight. Per-iter retros for each subprocess already committed inline.

## Session Stats

- **Iters dispatched**: 9 (P276 close-out / P314 ×5 RFC-005 B-tasks / P080 ×2 catchup mode + dogfood / P136 ADR-044 audit Phase 3c)
- **Releases shipped**: 2 (`@windyroad/retrospective@0.25.0`, `@windyroad/itil@0.51.0`)
- **Tickets transitioned**: P276 (Open → Verification Pending)
- **Tickets newly captured**: P371 (I13 gate lacks wire-existing-vehicle branch), P372 (ADR-043 context-budget delta-trigger lacks absolute-byte floor)
- **Tickets advanced**: P314 (B2/B6/B7/B8/B9 all closed — Phase 2 functionally complete mod B10 vp-blocked + B2-followup ADR-heavy), P080 (Phase 2 items 1-2 shipped + items 3-4 design-blocked on G1/G2 → Phase 3 direction set), P136 (Phase 3c — 3 SKILLs audited)
- **Risk register entries scaffolded**: 5 (R057-R061)
- **Cost**: ~ (iters ~ + Step 0b  + reviewer-subagent overhead)

## Briefing Changes

- **Added**: 1 entry to `docs/briefing/hooks-and-gates.md` (the P371 wire-existing-vehicle pre-check pattern — landed iter 6 retro then carried forward via 081445b0 at Step 2.4 gate (a) cleanup).
- **Removed / Updated**: none.
- **README index**: unchanged.
- **Scan evidence**: orchestrator main turn loaded the briefing topic index in Step 0 but did not deep-load topic files (iter subprocesses held the briefing context inside their own isolated processes per ADR-032 subprocess-boundary). Per-iter briefing changes already recorded by each iter's own retro. No new orchestrator-level observation warrants a topic-file edit.

## Signal-vs-Noise Pass (P105)

**Constrained scan** — orchestrator-main-turn perspective. The orchestrator did not deep-load any topic file in this session (only the directory listing at Step 0 and the post-iter cleanup of `hooks-and-gates.md`). Per-entry signal/noise scoring requires the orchestrator to have referenced or paraphrased entries, which only happened for the I13 wire-existing entry the orchestrator just committed (signal-score 0 = newly written, baseline). All other entries: decay-only from this surface's perspective.

Per-iter retros applied per-entry scoring within their own iter contexts. No delete-queue candidates accumulated at orchestrator-main-turn level.

## Problems Created/Updated

- **P276** (external-comms gate marker over-fires on PASS-class content edits) — Iter 1: transitioned Open → Verification Pending after documenting RCA + confirming iter-24's fix (substance-aware draft normalisation in compute_external_comms_key) had already shipped in risk-scorer@0.13.1 / voice-tone@0.5.11. Single-numeral tolerance explicitly rejected (security gate).
- **P314** (Rework the fix-time RFC-trace gate) — Iters 2-6: B2 done-by-reconciliation, B7 i13-rollout-survey (16 KE tickets surveyed), B8 forward-dogfood on P361 → RFC-026 auto-created via I13 path, B9 advisory-detector (`check-autocreate-rfc-scope.sh`) wired into `/wr-retrospective:run-retro` Step 2b — shipped @windyroad/retrospective@0.25.0, B6 closed-with-evidence. Phase 2 remaining: B10 (vp-blocked, orchestrator-owned RELEASE), B2-followup (ADR-060 prose alignment — ADR-077 compendium-regen + architect re-lock, heavier).
- **P080** (No bidirectional update of upstream-reported problems) — Iters 7-8: Phase 2 items 1-2 shipped (`--catchup` flag + `catchup-scan.sh` worklist scanner + SKILL amendment + ADR-024 amendment + 14 bats + promptfoo eval) → @windyroad/itil@0.51.0. Items 3-4 dogfooded; caught semantic gap before any factually-wrong upstream post (P113 → claude-code#52831 was worked-around-locally not upstream-fixed; close-template would have implied resolution). Phase 3 direction set via Step 2.4 gate (a): fix G1 (close-template upstream-fix vs local-workaround distinction) + G2 (invert outbound-reporter perspective) BEFORE re-running catchup.
- **P136** (ADR-044 alignment audit — master) — Iter 9: 3 SKILLs audited (review-problems / manage-story-map / update-policy); 1 substantive finding (review-problems Step 4 lazy-deferral on `yes — observed:` evidence-backed subset, inconsistent with run-retro Step 4a close-on-evidence precedent). 6 unaudited SKILLs remain on master.
- **P371** (NEW, iter 2) — I13 gate auto-creates a new RFC instead of wiring existing fix-vehicle's trace edge. Wire-existing pre-check workaround now documented in `docs/briefing/hooks-and-gates.md`.
- **P372** (NEW, iter 3) — ADR-043 context-budget delta-trigger lacks absolute-byte floor (deep-layer auto-fire condition).

## Tickets Deferred

None — every observation routed through `/wr-itil:manage-problem` or already-existing ticket update. No `skill_unavailable` fallback fired.

## Verification Candidates (Step 4a)

None at orchestrator-main-turn scope. P276 transitioned to Verification Pending THIS session (same-session exclusion per Step 4a sub-step 8). No other `.verifying.md` fix was exercised by orchestrator activity beyond iter-internal exercise (already covered by each iter's own retro). README Verification Queue scan for `yes — observed:` prior-session evidence rows: empty result (sub-step 9 prior-session-drain no-op).

## Pipeline Instability (Step 2b)

- **README inventory currency**: clean (13 packages, 0 drift).
- **Repeat-work friction**: external-comms commit gate required delegating to BOTH `wr-risk-scorer:external-comms` AND `wr-voice-tone:external-comms` reviewers with verbatim trailer for every commit (~5 commits this session). Pattern already captured in memory `feedback_external_comms_gate_marker_needs_verbatim_trailer` + briefing. Not new instability.
- **Release-path instability**: `release:watch` 120s poll timed out on 2/2 in-flight releases this session before the changesets workflow opened the release PR — required manual re-poll each time. Existing pattern (~all sessions). Worth checking whether the poll interval should grow, but folded into existing P-tickets covering release-watch poll timing.
- **Hook-protocol friction**: pipeline-drift detection fired on every commit after a working-tree change — required risk-scorer:pipeline re-score before each commit (5 re-scores this session). Per ADR-056 framework-mediated; behavior is correct but the rescore-per-commit pattern carries per-commit reviewer cost (~5 reviewer-subagent invocations across the session).

No new tickets warranted from these observations — all are known/documented patterns.

## Topic File Rotation Candidates (Step 3 Tier 3)

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/hooks-and-gates.md` | 5730 | 5120 | split-by-date OR trim-noise | **Deferred to per-iter retro pass** — orchestrator-main-turn lacks per-entry signal grounding (iter subprocesses held the per-entry context; orchestrator only saw directory listing + the new entry it carried forward). Ratio 1.12× is the lowest possible OVER, no MUST_SPLIT. Per-iter retros are the natural surface for per-entry signal scoring + rotation. |

## Ask Hygiene (P135 Phase 5 / ADR-044)

3 AskUserQuestion calls this session — all framework-prescribed:
- Call 1: Step 0 session-continuity halt (direction)
- Call 2: Step 2.4 gate (a) outstanding-questions surface (3 batched: 2 direction + 1 deviation-approval)
- Call 3: Step 2.4 re-surface after P350 brief-before-ID violation (correction-followup)

**Lazy count: 0**. R6 numeric gate not firing (TREND lazy_first=0 lazy_last=0 delta=+0 across 10 trail files including this session). Per-call detail in `docs/retros/2026-06-18-work-problems-session-ask-hygiene.md`.

## Codification Candidates (Step 4b)

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| improve | skill (run-retro) | `packages/itil/skills/work-problems/SKILL.md` Step 2.5b surfacing routine | Surfacing routine emitted opaque-ID question without inlining substance (P350 violation); user had to ask "elaborate. I don't know all those IDs". | iter-9 / Step 2.4 gate (a) Call 2 Q3 (RFC-021 / P215 / RFC-026 / P361 / ADR-073 named without substance). | **Self-contained — no new ticket**. The P350 brief-before-ID discipline is already documented in CLAUDE.md + memory `feedback_brief_before_id.md` + run-retro SKILL.md "Output Formatting" section. The violation was a *discipline lapse on a single question*, not a structural surface gap. Codifying further would over-fit. |

No structural codification candidates. The patterns exercised this session (claude -p subprocess dispatch with prompt-file, external-comms double-gate, pipeline drift re-score, P233 install-updates chain, P342 retro-auto-ticket carve-out) are all already shipped.

## No Action Needed

- External-comms double-gate pattern (memory + briefing already cover).
- Release-watch 120s poll timeout (existing pattern, no new ticket).
- Pipeline-drift re-score per commit (correct behaviour, no ticket).
- User opening `.afk-run-state/outstanding-questions.jsonl` repeatedly in IDE (informational signal of engagement; not a codifiable framework concern — the user has access to inspect the queue, which is the intended affordance).

## Session Cost

| Metric | Value |
|--------|-------|
| Iterations run | 9 |
| Successful (committed) | 8 (P276 + P314×5 + P080×2) plus 1 audit (P136) |
| Skipped | 0 |
| Step 0b pre-flight cost | ~ |
| Iter sum cost | ~ |
| Reviewer-subagent overhead (estimate) | ~ |
| **Total session cost (est.)** | **~** |
| Releases shipped | 2 |
| Tickets captured | 2 (P371, P372) |
| Risk register entries | 5 (R057-R061) |
