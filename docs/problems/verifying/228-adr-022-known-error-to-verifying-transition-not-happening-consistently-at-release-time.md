# Problem 228: ADR-022 .known-error.md → .verifying.md transition not happening consistently at release time

**Status**: Verification Pending
**Reported**: 2026-05-15
**Origin**: inbound-reported (#42)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `manage-problem` review step 9b item 10 auto-transitions Open → Known Error when root cause and workaround are documented, but it does NOT auto-transition Known Error → Verification Pending when a shipped fix is detected. Separately, ADR-022 prescribes the Known Error → Verifying transition on release but the trigger surface isn't fully wired across all release paths.

## Investigation Findings (2026-06-08, session 11 iter)

**Gap confirmed empirically.** Witness ticket: P220 (`docs/problems/known-error/220-manage-problem-has-no-cadence-for-checking-upstream-bound-tickets.md`). Phase 1 fix landed 2026-06-08 in commit 0f58210; the ticket body carries `## Fix Released` AND a `Release pending` paragraph stating *"K → V transition deferred to release per ADR-022 P143 fold-fix amendment"* with a recovery hint *"`/wr-itil:transition-problem 220 known-error` after reverting"*. The P143 citation is **misapplied** — P143 governs Open → Verification Pending single-commit fold-fix (ADR-022 lines 85-107), NOT a sanctioned K → V deferral. P220 is now stranded in `.known-error/` with no auto-fire surface to back-fill the K → V transition once `@windyroad/itil` next releases.

**No post-release auto-fire exists.** Verified by source review:

- `packages/itil/scripts/` carries no `transition-problem.sh`; `packages/itil/bin/` carries no `wr-itil-transition-problem` shim. The `/wr-itil:transition-problem` SKILL is the only transition executor and is agent-invoked (not script-callable from Step 6.5).
- `packages/itil/skills/work-problems/SKILL.md` Step 6.5 Drain action ends at `release:watch` + `/install-updates` post-release cache refresh (P233). No subsequent enumeration of `.known-error/` for `## Fix Released`-carrying tickets to auto-fire `/wr-itil:transition-problem <NNN> verifying`.
- `packages/itil/skills/review-problems/SKILL.md` Step 2 item 10 covers Open → Known Error auto-transition (root cause + workaround documented). There is no symmetric item 11 covering Known Error → Verification Pending when `## Fix Released` + `Release vehicle: .changeset/<name>.md` (P330 seed) are present.
- `packages/itil/skills/manage-problem/SKILL.md` Step 7 + the `/wr-itil:transition-problem` SKILL Step 6 document the K → V fold-fix discipline correctly (fold the rename + `## Fix Released` + README refresh into the same `fix(<scope>): <description> (closes P<NNN>)` commit). The contract is correct; the gap is **enforcement**, not the contract.

**ADR-022 amendments since 2026-05-15 (when this ticket was reported) reviewed.** The P143 amendment (2026-04-29) predates this ticket and governs Open → V fold-fix only. ADR-031 (2026-05-12) is the encoding shift (per-state subdirectories); orthogonal to lifecycle mechanics. No amendment has wired a release-time auto-fire surface for K → V.

**ADR-079 partial-overlap** (`docs/decisions/079-evidence-based-relevance-close-pass.proposed.md`). Phase 2 evidence shape 4 (`self-marker-in-body`) lists `^## Fix Released` heading as **contributory** evidence for the K → Closed-direct bypass — but ADR-079 closes to `.closed/` (skipping Verifying), which is semantically distinct from this ticket's ask (K → V transition preserves the Verification Queue prompt before final closure). The two paths are complementary, not equivalent: ADR-079 handles the "no fix released, no longer relevant" class; P228 handles the "fix released, awaiting verification" class. Composing them would require a Phase 3 shape that distinguishes "Release vehicle cited AND release shipped" (K → V) from "no release shipped, ticket no longer relevant" (K → Closed-direct).

## Candidate Fix Surfaces (substance-confirm-before-building)

Two viable surfaces — selection is a load-bearing decision that must be ratified by user before SKILL prose is authored, per the substance-confirm-before-build discipline ([`feedback_confirm_decision_substance_before_building`](#) + [`feedback_run_decisions_by_user_before_drafting`](#)):

1. **`/wr-itil:review-problems` Step 2 item 11** (new): symmetric counterpart to item 10. For each `.known-error.md` ticket with a `## Fix Released` section AND a `Release vehicle: .changeset/<name>.md` reference (the P330 seed), invoke `wr-itil-derive-release-vehicle <NNN>` — on exit 0 (release shipped, full citation available), auto-fire the K → V transition. On exit 3 (changeset still in working tree — unreleased), skip per existing transition-problem Step 6 routing. Fires at every review-problems invocation (~24h cadence per Step 0c deferred-placeholder pre-flight AND-trigger). Pros: composes with existing item 10 symmetric pattern; benefits from existing pre-flight cadence; lower hot-path coupling. Cons: lag between release and transition (up to 24h+); requires review-problems to actually run.

2. **`/wr-itil:work-problems` Step 6.5 post-release callback** (new): after `release:watch` success in the within-appetite Drain action (between step 2 release:watch and step 4 /install-updates cache refresh), enumerate `.known-error/` for tickets whose `Release vehicle: .changeset/<name>.md` reference matches a changeset deleted by the just-shipped `chore: version packages` commit. Auto-fire K → V for each match. Pros: fires immediately after release; tight coupling = no lag. Cons: introduces a new hot-path post-release callback; expands Step 6.5 (already R009-floor SKILL prose surface per the brief); more surprising to maintainer.

**Holding-area dependency (R009)**: either surface's SKILL prose change lands under R009 hold per the brief's iter constraint. Discharge path: promptfoo eval calibration (P012 reopen 2026-06-04 reports 0/1 passed) OR user ratification override.

## Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Identify the missing trigger surface: confirmed gap; two viable surfaces named above (review-problems Step 2 item 11 vs work-problems Step 6.5 post-release callback). Surface selection is a load-bearing decision deferred to user ratification per substance-confirm-before-building.
- [x] **User-ratified 2026-06-08**: Option B — work-problems Step 6.5 post-release callback. Picked over Option A (review-problems ~24h-lag) and Option C (close-as-superseded by ADR-079). Tight coupling = zero K→V lag.
- [x] **Implemented 2026-06-08 (session 11 iter)**: new helper `packages/itil/lib/enumerate-postrelease-kv-candidates.sh` (mirrors the helper-in-lib pattern of `check-deferred-placeholder-staleness.sh`), script wrapper `packages/itil/scripts/run-enumerate-postrelease-kv-candidates.sh`, ADR-080 bin shim `packages/itil/bin/wr-itil-enumerate-postrelease-kv-candidates`. SKILL.md Step 6.5 Drain action renumbered: step 4 = K→V auto-transition (new), step 5 = cache refresh (renumbered from 4). Per-`KV_CANDIDATE` line dispatches `/wr-itil:transition-problem <NNN> verifying` via the Skill tool (per ADR-010 amended P093 — transition-problem is the authoritative executor). Non-blocking on individual failure, AFK-safe, V→C remains a maintainer surface.
- [x] **Behavioural test landed**: `packages/itil/skills/work-problems/test/work-problems-step-6-5-postrelease-kv-callback.bats` — 9 cases (absent dir / empty dir / shipped → emit / no vehicle → skip / unreleased → skip / mixed cohort / README excluded / unknown exit). All PASS locally.
- [ ] (deferred — composes-not-blocks) Compose with ADR-079 Phase 3 shape that distinguishes "Release vehicle cited AND release shipped" (K → V) from "no release shipped, ticket no longer relevant" (K → Closed-direct). Tracked separately; not in scope for the P228 fix.

## Fix Strategy

**Release vehicle**: `.changeset/wr-itil-p228-postrelease-kv-auto-transition.md` (P330 seed reference — input signal for the post-release K→V callback this ticket implements; dogfoods itself by transitioning P228 K→V on the first release after this iter ships).

Fix shape (landed this iter): new helper `packages/itil/lib/enumerate-postrelease-kv-candidates.sh` + script wrapper + ADR-080 bin shim `wr-itil-enumerate-postrelease-kv-candidates`. SKILL.md Step 6.5 Drain action renumbered: step 4 = K→V auto-transition (new), step 5 = cache refresh (renumbered from 4). The enumerator dispatches `/wr-itil:transition-problem <NNN> verifying` per emitted `KV_CANDIDATE` line, non-blocking on individual failure, AFK-safe. V→C remains a maintainer-only surface. Status remains Known Error until the next release ships, at which point the new callback fires the K→V transition automatically (this is the dogfooding verification path).

## Fix Released

Released in @windyroad/itil@0.49.4 (changeset `wr-itil-p228-postrelease-kv-auto-transition.md` drained in release commit 333e24fc, 2026-06-11). Fix: post-release K→V auto-transition callback — `enumerate-postrelease-kv-candidates` helper lib + script + ADR-080 bin shim, wired as work-problems Step 6.5 Drain step 4. **Dogfood verification evidence (in-session, 2026-06-11)**: `wr-itil-enumerate-postrelease-kv-candidates docs/problems` exited 0 and emitted `KV_CANDIDATE` lines for P175, P184, and P228 itself (`KV_CANDIDATES_SUMMARY: total=3`) — this very K→V transition batch is the enumerator's output being executed, including catching up the two tickets (P175, P184) stranded by earlier releases that pre-dated the callback. Exactly the failure class this ticket describes, now self-healing. Awaiting user verification.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/42
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Composes with**: ADR-022 (Verifying status; P143 fold-fix amendment governs Open → V, NOT K → V deferral); ADR-079 (partial-overlap via Phase 2 shape 4 `## Fix Released` contributory; composing requires Phase 3); P062 (transition README refresh); P330 (Release vehicle seed reference — input signal for either fix surface); P220 (empirical witness 2026-06-08).
- **Empirical witness**: P220 (`docs/problems/known-error/220-manage-problem-has-no-cadence-for-checking-upstream-bound-tickets.md`) — Phase 1 fix shipped in 0f58210 on 2026-06-08 with `## Fix Released` populated but K → V deferred citing P143 (misapplied).

## Change Log

- **2026-05-15**: Captured. Placeholder Priority/Effort pending review-problems re-rate.
- **2026-06-08** (session 11 iter): Investigation pass — gap confirmed empirically (P220 witness); ADR-022 amendments since report date reviewed (no K → V release-time wiring landed); ADR-079 partial-overlap analysed (Phase 2 shape 4 contributory but K → Closed-direct ≠ K → V); two candidate fix surfaces named; surface selection deferred to user ratification per substance-confirm-before-building. Status remains Known Error.
- **2026-06-08** (session 11 iter follow-up): User ratified Option B (work-problems Step 6.5 post-release callback). Fix landed: new `enumerate-postrelease-kv-candidates` helper lib + script + ADR-080 bin shim + 9-case behavioural bats + SKILL.md Step 6.5 K→V auto-transition subsection + Non-Interactive Decision Making table row + changeset. Architect + JTBD gates both passed. Status remains Known Error — the new callback dogfoods on the first release after this iter ships (will auto-transition P228 K→V).
- **2026-06-11** (AFK iter 3): Fix released in @windyroad/itil@0.49.4 (release commit 333e24fc). Dogfood executed: enumerator emitted KV_CANDIDATE for P175/P184/P228; batch K→V transition via /wr-itil:transition-problems covered all three (P175 + P184 were the stranded-by-earlier-release class this ticket describes). Status → Verification Pending.

## Upstream Lifecycle Updates

- **2026-06-11** — Known Error → Verification Pending
  - **Target URL**: https://github.com/windyroad/agent-plugins/issues/42
  - **Comment URL**: https://github.com/windyroad/agent-plugins/issues/42#issuecomment-4676712085
  - **Disclosure path**: posted-comment
  - **Gate verdict**: external-comms PASS (no confidential-information class matched) + voice-tone PASS
