#!/usr/bin/env bats

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "complete required reports preserve explicit unknown and supplied data" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" unknown supplied
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "a nontriggered report needs no resource estimates" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" nontriggered
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "omitted required content and conflicting applicability cannot mint approval" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" omitted conflict caller_unknown dispute
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "unavailable or mismatched evidence stays advisory without approval" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" malformed missing mismatch context_missing malformed_context mismatched_context verdict_mismatch
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "incomplete mechanical evidence preserves substantive failures" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" fail_complete fail_omitted fail_malformed
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "consumed native child identity cannot be reopened by duplicate dispatch" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" consumed
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "reserved labels distinguish operative reports from quoted and nonreserved examples" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" json_example quoted_report ambiguous_report quoted_context
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}

@test "unsuccessful architecture reviews cannot refresh prior approval" {
  run python3 "$PACKAGE/hooks/test/architect-report-contract.py" --prior omitted malformed fail_complete direction unknown
  [ "$status" -eq 0 ] || { printf '%s\n' "$output"; return 1; }
}
