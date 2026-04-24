# @windyroad/risk-scorer

## 0.3.6

### Patch Changes

- 43e9cc0: Three-band TTL policy in `check_risk_gate` eliminates the manual rescore round-trip when the working tree is unchanged but the clock has moved past the half-life of the marker (P090).

  - **Band A** (age < TTL/2) → pass silently (unchanged).
  - **Band B** (TTL/2 ≤ age < TTL) → if the pipeline state-hash is invariant since the scorer ran, pass and slide the marker forward; if the hash drifted, halt as before. Bounded by a 2×TTL hard-cap from a new `<action>-born` sibling so an unchanged-but-idle tree cannot ride a single score indefinitely.
  - **Band C** (age ≥ TTL) → halt with the existing expired message (unchanged).

  `git-push-gate.sh` push-gate now routes through `check_risk_gate "push"` and inherits the band logic (previously carried its own inline binary TTL check). Push-specific threshold guidance preserved via a new `RISK_GATE_CATEGORY` export.

  Backward-compatible: markers written before this release have no `-born` sibling and retain the pre-P090 binary TTL behaviour until the next scorer run writes both files.

  ADR-009 amended with a three-band refinement footnote.

## 0.3.5

### Patch Changes

- 45e9c71: Fix pipeline-state drift hash to be stable across `git push` (P054). Previously the `--hash-inputs` output of `packages/risk-scorer/hooks/lib/pipeline-state.sh` used `git diff origin/main --stat`, which shrinks to empty after a policy-authorised push advances `origin/main`, causing `npm run release:watch` to fire a spurious "Pipeline state drift" denial every time and forcing a rote mid-cycle delegation to `wr-risk-scorer:pipeline`. The hash now derives from a tree-based snapshot (via `git stash create`, falling back to `HEAD^{tree}` on a clean tree) of the conceptual "committed + index + working tree" content, which is invariant across both commit and push. Adds 8 regression tests in `pipeline-state-hash.bats`. Also documents the post-push stability contract in `scripts/release-watch.sh`.

## 0.3.4

### Patch Changes

- 0370c4e: Risk scorer emits explicit STOP verdict above appetite.

  - `pipeline.md`, `wip.md`, `plan.md`: Above-Appetite sections now contain an
    explicit STOP / PAUSE / FAIL directive and forbid "Proceed", "Continue",
    "You may ship", and similar nudge language when cumulative risk exceeds
    appetite. The only sanctioned above-appetite output is the Risk Report +
    `RISK_SCORES:` + structured `RISK_REMEDIATIONS:` block — matching the
    symmetrical Below-Appetite Output Rule (ADR-013 Rule 5)
  - Doc-lint guard `risk-scorer-above-appetite-stop.bats` prevents regression
    across all three scoring modes
  - Previously, the scorer could contradict itself (structured output: high
    risk; verbal verdict: proceed with release), causing the agent to attempt
    gated actions and waste tool calls when the hook gate correctly blocked them

- 0edec54: Risk scorer refuses to credit monitoring as a control.

  - `pipeline.md`, `wip.md`, `plan.md`: Control Discovery now contains an
    explicit "Monitoring is not a control" rule. Monitoring, alerting,
    dashboards, "watch for elevated errors", and "be ready to rollback"
    MUST NOT be credited or reduce residual risk. Post-release detection
    shortens time-to-notice; it does not reduce pre-release risk.
  - Doc-lint guard `risk-scorer-monitoring-not-a-control.bats` (6 assertions)
    prevents regression across all three scoring modes.
  - Previously, 329-report corpus analysis showed scorers crediting
    monitoring as a control, producing false-confidence residual risk
    scores on releases with genuine pre-release risk gaps.

- 16be06f: Risk scorer now honours user-stated preconditions.

  - `pipeline.md`, `wip.md`, and `plan.md`: new **User-Stated Preconditions Check** section requires the scorer to inspect recent conversation, problem tickets, commits, and changesets for user-stated conditional-delivery warnings ("A is only safe if B ships alongside")
  - Unmet preconditions surface as standalone Risk items with inherent risk >= Medium (>= 5), routing into the existing above-appetite `RISK_REMEDIATIONS:` flow rather than being buried in prose or ignored because the diff's technical risk scored Low
  - Doc-lint guard test `risk-scorer-user-stated-preconditions.bats` prevents regression across all three scoring modes

- 6abd0ee: Tighten `RISK_BYPASS: reducing` criteria to restore discriminating power.

  - `pipeline.md`: reducing bypass now requires one of (1) ticket closure,
    (2) remediation of a previously-flagged risk, or (3) removal of a
    documented risk. Ordinary docs-only edits, test-only additions without
    a remediation link, and routine refactors are now risk-neutral and do
    NOT earn the bypass label.
  - Added companion `RISK_BYPASS_REASON:` line — every reducing bypass must
    cite the ticket closed, prior report remediated, or removed risk. This
    makes the bypass auditable.
  - Doc-lint guard `risk-scorer-reducing-bypass-criteria.bats` prevents
    regression.
  - Background: 329-report retrospective across 6 projects showed the
    previous loose criteria applied `reducing` to 97.9% of commits in this
    repo and 79.6% across consumer projects, rendering the label
    meaningless. Only 2 of 96 reports omitted it.

## 0.3.3

### Patch Changes

- a36a084: WIP verdict now emits `RISK_VERDICT: COMMIT` with a `RISK_COMMIT_REASON` when the WIP scorer detects completed governance work (closed problem tickets, accepted ADRs, transitioned states) that has not yet been committed (closes P024, implements ADR-016).

  - `wr-risk-scorer:wip` agent emits the new verdict with an explicit false-positive safeguard: any file outside governance-artefact paths suppresses `COMMIT`.
  - `wr-risk-scorer:assess-wip` skill Step 4 surfaces the verdict via `AskUserQuestion` with a "Not yet" defer option so users can defer without consequence.
  - New `packages/risk-scorer/agents/test/risk-scorer-commit-verdict.bats` covers the four contract assertions from ADR-016.

## 0.3.2

### Patch Changes

- 83b8be7: fix(risk-scorer): expand RISK_REMEDIATIONS to 5-column format (closes P021)

  - Adds `effort S/M/L` and `risk_delta -N` columns to RISK_REMEDIATIONS format
  - Updated in pipeline.md, wip.md, and plan.md agents
  - Structural BATS tests added to enforce format

## 0.3.1

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.0

### Minor Changes

- b7d6739: Add on-demand assessment skills (P020)

  New user-invocable skills per ADR-015:

  - `wr-risk-scorer:assess-release` — pipeline risk score on demand; pre-satisfies the commit gate
  - `wr-risk-scorer:assess-wip` — WIP risk nudge for the current uncommitted diff
  - `wr-architect:review-design` — on-demand ADR compliance review
  - `wr-jtbd:review-jobs` — on-demand persona/job alignment check

  All four skills are discoverable via `/` autocomplete and delegate to existing
  governance subagents. No hook gate changes; bypass marker is still written by
  the PostToolUse hook after the pipeline subagent runs.

## 0.2.1

### Patch Changes

- 23d0d10: Require structured `AskUserQuestion` prompts at all governance-skill decision branches (P021, ADR-013).

  **@windyroad/itil**: `manage-problem` skill now requires `AskUserQuestion` for WSJF tie-breaks, problem selection, and scope-change decisions. Prose "(a)/(b)/(c)" option lists are prohibited.

  **@windyroad/risk-scorer**: All three scorer agents (pipeline, wip, plan) now enforce below-appetite silence — no advisory prose, "Your call:", or suggestions when scores are within appetite. Above-appetite output uses structured `RISK_REMEDIATIONS:` blocks instead of free-text suggestions.

  New ADR-013 establishes the cross-cutting standard: every governance-skill branch point with ≥2 options must use `AskUserQuestion`; scoring agents stay pure output-only.

## 0.2.0

### Minor Changes

- fe1b903: Gate markers now persist across prompts (ADR-009). Removed Stop-hook reset scripts from all 5 review plugins. Marker lifecycle is now governed entirely by TTL (30 min default, configurable via `*_TTL` env vars) + drift detection of policy files. Resolves P001 — reviews no longer need to re-run on every prompt. Note: this is a behaviour change; users who relied on fresh-review-every-prompt should set a shorter TTL.

## 0.1.6

### Patch Changes

- ec16630: Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.

## 0.1.5

### Patch Changes

- b12e7c0: Fix misleading error messages in release gate: drift now clearly instructs "re-run risk-scorer", score-too-high retains "split/reduce/incident" guidance inline. Remove generic suffix in git-push-gate that conflated the two cases.

## 0.1.4

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.
- eb47a86: Improve git-push-gate hook to detect missing release:watch script and guide the agent to create one instead of directing to a non-existent command.

## 0.1.3

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.2

### Patch Changes

- a4cbfd9: Fix misleading error messages in risk-gate.sh that said the risk-scorer "runs automatically on each prompt". It doesn't — the agent must explicitly delegate to wr-risk-scorer:pipeline.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
