#!/usr/bin/env bats

# P159: retrospective-readme-jtbd-currency.sh PreToolUse:Bash hook must
# deny `git commit` invocations whose post-commit working tree exhibits
# JTBD-currency drift (no JTBD-NNN anchor in a plugin README, stale or
# deprecated-only citations, or skills/<dir>/ missing from the README).
# Hook-level enforcement at commit time replaces ADR-051 Phase 1's
# retro-time advisory surface, which the user correction (P159) and the
# architect verdict identify as too late: the most-common drift class
# (contributor adds skill/hook/agent and forgets the README) ships in a
# commit that doesn't touch README.md, so a retro-time consumer sees the
# drift only after the contributor has already committed.
#
# Detection delegates to the existing
# `packages/retrospective/scripts/check-readme-jtbd-currency.sh`
# detector, which the hook invokes against the project's working tree
# (`./packages/` + `./docs/jtbd/`). The hook reads the detector's
# `TOTAL packages=<N> with_jtbd=<M> drift_instances=<K>` summary line
# and denies when `drift_instances > 0`.
#
# Per ADR-005 (plugin testing strategy) — hook bats live under
# packages/<plugin>/hooks/test/ and assert on emitted JSON, not source
# content. Per ADR-052 / P081 — behavioural; no source greps. Per
# ADR-045 Pattern 1 — allow paths emit 0 bytes; deny-band ≤300 bytes.
# Per ADR-013 Rule 1 — deny redirects to mechanical recovery (here: the
# wr-jtbd:agent for prose-weaving guidance, with hand-edit fallback).
# Per ADR-013 Rule 6 — fail-open outside a git work tree, on parse
# errors, or in projects without ADR-051's structural anchors
# (./packages/ or ./docs/jtbd/) so adopter projects are not blocked.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/retrospective-readme-jtbd-currency.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  echo "seed" > seed.txt
  git add seed.txt
  git -c commit.gpgsign=false commit --quiet -m "initial"
  unset BYPASS_JTBD_CURRENCY
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
  unset BYPASS_JTBD_CURRENCY
}

run_bash_hook() {
  local cmd="$1"
  local json
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  echo "$json" | bash "$HOOK"
}

# Helper: build a stub project layout with a drifted plugin README.
# README has no JTBD-NNN citation; jtbd dir has one resolving job.
make_drifted_project() {
  mkdir -p packages/stub docs/jtbd/plugin-user
  printf '%s\n' "# @windyroad/stub" "no jtbd anchor here" > packages/stub/README.md
  cat > docs/jtbd/plugin-user/JTBD-302-trust-readme.proposed.md <<'EOF'
---
status: proposed
job-id: trust-readme
persona: plugin-user
date-created: 2026-05-04
---

# JTBD-302
EOF
}

# Helper: build a stub project layout with a clean plugin README.
# README cites a resolving JTBD-NNN; no skill drift.
make_clean_project() {
  mkdir -p packages/stub docs/jtbd/plugin-user
  printf '%s\n' "# @windyroad/stub" "Serves JTBD-302." > packages/stub/README.md
  cat > docs/jtbd/plugin-user/JTBD-302-trust-readme.proposed.md <<'EOF'
---
status: proposed
job-id: trust-readme
persona: plugin-user
date-created: 2026-05-04
---

# JTBD-302
EOF
}

# Helper: build a stub project with skill-inventory-drift —
# packages/stub/skills/orphan/ exists but README doesn't name "orphan".
make_skill_drift_project() {
  mkdir -p packages/stub/skills/orphan docs/jtbd/plugin-user
  printf '%s\n' "# @windyroad/stub" "Serves JTBD-302." > packages/stub/README.md
  cat > docs/jtbd/plugin-user/JTBD-302-trust-readme.proposed.md <<'EOF'
---
status: proposed
job-id: trust-readme
persona: plugin-user
date-created: 2026-05-04
---

# JTBD-302
EOF
}

# ── Trap detection: deny when drift detected ───────────────────────────────

@test "deny: drifted README (no JTBD-NNN cite) on git commit triggers deny" {
  make_drifted_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
  [[ "$output" == *"P159"* ]]
}

@test "deny: skill-inventory-drift on git commit triggers deny" {
  make_skill_drift_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny message names the offending plugin slug" {
  make_drifted_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"stub"* ]]
}

@test "deny message names the wr-jtbd:agent recovery path" {
  make_drifted_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-jtbd"* ]]
}

@test "deny message stays under ADR-045 deny-band (<300 bytes)" {
  make_drifted_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 300 ]
}

@test "deny: chore release commit (chore: version packages) is subject to the gate" {
  make_drifted_project
  run run_bash_hook "chore: version packages"
  # Not a `git commit` invocation — should NOT trigger deny because the
  # command field is the message, not the invocation. The actual release
  # path runs `git commit` which IS gated; verify that shape:
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]

  # Now the canonical release commit shape:
  run run_bash_hook "git commit -m 'chore: version packages'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

@test "deny: git commit --amend on drifted tree also triggers deny" {
  make_drifted_project
  run run_bash_hook "git commit --amend --no-edit"
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"permissionDecision\": \"deny\""* ]]
}

# ── Allow paths: each non-trap shape must NOT deny ─────────────────────────

@test "allow: clean README (cites resolving JTBD-NNN) on git commit allows the commit" {
  make_clean_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: BYPASS_JTBD_CURRENCY=1 env var allows drifted commit" {
  make_drifted_project
  BYPASS_JTBD_CURRENCY=1 run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: non-Bash tool exits 0 without deny" {
  make_drifted_project
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: Bash command that is NOT git commit (e.g., git status) bypasses detection" {
  make_drifted_project
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# ── Fail-open contracts (ADR-013 Rule 6) ───────────────────────────────────

@test "allow: outside a git work tree exits 0 without deny (fail-open)" {
  cd "$ORIG_DIR"
  TEMP_NONGIT=$(mktemp -d)
  cd "$TEMP_NONGIT"
  run run_bash_hook "git commit -m 'feat'"
  cd "$TEST_DIR"
  rm -rf "$TEMP_NONGIT"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: project without packages/ dir exits 0 without deny (fail-open)" {
  # No packages/, no docs/jtbd/ — adopter project shape.
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: project with packages/ but no docs/jtbd/ exits 0 without deny (fail-open)" {
  mkdir -p packages/stub
  echo "# stub" > packages/stub/README.md
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: empty JSON exits 0 without deny (fail-open on parse-incomplete)" {
  make_drifted_project
  run bash -c "echo '{}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

@test "allow: malformed JSON exits 0 without deny (fail-open on parse error)" {
  make_drifted_project
  run bash -c "echo 'not-json' | bash $HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"\"permissionDecision\": \"deny\""* ]]
}

# ── Allow path silence (ADR-045 Pattern 1) ─────────────────────────────────

@test "allow path on clean tree emits 0 bytes (ADR-045 Pattern 1 silent-on-pass)" {
  make_clean_project
  run run_bash_hook "git commit -m 'feat'"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

@test "allow path on non-Bash tool emits 0 bytes (silent-on-pass)" {
  make_drifted_project
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.md\"}}' | bash $HOOK"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

@test "allow path on non-commit Bash emits 0 bytes (silent-on-pass)" {
  make_drifted_project
  run run_bash_hook "git status"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}
