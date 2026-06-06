#!/usr/bin/env bats
# Tests for the CI-status precondition in the push/release gate.
#
# Closes P208 (known-error): git-push-gate.sh did not consult CI health
# before scoring push/release risk, so a push could land on a CI-red
# master and a release could ship broken code.
#
# Contract:
# - `check_ci_status` queries `gh run list --branch <current-branch>
#   --limit 1 --json status,conclusion,databaseId,url` for the current
#   branch and returns 0 (allow) / 1 (deny).
# - Deny on conclusion ∈ {failure, cancelled, timed_out, action_required,
#   startup_failure}.
# - Deny on status ∈ {queued, in_progress, pending, requested, waiting}.
# - Allow on conclusion ∈ {success, skipped, neutral} or unknown.
# - Empty array (no CI history yet) → allow. Handles the documented
#   "first push triggers CI" case naturally — no bypass marker required.
# - `gh` failure (auth/timeout/API error) → DENY (fail-closed per the
#   safe-high-fix-risk classifier on P208).
# - `${RDIR}/ci-bypass-${ACTION}` one-shot bypass marker — consumed on
#   use, same family as reducing-push / incident-release.
# - Integration: in git-push-gate.sh, the ordering is bypass-markers →
#   CI status → risk gate. The `incident-release` bypass MUST short-
#   circuit BEFORE the CI check fires (per JTBD-201 + ADR-018).

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$HOOKS_DIR/lib/gate-helpers.sh"
  source "$HOOKS_DIR/lib/risk-gate.sh"

  TEST_SESSION="bats-ci-gate-$$-${BATS_TEST_NUMBER}"
  RDIR=$(_risk_dir "$TEST_SESSION")
  rm -rf "$RDIR"
  mkdir -p "$RDIR"

  # Stand up a fake git repo so `git rev-parse --abbrev-ref HEAD` resolves.
  TEST_REPO="$(mktemp -d)"
  ( cd "$TEST_REPO" && git init -q -b main && \
      git -c user.email=t@e -c user.name=t commit --allow-empty -q -m "init" )

  # Stub `gh` on PATH. The stub reads $FAKE_GH_OUTPUT and $FAKE_GH_EXIT
  # for behaviour. PATH ordering: stub dir first.
  STUB_DIR="$(mktemp -d)"
  cat > "$STUB_DIR/gh" <<'STUB'
#!/bin/bash
if [ -n "${FAKE_GH_DELAY:-}" ]; then sleep "$FAKE_GH_DELAY"; fi
if [ -n "${FAKE_GH_OUTPUT:-}" ]; then
  printf '%s' "$FAKE_GH_OUTPUT"
fi
exit "${FAKE_GH_EXIT:-0}"
STUB
  chmod +x "$STUB_DIR/gh"
  # `timeout` may not exist on the path on some macOS setups — stub a
  # passthrough for portability. Tests inject FAKE_GH_DELAY only when
  # they specifically test timeout behaviour.
  ORIG_PATH="$PATH"
  export PATH="$STUB_DIR:$PATH"
  export TEST_REPO STUB_DIR
}

teardown() {
  rm -rf "$RDIR" "$TEST_REPO" "$STUB_DIR"
  export PATH="$ORIG_PATH"
  unset FAKE_GH_OUTPUT FAKE_GH_EXIT FAKE_GH_DELAY CI_GATE_REASON CI_GATE_CATEGORY 2>/dev/null || true
}

# Run check_ci_status inside the fake repo so branch resolution works.
_run_check() {
  local action="$1"
  CI_GATE_REASON=""
  CI_GATE_CATEGORY=""
  ( cd "$TEST_REPO" && \
      FAKE_GH_OUTPUT="${FAKE_GH_OUTPUT:-}" FAKE_GH_EXIT="${FAKE_GH_EXIT:-0}" \
      bash -c "source '$HOOKS_DIR/lib/gate-helpers.sh'; source '$HOOKS_DIR/lib/risk-gate.sh'; \
               if check_ci_status '$TEST_SESSION' '$action'; then echo ALLOW; \
               else echo \"DENY: \$CI_GATE_REASON\"; fi" )
}

@test "check_ci_status allows when latest CI run concluded success" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"success","databaseId":1,"url":"https://github.com/x/y/actions/runs/1"}]'
  result=$(_run_check "push")
  [[ "$result" == "ALLOW" ]]
}

@test "check_ci_status denies when latest CI run concluded failure (names conclusion + URL)" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":2,"url":"https://github.com/x/y/actions/runs/2"}]'
  result=$(_run_check "push")
  [[ "$result" == DENY:* ]]
  [[ "$result" == *"failure"* ]]
  [[ "$result" == *"https://github.com/x/y/actions/runs/2"* ]]
}

@test "check_ci_status denies when latest CI run concluded cancelled" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"cancelled","databaseId":3,"url":"https://github.com/x/y/actions/runs/3"}]'
  result=$(_run_check "release")
  [[ "$result" == DENY:* ]]
  [[ "$result" == *"cancelled"* ]]
}

@test "check_ci_status denies when latest CI run concluded timed_out" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"timed_out","databaseId":4,"url":"https://github.com/x/y/actions/runs/4"}]'
  result=$(_run_check "push")
  [[ "$result" == DENY:* ]]
  [[ "$result" == *"timed_out"* ]]
}

@test "check_ci_status denies when latest CI run status is in_progress" {
  export FAKE_GH_OUTPUT='[{"status":"in_progress","conclusion":null,"databaseId":5,"url":"https://github.com/x/y/actions/runs/5"}]'
  result=$(_run_check "push")
  [[ "$result" == DENY:* ]]
  [[ "$result" == *"in_progress"* ]]
}

@test "check_ci_status denies when latest CI run status is queued" {
  export FAKE_GH_OUTPUT='[{"status":"queued","conclusion":null,"databaseId":6,"url":"https://github.com/x/y/actions/runs/6"}]'
  result=$(_run_check "release")
  [[ "$result" == DENY:* ]]
  [[ "$result" == *"queued"* ]]
}

@test "check_ci_status allows when CI history is empty (first push triggers CI)" {
  export FAKE_GH_OUTPUT='[]'
  result=$(_run_check "push")
  [[ "$result" == "ALLOW" ]]
}

@test "check_ci_status denies when gh exits non-zero (fail-closed, safe-high-fix-risk)" {
  export FAKE_GH_OUTPUT=''
  export FAKE_GH_EXIT=1
  result=$(_run_check "push")
  [[ "$result" == DENY:* ]]
  # Must point at the ci-bypass marker for the documented override path.
  [[ "$result" == *"ci-bypass-push"* ]]
}

@test "check_ci_status allows when ci-bypass marker is present and consumes it" {
  : > "$RDIR/ci-bypass-push"
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":7,"url":"https://github.com/x/y/actions/runs/7"}]'
  result=$(_run_check "push")
  [[ "$result" == "ALLOW" ]]
  # Bypass markers are one-shot — same family as reducing-push / incident-release.
  [ ! -f "$RDIR/ci-bypass-push" ]
}

@test "check_ci_status bypass marker is action-scoped (push marker does not bypass release)" {
  : > "$RDIR/ci-bypass-push"
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":8,"url":"https://github.com/x/y/actions/runs/8"}]'
  result=$(_run_check "release")
  [[ "$result" == DENY:* ]]
  # push bypass must not have been consumed by a release check
  [ -f "$RDIR/ci-bypass-push" ]
}

@test "check_ci_status allows when conclusion is skipped" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"skipped","databaseId":9,"url":"https://github.com/x/y/actions/runs/9"}]'
  result=$(_run_check "push")
  [[ "$result" == "ALLOW" ]]
}

@test "check_ci_status allows when conclusion is neutral" {
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"neutral","databaseId":10,"url":"https://github.com/x/y/actions/runs/10"}]'
  result=$(_run_check "release")
  [[ "$result" == "ALLOW" ]]
}

# ---------------------------------------------------------------------------
# Integration: git-push-gate.sh ordering — bypass-markers → CI status → risk
# gate. JTBD-201 demands the incident-release bypass MUST short-circuit
# BEFORE the new CI-status check fires.
# ---------------------------------------------------------------------------

# Helper: build a PreToolUse Bash input with a given command
_build_input() {
  local cmd="$1"
  cat <<JSON
{
  "session_id": "$TEST_SESSION",
  "tool_name": "Bash",
  "tool_input": {
    "command": "$cmd"
  }
}
JSON
}

@test "git-push-gate.sh denies push:watch when CI is red even if risk score is within appetite" {
  # Within-appetite risk score
  echo "1" > "$RDIR/push"
  # Disable drift check (no stored hash file)
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":11,"url":"https://github.com/x/y/actions/runs/11"}]'

  INPUT=$(_build_input "npm run push:watch")
  output=$( cd "$TEST_REPO" && echo "$INPUT" | \
    FAKE_GH_OUTPUT="$FAKE_GH_OUTPUT" PATH="$STUB_DIR:$PATH" \
    "$HOOKS_DIR/git-push-gate.sh" )
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"failure"* ]]
}

@test "git-push-gate.sh denies release:watch when CI is red even if risk score is within appetite" {
  echo "1" > "$RDIR/release"
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":12,"url":"https://github.com/x/y/actions/runs/12"}]'

  INPUT=$(_build_input "npm run release:watch")
  output=$( cd "$TEST_REPO" && echo "$INPUT" | \
    FAKE_GH_OUTPUT="$FAKE_GH_OUTPUT" PATH="$STUB_DIR:$PATH" \
    "$HOOKS_DIR/git-push-gate.sh" )
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"failure"* ]]
}

@test "git-push-gate.sh allows release:watch when incident-release bypass is set, even if CI is red (JTBD-201)" {
  echo "9" > "$RDIR/release"
  : > "$RDIR/incident-release"
  # Even with a red CI conclusion, the incident bypass must short-circuit
  # both the CI check and the risk threshold.
  export FAKE_GH_OUTPUT='[{"status":"completed","conclusion":"failure","databaseId":13,"url":"https://github.com/x/y/actions/runs/13"}]'

  INPUT=$(_build_input "npm run release:watch")
  output=$( cd "$TEST_REPO" && echo "$INPUT" | \
    FAKE_GH_OUTPUT="$FAKE_GH_OUTPUT" PATH="$STUB_DIR:$PATH" \
    "$HOOKS_DIR/git-push-gate.sh" )
  # No permissionDecision means allow (exit 0 with no JSON).
  [[ "$output" != *"permissionDecision"* ]]
  # incident-release marker is one-shot — must be consumed
  [ ! -f "$RDIR/incident-release" ]
}

@test "git-push-gate.sh allows push:watch when CI history is empty (first push)" {
  echo "1" > "$RDIR/push"
  export FAKE_GH_OUTPUT='[]'

  INPUT=$(_build_input "npm run push:watch")
  output=$( cd "$TEST_REPO" && echo "$INPUT" | \
    FAKE_GH_OUTPUT="$FAKE_GH_OUTPUT" PATH="$STUB_DIR:$PATH" \
    "$HOOKS_DIR/git-push-gate.sh" )
  [[ "$output" != *"permissionDecision"* ]]
}
