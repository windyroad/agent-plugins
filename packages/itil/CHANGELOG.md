# @windyroad/problem

## 0.13.0

### Minor Changes

- 260768f: P084 fix: `/wr-itil:work-problems` Step 5 dispatches iterations via a `claude -p` subprocess instead of Agent-tool-spawned `general-purpose` subagents.

  **Why:** Agent-tool-spawned subagents do NOT have the Agent tool in their own surface (platform restriction; three-source evidence — ToolSearch probe, Claude Code docs, empirical runtime error). Without Agent, the iteration worker could not satisfy architect + JTBD PreToolUse edit-gate markers (only settable via Agent-tool PostToolUse hook) nor the risk-scorer commit gate. Every AFK iteration on a gate-covered path (`packages/`, ADRs, SKILL.md edits, hook edits) silently halted. The subprocess variant is a full main Claude Code session with Agent available, so governance reviews run at full depth and gate markers set natively.

  **Dispatch command:** `claude -p --permission-mode bypassPermissions --output-format json <iteration-prompt>`.

  **No per-iteration budget cap.** Per user direction, the AFK loop's natural stop condition is quota exhaustion, not an arbitrary dollar cap. A cap would halt iterations before quota is actually exhausted, leaving remaining backlog unprocessed. Quota-exhaust surfaces as a non-zero `claude -p` exit and the orchestrator halts cleanly per Step 6.75's exit-code handling.

  **What stays the same:** the `ITERATION_SUMMARY` return-summary contract is preserved verbatim (orchestrator extracts from the JSON `.result` field instead of the Agent-tool return value). Step 0 preflight (ADR-019), Step 6.5 release-cadence drain (ADR-018), and Step 6.75 inter-iteration verification (P036) all remain in the orchestrator's main turn unchanged. Every non-Step-5 block in the skill is untouched.

  **Adopter-tunable:** adopters with narrower permission scopes may substitute `--permission-mode acceptEdits` / `auto` / `dontAsk` for `bypassPermissions`. Adopters who genuinely need a per-iteration cap (multi-tenant billing, etc.) can add `--max-budget-usd` in their own fork — not the default.

  See `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` for the full subprocess-boundary sub-pattern contract (amendment dated 2026-04-21) and `docs/problems/084-work-problems-iteration-worker-has-no-agent-tool-so-architect-jtbd-gates-block.open.md` for the full diagnosis + probe evidence.

## 0.12.0

### Minor Changes

- 91da109: P071 split slice 4: new `/wr-itil:transition-problem` skill (+ manage-problem forwarder)

  `/wr-itil:manage-problem <NNN> known-error` / `<NNN> verifying` / `<NNN> close`
  is deprecated; the transition-a-ticket user intent now has its own skill so
  Claude Code `/` autocomplete surfaces it directly (JTBD-001 + JTBD-101).
  This is phase 4 of the P071 phased-landing plan.

  - `packages/itil/skills/transition-problem/SKILL.md` — NEW thin-router
    selection skill. Arguments: `<NNN>` (ticket ID) + `<status>` (one of
    `known-error`, `verifying`, `close`). Both are data parameters per the
    P071 split rule (ADR-010 amended); neither is a word-subcommand.
    Execution delegates to `/wr-itil:manage-problem <NNN> <status>` via the
    Skill tool — the authoritative Step 7 block (pre-flight checks + P057
    staging trap + P063 external-root-cause + P062 README refresh) stays
    on the host skill.
  - `packages/itil/skills/transition-problem/test/transition-problem-contract.bats`
    — NEW 14 contract assertions (ADR-037 pattern; @problem P071 +
    @jtbd JTBD-001 + @jtbd JTBD-101 traceability).
  - `packages/itil/skills/manage-problem/SKILL.md` — Step 1 parser updated
    to distinguish bare `<NNN>` (update flow, handled inline by Step 6)
    from `<NNN> <status>` (transition — delegated to the new skill). New
    "Forwarder for `<NNN> <status>` transitions" section added to the
    Deprecated-argument forwarders block, with the canonical deprecation
    notice (per ADR-010 amended template).
  - `packages/itil/skills/manage-problem/test/manage-problem-transition-forwarder.bats`
    — NEW 5 contract assertions for the forwarder contract.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  Remaining phased-landing slices tracked on P071: `list-incidents`,
  `mitigate-incident`, `restore-incident`, `close-incident`,
  `link-incident` (the `manage-incident` splits).

  **Recovery note:** this slice shipped after the iter-5 AFK halt per P036.
  The iteration subagent wrote the files correctly (19/19 bats green) but
  returned prematurely without committing, triggering Step 6.75's
  dirty-for-unknown-reason branch. Work verified sound post-hoc and
  committed here as the halt recovery. A follow-up ticket captures the
  iteration-worker-must-not-ScheduleWakeup contract gap (separate from
  P077's delegation-mechanism fix).

- ffa85a7: feat(itil): P071 split slice 3 — /wr-itil:work-problem (+ manage-problem forwarder)

  Phase 3 of P071's phased-landing plan: the "pick the highest-WSJF ticket and work it" user intent gets its own skill so `/` autocomplete surfaces it directly. Previously hidden behind `/wr-itil:manage-problem work` — a word-argument subcommand that Claude Code autocomplete does not surface.

  CRITICAL naming distinction: `/wr-itil:work-problem` is **singular** — one ticket per invocation, interactive `AskUserQuestion` selection. It is distinct from the already-existing plural `/wr-itil:work-problems` (AFK batch orchestrator). The two names coexist per P071's acknowledged trade-off; the singular skill is the per-iteration execution unit the plural orchestrator delegates into via the Agent tool (P077 + ADR-032).

  `/wr-itil:work-problem` (new skill):

  - Frontmatter: `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent` — the selection tool surface plus delegation to `/wr-itil:review-problems` (refresh) and `/wr-itil:manage-problem <NNN>` (execution).
  - Step 1 reads `docs/problems/README.md` if fresh (git-history staleness test per P031); delegates to `/wr-itil:review-problems` for the refresh if stale (P062 canonical-writer discipline — no fork).
  - Step 2 fires `AskUserQuestion` selection: Recommended single top-WSJF option, or per-tied-ticket peer options for multi-way ties, with per-option rationale. Never prose "(a)/(b)/(c)" (P053 + ADR-013 Rule 1 regression guard).
  - Step 3 delegates the execution to `/wr-itil:manage-problem <NNN>` via the Skill tool — thin-router discipline; the full investigate/transition/fix/release workflow stays on a single authoritative host.
  - Step 4 fires the standard scope-change `AskUserQuestion` (Continue / Re-rank / Pick-different) on effort drift.
  - Step 5 reports the outcome; does NOT loop automatically (that's the plural orchestrator's job).
  - AFK branch (ADR-013 Rule 6): when invoked inside a `/wr-itil:work-problems` iteration, skips `AskUserQuestion` and executes the pre-selected ticket. Within-day tiebreak matches the orchestrator spec.

  `/wr-itil:manage-problem` (deprecated-argument forwarder for `work`):

  - Step 1 `work` argument now delegates to `/wr-itil:work-problem` via the Skill tool and emits the canonical systemMessage verbatim per ADR-010's pinned template: `"/wr-itil:manage-problem work is deprecated; use /wr-itil:work-problem directly. This forwarder will be removed in @windyroad/itil's next major version."`
  - Forwarder does not re-implement the selection logic (thin-router per ADR-010).
  - `deprecated-arguments: true` frontmatter flag already present from slice 1; no change.

  Tests (ADR-037 contract-assertion pattern):

  - `packages/itil/skills/work-problem/test/work-problem-contract.bats` — 19 assertions covering: frontmatter (name singular + regression guard against plural drift; description names pick/highest-WSJF + singular distinction; allowed-tools AskUserQuestion + Skill); singular-vs-plural naming-distinction documentation; delegation to `/wr-itil:manage-problem` (anti-fork); defer-to-`/wr-itil:review-problems` for cache refresh (P062 ownership); git-history freshness test (P031); `AskUserQuestion` selection prompt fires (ADR-013 Rule 1); prose-selection fallback forbidden (P053); AFK branch documented (Rule 6); scope-expansion 3-option shape; one-ticket-per-invocation singular contract; no `deprecated-arguments: true` flag on clean-split skill; no word-argument subcommand branching regression; P071 + ADR-010 + P077 + ADR-032 traceability citations.
  - `packages/itil/skills/manage-problem/test/manage-problem-work-forwarder.bats` — 5 assertions covering: forwarder targets `/wr-itil:work-problem` (singular); singular-vs-plural name-collision guard; canonical deprecation notice emission; no inline re-implementation; parser-line pattern matches slice-1 + slice-2 shape.

  Cross-references:

  - P071 (docs/problems/071-\*.open.md) — originating ticket; phased plan's slice 3.
  - ADR-010 amended (Skill Granularity section) — canonical split-naming + forwarder contract.
  - ADR-013 Rule 1 — structured user interaction; Rule 6 — AFK fallback.
  - ADR-014 — governance skills commit their own work; delegated manage-problem owns per-ticket commits.
  - ADR-032 + P077 — plural AFK orchestrator delegates iterations via Agent tool; this singular skill is the canonical execution unit.
  - P031 — git-history freshness test; P062 — review-problems canonical README cache writer.
  - P053 + ADR-013 Rule 1 — no prose-selection fallback.

## 0.11.0

### Minor Changes

- d8ab4c5: P071 split slice 2: new `/wr-itil:review-problems` skill

  `/wr-itil:manage-problem review` is deprecated; the review-problems user
  intent now has its own skill so the `/` autocomplete surfaces it directly
  (JTBD-001 + JTBD-101). This is phase 2 of the P071 phased-landing plan
  (list-problems shipped as slice 1 in `@windyroad/itil@0.10.0`).

  - `packages/itil/skills/review-problems/SKILL.md` — NEW skill carrying
    the full review stack: re-read `RISK-POLICY.md`, re-score every
    `.open.md` / `.known-error.md` ticket (Impact × Likelihood × Effort →
    WSJF), auto-transition Open → Known Error when root cause + workaround
    are documented, fire the Verification Queue prompt (`.verifying.md`
    per ADR-022 + P048 Candidate 4 `Likely verified?` heuristic), rewrite
    `docs/problems/README.md`, and commit per ADR-014 + ADR-015.
    `allowed-tools`: `Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion,
Skill` — the tool surface the governance-scoped write path demands
    (contrast with `list-problems`'s read-only surface).
  - `packages/itil/skills/review-problems/test/review-problems-contract.bats`
    — NEW 16 contract assertions (ADR-037 pattern; `@problem P071` +
    `@jtbd JTBD-001` + `@jtbd JTBD-101` traceability). Covers: frontmatter
    name, description intent language, allowed-tools surface (Write +
    Edit + Skill + AskUserQuestion required), glob scope (.open.md /
    .known-error.md / .verifying.md / .parked.md), README-refresh ownership
    boundary, Verification Queue prompt contract (ADR-022 fix-summary
    requirement), auto-transition path, ADR-014/015 commit-gate, P057
    staging-trap citation, RISK-POLICY.md reuse (no hardcoded scale),
    P071/ADR-010 citation, clean-split no-deprecated-arguments flag, and
    regression guard against word-argument subcommand branching.
  - `packages/itil/skills/manage-problem/SKILL.md` — Step 1 `review`
    argument now routes to a thin-router forwarder that delegates to
    `/wr-itil:review-problems` via the Skill tool and emits the canonical
    deprecation notice verbatim per ADR-010's pinned template. Parser
    line updated from "run the review (step 9) only" to "delegate to
    `/wr-itil:review-problems`". Step 9's inline review logic stays in
    the file during the deprecation window (for historical reference +
    the inline `work` path that still flows through Step 9 pre-slice 3)
    but is no longer the primary entry point.
  - `packages/itil/skills/manage-problem/test/manage-problem-review-forwarder.bats`
    — NEW 4 contract assertions for the review-forwarder contract:
    target-skill reference, canonical deprecation notice, delegate /
    Skill tool language (no re-implementation), and parser-line shape.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  Remaining phased-landing slices tracked on P071: `work-problem`
  (singular; coexists with `/wr-itil:work-problems` AFK plural),
  `transition-problem`, plus the `manage-incident` splits
  (`list-incidents`, `mitigate-incident`, `restore-incident`,
  `close-incident`, `link-incident`).

## 0.10.1

### Patch Changes

- a0ec231: P077 fix: work-problems Step 5 delegates iterations via the Agent tool

  `/wr-itil:work-problems` Step 5 previously used an ambiguous "Invoke the
  manage-problem skill" line that read as a Skill-tool (in-process) invocation.
  That expanded manage-problem's 500+ line SKILL.md into the main orchestrator's
  context every iteration, accumulated across the AFK loop, and caused silent
  early-stop (`ALL_DONE` without a documented stop condition firing).

  Step 5 now delegates each iteration to a `general-purpose` subagent via the
  Agent tool. Option B per P077 — iteration work is general engineering, not
  specialised domain expertise, so a typed iteration-worker subagent would just
  re-export manage-problem's content. The AFK iteration-isolation wrapper
  sub-pattern is documented in ADR-032 (amended 2026-04-21).

  - `packages/itil/skills/work-problems/SKILL.md` Step 5 — rewritten with
    explicit Agent-tool delegation (`subagent_type: general-purpose`),
    self-contained prompt shape, and structured return-summary contract
    (`ticket_id` / `ticket_title` / `action` / `outcome` / `committed` /
    `commit_sha` / `reason` / `skip_reason_category` / `outstanding_questions` /
    `remaining_backlog_count` / `notes`). Architect R2: commit-state fields keep
    Step 6.75's Dirty-for-known-reason branch evaluable. JTBD extension:
    skip-reason category and outstanding-questions fields let Step 2.5 populate
    the Outstanding Design Questions table deterministically.
  - `allowed-tools` frontmatter — adds `Agent` (closes the pre-existing latent
    bug where Step 6.5 already required Agent-tool delegation).
  - Non-Interactive Decision Making table — new row documents iteration
    delegation default.
  - `## Related` section — new; cites P077, P036, P040, P041, P053, and ADR-013
    / ADR-014 / ADR-015 / ADR-018 / ADR-019 / ADR-022 / ADR-032 / ADR-037.
  - `packages/itil/skills/work-problems/test/work-problems-step-5-delegation.bats`
    — NEW, 10 contract assertions (ADR-037 pattern; `@problem P077` +
    `@jtbd JTBD-006` traceability).
  - `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` —
    amended with the "AFK iteration-isolation wrapper (P077 amendment)"
    sub-pattern under foreground synchronous. No supersession.
  - `docs/problems/077-...open.md` → `.verifying.md` with `## Fix Released`
    section per ADR-022.

  Inter-iteration continuity preserved: Step 6.5 (release cadence / ADR-018)
  and Step 6.75 (inter-iteration verification / P036) stay in the main
  orchestrator's turn. The iteration subagent commits its own work per ADR-014
  but MUST NOT run `push:watch`/`release:watch`.

## 0.10.0

### Minor Changes

- 412443f: P071 split slice 1: new `/wr-itil:list-problems` skill

  `/wr-itil:manage-problem list` is deprecated; the list-problems user intent
  now has its own skill so the `/` autocomplete surfaces it directly (JTBD-001

  - JTBD-101). This is phase 1 of the P071 phased-landing plan (audit landed
    in the prior commit — 2 offenders, both in @windyroad/itil).

  * `packages/itil/skills/list-problems/SKILL.md` — NEW read-only skill
    (`allowed-tools: Read, Bash, Grep, Glob` — no Write, no Edit, no
    AskUserQuestion). Reuses the git-log-based README cache freshness check
    from `manage-problem review` per P031 + architect Q4.
  * `packages/itil/skills/list-problems/test/list-problems-contract.bats` —
    NEW 9 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
    JTBD-001 + @jtbd JTBD-101 traceability).
  * `packages/itil/skills/manage-problem/SKILL.md` — `deprecated-arguments:
true` frontmatter flag per ADR-010 amended; Step 1 `list` argument now
    routes to a thin-router forwarder that delegates via the Skill tool and
    emits the canonical deprecation notice verbatim.
  * `packages/itil/skills/manage-problem/test/manage-problem-list-forwarder.bats`
    — NEW 4 contract assertions for the forwarder contract.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment. Full bats suite green (467/467).

  Remaining phased-landing slices tracked on P071: `work-problem`,
  `review-problems`, `transition-problem`, plus the `manage-incident`
  splits (`list-incidents`, `mitigate-incident`, `restore-incident`,
  `close-incident`, `link-incident`).

## 0.9.0

### Minor Changes

- 6ee6adc: **manage-problem + work-problems**: wire the external-root-cause detection surface so `manage-problem` prompts for `/wr-itil:report-upstream` invocation when root cause points upstream (closes P063).

  New behaviour:

  - `manage-problem` Step 7 (Open → Known Error transition) scans Root Cause Analysis for strict external markers: explicit `upstream` / `third-party` / `external` / `vendor` labels, or scoped-npm pattern `@[\w-]+/[\w-]+`. On hit, fires `AskUserQuestion` with three options: invoke `/wr-itil:report-upstream` now, defer and note in ticket, or mark false positive.
  - Parked lifecycle gains a pre-park hook: parking with `upstream-blocked` reason runs the same detection.
  - AFK non-interactive fallback (per ADR-013 Rule 6) appends the stable marker `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` to the ticket's `## Related` section. The skill is NOT auto-invoked (its Step 6 security-path is interactive per ADR-024 Consequences).
  - `work-problems` `upstream-blocked` skip category now runs the AFK fallback before skipping so accumulated upstream dependencies surface in the ticket body when the user returns.
  - Already-noted grep check prevents duplicate marker lines on subsequent runs.

  No new public skill or command; no ADR changes. Closes a discoverability gap between `manage-problem` (caller) and `/wr-itil:report-upstream` (callee, shipped in 0.8.0).

### Patch Changes

- 7e19eab: **manage-problem**: refresh `docs/problems/README.md` on every Step 7 status transition and stage it in the same commit (closes P062).

  Before this change, status transitions (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed, Parked) did NOT refresh the README.md cache — only the `review` operation did. The next session's fast-path freshness check correctly detected the lag and forced a full rescan (self-healing but wasteful), and human readers browsing README.md between sessions saw outdated WSJF rankings and an incomplete Verification Queue.

  SKILL.md Step 7 now includes a dedicated "README.md refresh on every transition (P062)" block describing the mechanism (regenerate in-place with the new filename set and Status; stage in the same commit; update the "Last reviewed" parenthetical). Step 11 commit convention requires `docs/problems/README.md` in the transition commit's stage list — including folded-fix commits where the `.verifying.md` transition rides with a `fix(<scope>): ...` commit.

  The refresh is a render, not a re-rank: existing WSJF values on ticket files are trusted; no full re-scoring pass fires. That remains Step 9's job.

  Cache stays fresh by construction — the Step 9 fast-path freshness check should return empty on any invocation after a transition commit.

## 0.8.0

### Minor Changes

- 8788489: Add `/wr-itil:report-upstream` skill — file a local problem ticket as a structured upstream issue or private security advisory with bidirectional cross-references. Implements the contract in ADR-024 (Cross-project problem-reporting contract).

  The skill discovers upstream `.github/ISSUE_TEMPLATE/` via `gh api`, classifies the local ticket (bug / feature / question / security), picks the best-matching template (or falls through to a structured default when none exist), routes security-classified tickets via the upstream's `SECURITY.md` (GitHub Security Advisories, `security@` mailbox, or other declared channel — never auto-opens a public issue for a security-classified ticket), and back-writes a `## Reported Upstream` section + `## Related` line into the local ticket.

  Three distinct AFK branches are encoded in the skill: public-issue path proceeds (voice-tone gate per ADR-028 may delegate-and-retry); declared-channel security path proceeds via `gh api .../security-advisories`; missing-`SECURITY.md` security path saves the drafted report and halts the orchestrator (loop-stopping event per ADR-024 Consequences). Above-appetite commit-gate uses the ADR-013 Rule 6 fail-safe.

  Step-0 auto-delegation per ADR-027 is deliberately deferred — `report-upstream` is in ADR-027's "held for reassessment" set with the explicit note "narrow workflow; decided at implementation time". The skill's main-agent context is the right place to evaluate the security-path branch and surface the missing-SECURITY.md `AskUserQuestion`.

  Includes a doc-lint bats test (Permitted Exception per ADR-005) covering all five ADR-024 Confirmation criterion 2 assertions plus the architect-required ADR-027 / ADR-028 / three-AFK-branch documentation. Closes P055 Part B; P055 Part A (intake scaffolding) shipped earlier in the same session.

## 0.7.2

### Patch Changes

- f9bfa56: Fix the next-ID origin-max lookup in `manage-problem` Step 3 and `create-adr` Step 3 (P056). The prior bash pipeline ran `git ls-tree origin/main <path>/ | grep -oE '[0-9]{3}'` — default `git ls-tree` output includes the 40-char blob SHA, whose hex run can contain three consecutive decimal digits that the regex falsely matches (observed `origin_max=997` on 2026-04-20 opening P055). The fix adds `--name-only` to drop mode/type/SHA columns and pipes through `sed` to strip the path prefix, so the anchored `grep -oE '^[0-9]+'` only picks up real filename IDs. ADR-019's next-ID invariant and P043's collision guard both presume this pipeline is sound; this change restores the invariant. Two new bats doc-lint tests (8 assertions) guard the contract.
- 3bf2074: Document the `git mv` + Edit + `git add` staging-ordering trap (P057) in `manage-problem` Step 7 and `create-adr` Step 6. `git mv` alone stages only the rename — subsequent `Edit`-tool modifications must be re-staged explicitly (`git add <new>`) before commit. Without the re-stage, transition commits capture the rename but drop the `Status:` / `## Fix Released` content edits, which then leak into an unrelated later commit and corrupt the audit trail (observed 2026-04-19 in P054's `.verifying.md` transition).

  Changes:

  - `manage-problem` Step 7: new warning block applying to all three transition arrows (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed), plus an explicit `git add <new>` line in each code block.
  - `manage-problem` Step 11: commit convention now recommends `git add -u` as a safety-net for tracked modifications.
  - `create-adr` Step 6: supersession rename now instructs authors to `git add` the file again after the frontmatter + "Superseded by" edits.
  - Two new bats doc-lint tests guard the contract in both SKILL.md files.

## 0.7.1

### Patch Changes

- c5f8039: Add inter-iteration verification to `wr-itil:work-problems` AFK orchestrator (closes P036). After the release-cadence check and before the next iteration, the skill now runs `git status --porcelain` and halts the loop if the working tree is dirty for a reason not stated in the last iteration's report. This is defence-in-depth behind P035's fallback: it catches silent subagent commit failures (a failure inside the assess-release skill, a git conflict, a malformed commit message) that would otherwise accumulate across iterations and corrupt the final summary. Non-interactive default recorded in the decision table. Recovery is explicitly out of scope per ADR-013 Rule 6 — the check surfaces the bug, the user decides. Includes a 6-test doc-lint bats regression file.

## 0.7.0

### Minor Changes

- 151b993: manage-problem Verification Queue detection (P048, minimal-scope).

  - **Fast-path cache hit**: step 9d now explicitly fires even when
    `docs/problems/README.md` is fresh (candidate 1). Prevents the prior
    regression where verification prompts were suppressed on cache hit —
    which is exactly when the user is most likely to verify.
  - **Verification Queue presentation**: step 9c now emits a
    `Likely verified?` column in the Verification Queue with
    `yes (N days)` / `no (N days)` values based on release age
    ≥ 14 days (candidate 4). 14-day default documented as a within-skill
    tunable (architect review confirmed not policy-level yet).
  - Step 9d surfaces the highlighted (`yes`) tickets first in the
    verification prompt so the user can batch-close long-standing
    verifications.
  - 5 new structural bats assertions in
    `manage-problem-verification-detection.bats`; full project suite
    269/269 green (+5).
  - Candidates 2 (standalone `verify-fixes` op), 3 (exercise observation
    records — new file-level state dimension), and 5 (AFK-mode
    orchestrator hook) are deferred pending an architect ADR-scope
    decision.

## 0.6.0

### Minor Changes

- 4e93bcf: Add Verification Pending `.verifying.md` problem-lifecycle status per ADR-022
  (P049 — the SKILL.md contract half; existing-file migration follows in a
  separate commit per ADR-022 Scope).

  - **manage-problem SKILL.md**: lifecycle table gains Verification Pending
    status and `.verifying.md` suffix; WSJF multiplier table documents
    Verification Pending = 0 (excluded from dev ranking); Known Error →
    Verification Pending transition documented (git mv + Status field +
    `## Fix Released` in one commit per ADR-014); step 9b skips
    `.verifying.md` files; step 9c gains a Verification Queue section; step
    9d targets `*.verifying.md` via glob; step 9e README template gains the
    Verification Queue section; closing workflow and commit-convention
    prose updated.
  - **work-problems SKILL.md**: step 1 scan excludes `.verifying.md`; step 4
    classifier row `Known Error with ## Fix Released` → `.verifying.md`
    (suffix-based, no file-body scan).
  - **manage-incident SKILL.md**: step 9 linked-problem close gating accepts
    `.verifying.md` alongside `.known-error.md` and `.closed.md`.
  - **docs/problems/README.md**: "Known Errors (Fix Released — pending
    verification)" shadow table replaced with "Verification Queue" citing
    ADR-022.
  - 11 new structural bats assertions in
    `manage-problem-verification-pending.bats`; full project suite
    264/264 green (+11).

## 0.5.0

### Minor Changes

- a0600d9: Surface outstanding design questions at work-problems stop-condition #2 (P053).

  - Step 2 branches on stop-condition: #2 now routes to a new Step 2.5 before
    emitting `ALL_DONE`; #1 and #3 keep the direct-emit behaviour.
  - Step 2.5 extracts user-answerable questions from skipped tickets. In
    interactive invocations, batches up to 4 into one `AskUserQuestion` call
    per ADR-013 Rule 1 (Anthropic's documented per-call cap). In
    non-interactive / AFK invocations (the JTBD-006 persona default), emits
    an `### Outstanding Design Questions` table in the post-stop summary
    per ADR-013 Rule 6 fail-safe.
  - Step 4 classifier gains a skip-reason taxonomy column:
    `user-answerable` / `architect-design` / `upstream-blocked`. Step 2.5
    selects the user-answerable subset to surface.
  - Output Format template includes an `### Outstanding Design Questions`
    section (Ticket / Question / Context), emitted only when
    stop-condition #2 fires with ≥1 user-answerable skip.
  - Non-Interactive Decision Making table documents the AFK-default path.
  - 7 structural bats assertions added in
    `work-problems-stop-condition-questions.bats`; full project suite
    253/253 green (+7).

## 0.4.5

### Patch Changes

- 5c677cc: manage-problem: add XL effort bucket and effort re-rate pre-flight (P047)

  - Effort table in `manage-problem` SKILL.md gains an **XL** bucket (divisor 8) for multi-day or cross-package work, with a new sub-example showing how WSJF flattens at XL and a live-estimate note pointing to steps 7 and 9b.
  - **Step 7** Open → Known Error pre-flight gains a checklist item requiring the effort bucket to be re-rated against the now-documented fix strategy, with the reason captured in the problem file.
  - **Step 9b** step 7 reworded from "Estimate Effort" to "Re-estimate Effort (S / M / L / XL) ... note the reason in a short parenthetical" so the review re-rate is unmissable.
  - `work-problems` SKILL.md example paragraphs updated non-normatively to reference "S to L or XL" for consistency.
  - New doc-lint test `manage-problem-effort-buckets.bats` (4 assertions) guards the new contract.

## 0.4.4

### Patch Changes

- 39e026c: itil: governance skills auto-release when changesets are queued (P028)

  Extends the terminal commit step of `manage-problem` and `manage-incident`
  so non-AFK governance invocations drain the release queue automatically
  after their own commit lands, rather than ending at `git commit` and
  relying on the user to remember `npm run push:watch` and
  `npm run release:watch`.

  Mechanism (per new ADR-020):

  - After commit, delegate to `wr-risk-scorer:assess-release` (subagent
    `wr-risk-scorer:pipeline` with Skill fallback per ADR-015).
  - If `push` and `release` scores are both within appetite (≤ 4/25 per
    `RISK-POLICY.md`) AND `.changeset/` is non-empty, run
    `npm run push:watch` followed by `npm run release:watch`.
  - Fail-safe identical to ADR-018: stop on `release:watch` failure, no
    retry. Above-appetite risk skips the drain and reports clearly.
  - Skipped automatically when the skill is invoked inside an AFK
    orchestrator — those flows handle release cadence via ADR-018 Step 6.5
    and must not double-release.

  Scope matches ADR-014 (manage-problem, manage-incident). The remaining
  governance skills (`create-adr`, `run-retro`, `update-guide`,
  `update-policy`) inherit ADR-020 automatically once they adopt ADR-014.

  Splits the original P028 auto-install concern into P045 (deferred
  pending Claude Code in-session plugin reload). Closes P028 pending user
  verification.

## 0.4.3

### Patch Changes

- 359ec7c: ticket-creators: next-ID collision guard against origin (P043)

  Adds the next-ID collision guard from ADR-019 confirmation criterion 2 to
  both ticket-creator skills:

  - `manage-problem` step 3 (Assign the next ID): now computes max of
    local-max and `git ls-tree origin/<base>` max, then increments. Catches
    collisions between local work and parallel sessions before the ticket
    file is written.
  - `create-adr` step 3 (Determine sequence number): same mechanism applied
    to `docs/decisions/`.

  Both skills cite ADR-019 and log renumber decisions in the user-facing
  report. Sibling fix to P040 (work-problems Step 0 preflight, shipped in
  @windyroad/itil@0.4.2): preflight catches divergence at loop start; this
  ticket catches collisions at ticket-creation time as a defence in depth.

  Adds bats tests (3 assertions per skill) verifying ADR-019 references and
  the collision-guard pattern.

  Closes P043 pending user verification.

## 0.4.2

### Patch Changes

- 9c6019e: work-problems: add preflight to reconcile with origin before iteration (P040)

  Adds Step 0 (Preflight) to the work-problems AFK orchestrator per ADR-019.
  Before opening the work loop, the orchestrator now runs `git fetch origin`
  and compares local HEAD with `origin/<base>`. On trivial fast-forward
  divergence, it pulls non-interactively (`git pull --ff-only`). On
  non-fast-forward divergence (local has unpushed commits AND origin has
  advanced), it stops with a clear divergence report (`git log --oneline
HEAD..origin/<base>` and reverse). Non-interactive rebase or merge is
  explicitly forbidden — the persona requires user judgment for those.

  Network failure on `git fetch origin` defaults to fail-closed (stop and
  report); the user can retry when network is restored.

  Adds row to Non-Interactive Decision Making table covering origin
  divergence. Adds bats test (7 assertions) covering ADR-019 confirmation
  criteria: skill cites ADR-019; references `git fetch origin` and
  `pull --ff-only`; has discrete preflight step; non-interactive table
  covers it; explicitly forbids non-interactive merge/rebase.

  The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in
  ticket-creator skills (manage-problem, wr-architect:create-adr) and is
  tracked in a separate problem ticket.

  Closes P040 pending user verification.

## 0.4.1

### Patch Changes

- 87c2ecf: work-problems: enforce inter-iteration release cadence (P041)

  Adds Step 6.5 (Release-cadence check) to the work-problems AFK orchestrator
  per ADR-018. After each successful iteration, the orchestrator now invokes
  `wr-risk-scorer:assess-release` (or its pipeline subagent) and, if `push` or
  `release` score is at or above appetite (4/25 per RISK-POLICY.md), drains
  the queue with `npm run push:watch` then `npm run release:watch` before
  starting the next iteration. The drain runs non-interactively per ADR-013
  Rule 6 (policy-authorised when within appetite). On `release:watch`
  failure, the loop stops and reports — no non-interactive retry.

  Also adds a row to the Non-Interactive Decision Making table covering the
  new behaviour, and a bats test asserting the SKILL.md references both
  `assess-release` and `release:watch` (ADR-018 confirmation criterion).

  Closes P041 pending user verification of the next AFK loop.

## 0.4.0

### Minor Changes

- a36a084: Add `wr-itil:work-problems` AFK batch orchestrator skill and document a commit-gate fallback in `wr-itil:manage-problem` (JTBD-006).

  - **New skill** `wr-itil:work-problems` — loops through ITIL problem tickets by WSJF priority, delegating each iteration to `wr-itil:manage-problem` non-interactively. Stops gracefully when nothing remains actionable. Emits `ALL_DONE` sentinel for external detection. Deterministic Step 4 classification rules (skip known-errors with Fix Released; work everything else).
  - **Fix** `wr-itil:manage-problem` commit gate now documents a two-path delegation (closes P035). Primary: delegate to `wr-risk-scorer:pipeline` subagent-type via the Agent tool. Fallback: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent-type is unavailable (e.g., when `manage-problem` is itself running inside a spawned subagent). Per ADR-015 both produce equivalent bypass markers. Non-interactive fail-safe preserved for the risk-above-appetite branch only — silent-skip for delegation-unavailable is no longer sanctioned.

## 0.3.3

### Patch Changes

- 83b8be7: fix(manage-problem): add Parked lifecycle status and README.md fast-path cache (closes P027)

  - Adds `.parked.md` suffix and Parked status to problem lifecycle table
  - `problem work` checks README.md freshness before triggering full 18-file re-scan
  - Step 9e writes/overwrites `docs/problems/README.md` after every full re-rank
  - Parked problems excluded from WSJF ranking; shown in separate Parked table

## 0.3.2

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.1

### Patch Changes

- e8216b1: Governance skills now commit their own completed work (P023, ADR-014).

  **@windyroad/itil**: `manage-problem` and `manage-incident` skills no longer end with "Do not commit — the user will commit when ready." They now instruct the agent to stage files, delegate to `wr-risk-scorer:pipeline` for a risk assessment, and commit automatically using a conventional commit message referencing the problem or incident ID. If risk is above appetite, an `AskUserQuestion` prompt is presented before committing. Non-interactive fail-safe per ADR-013 Rule 6.

  New ADR-014 documents the cross-skill commit pattern, commit message convention, and risk-gate delegation sequence.

## 0.3.0

### Minor Changes

- e5eb0bd: Add `manage-incident` skill for evidence-first incident response with automatic handoff to problem management.

  The new `/wr-itil:manage-incident` skill implements an ITIL-aligned incident workflow focused on **restoring service fast** while keeping a disciplined audit trail. Hypotheses must cite evidence before any mitigation. Reversible mitigations (rollback, feature flag, restart) are preferred over forward fixes. On restoration, the skill automatically invokes `manage-problem` to create or update the underlying root-cause ticket, linking the incident to a `P###`.

  Incidents use a separate `I###` namespace in `docs/incidents/` so lifecycles, prioritisation (severity for incidents, WSJF for problems), and audit trails stay clean. See ADR-011 and JTBD-201 for the full design.

### Patch Changes

- 23d0d10: Require structured `AskUserQuestion` prompts at all governance-skill decision branches (P021, ADR-013).

  **@windyroad/itil**: `manage-problem` skill now requires `AskUserQuestion` for WSJF tie-breaks, problem selection, and scope-change decisions. Prose "(a)/(b)/(c)" option lists are prohibited.

  **@windyroad/risk-scorer**: All three scorer agents (pipeline, wip, plan) now enforce below-appetite silence — no advisory prose, "Your call:", or suggestions when scores are within appetite. Above-appetite output uses structured `RISK_REMEDIATIONS:` blocks instead of free-text suggestions.

  New ADR-013 establishes the cross-cutting standard: every governance-skill branch point with ≥2 options must use `AskUserQuestion`; scoring agents stay pure output-only.

## 0.2.0

### Minor Changes

- 6eeef94: Rename `@windyroad/problem` → `@windyroad/itil` (plugin `wr-problem` → `wr-itil`, skill `/wr-problem:update-ticket` → `/wr-itil:manage-problem`). Makes room for peer ITIL skills (incident, change) under the same plugin. Hard rename, no shim — per ADR-010.

  **Migration**: if you had `@windyroad/problem` installed, uninstall it (`npx @windyroad/problem --uninstall`) then install `@windyroad/itil`. The skill command changes from `/wr-problem:update-ticket` to `/wr-itil:manage-problem`. `@windyroad/retrospective`'s dependency is updated automatically.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
