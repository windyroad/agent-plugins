# @windyroad/jtbd

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
