#!/usr/bin/env bats

# @problem P149 — manage-problem Step 0 reconcile halt-on-drift directive
# doesn't distinguish uncommitted-rename-rooted drift (same-session pending,
# in-flow P094/P062 refresh will land it in the upcoming commit per ADR-014)
# from committed cross-session drift (must halt and route to
# /wr-itil:reconcile-readme).
#
# Contract: `classify-readme-drift.sh <drift-stdout-file> [<problems-dir>]`
# reads the captured stdout of reconcile-readme.sh exit-1 output AND the
# working-tree state via `git status --porcelain`, then classifies the drift.
#
# Output (stdout, one classification line):
#   INLINE_REFRESH covered=<N>            — every drift ID is the destination
#                                            of a staged rename in the working
#                                            tree; defer to in-flow P094/P062
#                                            refresh per ADR-014.
#   HALT_ROUTE_RECONCILE uncovered=<N>    — at least one drift ID is NOT
#                                            covered by a working-tree rename;
#                                            committed cross-session drift OR
#                                            mixed; route to
#                                            /wr-itil:reconcile-readme.
#
# Exit codes:
#   0 = INLINE_REFRESH
#   1 = HALT_ROUTE_RECONCILE
#   2 = parse error (drift-stdout-file missing or empty)
#
# @adr ADR-014 (single-commit grain — the carve-out preserves it for the
#               in-flow path while keeping cross-session drift safety)
# @adr ADR-005 (Plugin testing strategy — behavioural bats per P081)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK loop continuity)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — single-commit grain)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/classify-readme-drift.sh"
  FIXTURE_DIR="$(mktemp -d)"
  cd "$FIXTURE_DIR"
  git init -q
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p docs/problems
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "classify-readme-drift: script exists" {
  [ -f "$SCRIPT" ]
}

@test "classify-readme-drift: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Exit 0 (INLINE_REFRESH): every drift ID covered by staged rename ────────

@test "classify-readme-drift: single drift ID covered by staged rename → INLINE_REFRESH" {
  # Simulate the P148 scenario: prior session staged a rename for a ticket
  # transition; reconcile-readme observes the README is stale (still claims
  # the old status) and emits a DRIFT line. The in-flow P094/P062 refresh
  # at Step 5/Step 7 will reconcile the README in the same commit per
  # ADR-014.
  echo "stub" > docs/problems/148-foo.open.md
  git add docs/problems/148-foo.open.md
  git commit -q -m "init"
  git mv docs/problems/148-foo.open.md docs/problems/148-foo.verifying.md

  cat > drift.txt <<'EOF'
DRIFT    P148 wsjf-rankings: claims=open actual=verifying
MISSING  P148 verification-queue: actual=verifying
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "INLINE_REFRESH"
  echo "$output" | grep -q "covered=1"
}

@test "classify-readme-drift: multiple drift IDs all covered by staged renames → INLINE_REFRESH" {
  echo "stub" > docs/problems/100-aaa.open.md
  echo "stub" > docs/problems/101-bbb.open.md
  git add docs/problems/
  git commit -q -m "init"

  git mv docs/problems/100-aaa.open.md docs/problems/100-aaa.known-error.md
  git mv docs/problems/101-bbb.open.md docs/problems/101-bbb.verifying.md

  cat > drift.txt <<'EOF'
DRIFT    P100 wsjf-rankings: claims=open actual=known-error
DRIFT    P101 wsjf-rankings: claims=open actual=verifying
MISSING  P101 verification-queue: actual=verifying
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "INLINE_REFRESH"
  echo "$output" | grep -q "covered=2"
}

@test "classify-readme-drift: rename-with-modification (RM) is recognised as covered" {
  # `git mv` followed by an `Edit` to the renamed file's body shows up as
  # `RM` in `git status --porcelain` (rename + unstaged modification). The
  # carve-out must treat both `R ` and `RM` as covered.
  cat > docs/problems/200-xyz.open.md <<'EOF'
# Problem 200: XYZ
**Status**: Open
EOF
  git add docs/problems/200-xyz.open.md
  git commit -q -m "init"

  git mv docs/problems/200-xyz.open.md docs/problems/200-xyz.verifying.md
  # Modify the renamed file's content (without re-staging) — emits RM.
  cat >> docs/problems/200-xyz.verifying.md <<'EOF'

## Fix Released
Deployed in v0.99.0.
EOF

  cat > drift.txt <<'EOF'
DRIFT    P200 wsjf-rankings: claims=open actual=verifying
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "INLINE_REFRESH"
  echo "$output" | grep -q "covered=1"
}

# ── Exit 1 (HALT_ROUTE_RECONCILE): committed cross-session drift ────────────

@test "classify-readme-drift: single drift ID not covered by any rename → HALT_ROUTE_RECONCILE" {
  # Simulate the P118 originating scenario: a prior session committed a
  # ticket transition without staging the README refresh. The README is
  # stale; the working tree is clean (no pending rename). Halt and route
  # to /wr-itil:reconcile-readme.
  cat > docs/problems/074-foo.closed.md <<'EOF'
# Problem 074: Foo
**Status**: Closed
EOF
  git add docs/problems/074-foo.closed.md
  git commit -q -m "init"

  cat > drift.txt <<'EOF'
DRIFT    P074 wsjf-rankings: claims=open actual=closed
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HALT_ROUTE_RECONCILE"
  echo "$output" | grep -q "uncovered=1"
}

@test "classify-readme-drift: mixed (some covered, some uncovered) → HALT_ROUTE_RECONCILE" {
  # Mixed case: one ID has a staged rename, another is committed drift.
  # The architect's confirmation: mixed routes to halt (the safe path),
  # because reconcile-readme will resolve both, and the in-flow refresh
  # only handles the rename'd one.
  cat > docs/problems/074-foo.closed.md <<'EOF'
# Problem 074: Foo
**Status**: Closed
EOF
  cat > docs/problems/148-bar.open.md <<'EOF'
# Problem 148: Bar
**Status**: Open
EOF
  git add docs/problems/
  git commit -q -m "init"

  git mv docs/problems/148-bar.open.md docs/problems/148-bar.verifying.md

  cat > drift.txt <<'EOF'
DRIFT    P074 wsjf-rankings: claims=open actual=closed
DRIFT    P148 wsjf-rankings: claims=open actual=verifying
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HALT_ROUTE_RECONCILE"
  # Only P074 is uncovered.
  echo "$output" | grep -q "uncovered=1"
}

@test "classify-readme-drift: clean working tree (no renames) → HALT_ROUTE_RECONCILE for any drift" {
  cat > docs/problems/050-zzz.verifying.md <<'EOF'
# Problem 050: Zzz
**Status**: Verification Pending
EOF
  git add docs/problems/050-zzz.verifying.md
  git commit -q -m "init"

  cat > drift.txt <<'EOF'
MISSING  P050 verification-queue: actual=verifying
EOF

  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HALT_ROUTE_RECONCILE"
  echo "$output" | grep -q "uncovered=1"
}

# ── Exit 2: parse errors ────────────────────────────────────────────────────

@test "classify-readme-drift: missing drift-stdout-file → exit 2" {
  run "$SCRIPT" /nonexistent/drift.txt docs/problems
  [ "$status" -eq 2 ]
  echo "$output" | grep -qi "PARSE_ERROR"
}

@test "classify-readme-drift: empty drift-stdout-file → exit 2" {
  : > drift.txt
  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 2 ]
  echo "$output" | grep -qi "PARSE_ERROR"
}

@test "classify-readme-drift: no arguments → exit 2 with usage" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qi "USAGE"
}

# ── Default problems-dir resolution ─────────────────────────────────────────

@test "classify-readme-drift: defaults to ./docs/problems when problems-dir omitted" {
  echo "stub" > docs/problems/300-default.open.md
  git add docs/problems/300-default.open.md
  git commit -q -m "init"
  git mv docs/problems/300-default.open.md docs/problems/300-default.verifying.md

  cat > drift.txt <<'EOF'
DRIFT    P300 wsjf-rankings: claims=open actual=verifying
EOF

  run "$SCRIPT" drift.txt
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "INLINE_REFRESH"
}

# ── Non-git working tree (defensive — outside a repo) ───────────────────────

@test "classify-readme-drift: outside git repo with drift → HALT_ROUTE_RECONCILE (no rename evidence)" {
  # If the script is invoked from outside a git repo (defensive — should not
  # happen in the SKILL.md flow but safest fail-closed), there is no rename
  # evidence, so all drift is treated as uncovered.
  NON_GIT="$(mktemp -d)"
  cd "$NON_GIT"
  mkdir -p docs/problems
  cat > drift.txt <<'EOF'
DRIFT    P074 wsjf-rankings: claims=open actual=closed
EOF
  run "$SCRIPT" drift.txt docs/problems
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HALT_ROUTE_RECONCILE"
  cd /
  rm -rf "$NON_GIT"
}
