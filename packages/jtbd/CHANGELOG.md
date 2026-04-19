# @windyroad/jtbd

## 0.6.0

### Minor Changes

- 6dd6a77: **Breaking change for external adopters**: remove the `docs/JOBS_TO_BE_DONE.md` runtime fallback. Canonical JTBD layout is now `docs/jtbd/` only (ADR-008 Option 3 chosen 2026-04-20 per P019).

  **Who is affected**: any project still using the legacy single-file `docs/JOBS_TO_BE_DONE.md` layout. The JTBD gate, agent, and CI validation no longer consult the legacy file.

  **Migration**: run `/wr-jtbd:update-guide` — it is the **sole** component in the suite permitted to read `docs/JOBS_TO_BE_DONE.md`, and only for one-shot migration into the `docs/jtbd/` directory layout. After migration, the legacy file can be deleted (git history is the archive).

  **Runtime changes**:

  - `@windyroad/jtbd` eval hook no longer injects the "docs/JOBS_TO_BE_DONE.md" enforcement variant; missing `docs/jtbd/` triggers an update-guide recommendation.
  - `@windyroad/jtbd` enforce hook no longer exempts the legacy file and no longer falls back to it. On projects without `docs/jtbd/`, the gate blocks with a `/wr-jtbd:update-guide` suggestion.
  - `@windyroad/jtbd` mark-reviewed hook no longer stores a hash against the legacy file; it exits early when `docs/jtbd/` is absent.
  - `@windyroad/jtbd` agent description and lookup logic now reference only `docs/jtbd/`.
  - `@windyroad/architect` enforce hook no longer exempts `docs/JOBS_TO_BE_DONE.md` as a peer-plugin policy artefact (it is no longer a recognised governance artefact).
  - `@windyroad/architect` detect hook's "does not apply to" list no longer mentions `docs/JOBS_TO_BE_DONE.md`.

  **Documentation changes**:

  - ADR-008 amended: Option 3 "Directory-only, no fallback" added as the chosen option; Option 1 retained with dated rejection (2026-04-19) so the rationale chain is readable.
  - ADR-005 line 138 rephrased to reflect the single canonical path.
  - ADR-007 supersession note extended to call out the artefact-name change (format, not just structure).
  - `wr-jtbd:update-guide` SKILL.md documents the migration carve-out explicitly.
  - This repository's own `docs/JOBS_TO_BE_DONE.md` stub is deleted (it was a 5-line redirect with no unique content).
  - Bats tests in `jtbd-eval`, `jtbd-enforce-scope`, `jtbd-mark-reviewed`, and `architect-enforce-scope` inverted to assert the legacy-file path is not consulted.

## 0.5.2

### Patch Changes

- 6e7c2e4: Strengthen the `wr-jtbd:agent` output contract to forbid bare verdicts without remediation guidance (closes P037). The agent now treats the inline response as the primary authoritative channel and the `/tmp/jtbd-verdict` file as a subordinate internal signal. Every response must begin with a structured `JTBD Review: PASS | ISSUES FOUND | JOB UPDATE NEEDED | PERSONA UPDATE NEEDED` line and, on non-PASS verdicts, include file + line + issue + affected job + suggested fix. "FAIL" alone or a bare file list is now explicitly forbidden. Includes a 7-test doc-lint bats regression file.

## 0.5.1

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.5.0

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

## 0.4.0

### Minor Changes

- fe1b903: Gate markers now persist across prompts (ADR-009). Removed Stop-hook reset scripts from all 5 review plugins. Marker lifecycle is now governed entirely by TTL (30 min default, configurable via `*_TTL` env vars) + drift detection of policy files. Resolves P001 — reviews no longer need to re-run on every prompt. Note: this is a behaviour change; users who relied on fresh-review-every-prompt should set a shorter TTL.

## 0.3.1

### Patch Changes

- ec16630: Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.

## 0.3.0

### Minor Changes

- 2b39c9e: Migrate JTBD plugin to docs/jtbd/ directory structure with per-persona directories and individual job files (ADR-008). Backward compatible with docs/JOBS_TO_BE_DONE.md.

## 0.2.1

### Patch Changes

- e6a916a: Fix chicken-and-egg bug where JTBD enforce hook blocked creation of docs/JOBS_TO_BE_DONE.md itself (P002)

## 0.2.0

### Minor Changes

- 93527a5: Broaden JTBD enforcement to all project files, not just web UI files. JTBD is a product-level concern that applies to any project type.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
