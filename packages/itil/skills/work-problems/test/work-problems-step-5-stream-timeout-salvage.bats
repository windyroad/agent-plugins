#!/usr/bin/env bats
# tdd-review: structural-permitted (justification: the doc-lint slice below
# asserts SKILL.md / ADR-032 prose contract — SKILL.md is the contract
# document per ADR-037 Permitted Exception; these guards catch prose drift
# away from the behavioural SALVAGE/HALT contract exercised above. The
# load-bearing core of this fixture is behavioural per ADR-052. harness-gap P012)
#
# Behavioural test: work-problems Step 5 exit-code semantics — the is_error:true
# stream-timeout SALVAGE carve-out (P261). When an iter subprocess returns
# `is_error: true` (e.g. `API Error: Stream idle timeout - partial response
# received`) AFTER staging coherent work but BEFORE `git commit`, the staged
# work survives in the working tree. The orchestrator's salvage decision logic
# is: IF is_error:true AND staged files exist AND iter-authored bats pass →
# SALVAGE (commit the staged work from the main turn with iter-attribution; the
# commit gate fires fresh). ELSE → HALT per the existing exit-code contract.
#
# This is a NEW recovery branch, distinct from:
#   - P121 (SIGTERM idle-timeout — is_error:false clean exit-flush; subprocess
#     HAD committed before going idle)
#   - P147 (SIGTERM stuck-before-emit — exit 143 + 0-byte JSON; metadata lost)
#   - P146 (bash-polling antipattern — the deadlock mechanism behind P147)
# The stream-timeout class preserves metadata in the JSON envelope AND the
# staged files; the iter exits on its own with is_error:true (no SIGTERM).
#
# The fake-stuck-shim below re-creates the production shape: it stages coherent
# work in the repo, then emits an is_error:true stream-timeout JSON envelope
# (no ITERATION_SUMMARY, no commit). The harness re-implements the orchestrator's
# SALVAGE-vs-HALT decision contract (faithful to SKILL.md Step 5) and asserts the
# branch outcome across the four input shapes. Adopters who copy the SKILL.md
# Step 5 exit-code block into their orchestrator should observe the same outcomes.
#
# @problem P261
# @jtbd JTBD-006
# @jtbd JTBD-001
#
# Cross-reference:
#   P261 (iter subprocess API stream-timeout salvage path) — driver ticket
#   ADR-032 (governance skill invocation patterns — is_error:true stream-timeout
#     salvage sub-variant, P261 amendment) — the carved-out commit-authorship
#     contract this fixture pins
#   ADR-009 (gate-marker-lifecycle — is_error:true subprocess MUST NOT extend
#     parent trust window; salvage commit fires the gate fresh on the
#     orchestrator's own SESSION_ID)
#   ADR-014 (single-commit grain — the salvage commit IS the iteration's one
#     commit; amend-folding is inapplicable because no iter commit exists)
#   ADR-037 / ADR-052 (skill testing strategy — behavioural default; doc-lint
#     contract assertion is the Permitted Exception, marked above)

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="${TEST_TMP}/bin"
  mkdir -p "$FAKE_BIN"

  # Fake `claude` binary simulating a stuck iteration subprocess of the
  # stream-timeout class: it stages coherent work in the CWD git repo, then
  # emits an is_error:true JSON envelope carrying the stream-timeout error
  # string in `.result`. No ITERATION_SUMMARY; no commit. This matches the
  # 2026-05-18 session-6 iter-4 shape captured in P261: 7 files staged, then
  # `API Error: Stream idle timeout - partial response received`.
  cat > "$FAKE_BIN/claude" <<'FAKE_EOF'
#!/usr/bin/env bash
# Test fake for work-problems Step 5 P261 stream-timeout salvage fixture.
# Stages coherent work, then emits is_error:true stream-timeout JSON.
if [ "${FAKE_STAGE_WORK:-1}" = "1" ]; then
  printf 'salvaged SKILL amendment + bats fixture\n' > staged-iter-work.txt
  git add staged-iter-work.txt 2>/dev/null || true
fi
if [ "${FAKE_IS_ERROR:-true}" = "true" ]; then
  printf '%s\n' '{"is_error":true,"result":"API Error: Stream idle timeout - partial response received","total_cost_usd":12.91,"duration_ms":300000,"usage":{"input_tokens":1000,"output_tokens":2000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}'
else
  printf '%s\n' '{"is_error":false,"result":"ITERATION_SUMMARY\nticket_id: P000\naction: worked\noutcome: investigated\ncommitted: true\nremaining_backlog_count: 0\nnotes: normal exit","total_cost_usd":0.5,"duration_ms":1000,"usage":{"input_tokens":10,"output_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}'
fi
FAKE_EOF
  chmod +x "$FAKE_BIN/claude"

  # Fake `iter_bats` stub — stands in for running the iter-authored bats
  # fixtures as the salvage path's step-1 structural sanity check. Its exit
  # code is controlled by FAKE_BATS_EXIT (0 = green, 1 = fail) so the harness
  # can exercise both the bats-green and bats-fail branches behaviourally.
  cat > "$FAKE_BIN/iter_bats" <<'FAKE_EOF'
#!/usr/bin/env bash
exit "${FAKE_BATS_EXIT:-0}"
FAKE_EOF
  chmod +x "$FAKE_BIN/iter_bats"
  export PATH="$FAKE_BIN:$PATH"

  # A throwaway git repo so staged-work detection + the salvage commit are real.
  REPO="${TEST_TMP}/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name "Test"
  git -C "$REPO" commit -q --allow-empty -m "root"

  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  ADR_FILE="$(cd "${SKILL_DIR}/../../../.." && pwd)/docs/decisions/032-governance-skill-invocation-patterns.proposed.md"
}

teardown() {
  if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# Faithful re-implementation of SKILL.md Step 5's is_error:true salvage decision
# contract. Consumes the iter JSON envelope + the repo working-tree state and
# returns the orchestrator's branch decision. The SALVAGE branch performs the
# real 4-step path's commit (step 3) so the commit is observable; the bats
# sanity check (step 1) is exercised via the FAKE_BATS_EXIT-controlled stub.
salvage_decision() {
  local json="$1"
  local repo="$2"

  local is_error
  is_error=$(printf '%s' "$json" | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("is_error")).lower())')

  # is_error:false → normal exit-code path; not the salvage branch.
  if [ "$is_error" != "true" ]; then
    printf 'DECISION=PARSE_SUMMARY\n'
    return 0
  fi

  # is_error:true with no staged work → halt per the existing exit-code contract.
  local staged
  staged=$(git -C "$repo" diff --cached --name-only)
  if [ -z "$staged" ]; then
    printf 'DECISION=HALT reason=no-staged-work\n'
    return 0
  fi

  # is_error:true with staged work → run the iter-authored bats as the
  # structural sanity check (step 1). Green → SALVAGE; fail → HALT.
  if iter_bats; then
    # Step 3: commit the staged work from the orchestrator main turn with
    # explicit iter-attribution. (Step 4 — fresh commit gate — is the runtime
    # orchestrator's concern, asserted via the doc-lint slice below.)
    git -C "$repo" commit -q -m "salvage(P000): iter hit API stream timeout before commit — committed staged work from orchestrator main turn; iter-authored bats green"
    printf 'DECISION=SALVAGE\n'
  else
    printf 'DECISION=HALT reason=bats-fail\n'
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Behavioural cases (the load-bearing core per ADR-052).
# ---------------------------------------------------------------------------

@test "P261: is_error:true + staged work + bats green -> SALVAGE (commit from main turn)" {
  export FAKE_IS_ERROR=true FAKE_STAGE_WORK=1 FAKE_BATS_EXIT=0
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run salvage_decision "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=SALVAGE"* ]]
  # The salvage commit must have landed, carrying the staged work + attribution.
  run git -C "$REPO" log -1 --format=%s
  [[ "$output" == *"salvage"* ]]
  [[ "$output" == *"orchestrator main turn"* ]]
  run git -C "$REPO" show --stat HEAD
  [[ "$output" == *"staged-iter-work.txt"* ]]
}

@test "P261: is_error:true + staged work + bats FAIL -> HALT (incoherent work not salvaged)" {
  export FAKE_IS_ERROR=true FAKE_STAGE_WORK=1 FAKE_BATS_EXIT=1
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run salvage_decision "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=bats-fail"* ]]
  # No salvage commit landed — HEAD is still the root commit.
  run git -C "$REPO" log --oneline
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 1 ]
}

@test "P261: is_error:true + NO staged work -> HALT per existing exit-code contract" {
  export FAKE_IS_ERROR=true FAKE_STAGE_WORK=0 FAKE_BATS_EXIT=0
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run salvage_decision "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=no-staged-work"* ]]
}

@test "P261: is_error:false (normal exit) -> PARSE_SUMMARY, NOT the salvage branch" {
  export FAKE_IS_ERROR=false FAKE_STAGE_WORK=0
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run salvage_decision "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=PARSE_SUMMARY"* ]]
}

# ---------------------------------------------------------------------------
# Doc-lint contract assertions (Permitted Exception per ADR-037; structural
# slice marked at top of file per ADR-052 Surface 2). These guard the SKILL.md
# / ADR-032 prose against drift away from the behavioural contract above.
# ---------------------------------------------------------------------------

@test "P261: SKILL.md Step 5 exit-code semantics documents the is_error:true salvage carve-out" {
  run grep -niE "is_error.{0,30}salvage|salvage.{0,40}is_error|stream.?idle.?timeout.{0,80}salvage|salvage.{0,80}stream.?(idle.?)?timeout" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: SKILL.md salvage carve-out names the staged-work + bats-pass gate condition" {
  run grep -niE "staged.{0,40}(file|work).{0,80}bats|bats.{0,80}(pass|green).{0,80}salvage|salvage.{0,120}staged" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: SKILL.md salvage carve-out documents the commit-from-main-turn + fresh-gate steps" {
  run grep -niE "(orchestrator|main turn).{0,80}commit.{0,120}(attribut|fresh)|commit gate fires fresh|fresh.{0,30}commit gate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: SKILL.md salvage carve-out distinguishes the class from P147 / P121 / P146" {
  run grep -niE "P147" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "P146" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: SKILL.md Step 5 cites P261 (salvage-carve-out driver)" {
  run grep -nE "P261" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: SKILL.md line ~486 orchestrator-commit rule carries the salvage exception cross-reference" {
  # The 'orchestrator does NOT commit from its main turn' rule must no longer
  # read as unqualified — it must name the salvage carve-out as the one
  # bounded exception so SKILL.md and ADR-032 stay in agreement.
  run grep -niE "orchestrator does NOT commit from its main turn.{0,200}(except|salvage)|salvage.{0,80}(except|one case).{0,120}main turn" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: ADR-032 carries the is_error:true stream-timeout salvage sub-variant amendment" {
  run grep -niE "is_error.{0,30}(stream.?timeout)?.{0,30}salvage|stream.?timeout salvage|P261 amendment" "$ADR_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: ADR-032 salvage amendment preserves one-commit-per-iteration grain (amend-folding inapplicable)" {
  run grep -niE "amend.?(based)?.?folding.{0,80}(inapplicable|no iter commit|not apply)|salvage commit IS the iteration|no iter commit.{0,40}amend" "$ADR_FILE"
  [ "$status" -eq 0 ]
}

@test "P261: ADR-032 salvage amendment confirms fresh-gate-marker behaviour per ADR-009" {
  run grep -niE "ADR-009|fresh.{0,30}(gate|commit gate)|own SESSION_ID|trust window" "$ADR_FILE"
  [ "$status" -eq 0 ]
}
