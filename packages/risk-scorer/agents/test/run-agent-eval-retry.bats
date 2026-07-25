#!/usr/bin/env bats
# Behavioural test for run-agent-eval.sh's P459 bounded-retry (ADR-005).
# The retry re-runs the agent generation up to 3× until the agent's contract
# verdict TOKEN PREFIX appears — stabilising the flaky Agent-Prose Evals job
# without masking correctness regressions. The load-bearing invariant is that
# the retry keys on the token PREFIX (`RISK_VERDICT:`), NOT the verdict VALUE —
# so a wrong-value verdict must NOT trigger a retry (branch iii). A `claude`
# mock on PATH stands in for the non-deterministic generation.

setup() {
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-agent-eval.sh"
  TMP="$(mktemp -d)"
  BIN="$TMP/bin"; mkdir -p "$BIN"
  export PATH="$BIN:$PATH"
  export WR_EVAL_RUNTIME=claude   # force the claude branch, not codex
  CALLS="$TMP/calls"; echo 0 > "$CALLS"
  export CALLS
  PROMPT='AGENT: plan
POLICY_THRESHOLD: 5
Score this plan.'
}
teardown() { rm -rf "$TMP"; }

# Write a mock `claude` whose Nth invocation emits $1 (a bash case body deciding
# output by call number). It always ignores its args and records the call count.
mock_claude() {
  cat > "$BIN/claude" <<MOCK
#!/usr/bin/env bash
n=\$(cat "$CALLS"); n=\$((n+1)); echo "\$n" > "$CALLS"
$1
MOCK
  chmod +x "$BIN/claude"
}

@test "P459: a token-less first generation retries and recovers (flake absorbed)" {
  # call 1 omits the token; call 2 emits it → loop breaks at 2, output has token.
  mock_claude 'if [ "$n" -lt 2 ]; then echo "Residual risk: 5/25 (Low)"; else printf "Residual risk: 5/25 (Low)\nRISK_VERDICT: PASS\n"; fi'
  run bash "$DRIVER" "$PROMPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RISK_VERDICT: PASS"* ]]
  [ "$(cat "$CALLS")" -eq 2 ]
}

@test "P459: an agent that never emits the token still fails after 3 attempts (real regression preserved)" {
  mock_claude 'echo "Residual risk: 5/25 (Low) — no verdict line"'
  run bash "$DRIVER" "$PROMPT"
  [ "$status" -eq 0 ]                       # driver exits 0; the ASSERTION (icontains) is what fails downstream
  [[ "$output" != *"RISK_VERDICT:"* ]]      # token absent → promptfoo icontains fails → real signal
  [ "$(cat "$CALLS")" -eq 3 ]               # all retries exhausted
}

@test "P459 INVARIANT: a wrong-VALUE verdict has the token present, so NO retry fires (masking-avoidance)" {
  # The agent emits RISK_VERDICT: FAIL on call 1. The token PREFIX is present, so
  # the loop breaks immediately — the eval's icontains still grades the (wrong)
  # value and fails. If the retry ever keyed on the value, this would loop and
  # could mask the regression. Exactly ONE call proves the prefix-only invariant.
  mock_claude 'printf "Residual risk: 9/25\nRISK_VERDICT: FAIL\n"'
  run bash "$DRIVER" "$PROMPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RISK_VERDICT: FAIL"* ]]
  [ "$(cat "$CALLS")" -eq 1 ]
}
