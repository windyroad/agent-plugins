#!/usr/bin/env bats
# Tests for git-push-gate.sh — gh pr merge block and release:watch guidance

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$HOOKS_DIR/git-push-gate.sh"

  TEST_SESSION="bats-push-gate-$$-${BATS_TEST_NUMBER}"
  # Ensure a clean risk dir
  RDIR="${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
  rm -rf "$RDIR"
  mkdir -p "$RDIR"

  # Create a temp project dir for package.json detection
  TEST_PROJECT_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$RDIR"
  rm -rf "$TEST_PROJECT_DIR"
}

# Helper: build a PreToolUse Bash input with a given command
build_input() {
  local cmd="$1"
  cat <<ENDJSON
{
  "session_id": "$TEST_SESSION",
  "tool_name": "Bash",
  "tool_input": {
    "command": "$cmd"
  }
}
ENDJSON
}

@test "gh pr merge is blocked with release:watch guidance when script exists" {
  # Create a package.json with release:watch
  cat > "$TEST_PROJECT_DIR/package.json" <<'PKG'
{ "scripts": { "release:watch": "bash scripts/release-watch.sh" } }
PKG

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$TEST_PROJECT_DIR' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"release:watch"* ]]
}

@test "gh pr merge tells agent to create release:watch when script missing" {
  # Create a package.json WITHOUT release:watch
  cat > "$TEST_PROJECT_DIR/package.json" <<'PKG'
{ "scripts": { "test": "echo test" } }
PKG

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$TEST_PROJECT_DIR' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  # Should tell agent to create the script
  [[ "$output" == *"no release:watch script"* ]]
  [[ "$output" == *"gh pr merge"* ]]
  [[ "$output" == *"gh run watch"* ]]
}

@test "gh pr merge tells agent to create release:watch when no package.json" {
  local empty_dir="$(mktemp -d)"

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$empty_dir' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  # Should tell agent to create the script
  [[ "$output" == *"no release:watch script"* ]]
  [[ "$output" == *"gh pr merge"* ]]
  [[ "$output" == *"gh run watch"* ]]

  rm -rf "$empty_dir"
}

# ── gh pr merge: release-PR-scoped deny ─────────────────────────────────────
#
# The deny exists to protect the changesets release PR, whose merge flips
# the publish boundary and must be watched by `npm run release:watch`. An
# ordinary feature/worktree branch PR merging into main is not that, and
# blocking it left sessions with a green PR and no way to land it.
#
# Head branch is resolved with `gh pr view --json headRefName`; a lookup
# that fails for any reason (no gh, no auth, no repo, timeout) falls
# through to the existing deny — fail closed.

# Put a fake `gh` on PATH that reports a given head branch.
stub_gh() {
  local head_ref="$1" exit_code="${2:-0}"
  mkdir -p "$TEST_PROJECT_DIR/bin"
  cat > "$TEST_PROJECT_DIR/bin/gh" <<STUB
#!/usr/bin/env bash
echo "$head_ref"
exit $exit_code
STUB
  chmod +x "$TEST_PROJECT_DIR/bin/gh"
}

pkg_with_release_watch() {
  cat > "$TEST_PROJECT_DIR/package.json" <<'PKG'
{ "scripts": { "release:watch": "bash scripts/release-watch.sh" } }
PKG
}

@test "gh pr merge of the changeset release PR is still denied" {
  pkg_with_release_watch
  stub_gh "changeset-release/main"

  INPUT=$(build_input "gh pr merge 471 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"release:watch"* ]]
}

@test "gh pr merge of a feature branch PR is allowed" {
  pkg_with_release_watch
  stub_gh "fix/stripe-customer-email"

  INPUT=$(build_input "gh pr merge 437 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}

@test "gh pr merge with no PR argument resolves the current branch and is allowed" {
  pkg_with_release_watch
  stub_gh "worktree/sad-ramanujan"

  INPUT=$(build_input "gh pr merge --squash --delete-branch")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}

@test "gh pr merge is denied when the head branch lookup fails" {
  pkg_with_release_watch
  stub_gh "" 1

  INPUT=$(build_input "gh pr merge 437 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "a branch merely prefixed like the release branch is not swept into the deny" {
  pkg_with_release_watch
  stub_gh "wip-changeset-release/experiment"

  INPUT=$(build_input "gh pr merge 500 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}

@test "the release branch prefix is overridable for a non-default changesets setup" {
  pkg_with_release_watch
  stub_gh "releases/v2"

  INPUT=$(build_input "gh pr merge 512 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && WR_RELEASE_BRANCH_PREFIX=releases/ && export WR_RELEASE_BRANCH_PREFIX && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"release:watch"* ]]
}

@test "the default release prefix still applies when the override is unset" {
  pkg_with_release_watch
  stub_gh "releases/v2"

  INPUT=$(build_input "gh pr merge 512 --squash")
  run bash -c "cd '$TEST_PROJECT_DIR' && PATH='$TEST_PROJECT_DIR/bin:$PATH' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]
}
