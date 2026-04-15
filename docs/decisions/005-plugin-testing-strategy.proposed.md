---
status: "proposed"
date: 2026-04-12
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-12
---

# Plugin Testing Strategy

## Context and Problem Statement

The plugin suite has 10 plugins with ~40 shell hook scripts, 11 skills, and 5 agent definitions. During development, multiple bugs were discovered only through manual testing in live sessions:

- Risk-scorer grep patterns using dashes instead of colons (agent name mismatch)
- Missing `gate-helpers.sh` in 3 packages (undefined functions, garbage TTL values)
- JTBD `store_review_hash` using wrong policy file path (drift always detected)
- Architect verdict file not session-scoped (concurrent session race condition)
- TDD enforce hook blocking its own setup skill (chicken-and-egg)
- Retrospective plugin enforcing reviews from external agents

Each bug required a push, marketplace update, plugin reinstall, and session restart cycle to test. There is no automated test suite. The existing `risk-gate.bats` file in the risk-scorer package is the only test file in the repo and it's unclear if it still passes.

A test strategy is needed to catch these classes of bugs before they reach users.

## Decision Drivers

- **Catch hook bugs before release**: Pattern matching, marker creation, drift detection, and JSON output all need validation
- **Existing precedent**: `bats-core` is already used in the risk-scorer package
- **CI integration**: Tests should run in the GitHub Actions CI pipeline as a quality gate
- **Shell-native testing**: Hooks are bash scripts; testing them with a bash-native tool avoids the impedance mismatch of testing shell from JS
- **Monorepo structure**: Each package should own its tests, but shared helpers (`gate-helpers.sh`, `review-gate.sh`) need testing too

## Considered Options

### Option 1: bats-core for Hook Unit Tests + CI Integration

Use `bats-core` (Bash Automated Testing System) for unit testing individual hook functions and behaviors. Each package gets a `hooks/test/` directory with `.bats` files. CI runs all tests as a quality gate.

### Option 2: Node.js (vitest) for All Testing

Use vitest to test hooks via `child_process.execSync`, parsing stdout/stderr. Single test framework, familiar to JS developers, but adds shell-to-JS translation overhead.

### Option 3: No Automated Tests (Status Quo)

Continue manual testing via live sessions. Accept the push, reinstall, restart cycle for bug verification.

## Decision Outcome

Chosen option: **"Option 1 -- bats-core for Hook Unit Tests + CI Integration"**, because hooks are bash scripts and bats-core tests them natively without translation overhead. There's already a precedent in the repo (`risk-gate.bats`), and bats-core integrates cleanly with CI via TAP output.

## Test Architecture

### What to Test

**Hook functions** (unit tests):
- `tdd_classify_file` -- returns correct type for test, exempt, and impl files
- `tdd_has_test_script` -- detects presence/absence of test script in package.json
- `check_review_gate` -- TTL, drift detection, marker existence
- `check_architect_gate` -- TTL, drift detection, marker existence
- `check_risk_gate` -- TTL, drift, threshold, bypass markers
- `store_review_hash` / `_hashcmd` / `_mtime` -- hash computation and file modification time

**Hook scripts** (integration tests):
- Simulated hook input JSON to assert correct output JSON (deny/allow)
- Marker creation after simulated PostToolUse agent completion
- Pattern matching on subagent_type (colon-style names)
- Verdict parsing from agent output text

**CI pipeline**:
- All bats tests run as a step in `.github/workflows/ci.yml`
- Failure blocks merge

### Test File Location

```
packages/{plugin}/hooks/test/*.bats    # per-package hook tests
packages/shared/test/*.bats            # shared helper tests (if any)
```

### Test Conventions

- Each `.bats` file tests one hook script or one shared library
- Test names describe the scenario: `@test "classify_file returns exempt for .config.ts files"`
- Fixtures go in `hooks/test/fixtures/` (sample JSON inputs, mock package.json files)
- Use `setup()` and `teardown()` for temp file cleanup

### Behavioural assertions must be functional, not source-grep (P011)

Tests for hook **behaviour** (does this file path get blocked? does this
exclusion apply?) MUST execute the hook with mock JSON input and assert
on exit status and output text. They must NOT grep the hook's source
file for expected patterns.

Source-grep assertions over-specify the implementation. They pass when
the literal pattern appears in source — even if the surrounding code
no longer applies it — and they false-positive on legitimate refactors
that change the pattern's text without changing behaviour. P011
documents two such regressions in `jtbd-enforce-scope.bats`; converting
the suite to functional tests immediately surfaced three real bugs in
the hook's exclusion patterns that the source-greps had missed.

**Permitted exceptions** (structural, not behavioural):

- `hooks.json` content checks (e.g., `! grep -q '"Stop"' hooks.json`) —
  asserting the absence/presence of a hook registration in a config
  file is a contract assertion, not a behavioural one.
- File-existence / file-removed checks (e.g.,
  `architect-reset-marker.sh has been removed`).

**Functional pattern**:

```bash
run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "enforce: excludes lockfiles" {
  run run_hook_with_file "$PWD/package-lock.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}
```

Use `$PWD`-prefixed paths so the test data matches the absolute
`file_path` that Claude Code passes in real invocations (and so the
P004 project-root check resolves correctly).

## Consequences

### Good

- Catches pattern matching bugs (grep dashes vs colons) before release
- Catches missing files (gate-helpers.sh) via import errors in test
- Catches hash path mismatches (JTBD docs/jtbd vs docs/JOBS_TO_BE_DONE.md)
- Tests run in CI; bugs blocked before merge
- bats-core is lightweight, no compile step, pure bash

### Neutral

- Adds `bats-core` as a devDependency (or installed via npm/brew in CI)
- Test files add to repo size but are excluded from npm packages via `files` field
- Each new hook should have a corresponding test, which adds development overhead

### Bad

- bats-core cannot test agent behavior (agent output parsing is tested, but not whether the agent produces the right output)
- Cannot test the full install, review, edit, commit cycle (that requires a running Claude Code session)
- Shell test fixtures (mock JSON input) can diverge from actual Claude Code hook input format if the format changes

## Confirmation

- `bats` command runs all `.bats` files in the repo and exits 0
- CI quality gate includes a "Run hook tests" step that fails on test failure
- Each package with hooks has at least one `.bats` file in `hooks/test/`
- The risk-scorer's existing `risk-gate.bats` passes

## Pros and Cons of the Options

### Option 1: bats-core

- Good: Native bash testing, no impedance mismatch
- Good: Existing precedent in the repo
- Good: Lightweight, fast, TAP output for CI
- Good: Tests hook functions directly (source the library, call the function)
- Bad: Another tool to install (bats-core + bats-support + bats-assert)
- Bad: Cannot test full agent workflow end-to-end

### Option 2: vitest

- Good: Single test framework for everything (JS + shell)
- Good: Familiar to JS developers
- Bad: Testing shell via child_process is clunky, string matching on stdout
- Bad: Cannot source bash functions directly, must test entire scripts as black boxes
- Bad: Adds JS test infra (vitest, config) to a repo that's primarily shell scripts

### Option 3: Status Quo

- Good: No setup overhead
- Bad: Bugs reach users via broken marketplace installs
- Bad: Manual test cycle is slow (push, reinstall, restart, verify)
- Bad: Regression bugs reappear when refactoring

## Reassessment Criteria

- **Agent testing capability**: If Claude Code adds a way to test agent behavior programmatically (mock sessions), consider adding agent integration tests.
- **Plugin count grows**: If the suite grows beyond 15 plugins, consider whether test infrastructure needs tooling (test runner scripts, parallel execution).
- **CI run time**: If bats tests exceed 60 seconds, consider splitting into per-package test jobs.
