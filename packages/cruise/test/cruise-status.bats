#!/usr/bin/env bats
# Behavioural tests for the cruise status/telemetry reporter (STORY-044).

setup() {
  unset CODEX_THREAD_ID CODEX_HOME CODEX_BINARY
  SC="${BATS_TEST_DIRNAME}/../scripts/cruise-status.sh"
  TMP="$(mktemp -d)"
  export WR_QUOTA_CACHE_FILE="$TMP/cache"
  export WR_QUOTA_MARKER="$TMP/state"
  export CLAUDE_SESSION_ID=t
  NOW="$(date +%s)"
}
teardown() { rm -rf "$TMP"; }
write_cache() { printf '{"five_used_pct":%s,"five_resets_at":%s,"week_used_pct":%s,"week_resets_at":%s}' "$1" "$2" "$3" "$4" > "$WR_QUOTA_CACHE_FILE"; }
write_state() { printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5" > "$WR_QUOTA_MARKER"; }

@test "reports only the available dynamic window" {
  printf '{"five_used_pct":0,"five_resets_at":0,"five_window_s":0,"week_used_pct":7,"week_resets_at":%s,"week_window_s":604800}' "$((NOW+500000))" > "$WR_QUOTA_CACHE_FILE"
  run bash "$SC" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "7-day window"
  ! echo "$output" | grep -q "5-hour window"
}

@test "no cache → warns the throttle is fail-open (inert), never errors" {
  run bash "$SC" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "FAIL-OPEN"
  echo "$output" | grep -qi "No quota cache"
}

@test "reports per-window usage vs pace, ahead/behind, and time-to-reset" {
  write_cache 60 $((NOW+9000)) 55 $((NOW+500000))
  run bash "$SC" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "5-hour window"
  echo "$output" | grep -q "7-day window"
  echo "$output" | grep -q "used 60%"
  echo "$output" | grep -qi "ahead"
  echo "$output" | grep -qi "resets in"
}

@test "expired windows report unavailable sustainable burn without arithmetic errors" {
  write_cache 60 0 55 0
  run bash "$SC" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "sustainable n/a"
  echo "$output" | grep -q "reset passed"
  ! echo "$output" | grep -Eq "division by 0|error token"
}

@test "surfaces the sleep the throttle is injecting right now (cur_s)" {
  write_cache 60 $((NOW+9000)) 55 $((NOW+500000))
  write_state "$NOW" $((NOW-120)) 45 15 45
  run bash "$SC" </dev/null
  echo "$output" | grep -q "sleeping 45s"
}

@test "idle throttle (cur_s=0) reports full speed" {
  write_cache 5 $((NOW+9000)) 5 $((NOW+500000))
  write_state "$NOW" $((NOW-120)) 5 5 0
  run bash "$SC" </dev/null
  echo "$output" | grep -qi "idle"
}

@test "idle while ahead reports braking is not engaged" {
  write_cache 0 0 29 $((NOW+500000))
  printf '%s %s %s %s 0\n' "$((NOW-100))" "$((NOW-100))" 20 0 > "$WR_QUOTA_MARKER"
  run bash "$SC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ahead, braking not engaged"
  ! echo "$output" | grep -q "throttle is slowing"
}

@test "fresh cache is reported as fresh" {
  write_cache 5 $((NOW+9000)) 5 $((NOW+500000))
  run bash "$SC" </dev/null
  echo "$output" | grep -qi "cache fresh"
}

@test "stale cache (mtime > 30min) is flagged as fail-open" {
  write_cache 5 $((NOW+9000)) 5 $((NOW+500000))
  touch -t "$(date -v-40M +%Y%m%d%H%M 2>/dev/null || date -d '40 min ago' +%Y%m%d%H%M)" "$WR_QUOTA_CACHE_FILE" 2>/dev/null
  run bash "$SC" </dev/null
  echo "$output" | grep -qi "STALE"
  echo "$output" | grep -qi "fail-open"
}

@test "malformed cache → graceful fail-open message, not an error" {
  printf 'not json' > "$WR_QUOTA_CACHE_FILE"
  run bash "$SC" </dev/null
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "malformed"
}
