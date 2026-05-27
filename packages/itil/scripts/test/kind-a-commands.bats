#!/usr/bin/env bats
# P317 / RFC-009 T2 + ADR-049: the KIND A wrapper commands resolve their
# canonical lib RELATIVE TO THE SCRIPT (`$(dirname)/../lib`), so they work in an
# adopter install — not just the source monorepo where `source packages/...`
# happened to resolve. Behavioural: simulate an install tree, invoke from a
# FOREIGN cwd, assert clean lib resolution.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  INSTALL="$(mktemp -d)"
  mkdir -p "$INSTALL/scripts" "$INSTALL/lib" "$INSTALL/bin"
  cp "$REPO_ROOT/packages/itil/scripts/run-migrate-problems-layout.sh" "$INSTALL/scripts/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/scripts/run-check-upstream-cache-staleness.sh" "$INSTALL/scripts/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/bin/wr-itil-migrate-problems-layout" "$INSTALL/bin/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/bin/wr-itil-check-upstream-cache-staleness" "$INSTALL/bin/" 2>/dev/null || true
  cp "$REPO_ROOT"/packages/itil/lib/*.sh "$INSTALL/lib/" 2>/dev/null || true
  FOREIGN="$(mktemp -d)"   # adopter repo cwd — no packages/ tree
}

teardown() {
  rm -rf "$INSTALL" "$FOREIGN"
}

@test "wr-itil-migrate-problems-layout resolves its lib from a foreign cwd, no-ops on empty dir (P317)" {
  cd "$FOREIGN"
  run bash "$INSTALL/bin/wr-itil-migrate-problems-layout" "$FOREIGN"
  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file"* ]]
  [[ "$output" != *"command not found"* ]]
}

@test "wr-itil-check-upstream-cache-staleness resolves its lib from a foreign cwd (P317)" {
  cd "$FOREIGN"
  run bash "$INSTALL/bin/wr-itil-check-upstream-cache-staleness" "$FOREIGN"
  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file"* ]]
  [[ "$output" != *"command not found"* ]]
  [[ "$output" != *"migrate_problems_to_per_state_layout: command not found"* ]]
}

@test "the direct script (not just the shim) also resolves its lib from a foreign cwd (P317)" {
  cd "$FOREIGN"
  run bash "$INSTALL/scripts/run-migrate-problems-layout.sh" "$FOREIGN"
  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file"* ]]
}
