#!/usr/bin/env bats

# @problem P267 — Codify derive-release-vehicle.sh helper for K→V release-cycle
#                 citation. K→V transitions composed by hand from inline
#                 pre-flight evidence are fragile to wrong-release-cited errors
#                 (observed 2026-05-18 session 7 iter 1 — P250's K→V cited
#                 P247's release refs). Helper makes citation deterministic.
#
# Contract: `derive-release-vehicle.sh <ticket-id> [<problems-dir>]` reads the
# ticket file for a changeset filename reference, walks `git log
# --diff-filter=D` for the deletion commit (chore: version packages), then
# resolves the merge PR + merge commit. Emits a structured citation block on
# stdout.
#
# Output (stdout, multi-line key:value block):
#   RELEASE_VEHICLE:
#     changeset: .changeset/<name>.md
#     version-packages-commit: <SHA>
#     pr: #<N>
#     merge-commit: <SHA>
#     release-date: <YYYY-MM-DD>
#
# Exit codes:
#   0 = OK (full citation emitted, OR de-facto-released graduated-holding
#       changeset whose code already shipped with a sibling release — P361)
#   1 = ticket file not found
#   2 = no changeset reference in ticket body
#   3 = changeset still present AND not de-facto-released (genuinely unreleased)
#   4 = deletion commit found but no merge PR / merge commit resolvable
#
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-022 (Verifying lifecycle — citation supports K→V transition)
# @adr ADR-014 (single-commit grain — helper is read-only, no commit impact)
# @adr ADR-005 (Plugin testing strategy — behavioural bats per P081)
# @jtbd JTBD-001 (Enforce Governance — deterministic citation prevents
#                 cross-cite errors)
# @jtbd JTBD-006 (Progress Backlog AFK — orchestrator per-iter K→V audit
#                 trail trustworthy)
# @jtbd JTBD-101 (Extend the Suite — sibling shim naming grammar)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/derive-release-vehicle.sh"
  FIXTURE_DIR="$(mktemp -d)"
  cd "$FIXTURE_DIR"
  git init -q -b main
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p docs/problems/known-error docs/problems/verifying .changeset
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "derive-release-vehicle: script exists" {
  [ -f "$SCRIPT" ]
}

@test "derive-release-vehicle: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Usage / argument errors ─────────────────────────────────────────────────

@test "derive-release-vehicle: no arguments → exit non-zero with usage" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "USAGE"
}

@test "derive-release-vehicle: ticket file not found → exit 1" {
  run "$SCRIPT" P999 docs/problems
  [ "$status" -eq 1 ]
  echo "$output" | grep -qi "not found"
}

# ── Exit 2: no changeset reference in body ──────────────────────────────────

@test "derive-release-vehicle: ticket body has no changeset reference → exit 2" {
  cat > docs/problems/known-error/100-no-changeset.md <<'EOF'
# Problem 100: No Changeset

**Status**: Known Error

## Description

This ticket body does NOT reference any .changeset filename.
EOF
  git add docs/problems/known-error/100-no-changeset.md
  git commit -q -m "init"

  run "$SCRIPT" P100 docs/problems
  [ "$status" -eq 2 ]
  echo "$output" | grep -qiE "no .?changeset|changeset.*reference"
}

# ── Exit 3: changeset still present (unreleased) ────────────────────────────

@test "derive-release-vehicle: changeset still in working tree (unreleased) → exit 3" {
  cat > .changeset/p101-unreleased.md <<'EOF'
---
'@windyroad/itil': patch
---

Stub for P101.
EOF
  cat > docs/problems/known-error/101-unreleased.md <<'EOF'
# Problem 101: Unreleased

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p101-unreleased.md`.
EOF
  git add .
  git commit -q -m "init"

  run "$SCRIPT" P101 docs/problems
  [ "$status" -eq 3 ]
  echo "$output" | grep -qi "unreleased\|not.*delet"
}

# ── Exit 0: de-facto-released graduated-holding changeset (P361) ─────────────

@test "derive-release-vehicle: graduated holding changeset whose code shipped with a sibling release → exit 0 de-facto-released" {
  # P361 / ADR-061 Rule 5 + P359: a changeset can be reinstated to
  # .changeset/ awaiting changelog attribution AFTER its code already shipped
  # with a sibling release. Present-in-tree must NOT read as unreleased.
  cat > .changeset/p211-graduated.md <<'EOF'
---
'@windyroad/itil': patch
---

P211 fix — held then graduated.
EOF
  cat > docs/problems/verifying/211-graduated.md <<'EOF'
# Problem 211: Graduated

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p211-graduated.md`.
EOF
  git add .
  git commit -q -m "feat(itil): P211 fix + changeset"   # commit A — the fix

  # Hold it out of the active release queue (ADR-042 Rule 7).
  mkdir -p docs/changesets-holding
  git mv .changeset/p211-graduated.md docs/changesets-holding/p211-graduated.md
  git commit -q -m "chore(itil): hold P211 changeset (above-appetite)"

  # A sibling release ships AFTER the fix landed (P359: code ships regardless).
  cat > .changeset/p999-sibling.md <<'EOF'
---
'@windyroad/itil': patch
---

Sibling fix.
EOF
  git add .changeset/p999-sibling.md
  git commit -q -m "feat(itil): sibling fix + changeset"
  git rm -q .changeset/p999-sibling.md
  git commit -q -m "chore: version packages"   # the published release bump

  # Graduate the held changeset back to .changeset/ awaiting attribution.
  mkdir -p .changeset
  git mv docs/changesets-holding/p211-graduated.md .changeset/p211-graduated.md
  git commit -q -m "chore(itil): graduate P211 changeset"

  run "$SCRIPT" P211 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "de-facto-released"
  echo "$output" | grep -q "changeset: .changeset/p211-graduated.md"
}

@test "derive-release-vehicle: fresh changeset added AFTER the last release → still exit 3 (not a false de-facto-released)" {
  # Guard: a prior release exists, but THIS changeset was added afterwards —
  # its code has NOT shipped. Its add-commit is a DESCENDANT of the last
  # version bump, so the is-ancestor discriminator must keep it at exit 3.
  cat > .changeset/p888-old.md <<'EOF'
---
'@windyroad/itil': patch
---

Old fix that did ship.
EOF
  git add .changeset/p888-old.md
  git commit -q -m "feat(itil): old fix + changeset"
  git rm -q .changeset/p888-old.md
  git commit -q -m "chore: version packages"   # prior release

  # Now add a NEW changeset AFTER the release — genuinely unreleased.
  mkdir -p .changeset
  cat > .changeset/p889-fresh.md <<'EOF'
---
'@windyroad/itil': patch
---

Fresh fix, not yet released.
EOF
  cat > docs/problems/known-error/889-fresh.md <<'EOF'
# Problem 889: Fresh

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p889-fresh.md`.
EOF
  git add .
  git commit -q -m "feat(itil): fresh fix + changeset"

  run "$SCRIPT" P889 docs/problems
  [ "$status" -eq 3 ]
  echo "$output" | grep -qi "unreleased"
}

# ── Exit 0: happy path — full citation emitted ──────────────────────────────

@test "derive-release-vehicle: happy path — full citation block on stdout" {
  # Set up the canonical release-cycle shape:
  #   commit A: ticket + changeset added
  #   commit B (on PR branch): chore: version packages — deletes changeset
  #   commit C (on main): merge commit referencing PR #42
  cat > .changeset/p102-happy.md <<'EOF'
---
'@windyroad/itil': patch
---

P102 happy-path fix.
EOF
  cat > docs/problems/known-error/102-happy.md <<'EOF'
# Problem 102: Happy

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p102-happy.md`.
EOF
  git add .
  git commit -q -m "feat(itil): P102 fix + changeset"

  # Simulate the changeset-release/main PR branch: version-packages commit
  # deletes the changeset; merge commit lands on main with a "#<N>" reference.
  git checkout -q -b changeset-release/main
  git rm -q .changeset/p102-happy.md
  git commit -q -m "chore: version packages"
  git checkout -q main
  git merge --no-ff -q changeset-release/main -m "Merge pull request #42 from windyroad/changeset-release/main"

  run "$SCRIPT" P102 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RELEASE_VEHICLE:"
  echo "$output" | grep -q "changeset: .changeset/p102-happy.md"
  echo "$output" | grep -qE "version-packages-commit: [0-9a-f]{7,40}"
  echo "$output" | grep -qE "pr: #42"
  echo "$output" | grep -qE "merge-commit: [0-9a-f]{7,40}"
  echo "$output" | grep -qE "release-date: [0-9]{4}-[0-9]{2}-[0-9]{2}"
}

@test "derive-release-vehicle: per-state subdir layout (verifying/) is reachable" {
  # ADR-031 per-state subdir — ticket may live in docs/problems/verifying/
  # post-K→V. Helper must dual-tolerantly find it.
  cat > .changeset/p103-subdir.md <<'EOF'
---
'@windyroad/itil': patch
---

P103.
EOF
  cat > docs/problems/verifying/103-subdir.md <<'EOF'
# Problem 103: Subdir

**Status**: Verification Pending

## Fix Strategy

Ship via `.changeset/p103-subdir.md`.
EOF
  git add .
  git commit -q -m "init"

  git checkout -q -b changeset-release/main
  git rm -q .changeset/p103-subdir.md
  git commit -q -m "chore: version packages"
  git checkout -q main
  git merge --no-ff -q changeset-release/main -m "Merge pull request #43 from windyroad/changeset-release/main"

  run "$SCRIPT" P103 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "changeset: .changeset/p103-subdir.md"
}

@test "derive-release-vehicle: accepts bare numeric ID (no P prefix)" {
  cat > .changeset/p104-bare.md <<'EOF'
---
'@windyroad/itil': patch
---

P104.
EOF
  cat > docs/problems/known-error/104-bare.md <<'EOF'
# Problem 104: Bare

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p104-bare.md`.
EOF
  git add .
  git commit -q -m "init"

  git checkout -q -b changeset-release/main
  git rm -q .changeset/p104-bare.md
  git commit -q -m "chore: version packages"
  git checkout -q main
  git merge --no-ff -q changeset-release/main -m "Merge pull request #44 from windyroad/changeset-release/main"

  # Plain "104" — no P prefix.
  run "$SCRIPT" 104 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RELEASE_VEHICLE:"
}

# ── Exit 4: deletion commit found but no merge PR resolvable ────────────────

@test "derive-release-vehicle: deletion on main branch, no merge PR → exit 4" {
  # Direct commit to main (no PR merge) — helper finds the deletion commit
  # but cannot resolve a #<N> merge PR. Exit 4.
  cat > .changeset/p105-no-pr.md <<'EOF'
---
'@windyroad/itil': patch
---

P105.
EOF
  cat > docs/problems/known-error/105-no-pr.md <<'EOF'
# Problem 105: No PR

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p105-no-pr.md`.
EOF
  git add .
  git commit -q -m "init"

  # Delete on main directly (no merge commit, no PR reference).
  git rm -q .changeset/p105-no-pr.md
  git commit -q -m "chore: version packages (direct)"

  run "$SCRIPT" P105 docs/problems
  [ "$status" -eq 4 ]
  echo "$output" | grep -qiE "no.*(merge|pr)|cannot resolve"
}

# ── Default problems-dir resolution ─────────────────────────────────────────

@test "derive-release-vehicle: defaults to ./docs/problems when problems-dir omitted" {
  cat > .changeset/p106-default.md <<'EOF'
---
'@windyroad/itil': patch
---

P106.
EOF
  cat > docs/problems/known-error/106-default.md <<'EOF'
# Problem 106: Default

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p106-default.md`.
EOF
  git add .
  git commit -q -m "init"

  git checkout -q -b changeset-release/main
  git rm -q .changeset/p106-default.md
  git commit -q -m "chore: version packages"
  git checkout -q main
  git merge --no-ff -q changeset-release/main -m "Merge pull request #46 from windyroad/changeset-release/main"

  # Omit problems-dir.
  run "$SCRIPT" P106
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "changeset: .changeset/p106-default.md"
}

# ── Bin shim parity ─────────────────────────────────────────────────────────

@test "derive-release-vehicle: bin shim wr-itil-derive-release-vehicle exists and is executable" {
  BIN="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-derive-release-vehicle"
  [ -f "$BIN" ]
  [ -x "$BIN" ]
}

@test "derive-release-vehicle: bin shim dispatches to the canonical script" {
  BIN="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-derive-release-vehicle"
  cat > .changeset/p107-shim.md <<'EOF'
---
'@windyroad/itil': patch
---

P107.
EOF
  cat > docs/problems/known-error/107-shim.md <<'EOF'
# Problem 107: Shim

**Status**: Known Error

## Fix Strategy

Ship via `.changeset/p107-shim.md`.
EOF
  git add .
  git commit -q -m "init"

  git checkout -q -b changeset-release/main
  git rm -q .changeset/p107-shim.md
  git commit -q -m "chore: version packages"
  git checkout -q main
  git merge --no-ff -q changeset-release/main -m "Merge pull request #47 from windyroad/changeset-release/main"

  run "$BIN" P107 docs/problems
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "RELEASE_VEHICLE:"
  echo "$output" | grep -q "pr: #47"
}
