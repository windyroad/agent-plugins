# @windyroad/tdd

## 0.2.1

### Patch Changes

- ec16630: Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.

## 0.2.0

### Minor Changes

- c980e8c: Per-test-file TDD state tracking, scoped test runs, and deadlock fix

  - State is now tracked per test file instead of globally — a failing Countdown test no longer blocks editing Hero
  - PostToolUse runs only the relevant test file after writes, not the full suite
  - Only timeout (exit 124) transitions to BLOCKED; all other non-zero exits become RED, fixing the deadlock where importing a non-existent component would block creating it
  - Enforcement hook checks the associated test's state for each impl file independently
  - Inject hook displays per-file states with test file identification
  - New functions: tdd_find_test_for_impl, tdd_read_state_for_impl, tdd_get_all_states, tdd_suggest_test_path, tdd_run_test_file

## 0.1.4

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.3

### Patch Changes

- adbd9e6: Fix TDD setup skill chicken-and-egg problem: allow edits during test setup by checking a PostToolUse:Skill marker, and fix skill name reference from wr-tdd:create to wr-tdd:setup-tests

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
