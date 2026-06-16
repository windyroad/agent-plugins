#!/usr/bin/env bats
# tdd-review: structural-permitted (justification: the doc-lint slice below
# asserts SKILL.md / ADR-032 prose contract — SKILL.md is the contract
# document per ADR-037 Permitted Exception; these guards catch prose drift
# away from the behavioural revert-and-proceed contract exercised above. The
# load-bearing core of this fixture is behavioural per ADR-052. harness-gap P012)
#
# Behavioural test: work-problems Step 0 PRE-FLIGHT subprocess failure handling
# (P358). Step 0b / 0c / 0d dispatch a /wr-itil:review-problems (or
# check-upstream-responses) pre-flight subprocess "same shape as Step 5". But a
# pre-flight is a NON-load-bearing cache-refresh dependency, NOT an iter (the
# loop body). When a pre-flight subprocess exits non-zero OR returns
# `is_error: true` (e.g. `API Error: The socket connection was closed
# unexpectedly`), the orchestrator's contract is NON-BLOCKING:
#   (1) revert any dirty (unstaged) partial cache/audit/README write the
#       pre-flight left (`git checkout -- docs/problems/ docs/audits/`);
#   (1b) if a dead pre-flight left STAGED residue, `git reset` then revert
#        (ADR-009 no-trust-window-extension — a dead is_error:true subprocess
#        must not seed the parent's commit);
#   (2) log a one-line annotation;
#   (3) proceed to Step 1 with the existing README.
# This is ORTHOGONAL to the Step 5 iter SALVAGE-vs-HALT axis (P261 / P214):
# that axis classifies an *iter's* is_error:true; this fixture classifies the
# *pre-flight role* — which NEVER salvages and NEVER halts the loop.
#
# The fake `claude` shim below re-creates the production shape: it dirties an
# unstaged cache file in the repo, then emits an is_error:true socket-closed
# JSON envelope (no commit). The harness re-implements the orchestrator's
# pre-flight failure contract (faithful to SKILL.md § "Step 0 pre-flight
# subprocess failure handling (P358)") and asserts the revert-and-proceed
# outcome across the input shapes. Adopters who copy the SKILL.md pre-flight
# block into their orchestrator should observe the same outcomes.
#
# @problem P358
# @rfc RFC-024
# @jtbd JTBD-006
#
# Cross-reference:
#   P358 (claude -p subprocess dispatch socket-closed; pre-flight is_error
#     handling gap) — driver ticket
#   RFC-024 (work-problems pre-flight subprocess failure handling) — fix vehicle
#   ADR-032 (governance skill invocation patterns — § "Pre-flight subprocess
#     failure handling — non-blocking revert-and-proceed (P358 amendment)") —
#     the iter-vs-pre-flight failure-semantics distinction this fixture pins
#   ADR-009 (gate-marker / no-trust-window-extension — staged residue git reset)
#   ADR-019 (preflight clean-tree reconciliation surface)
#   P261 / P214 (the iter is_error:true SALVAGE/HALT axis this is orthogonal to)
#   ADR-037 / ADR-052 (skill testing strategy — behavioural default; doc-lint
#     contract assertion is the Permitted Exception, marked above)

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="${TEST_TMP}/bin"
  mkdir -p "$FAKE_BIN"

  # Fake `claude` binary simulating a pre-flight subprocess of the socket-closed
  # class: it leaves a dirty (UNSTAGED by default) partial cache write in the
  # CWD git repo, then emits an is_error:true JSON envelope carrying the
  # socket-closed error string in `.result`. No commit. This matches the
  # 2026-06-10 P358 shape: a /wr-itil:review-problems pre-flight that partially
  # refreshed docs/problems/.upstream-cache.json then died with
  # `API Error: The socket connection was closed unexpectedly`.
  cat > "$FAKE_BIN/claude" <<'FAKE_EOF'
#!/usr/bin/env bash
# Test fake for work-problems Step 0 pre-flight failure-handling fixture.
# Dirties a partial cache write, then emits is_error:true socket-closed JSON.
mkdir -p docs/problems
printf 'partial-refresh-mid-die\n' >> docs/problems/.upstream-cache.json
if [ "${FAKE_STAGE_RESIDUE:-0}" = "1" ]; then
  git add docs/problems/.upstream-cache.json 2>/dev/null || true
fi
if [ "${FAKE_EXIT:-0}" != "0" ]; then
  printf '%s\n' '{"is_error":true,"result":"subprocess crashed"}'
  exit "${FAKE_EXIT}"
fi
printf '%s\n' '{"is_error":true,"result":"API Error: The socket connection was closed unexpectedly. For more information, pass `verbose: true`","total_cost_usd":0.0,"duration_ms":727000}'
FAKE_EOF
  chmod +x "$FAKE_BIN/claude"
  export PATH="$FAKE_BIN:$PATH"

  # A throwaway git repo so dirty-detection + the revert are real. Seed a
  # committed clean cache so the partial write is observably a dirty delta.
  REPO="${TEST_TMP}/repo"
  mkdir -p "$REPO/docs/problems"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name "Test"
  printf 'clean-cache\n' > "$REPO/docs/problems/.upstream-cache.json"
  git -C "$REPO" add docs/problems/.upstream-cache.json
  git -C "$REPO" commit -q -m "root: clean cache"

  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  ADR_FILE="$(cd "${SKILL_DIR}/../../../.." && pwd)/docs/decisions/032-governance-skill-invocation-patterns.proposed.md"
}

teardown() {
  if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# Faithful re-implementation of SKILL.md § "Step 0 pre-flight subprocess failure
# handling (P358)". Consumes the pre-flight JSON envelope + the pre-flight exit
# code + the repo working-tree state, applies the non-blocking revert-and-proceed
# contract, and returns the orchestrator's decision. KEY PROPERTY: a pre-flight
# NEVER halts the loop and NEVER salvages — it reverts and proceeds.
preflight_failure_outcome() {
  local json="$1"
  local exit_code="$2"
  local repo="$3"

  local is_error
  is_error=$(printf '%s' "$json" | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("is_error")).lower())' 2>/dev/null || echo unknown)

  # Pre-flight succeeded (exit 0 AND is_error:false) → cache refreshed; proceed.
  if [ "$exit_code" = "0" ] && [ "$is_error" = "false" ]; then
    printf 'DECISION=PROCEED reason=preflight-ok\n'
    return 0
  fi

  # Pre-flight FAILED (non-zero exit OR is_error:true) → NON-BLOCKING contract.
  # Step 1b: if the dead pre-flight left STAGED residue, unstage it first
  # (ADR-009 — a dead is_error:true subprocess must not seed the parent index).
  if [ -n "$(git -C "$repo" diff --cached --name-only)" ]; then
    git -C "$repo" reset -q
  fi
  # Step 1: revert the whole contractually-touchable path set (not just cache).
  # Per-path tolerant — a COMBINED `git checkout -- A B` errors and reverts
  # NOTHING when B is absent (e.g. docs/audits/ on a fresh adopter repo), so
  # revert each path independently.
  git -C "$repo" checkout -- docs/problems/ 2>/dev/null || true
  git -C "$repo" checkout -- docs/audits/ 2>/dev/null || true
  # Step 3: proceed to Step 1 (never halt).
  printf 'DECISION=PROCEED reason=preflight-failed-reverted\n'
  return 0
}

# ---------------------------------------------------------------------------
# Behavioural cases (the load-bearing core per ADR-052).
# ---------------------------------------------------------------------------

@test "P358: pre-flight is_error:true (socket-closed) + unstaged partial write -> revert + PROCEED (never halt)" {
  export FAKE_STAGE_RESIDUE=0 FAKE_EXIT=0
  local json
  json=$( cd "$REPO" && claude -p --output-format json "PREFLIGHT" < /dev/null )
  # The fake left a dirty partial cache write.
  run git -C "$REPO" status --porcelain docs/problems/.upstream-cache.json
  [ -n "$output" ]
  run preflight_failure_outcome "$json" 0 "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=PROCEED"* ]]
  [[ "$output" == *"preflight-failed-reverted"* ]]
  # The dirty partial write was reverted — tree is clean again.
  run git -C "$REPO" status --porcelain
  [ -z "$output" ]
  # The committed clean cache content survived (revert restored it).
  run cat "$REPO/docs/problems/.upstream-cache.json"
  [[ "$output" == "clean-cache" ]]
}

@test "P358: pre-flight non-zero exit -> revert + PROCEED (non-blocking; not a loop halt)" {
  export FAKE_STAGE_RESIDUE=0 FAKE_EXIT=1
  local json
  json=$( cd "$REPO" && claude -p --output-format json "PREFLIGHT" < /dev/null || true )
  run preflight_failure_outcome "$json" 1 "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=PROCEED"* ]]
  # Crucially NOT a HALT — a pre-flight failure does not stop the loop.
  [[ "$output" != *"HALT"* ]]
  run git -C "$REPO" status --porcelain
  [ -z "$output" ]
}

@test "P358: pre-flight left STAGED residue -> git reset then revert (ADR-009 no-seed-parent-index)" {
  export FAKE_STAGE_RESIDUE=1 FAKE_EXIT=0
  local json
  json=$( cd "$REPO" && claude -p --output-format json "PREFLIGHT" < /dev/null )
  # The fake STAGED the partial write.
  run git -C "$REPO" diff --cached --name-only
  [[ "$output" == *".upstream-cache.json"* ]]
  run preflight_failure_outcome "$json" 0 "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=PROCEED"* ]]
  # Staged residue was unstaged AND reverted — index + tree both clean.
  run git -C "$REPO" diff --cached --name-only
  [ -z "$output" ]
  run git -C "$REPO" status --porcelain
  [ -z "$output" ]
}

@test "P358: pre-flight success (exit 0 + is_error:false) -> PROCEED without revert" {
  # Hand-build a clean success envelope (the fake always fails by design).
  local json='{"is_error":false,"result":"refreshed"}'
  run preflight_failure_outcome "$json" 0 "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=PROCEED"* ]]
  [[ "$output" == *"preflight-ok"* ]]
}

# ---------------------------------------------------------------------------
# Doc-lint contract assertions (Permitted Exception per ADR-037; structural
# slice marked at top of file per ADR-052 Surface 2). These guard the SKILL.md
# / ADR-032 prose against drift away from the behavioural contract above.
# ---------------------------------------------------------------------------

@test "P358: SKILL.md documents the Step 0 pre-flight failure-handling subsection" {
  run grep -niE "pre-flight subprocess failure handling.{0,40}P358|Step 0 pre-flight subprocess failure" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P358: SKILL.md pre-flight contract names the non-blocking revert-and-proceed rule" {
  run grep -niE "non-?blocking" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "revert.{0,40}(proceed|partial)|proceed to Step 1 with the existing" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P358: SKILL.md distinguishes pre-flight (cache-refresh dependency) from iter (loop body)" {
  run grep -niE "non-load-bearing cache-refresh dependency" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "iter IS the loop body|the iter is the loop body" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P358: SKILL.md pre-flight forward-pointer fires in the 0b/0c/0d dispatch paragraphs" {
  # At least three "do NOT halt the loop (a failed pre-flight ...)" pointers.
  run bash -c "grep -ciE 'do NOT halt the loop .a failed pre-flight' '$SKILL_FILE'"
  [ "$status" -eq 0 ]
  [ "$output" -ge 3 ]
}

@test "P358: SKILL.md pre-flight contract cites P358" {
  run grep -nE "P358" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P358: ADR-032 carries the pre-flight failure-handling P358 amendment" {
  run grep -niE "Pre-flight subprocess failure handling.{0,60}P358 amendment" "$ADR_FILE"
  [ "$status" -eq 0 ]
}

@test "P358: ADR-032 amendment names the iter-vs-pre-flight failure-semantics axis as orthogonal to SALVAGE/HALT" {
  run grep -niE "orthogonal" "$ADR_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "No SALVAGE for a pre-flight|SALVAGE branch does NOT apply to a pre-flight" "$ADR_FILE"
  [ "$status" -eq 0 ]
}
