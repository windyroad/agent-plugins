#!/usr/bin/env bats
# tdd-review: structural-permitted (justification: the doc-lint slice below
# asserts SKILL.md / ADR-032 prose contract — SKILL.md is the contract
# document per ADR-037 Permitted Exception; these guards catch prose drift
# away from the behavioural HALT-with-advisory contract exercised above. The
# load-bearing core of this fixture is behavioural per ADR-052. harness-gap P012)
#
# Behavioural test: work-problems Step 5 exit-code semantics — the
# is_error:true TRANSIENT-API-ERROR HALT branch (P214). When an iter
# subprocess returns `is_error: true` with `total_cost_usd: 0` AND no staged
# work in the tree (the 529 Overloaded / 429 rate-limit / 401 auth-expired
# shape — the API call never landed; nothing was done; metadata records the
# failure), the orchestrator MUST halt the loop with a class-appropriate
# advisory line in the final summary — NOT silently treat exit-0 as success
# and try to parse a missing ITERATION_SUMMARY block.
#
# This is the HALT counterpart to the existing P261 SALVAGE branch (covered
# by work-problems-step-5-stream-timeout-salvage.bats):
#   - SALVAGE: is_error:true + staged work + bats green (stream-timeout class)
#   - HALT:    is_error:true + nothing staged (transient-API-error class — P214)
# Both branches require the orchestrator to read `is_error` BEFORE the
# Exit-0 → parse-ITERATION_SUMMARY path; without the explicit check-order
# the loop silently miscounts and may spawn further subprocesses that fail
# identically (the AFK-promise-breaking shape P214 reports).
#
# The fake-shim below re-creates the production 529 Overloaded shape:
# is_error:true, total_cost_usd:0, no staged work, .result carrying the
# upstream error string. The harness re-implements the orchestrator's
# ordered-check decision contract (faithful to SKILL.md Step 5) and asserts
# the HALT routing + class-appropriate advisory for each transient class.
#
# @problem P214
# @jtbd JTBD-006
#
# Cross-reference:
#   P214 (work-problems Step 5 exit-code rule doesn't handle is_error:true
#     transient API failures) — driver ticket
#   P261 (is_error:true stream-timeout salvage carve-out) — sibling SALVAGE
#     branch; this fixture covers the HALT counterpart
#   ADR-032 (governance skill invocation patterns — is_error:true class
#     taxonomy: SALVAGE = stream-timeout; HALT = transient-API-error) — the
#     amended contract this fixture pins
#   ADR-013 Rule 6 (AFK fail-safe — HALT routing is non-interactive; no
#     AskUserQuestion) — invariant honoured
#   ADR-037 / ADR-052 (skill testing strategy — behavioural default; doc-lint
#     contract assertion is the Permitted Exception, marked above)

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="${TEST_TMP}/bin"
  mkdir -p "$FAKE_BIN"

  # Fake `claude` binary simulating the transient-API-error shape: exits 0,
  # emits an is_error:true JSON envelope with total_cost_usd:0 and the
  # transient-class error string in `.result`. No staged work — the API call
  # never landed; nothing was done.
  cat > "$FAKE_BIN/claude" <<'FAKE_EOF'
#!/usr/bin/env bash
# Test fake for work-problems Step 5 P214 transient-API-error halt fixture.
# Emits is_error:true with total_cost_usd:0 and a class-specific .result string.
# FAKE_ERROR_CLASS selects the transient class: overloaded | rate-limit | auth-expired
case "${FAKE_ERROR_CLASS:-overloaded}" in
  overloaded)
    RESULT='API Error (529): Overloaded'
    ;;
  rate-limit)
    RESULT='API Error (429): Rate limit exceeded'
    ;;
  auth-expired)
    RESULT='API Error (401): Authentication expired'
    ;;
  *)
    RESULT='API Error: Unknown'
    ;;
esac
printf '%s\n' "{\"is_error\":true,\"result\":\"${RESULT}\",\"total_cost_usd\":0,\"duration_ms\":1500,\"usage\":{\"input_tokens\":0,\"output_tokens\":0,\"cache_creation_input_tokens\":0,\"cache_read_input_tokens\":0}}"
FAKE_EOF
  chmod +x "$FAKE_BIN/claude"
  export PATH="$FAKE_BIN:$PATH"

  # A throwaway git repo so staged-work detection is real (and empty — no
  # staged work is the load-bearing characteristic of this class).
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

# Faithful re-implementation of SKILL.md Step 5's ORDERED-CHECK decision
# contract (P214 amendment to the P261 carve-out). The orchestrator reads
# (1) exit code, (2) is_error, (3) ITERATION_SUMMARY — in that order. On
# is_error:true + nothing staged, emit a class-appropriate advisory.
ordered_check_decision() {
  local exit_code="$1"
  local json="$2"
  local repo="$3"

  # (1) Non-zero exit → halt per the exit-code contract.
  if [ "$exit_code" -ne 0 ]; then
    printf 'DECISION=HALT reason=non-zero-exit\n'
    return 0
  fi

  # (2) Parse is_error BEFORE attempting to parse ITERATION_SUMMARY (the
  # ordered-check rule P214 amends in).
  local is_error result
  is_error=$(printf '%s' "$json" | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("is_error")).lower())')
  result=$(printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("result",""))')

  if [ "$is_error" = "true" ]; then
    # is_error:true with staged work → defer to existing P261 SALVAGE branch
    # (covered by sibling fixture work-problems-step-5-stream-timeout-salvage.bats).
    local staged
    staged=$(git -C "$repo" diff --cached --name-only)
    if [ -n "$staged" ]; then
      printf 'DECISION=DEFER_TO_SALVAGE_BRANCH\n'
      return 0
    fi

    # is_error:true with NO staged work → HALT with class-appropriate advisory.
    local advisory
    case "$result" in
      *"529"*|*"Overloaded"*|*"overloaded"*)
        advisory='API overloaded; retry when service recovers'
        ;;
      *"429"*|*"Rate limit"*|*"rate limit"*|*"rate-limit"*)
        advisory='API rate-limited; retry when limit window resets'
        ;;
      *"401"*|*"Authentication"*|*"auth"*)
        advisory='API auth expired; refresh credentials before resuming'
        ;;
      *)
        advisory='transient API error; inspect .result and resume manually'
        ;;
    esac
    printf 'DECISION=HALT reason=is-error-transient advisory=%s\n' "$advisory"
    return 0
  fi

  # (3) Exit 0 AND is_error:false → parse ITERATION_SUMMARY.
  printf 'DECISION=PARSE_SUMMARY\n'
  return 0
}

# ---------------------------------------------------------------------------
# Behavioural cases (the load-bearing core per ADR-052).
# ---------------------------------------------------------------------------

@test "P214: is_error:true + 529 Overloaded + no staged work -> HALT with API-overloaded advisory" {
  export FAKE_ERROR_CLASS=overloaded
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 0 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=is-error-transient"* ]]
  [[ "$output" == *"API overloaded"* ]]
  [[ "$output" == *"retry when service recovers"* ]]
}

@test "P214: is_error:true + 429 rate-limit + no staged work -> HALT with rate-limited advisory" {
  export FAKE_ERROR_CLASS=rate-limit
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 0 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=is-error-transient"* ]]
  [[ "$output" == *"rate-limited"* ]]
}

@test "P214: is_error:true + 401 auth-expired + no staged work -> HALT with refresh-credentials advisory" {
  export FAKE_ERROR_CLASS=auth-expired
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 0 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=is-error-transient"* ]]
  [[ "$output" == *"auth expired"* ]]
  [[ "$output" == *"refresh credentials"* ]]
}

@test "P214: is_error MUST be checked BEFORE ITERATION_SUMMARY parse on Exit 0 (ordered-check invariant)" {
  # The load-bearing P214 invariant: when exit 0 AND is_error:true, the
  # decision is HALT, NOT PARSE_SUMMARY. Without the ordered-check rule the
  # loop would silently route to PARSE_SUMMARY and miss the failure.
  export FAKE_ERROR_CLASS=overloaded
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 0 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" != *"DECISION=PARSE_SUMMARY"* ]]
  [[ "$output" == *"DECISION=HALT"* ]]
}

@test "P214: non-zero exit takes precedence over is_error check (HALT routing)" {
  # Non-zero exit halts regardless of is_error value — the exit-code rule
  # is check (1) in the ordered sequence.
  export FAKE_ERROR_CLASS=overloaded
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 1 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=HALT"* ]]
  [[ "$output" == *"reason=non-zero-exit"* ]]
}

@test "P214: is_error:true + staged work -> defers to existing P261 SALVAGE branch (no double-handling)" {
  # When staged work exists, the transient-API-error HALT branch must NOT
  # fire — it MUST defer to the P261 SALVAGE branch. This guards against
  # the new branch swallowing salvage-eligible work.
  export FAKE_ERROR_CLASS=overloaded
  printf 'salvageable work\n' > "$REPO/salvage-me.txt"
  git -C "$REPO" add salvage-me.txt
  local json
  json=$( cd "$REPO" && claude -p --output-format json "TEST" < /dev/null )
  run ordered_check_decision 0 "$json" "$REPO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DECISION=DEFER_TO_SALVAGE_BRANCH"* ]]
}

# ---------------------------------------------------------------------------
# Doc-lint contract assertions (Permitted Exception per ADR-037; structural
# slice marked at top of file per ADR-052 Surface 2). These guard the SKILL.md
# / ADR-032 prose against drift away from the behavioural contract above.
# ---------------------------------------------------------------------------

@test "P214: SKILL.md Step 5 documents the ORDERED check sequence (exit-code, is_error, ITERATION_SUMMARY)" {
  # The ordered-check rule must be explicit in the prose so an implementer
  # reading Step 5 routes is_error:true to HALT before attempting to parse
  # a missing ITERATION_SUMMARY block.
  run grep -niE "(check|read|parse).{0,40}is_error.{0,80}before.{0,80}(ITERATION_SUMMARY|parse|\.result)|ordered check|check.order" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P214: SKILL.md Step 5 names the transient-API-error classes (overloaded / rate-limit / auth-expired)" {
  # The HALT advisory must enumerate the known transient classes so the
  # final summary carries an actionable message rather than a generic
  # "loop halted" line.
  run grep -niE "529|Overloaded|overload" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "429|rate.?limit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "401|auth.?expired|auth.*expir" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P214: SKILL.md Step 5 cites P214 as the driver of the transient-API-error HALT branch" {
  run grep -nE "P214" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P214: SKILL.md HALT branch distinguishes the transient-API-error class from the P261 stream-timeout SALVAGE class" {
  # The two is_error:true branches (SALVAGE vs HALT) must be cross-referenced
  # so adopters reading either branch see the other.
  run grep -niE "P261.{0,200}(transient|HALT|overload|class)|transient.{0,200}P261|salvage.{0,200}(transient|class)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P214: ADR-032 P261 section names the is_error:true class taxonomy (SALVAGE = stream-timeout; HALT = transient-API-error)" {
  # ADR-032's P261 amendment should be extended with the broader class
  # taxonomy so the SKILL prose and the ADR contract stay in sync.
  run grep -niE "P214|transient.?(API.?)?error|class taxonomy|(overload|rate.?limit|auth.?expired).{0,80}HALT|HALT.{0,80}(overload|rate.?limit|auth.?expired)" "$ADR_FILE"
  [ "$status" -eq 0 ]
}
