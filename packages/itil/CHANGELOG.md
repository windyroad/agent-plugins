# @windyroad/problem

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
