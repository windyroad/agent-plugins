# Problem 080: No bidirectional update of upstream-reported problems — local lifecycle transitions never propagate back to the reporter

**Status**: Known Error
**Reported**: 2026-04-21
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M (marginal) — new sibling skill `/wr-itil:update-upstream` (per user direction 2026-04-26) that fires from `manage-problem`/`transition-problem` Step 7 transitions, drafts the lifecycle-update comment, runs it through the P064 risk gate + P038 voice-tone gate, and auto-posts when both gates pass within appetite. Above-appetite triggers `AskUserQuestion` (interactive) or halt-with-report (AFK).

**WSJF**: 3.0 — (12 × 1.0) / max(M=2, P079_transitive=4) = 12/4 — re-rated 2026-05-23: P064/P038 closed; now bounded by P079 (L)

<!-- transitive: M (marginal) → XL (transitive) via P038 -->

## User direction (2026-04-26 interactive AskUserQuestion resolution)

Two of the original three architect-design questions resolved:

- **(a) Skill shape**: **New sibling `/wr-itil:update-upstream`** — matches P071's split-skill direction per ADR-010 amended. Distinct user intent (lifecycle-update vs initial-report) gets its own skill name + autocomplete surface + scoped SKILL.md.
- **(b) Confirmation pattern**: **Risk + voice-tone gated, then auto-comment**. Every transition with a `## Reported Upstream` link fires the update; the drafted comment goes through P064 risk gate + P038 voice-tone gate. Within-appetite → comment posts automatically. Above-appetite → `AskUserQuestion` (interactive) or halt-with-report (AFK). This matches the **same dual-gate pattern P079's assessment pipeline uses for inbound comments** — the external-comms surface is unified across inbound and outbound.
- **(c) P064 gate composition**: same as (b) — gates compose by running both before any post; failure of either blocks. Specific composition shape (gate ordering, short-circuit semantics, audit-log shape) is the architect call when implementing.

## Description

Plugin users who file upstream reports (via our shipped `problem-report.yml` intake templates OR via `/wr-itil:report-upstream` when the local session invokes outbound reporting) get one acknowledgement — the initial issue filing. After that, they're out of the loop.

When a locally-tracked problem with a `## Reported Upstream` section (per `ADR-024` Confirmation criterion 3a) transitions through its lifecycle:

- **Open → Known Error**: root cause confirmed. The reporter would benefit from knowing someone investigated and found the cause.
- **Known Error → Verification Pending (fix released)**: fix is on npm. The reporter can upgrade and verify.
- **Verification Pending → Closed**: fix verified. The reporter knows the loop is closed.

None of these transitions post a comment to the upstream issue. The reporter has to manually poll the upstream tracker (which they reported TO) to see if anything happened. This violates the core trust-and-transparency contract the `plugin-user` persona (`JTBD-301`) depends on.

The user's direction (2026-04-21 interactive): when we work a reported problem, we should have a process to update the reported problem. Currently we don't. That's the gap this ticket closes.

This is the outbound-lifecycle-update leg of the reporter-loop. P079 closes the inbound-discovery leg (new reports visible to maintainer). Together P079 + P080 make the reporter experience end-to-end.

## Symptoms

- Plugin user files a `problem-report.yml` issue. Maintainer acknowledges + triages (manually, because P079 is still open) and opens a local ticket with a `## Reported Upstream` section referencing the upstream issue.
- Maintainer investigates the local ticket over a session or two; root cause is confirmed; local ticket transitions `.open.md` → `.known-error.md`. No comment is posted to the upstream issue. Reporter sees no movement.
- Fix ships via changeset release; local ticket transitions `.known-error.md` → `.verifying.md` with a `## Fix Released` section. No comment is posted to the upstream issue. Reporter has no way to know the fix is available without checking npm.
- Maintainer closes the local ticket after user-side verification; upstream issue is NOT closed on the upstream side (still Open on GitHub despite local `.closed.md`).
- Upstream issue tracker accumulates stale-looking issues ("nothing's happening on these — maintainer abandoned the project?") even though the work landed.
- `gh issue close` requires maintainer to manually walk each `## Reported Upstream` link — error-prone and skipped under load.

## Workaround

Maintainer manually posts a comment to each upstream issue at each lifecycle transition, using a copy-paste template. In practice this drops — the transitions happen during AFK loops or quick sessions and the upstream-update step gets forgotten. Unreliable.

## Impact Assessment

- **Who is affected**:
  - **plugin-user persona** (`JTBD-301` — report-upstream job) — reporter's expected feedback loop breaks after submission. "I filed, nothing happened" is the default experience even when work DID happen.
  - **solo-developer persona** (`JTBD-001`) — maintainer must remember to update each upstream issue at each transition; manual step defeats governance-without-slowing-down.
  - **tech-lead persona** (`JTBD-201`) — audit trail is incomplete: local ticket says "closed", upstream issue says "open"; downstream observer can't reconcile.
  - **plugin-developer persona** (`JTBD-101`) — downstream plugin authors inherit the same gap for their own projects if they adopt our patterns; the pattern mis-teaches the bidirectional contract.
- **Frequency**: every locally-reported-upstream ticket, at every lifecycle transition. Typically 3 transitions per ticket (Open→KE→Verifying→Closed) → 3 missed-update opportunities per ticket.
- **Severity**: High. Directly-observable trust breakage at the reporter-relationship boundary. Sending a silent "fix shipped, please upgrade" comment is high-value, low-effort; NOT sending it is a recurring quality defect.
- **Analytics**: N/A today. Post-fix candidate metrics: (1) ratio of local lifecycle transitions to upstream-issue comments on matched tickets, (2) upstream-issue close rate after local `.closed.md` transitions, (3) reporter-response rate on auto-comments (signal of comment quality).

## Root Cause Analysis

### Structural

`packages/itil/skills/report-upstream/SKILL.md` scope (per ADR-024) is **outbound-initial-filing only**. The skill runs once per local ticket, files the upstream report, and writes the `## Reported Upstream` section with the upstream URL. It does not revisit the upstream issue later.

`packages/itil/skills/manage-problem/SKILL.md` Step 7 (status transitions: Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed) operates on local files only:

- `git mv` the ticket file to the new suffix.
- Edit the Status field.
- Optionally add a `## Fix Released` section (for .verifying.md).
- Re-stage per P057.

No step reads the `## Reported Upstream` section, no step posts to the upstream issue, no step closes the upstream issue on `.closed.md` transition.

### Why it wasn't caught earlier

ADR-024 explicitly scoped report-upstream as initial-filing. The bidirectional surface (lifecycle updates) was noted as a follow-up in ADR-024's Out-of-Scope section but never produced a ticket. P063 (trigger surface for outbound filing) closed the "when to file" gap; the "what happens after filing" gap stayed open.

P070 added dedup-before-filing with a maintainer-annoyance risk evaluator — that infrastructure is exactly what this ticket's upstream-update gate needs, but P070's scope is pre-filing, not post-filing.

### Candidate fix

**Option A: Extend `/wr-itil:report-upstream` with an `--update` mode.**

`/wr-itil:report-upstream --update <local-ticket-path>` reads the ticket's `## Reported Upstream` section, determines the current local status (from filename suffix), generates the appropriate update comment from a template, runs the comment through the external-comms risk gate (P064), and posts if within appetite.

Pros: single skill for all upstream-write surfaces; consistent auth + auth-check logic.
Cons: argument-based subcommand pattern that P071 is migrating AWAY from; would be short-lived.

**Option B: New sibling skill `/wr-itil:update-upstream` (preferred).**

Separate skill, discoverable via `/wr-itil:` autocomplete. Invoked from `manage-problem` Step 7's transition blocks when the local ticket has a `## Reported Upstream` section. Each transition type has its own template:

- **Open → Known Error**: "Root cause identified. Local tracking ticket now at `## Known Error`. Investigation notes: [excerpt]. Fix path: [from ticket's Fix Strategy]. Will update here on release."
- **Known Error → Verification Pending**: "Fix released in `<package>@<version>` (commit `<sha>`). Upgrade + verify when convenient; we'll close this issue after your confirmation OR after a 14-day quiet period (per `P048` Candidate 4 default)."
- **Verification Pending → Closed**: "Closed locally after user-side verification. Closing upstream issue to match. Thanks for the report." + `gh issue close <n>`.

Each update is gated by:
1. **Appropriateness check** — does the local transition add new information for the reporter? (Open→KE: yes, reporter learns root cause exists. KE→Verifying: yes, reporter can upgrade. Verifying→Closed: yes, closes the loop.)
2. **Maintainer-annoyance risk gate** — reuse P070's infrastructure. Cheap updates (one per transition) pass; redundant updates (same status comment already posted) skip. Appetite-driven same as P070.
3. **Voice-and-tone gate** (per ADR-028 amended External-comms gate) — external-facing copy goes through voice-tone review before posting.

Pros: matches P071 / ADR-010 sibling-skill pattern; reuses existing risk + voice gates; cleaner single-responsibility.
Cons: one more skill in the suite.

**Option C: Build the update logic into `manage-problem` transition steps directly.**

Each transition in Step 7 adds an inline "post-to-upstream-if-linked" sub-step.

Pros: no new skill surface; transitions stay a single-commit flow.
Cons: bloats `manage-problem` SKILL.md; couples lifecycle to external-comms; harder to disable upstream updates without disabling transitions.

### Lean direction

**Option B — new sibling skill `/wr-itil:update-upstream`.** Matches the sibling-skill convention under ADR-010 amended + ADR-032 sibling-pattern. Reuses:
- P070's maintainer-annoyance risk evaluator (composes via the P064 + ADR-028 external-comms gate).
- ADR-028 amended's voice-tone + risk gate (the same gate P073 + P074 feed into).
- `/wr-itil:report-upstream`'s auth + preference-order logic for channel resolution.

Architect call required at implementation time to:
1. Confirm Option B vs A/C.
2. Decide the close-on-verification policy: auto-close after user verification? After N-day quiet period? Require explicit user opt-in?
3. Decide whether `update-upstream` auto-invokes from `manage-problem` transition steps OR is user-triggered only.
4. Decide whether a NEW ADR is needed or an amendment to ADR-024 (lean: amendment — this is the bidirectional extension ADR-024 explicitly scoped out).

### Related sub-concerns

**Sub-concern 1**: auto-invoke vs manual. If `manage-problem` transitions auto-fire the update, the risk gate must be strict — a spammy auto-update is worse than no auto-update. Lean: auto-invoke for KE→Verifying and Verifying→Closed (high-value updates); leave Open→KE as user-initiated (investigation notes may be partial and want review before posting).

**Sub-concern 2**: multiple `## Reported Upstream` entries. A local ticket may accumulate multiple upstream references if the same problem was filed to multiple trackers. The update logic should post to EACH linked upstream issue, not just the first. Risk gate composes per-channel.

**Sub-concern 3**: historical catch-up. Existing `.verifying.md` / `.closed.md` tickets with `## Reported Upstream` sections need retroactive updates on first deployment. A one-shot migration pass would post "catching up: this was resolved in version X" to each unclosed upstream issue. Architect review to decide whether migration is in-scope for this ticket or a sibling.

**Sub-concern 4**: downstream-scaffolded trackers. When a downstream project uses ADR-036-scaffolded intake templates, the downstream maintainer handles bidirectional updates on their side. Our `update-upstream` only acts when the local ticket's `## Reported Upstream` references OUR outbound path (i.e. this repo filed to an upstream we depend on). This scope boundary mirrors P079's channel scoping.

### Investigation Tasks

- [x] Architect review: pick Option A / B / C. ADR shape (amend ADR-024 vs new ADR). **Resolved 2026-06-09 (Phase 1 iter)**: Option B (new sibling skill `/wr-itil:update-upstream`); amend ADR-024 (no new ADR) — matches the post-P270 / 2026-04-25 / 2026-04-21 amendment lineage shape. Architect PASS verdict on the Phase 1 plan.
- [x] Draft the `update-upstream` SKILL.md (or the ADR-024 amendment per architect). **Done 2026-06-09**: `packages/itil/skills/update-upstream/SKILL.md` shipped. Cross-references ADR-024 amendment (P080), ADR-028 (voice-tone gate), ADR-013 (Rule 1 + Rule 6), ADR-014 (single-commit grain), ADR-010 amended (sibling-skill split), ADR-044 (framework-resolution boundary), ADR-042 (within-axis precedent), ADR-075 Amendment 2026-06-02 (paired-eval R009 discharge), ADR-061 Rule 4 (evidence-floor).
- [x] Define the update-template shape for each transition type (Open→KE, KE→Verifying, Verifying→Closed). **Done 2026-06-09**: three transition templates encoded in SKILL.md Step 4 — root-cause-identified investigation findings (Open→KE), release-info + upgrade-and-verify (KE→Verifying), closure-thanks (Verifying→Closed). No-invention rule pinned per template-filling discipline.
- [x] Compose with P064 + ADR-028 amended external-comms gate (voice-tone + risk). Architect review decides gate ordering. **Done 2026-06-09**: SKILL.md Step 5 — risk gate (5a) first, voice-tone gate (5b) second; gates compose AND (one fail blocks); above-appetite handling (5c) silent risk-reduces + re-scores then queues per P352. Same composition shape as the post-P270 amendment's initial-filing path.
- [x] Integrate with `manage-problem` Step 7 transition blocks: each transition checks for `## Reported Upstream`; if present, invokes `update-upstream`. **Done 2026-06-09**: advisory subsection added to `/wr-itil:transition-problem` Step 7b AND `/wr-itil:manage-problem` in-skill Step 7 (copy-not-move per ADR-010 amended P093). Trigger fires unconditionally — sibling skill's no-op exit absorbs the misses.
- [x] Integrate with `work-problems` AFK orchestrator: transitions fired by iteration subagents should still post upstream updates (non-interactive default per ADR-013 Rule 6 when the risk gate passes). **Done 2026-06-09**: Step 7b's advisory inherits from the transition-problem trigger surface that work-problems iters already invoke; AFK behaviour summary table in update-upstream SKILL.md encodes the queue-and-continue per P352.
- [x] Bats doc-lint assertions per ADR-037: skill contract, template presence per transition, risk-gate composition, policy-decision traceability. **Done 2026-06-09**: `packages/itil/skills/update-upstream/test/update-upstream-contract.bats` ships 23 tests covering the contract surface; all GREEN locally. Structural-permitted carve-out per ADR-052 Migration clause; behavioural Tier-A/B coverage rides on the paired promptfoo eval per ADR-075 Amendment 2026-06-02.
- [x] **Paired promptfoo eval — R009 prose-floor discharge.** **Done 2026-06-09**: `packages/itil/skills/update-upstream/eval/{promptfooconfig.yaml,run-skill-eval.sh,grade-llm-rubric.sh}` ship in the same commit as the SKILL prose per ADR-061 Rule 4 evidence-floor (mirrors the P324 Phase 6 / RFC-019 P355 pattern). Tier-A regex + Tier-B llm-rubric coverage for gate composition, queue-and-continue, Verifying→Closed dual-command behaviour, no-op exit, gate-AND vs gate-OR semantics.
- [ ] Reuse P070's maintainer-annoyance risk evaluator — confirm composability; architect review decides whether extract-to-shared-lib or copy-adapt. **Phase 2 (out of scope this iter)** — the `wr-risk-scorer:external-comms` agent already shipped per the post-P270 amendment; the update-upstream SKILL uses the same evaluator surface. No extract-to-shared-lib needed at Phase 1.
- [x] Historical catch-up: one-shot migration pass OR runtime first-fire detection. **Done 2026-06-18 (Phase 2 iter)**: `--catchup` mode added to `/wr-itil:update-upstream` (SKILL.md § Catchup migration mode). Read-only/local worklist scanner `packages/itil/scripts/catchup-scan.sh` (invoked via `wr-itil-catchup-scan` ADR-049 shim) walks the `.verifying.md` + `.closed.md` corpus, filters to `## Reported Upstream`-carrying tickets, applies marker-based idempotency (skips tickets whose `## Upstream Lifecycle Updates` log already records the target state), and emits a `CATCHUP`/`SKIP` worklist; the SKILL loops the existing per-ticket gate+post+back-write (Steps 4-6) for each `CATCHUP`. ADR-024 amended (P080 Phase 2 entry). 14 behavioural bats at `packages/itil/scripts/test/catchup-scan.bats` (fixture corpus + idempotency assertions) — all green; existing 23 contract bats still green. Architect PASS + jtbd PASS pre-edit.
- [ ] End-to-end test: transition a test ticket with a synthetic `## Reported Upstream`; confirm the upstream issue receives a comment matching the transition template. **Deferred to post-release** — the live-upstream confirmation IS P080's overall verification step. The real corpus has one catchup target (P113 → `https://github.com/anthropics/claude-code/issues/52831`); running `--catchup` against it post-release and confirming the comment lands closes P080 to Verifying. Cannot run pre-release (the orchestrator owns release; the `--catchup` mode is not yet on the published `@windyroad/itil`).

## Fix Strategy

Phase 1 (Option B — new sibling skill `/wr-itil:update-upstream`) shipped 2026-06-09 per the Investigation Tasks above: SKILL.md + three transition templates + dual-gate (risk + voice-tone) composition + paired promptfoo eval (R009 discharge) + 23 bats + ADR-024 amendment + `transition-problem` Step 7b / `manage-problem` Step 7 advisory wire-in.

**Release vehicle**: .changeset/wr-itil-p080-update-upstream-sibling-skill.md

### Phase 2 reopened 2026-06-17 — `--catchup` migration mode

User direction during the 2026-06-17 outstanding-questions drain: **"reopen P080 so phase 2 can be implemented"**. P080 transitioned Verifying → Known Error to surface Phase 2 in the WSJF queue rather than splitting into a sibling ticket.

**Phase 2 scope**: a one-shot `--catchup` migration mode on `/wr-itil:update-upstream` that walks every existing `.verifying.md` / `.closed.md` ticket carrying a `## Reported Upstream` section and retroactively posts the appropriate lifecycle update to the upstream issue. Backfills history for tickets reported upstream BEFORE Phase 1 shipped OR transitioned outside Phase 1's path.

**Phase 2 acceptance criteria**:

1. New invocation surface: `/wr-itil:update-upstream --catchup` (or equivalent flag).
2. Walks the `.verifying.md` + `.closed.md` corpus; per-ticket: read `## Reported Upstream`, derive lifecycle state from filename + Status field, dispatch the appropriate transition template comment.
3. Idempotent: a ticket whose upstream issue already received the lifecycle comment (detected via prior comment from the bot account / a marker on the ticket body) is skipped silently.
4. Dual-gate composition: each catchup comment passes through risk + voice-tone gates per Phase 1.
5. Above-appetite triggers `AskUserQuestion` (interactive) or halt-with-report (AFK) — same shape as Phase 1.
6. Behavioural bats: fixture exercises catchup on a synthetic verifying/closed corpus + asserts idempotency.
7. End-to-end test against a live upstream: confirms the comment lands. This is also P080's overall verification step.
8. Closes P363's root-cause finding (the inbound-reported-tickets-never-receive-fix-released-verdict gap); once catchup runs on the existing corpus, P363 can transition Known Error → Verifying (composing fix).

**Implementation order**:

1. ~~SKILL.md amendment to `/wr-itil:update-upstream`: add `--catchup` mode + invocation surface + idempotency contract.~~ **Done 2026-06-18** — also shipped the read-only worklist scanner `catchup-scan.sh` + `wr-itil-catchup-scan` shim + ADR-024 Phase 2 amendment + changeset (`.changeset/wr-itil-p080-phase2-update-upstream-catchup.md`, `@windyroad/itil` minor).
2. ~~Behavioural bats: catchup fixture + idempotency guard.~~ **Done 2026-06-18** — 14 bats at `packages/itil/scripts/test/catchup-scan.bats`, all green.
3. Live-upstream end-to-end test execution (one-shot; result documented on this ticket). **Post-release** — needs `--catchup` on the published tree; orchestrator owns release.
4. Transition Known Error → Verifying once 1-3 land + a fresh release goes out. **Post-release.**

Composes with P363 (the inbound-reported-tickets-never-receive-fix-released-verdict ticket whose fix this Phase 2 closes).

**Phase 2 iter progress (2026-06-18)**: items 1-2 shipped (code + tests + ADR amendment + changeset, committed this iter). Items 3-4 are post-release (the orchestrator owns the release; the live-upstream confirmation is P080's overall verification step). One queued ratification: the ADR-024 Phase 2 amendment's implementation-interpretation confirmation (P357/ADR-066 AFK fallback — direction-traced from the 2026-06-17 drain, substance-confirm queued for the next interactive drain).

## Fix Released

**Phase 1 released in `@windyroad/itil@0.48.0`** (version-packages commit `43e164fe`, PR #248, merge commit `2571d9da`, released 2026-06-09). Present in the current published `@windyroad/itil@0.49.5` tree (feat commit `5a4f8b1c` is an ancestor of the latest release bump `0449bc7f`). <!-- no-changeset-reference --> (release-vehicle helper resolved a full citation after the P330 seed above; the original ticket body carried no `.changeset/` reference.)

Phase 1 shipped the new sibling skill `/wr-itil:update-upstream` (bidirectional lifecycle-update leg of the reporter loop): drafts a transition-specific comment (Open→KE / KE→Verifying / Verifying→Closed templates), composes it through the external-comms risk gate + voice-tone gate (AND composition — both must pass), auto-posts via `gh issue comment` within appetite, queues `outstanding_questions` above appetite (P352 queue-and-continue, never halts), and runs `gh issue close` on Verifying→Closed. Wired into `transition-problem` Step 7b + `manage-problem` Step 7 advisory (copy-not-move). ADR-024 amended (P080 entry). R009 prose-floor discharged via the paired promptfoo eval (Tier-A/B); 23 contract bats all green.

**Awaiting user verification** — confirm the bidirectional update fires correctly on a real upstream-reported ticket transition (the deferred Phase 2 end-to-end test against a live upstream issue IS this verification step). On confirmation, close P080 Phase 1.

**Phase 2 remains deferred (not blocking this transition per the P184 conditional-deferral check — no fired gating condition):** `--catchup` migration mode for retroactive coverage of existing `.verifying.md` / `.closed.md` tickets with `## Reported Upstream` sections is genuine future dev work ("a future amendment may add"). If pursued it should re-surface in the WSJF queue rather than be lost in this ticket's verifying state — see the loop-end outstanding question.

## Related

- **P079** (`docs/problems/079-no-inbound-sync-of-upstream-reported-problems.open.md`) — sibling concern. Inbound-discovery leg; together P079 + P080 close the reporter-loop end-to-end.
- **P055** (`docs/problems/055-no-standard-problem-reporting-channel.closed.md`) — shipped `/wr-itil:report-upstream` (Part B); this ticket adds the bidirectional-update mode the original skill scoped out.
- **P063** (`docs/problems/063-manage-problem-does-not-trigger-report-upstream-for-external-root-cause.verifying.md`) — outbound-initial-filing trigger surface. This ticket adds the outbound-lifecycle-update trigger surface.
- **P064** (`docs/problems/064-no-risk-scoring-gate-on-external-comms.open.md`) — external-comms risk gate the upstream-update comment MUST compose through (per ADR-028 amended).
- **P067** (`docs/problems/067-report-upstream-classifier-is-not-problem-first.open.md`) — classifier-shape dependency; bidirectional updates follow the same problem-first copy shape.
- **P070** (`docs/problems/070-report-upstream-does-not-check-for-existing-upstream-issues.open.md`) — maintainer-annoyance risk evaluator this ticket reuses for the update-gate.
- **P072** (`docs/problems/072-no-persona-models-external-repo-reporter.verifying.md`) — `plugin-user` persona + `JTBD-301` this ticket serves.
- **ADR-024** (`docs/decisions/024-cross-project-problem-reporting-contract.proposed.md`) — outbound-initial-filing contract this ticket's amendment (or new paired ADR) extends to bidirectional.
- **ADR-028** (`docs/decisions/028-external-comms-gate.proposed.md` — amended) — voice-tone + risk gate for external-facing copy the update comments pass through.
- **ADR-010** (`docs/decisions/010-skill-naming.proposed.md` — amended) — sibling-skill naming convention; new `/wr-itil:update-upstream` follows this pattern.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 6 non-interactive fail-safe applies to AFK-transition-triggered upstream updates.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — upstream-update commit + post action both belong in the transition commit's ownership.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — foreground synchronous for user-initiated updates; AFK iteration isolation wrapper for orchestrator-initiated updates during transitions.
- **JTBD-001**, **JTBD-101**, **JTBD-201**, **JTBD-301** — personas whose end-to-end promise this ticket serves.
