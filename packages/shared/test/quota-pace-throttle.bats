#!/usr/bin/env bats
# Behavioural tests for quota-pace-throttle.sh (P160 / ADR-093 / RFC-046).
# A `sleep` shim on PATH records the requested seconds instead of sleeping, so
# the "ahead of pace → sleep N" assertions run instantly.

setup() {
  HOOK="${BATS_TEST_DIRNAME}/../hooks/quota-pace-throttle.sh"
  TMP="$(mktemp -d)"
  export WR_QUOTA_CACHE="$TMP/quota-state.json"
  export WR_QUOTA_MARKER="$TMP/marker"
  # sleep shim: record arg, return immediately.
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/sleep" <<SH
#!/usr/bin/env bash
printf '%s' "\$1" > "$TMP/slept"
exit 0
SH
  chmod +x "$TMP/bin/sleep"
  export PATH="$TMP/bin:$PATH"
  NOW="$(date +%s)"
}
teardown() { rm -rf "$TMP"; }

slept() { cat "$TMP/slept" 2>/dev/null || echo 0; }
write_cache() { # five_used five_reset week_used week_reset
  printf '{"five_used_pct":%s,"five_resets_at":%s,"week_used_pct":%s,"week_resets_at":%s}' \
    "$1" "$2" "$3" "$4" > "$WR_QUOTA_CACHE"
}

@test "ahead of pace on the 5h window sleeps a capped catch-up" {
  write_cache 60 $((NOW+16200)) 20 $((NOW+600000))   # 60% used, ~10% elapsed
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ "$(slept)" -gt 0 ]
  [ "$(slept)" -le 60 ]
}

@test "behind pace is a fast no-op (no sleep)" {
  write_cache 5 $((NOW+9000)) 5 $((NOW+300000))      # 5% used, ~50%/~50% elapsed
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/slept" ]
}

@test "the tighter (larger-gap) window wins" {
  # 5h barely ahead (30% used ~25% elapsed → gap 5), 7d far ahead (80% used ~10% elapsed → gap ~65)
  write_cache 30 $((NOW+13500)) 80 $((NOW+540000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  # week gap dominates → sleep hits the 60s cap
  [ "$(slept)" -eq 60 ]
}

@test "weekly headroom throttles a lead that would otherwise read as on-pace" {
  # 5h clearly behind; 7d used 8%, elapsed ~10% → raw gap -2 (on pace), but the
  # 5pp headroom tightens it to gap +3 → throttles early to preserve weekly headroom.
  write_cache 5 $((NOW+9000)) 8 $((NOW+544320))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ "$(slept)" -gt 0 ]
}

@test "missing cache fails open (exit 0, no sleep)" {
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/slept" ]
}

@test "malformed cache fails open" {
  printf 'not json' > "$WR_QUOTA_CACHE"
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/slept" ]
}

@test "a check within 5s of the last is skipped (recent-check no-op)" {
  write_cache 60 $((NOW+16200)) 20 $((NOW+600000))   # would otherwise sleep
  printf '%s' "$NOW" > "$WR_QUOTA_MARKER"             # just checked
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/slept" ]
}

@test "never emits a permissionDecision deny" {
  write_cache 99 $((NOW+17900)) 99 $((NOW+603000))   # maximally ahead
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qi 'permissionDecision'
  ! echo "$output" | grep -qi 'deny'
}
