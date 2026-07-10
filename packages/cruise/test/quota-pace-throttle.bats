#!/usr/bin/env bats
# Behavioural tests for the self-calibrating quota-pace-throttle (P160/P443/P446/ADR-093).
# A `sleep` shim on PATH records the requested seconds instead of sleeping.

setup() {
  HOOK="${BATS_TEST_DIRNAME}/../hooks/quota-pace-throttle.sh"
  TMP="$(mktemp -d)"
  export CLAUDE_SESSION_ID=test
  export WR_QUOTA_MARKER="$TMP/state"       # per-session state file
  export WR_QUOTA_CACHE_FILE="$TMP/cache"
  mkdir -p "$TMP/bin"
  printf '#!/usr/bin/env bash\nprintf "%%s" "$1" > "%s/slept"\n' "$TMP" > "$TMP/bin/sleep"
  chmod +x "$TMP/bin/sleep"
  export PATH="$TMP/bin:$PATH"
  NOW="$(date +%s)"
}
teardown() { rm -rf "$TMP"; }

slept() { cat "$TMP/slept" 2>/dev/null || echo 0; }
# nested schema (ADR-093): five_used five_reset week_used week_reset
write_cache() {
  printf '{"written_at":%s,"five_hour":{"used_percentage":%s,"resets_at":%s},"seven_day":{"used_percentage":%s,"resets_at":%s}}' \
    "$NOW" "$1" "$2" "$3" "$4" > "$WR_QUOTA_CACHE_FILE"
}
# state: check_ts base_ts base_week base_five cur_s
write_state() { printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5" > "$WR_QUOTA_MARKER"; }

@test "missing cache fails open (exit 0, no sleep)" {
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "malformed cache fails open" {
  printf 'not json' > "$WR_QUOTA_CACHE_FILE"
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "first firing records a baseline and does not sleep" {
  write_cache 20 $((NOW+9000)) 50 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
  [ -f "$WR_QUOTA_MARKER" ]                      # baseline written
  grep -q " 50 20 0" "$WR_QUOTA_MARKER"          # base_week base_five cur_s
}

@test "over pace ramps the per-call sleep up (self-calibrating)" {
  write_state $((NOW-100)) $((NOW-100)) 40 15 0  # baseline 100s ago at 40% week
  write_cache 20 $((NOW+9000)) 55 $((NOW+500000)) # burned +15% in 100s, tiny sustainable rate
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 0 ]
}

@test "over pace ramps FURTHER on a second over-pace firing" {
  write_state $((NOW-100)) $((NOW-100)) 40 15 10  # already sleeping 10
  write_cache 20 $((NOW+9000)) 55 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 10 ]      # 10 -> 10*3/2+10 = 25
}

@test "sleep is clamped to the ceiling (max_sleep_s)" {
  export WR_QUOTA_THROTTLE_MAX_SLEEP=30
  write_state $((NOW-100)) $((NOW-100)) 10 5 600  # would ramp above 30
  write_cache 20 $((NOW+9000)) 90 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -le 30 ]
}

@test "on/under pace eases the sleep off toward zero" {
  write_state $((NOW-100)) $((NOW-100)) 40 15 20  # sleeping 20, but no burn since
  write_cache 15 $((NOW+9000)) 40 $((NOW+500000)) # week unchanged (40->40) => under pace
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  grep -qE " (0|[1-3])$" "$WR_QUOTA_MARKER"       # cur_s eased down (20*2/3-10 = 3)
}

@test "a check within 5s of the last is skipped" {
  write_state "$NOW" $((NOW-100)) 40 15 200
  write_cache 90 $((NOW+9000)) 90 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "kill-switch disables throttling entirely" {
  export WR_QUOTA_THROTTLE_DISABLE=1
  write_state $((NOW-100)) $((NOW-100)) 10 5 0
  write_cache 99 $((NOW+100)) 99 $((NOW+100))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "never emits a permissionDecision deny (slow-not-block)" {
  write_state $((NOW-100)) $((NOW-100)) 10 5 0
  write_cache 99 $((NOW+100)) 99 $((NOW+100))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qi 'permissionDecision'
  ! echo "$output" | grep -qi 'deny'
}

@test "5h window can govern when it is the tighter constraint" {
  # 5h badly over (5->30 in 100s, reset soon); week fine. Should throttle on the 5h.
  write_state $((NOW-100)) $((NOW-100)) 10 5 0
  write_cache 30 $((NOW+600)) 12 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 0 ]
}
