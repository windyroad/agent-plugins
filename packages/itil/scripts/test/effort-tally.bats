#!/usr/bin/env bats

# ADR-067 / P248: effort-tally.sh attributes .afk-run-state/iter*.json actuals
# back to their source ticket (pNNN filename token) and emits the per-ticket
# tally. Behavioural — exercises the script against fixture iter-JSON trees.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/itil/scripts/effort-tally.sh"
  DIR="$(mktemp -d)"
  mkdir -p "$DIR/.afk-run-state"
}

teardown() { rm -rf "$DIR"; }

mk_iter() { # mk_iter <filename> <cost> <duration_ms> <input_tokens>
  cat > "$DIR/.afk-run-state/$1" <<EOF
{"total_cost_usd": $2, "duration_ms": $3, "usage": {"input_tokens": $4, "output_tokens": 0, "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}}
EOF
}

@test "attributes a single iter to its ticket via the pNNN filename token" {
  mk_iter "iter1-p087.json" 12.50 600000 1000000
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P087"* ]]
  [[ "$output" == *"cost_usd=12.50"* ]]
  [[ "$output" == *"minutes=10.0"* ]]
}

@test "sums multiple iters for the same ticket" {
  mk_iter "iter1-p087.json" 10.00 300000 500000
  mk_iter "iter2-p087.json" 5.00 300000 500000
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [[ "$output" == *"P087 | iters=2 | cost_usd=15.00"* ]]
}

@test "authoritative cost comes from total_cost_usd; tokens flagged best-effort with ~" {
  mk_iter "iter1-p100.json" 7.00 60000 2000000
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [[ "$output" == *"cost_usd=7.00"* ]]
  [[ "$output" == *"tokens=~2.0M"* ]]
}

@test "tickets are sorted by descending cost" {
  mk_iter "iter1-p010.json" 3.00 60000 100000
  mk_iter "iter1-p020.json" 30.00 60000 100000
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  # P020 (30.00) must appear before P010 (3.00)
  [[ "$(echo "$output" | grep -n P020 | cut -d: -f1)" -lt "$(echo "$output" | grep -n P010 | cut -d: -f1)" ]]
}

@test "handles JSON-array (event-stream) shape, not just a single object" {
  cat > "$DIR/.afk-run-state/iter1-p050.json" <<'EOF'
[{"type":"system"},{"type":"result","total_cost_usd":9.00,"duration_ms":120000,"usage":{"input_tokens":3000000,"output_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}]
EOF
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [[ "$output" == *"P050"* ]]
  [[ "$output" == *"cost_usd=9.00"* ]]
}

@test "files without a pNNN token are ignored" {
  mk_iter "drain-push.json" 99.00 60000 100000
  cp "$DIR/.afk-run-state/drain-push.json" "$DIR/.afk-run-state/work-problems-session-totals.json"
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [ -z "$output" ]
}

@test "files without total_cost_usd are skipped" {
  echo '{"pid": 1234, "start": 999}' > "$DIR/.afk-run-state/iter1-p077.json"
  run bash "$SCRIPT" "$DIR/.afk-run-state"
  [ -z "$output" ]
}

@test "missing afk dir exits 0 with no output" {
  run bash "$SCRIPT" "$DIR/nonexistent"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
