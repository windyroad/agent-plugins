#!/usr/bin/env bats
# P317 / RFC-009 T1 + ADR-049: the create-gate marker commands resolve their
# sibling libs RELATIVE TO THE SCRIPT (adopter-safe), not relative to cwd. The
# bug they fix: SKILLs did `source packages/itil/hooks/lib/*.sh`, which only
# resolves in the source monorepo and breaks in adopter installs.
#
# Behavioural — simulates an adopter install by copying the shipped script +
# lib tree to a temp dir in the SAME relative layout, then invokes from a
# FOREIGN cwd (an "adopter repo" with no packages/ tree) and asserts success.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  INSTALL="$(mktemp -d)"
  mkdir -p "$INSTALL/scripts" "$INSTALL/hooks/lib" "$INSTALL/bin"
  cp "$REPO_ROOT/packages/itil/scripts/mark-create-gate.sh" "$INSTALL/scripts/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/scripts/mark-rfc-capture-gate.sh" "$INSTALL/scripts/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/bin/wr-itil-mark-create-gate" "$INSTALL/bin/" 2>/dev/null || true
  cp "$REPO_ROOT/packages/itil/bin/wr-itil-mark-rfc-capture-gate" "$INSTALL/bin/" 2>/dev/null || true
  cp "$REPO_ROOT"/packages/itil/hooks/lib/*.sh "$INSTALL/hooks/lib/" 2>/dev/null || true
  FOREIGN="$(mktemp -d)"   # an adopter repo cwd — no packages/ tree
  MARKERS="$(mktemp -d)"   # empty announce-marker dir so candidates = CLAUDE_SESSION_ID only
  SID="p317-test-$$-${RANDOM}"
}

teardown() {
  rm -rf "$INSTALL" "$FOREIGN" "$MARKERS"
  rm -f "/tmp/manage-problem-grep-$SID" "/tmp/wr-itil-rfc-capture-grep-$SID"
}

@test "mark-create-gate.sh runs from a foreign cwd, resolving libs from its own location (P317)" {
  cd "$FOREIGN"
  run env CLAUDE_SESSION_ID="$SID" SESSION_MARKER_DIR="$MARKERS" bash "$INSTALL/scripts/mark-create-gate.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file"* ]]
  [[ "$output" != *"command not found"* ]]
  [ -f "/tmp/manage-problem-grep-$SID" ]
}

@test "wr-itil-mark-create-gate shim dispatches the script from a foreign cwd (P317/ADR-049)" {
  cd "$FOREIGN"
  run env CLAUDE_SESSION_ID="$SID" SESSION_MARKER_DIR="$MARKERS" bash "$INSTALL/bin/wr-itil-mark-create-gate"
  [ "$status" -eq 0 ]
  [ -f "/tmp/manage-problem-grep-$SID" ]
}

@test "mark-rfc-capture-gate.sh writes the RFC-tier marker from a foreign cwd (P317)" {
  cd "$FOREIGN"
  run env CLAUDE_SESSION_ID="$SID" SESSION_MARKER_DIR="$MARKERS" bash "$INSTALL/scripts/mark-rfc-capture-gate.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file"* ]]
  [ -f "/tmp/wr-itil-rfc-capture-grep-$SID" ]
}

@test "wr-itil-mark-rfc-capture-gate shim dispatches from a foreign cwd (P317/ADR-049)" {
  cd "$FOREIGN"
  run env CLAUDE_SESSION_ID="$SID" SESSION_MARKER_DIR="$MARKERS" bash "$INSTALL/bin/wr-itil-mark-rfc-capture-gate"
  [ "$status" -eq 0 ]
  [ -f "/tmp/wr-itil-rfc-capture-grep-$SID" ]
}
