#!/usr/bin/env bats

# Behavioural tests for the plugin-staleness surfacer hook
# (ADR-088 / RFC-036 / P045 / P375).
#
# The hook self-locates its own version + plugin key from its script path
# (installed layout: <cache>/windyroad/<key>/<version>/hooks/staleness-check.sh)
# and compares against the highest semver-named sibling version dir. That
# self-location is what makes it testable WITHOUT mocking the real plugin
# cache: each test stages the canonical script inside a fake versioned
# layout under BATS_TEST_TMPDIR and creates sibling version dirs.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  CANONICAL="$REPO_ROOT/packages/shared/hooks/staleness-check.sh"

  # Fake plugin cache: <tmp>/windyroad/wr-test/<version>/hooks/staleness-check.sh
  CACHE="$BATS_TEST_TMPDIR/windyroad/wr-test"
  TEST_SID="stale-test-$$-$RANDOM"
}

teardown() {
  rm -f /tmp/wr-staleness-announced-"${TEST_SID}"-* 2>/dev/null || true
}

# Stage the canonical hook at <key>/<version>/hooks/ and create the given
# sibling version dirs. Usage: stage_version 0.1.0 0.1.0 0.2.0
stage_version() {
  local self="$1"; shift
  mkdir -p "$CACHE/$self/hooks"
  cp "$CANONICAL" "$CACHE/$self/hooks/staleness-check.sh"
  chmod +x "$CACHE/$self/hooks/staleness-check.sh"
  local v
  for v in "$@"; do mkdir -p "$CACHE/$v"; done
  SELF_HOOK="$CACHE/$self/hooks/staleness-check.sh"
}

# Unset WR_SUPPRESS_OVERSIGHT_NUDGE: an AFK iteration exports it =1, which
# would suppress every advisory and mask real behaviour (the documented
# bats-pollution trap). The dedicated AFK test re-sets it explicitly.
run_hook() {
  run env -u WR_SUPPRESS_OVERSIGHT_NUDGE bash -c "printf '%s' '{\"session_id\":\"$TEST_SID\"}' | '$SELF_HOOK'"
}

@test "canonical hook exists and is executable" {
  [ -x "$CANONICAL" ]
}

@test "behind: emits one advisory line naming key, self version, and highest" {
  stage_version 0.1.0 0.1.0 0.2.0
  run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-test"* ]]
  [[ "$output" == *"0.1.0"* ]]
  [[ "$output" == *"0.2.0"* ]]
  [[ "$output" == *"restart"* ]]
}

@test "current: silent when session is on the highest installed version" {
  stage_version 0.2.0 0.1.0 0.2.0
  run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ahead: silent when session version exceeds every installed version" {
  stage_version 0.3.0 0.1.0 0.2.0
  run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "unchanged: advisory emitted once, silent on subsequent same-session turns" {
  stage_version 0.1.0 0.1.0 0.2.0
  run_hook
  [ -n "$output" ]
  run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "version advances mid-session: advisory re-emitted once for the new version" {
  stage_version 0.1.0 0.1.0 0.2.0
  run_hook
  [[ "$output" == *"0.2.0"* ]]
  run_hook
  [ -z "$output" ]           # deduped for 0.2.0
  mkdir -p "$CACHE/0.3.0"    # newer version installed mid-session
  run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"0.3.0"* ]]
}

@test "not in versioned cache: fail-open silent when own dir is not semver" {
  # Stage under a non-semver 'self' dir so version inference yields no semver.
  mkdir -p "$CACHE/main/hooks"
  cp "$CANONICAL" "$CACHE/main/hooks/staleness-check.sh"
  mkdir -p "$CACHE/0.2.0"
  SELF_HOOK="$CACHE/main/hooks/staleness-check.sh"
  run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "SHA-residual sibling dirs are ignored by the semver filter" {
  stage_version 0.1.0 0.1.0 0.2.0
  mkdir -p "$CACHE/2287c49f7b4b"   # git-source SHA residual — must NOT win sort
  run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"0.2.0"* ]]     # highest semver, not the SHA
}

@test "AFK-launched: suppressed even when behind" {
  stage_version 0.1.0 0.1.0 0.2.0
  run bash -c "WR_SUPPRESS_OVERSIGHT_NUDGE=1 printf '%s' '{\"session_id\":\"$TEST_SID\"}' | WR_SUPPRESS_OVERSIGHT_NUDGE=1 '$SELF_HOOK'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no session_id: still surfaces (no dedup marker path with empty id)" {
  stage_version 0.1.0 0.1.0 0.2.0
  run env -u WR_SUPPRESS_OVERSIGHT_NUDGE bash -c "printf '%s' '{}' | '$SELF_HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0.2.0"* ]]
}
