#!/usr/bin/env bats
# Behavioural tests for the self-calibrating quota-pace-throttle (P160/P443/P446/ADR-093).
# A `sleep` shim on PATH records the requested seconds instead of sleeping.

setup() {
  unset CODEX_THREAD_ID CODEX_HOME CODEX_BINARY
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
# flat schema (shipped reality): five_used five_reset week_used week_reset
write_cache() {
  printf '{"five_used_pct":%s,"five_resets_at":%s,"week_used_pct":%s,"week_resets_at":%s}' \
    "$1" "$2" "$3" "$4" > "$WR_QUOTA_CACHE_FILE"
}
# state: check_ts base_ts base_week base_five cur_s
write_state() { printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5" > "$WR_QUOTA_MARKER"; }

@test "a duration-zero window is ignored" {
  write_state $((NOW-100)) $((NOW-100)) 10 99 0
  printf '{"five_used_pct":99,"five_resets_at":%s,"five_window_s":0,"week_used_pct":10,"week_resets_at":%s,"week_window_s":604800}' \
    "$((NOW+100))" "$((NOW+500000))" > "$WR_QUOTA_CACHE_FILE"
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "missing cache fails open (exit 0, no sleep)" {
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "malformed cache fails open" {
  printf 'not json' > "$WR_QUOTA_CACHE_FILE"
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "first firing over pace records a baseline and starts minimum braking" {
  write_cache 20 $((NOW+9000)) 50 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -eq 10 ]
  [ -f "$WR_QUOTA_MARKER" ]                      # baseline written
  grep -q " 50 20 10" "$WR_QUOTA_MARKER"         # base_week base_five cur_s
}

@test "throttling announces engage and release transitions but stays silent while active" {
  write_cache 20 $((NOW+9000)) 50 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"has started pacing quota use"* ]]
  [[ "$output" == *"cancelling or retrying restarts the pacing delay"* ]]
  [ -d "${WR_QUOTA_MARKER}.pacing" ]

  rm -f "$TMP/slept"
  write_state $((NOW-100)) $((NOW-100)) 50 20 10
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ -z "$output" ]; [ "$(slept)" -eq 10 ]

  rm -f "$TMP/slept"
  write_state $((NOW-100)) $((NOW-100)) 13 8 10
  write_cache 8 $((NOW+9000)) 13 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
  [[ "$output" == *"pacing has stopped"* ]]
  [ ! -d "${WR_QUOTA_MARKER}.pacing" ]
}

@test "first firing behind pace records a baseline without braking" {
  write_cache 8 $((NOW+9000)) 10 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
  grep -q " 10 8 0" "$WR_QUOTA_MARKER"
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
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 10 ]      # cur_s := 10*3/2 + kick, kick scales with burn
}

@test "a severe over-line sprint slams the brake toward the ceiling in ONE call (rec 3 proportional kick)" {
  # From a standing start (cur_s=0), a burn many multiples over sustainable must jump
  # to a large sleep immediately, not crawl up +10/call. Week 20->90 (+70%) in 100s vs
  # a ~6-day window: burn is thousands× sustainable → kick clamps to the ceiling.
  write_state $((NOW-100)) $((NOW-100)) 20 5 0
  write_cache 10 $((NOW+9000)) 90 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 100 ]     # far above the old 0 -> 10 first step
}

@test "sleep is clamped to the ceiling (max_sleep_s)" {
  export WR_QUOTA_THROTTLE_MAX_SLEEP=30
  write_state $((NOW-100)) $((NOW-100)) 10 5 600  # would ramp above 30
  write_cache 20 $((NOW+9000)) 90 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -le 30 ]
}

@test "ahead of pace with an unresolved integer delta keeps the established brake" {
  write_state $((NOW-100)) $((NOW-100)) 40 15 20
  write_cache 15 $((NOW+9000)) 40 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ "$(slept)" -eq 20 ]
  grep -qE " 20$" "$WR_QUOTA_MARKER"
}

@test "monthly window ahead at 89 percent starts minimum braking without a measurable delta" {
  write_state $((NOW-100)) $((NOW-100)) 89 0 0
  printf '{"five_used_pct":0,"five_resets_at":0,"five_window_s":0,"week_used_pct":89,"week_resets_at":%s,"week_window_s":2678400}' \
    "$((NOW+741600))" > "$WR_QUOTA_CACHE_FILE"
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -eq 10 ]
  grep -qE " 10$" "$WR_QUOTA_MARKER"
}

@test "ahead of pace with a positive measurably sustainable delta releases braking" {
  write_state $((NOW-100000)) $((NOW-100000)) 39 15 40
  write_cache 15 $((NOW+9000)) 40 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
  grep -qE " 0$" "$WR_QUOTA_MARKER"
}

@test "one unresolved overline window retains braking when another is measurably sustainable" {
  write_state $((NOW-10000)) $((NOW-10000)) 89 69 0
  write_cache 70 $((NOW+9000)) 89 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -eq 10 ]
  grep -qE " 10$" "$WR_QUOTA_MARKER"
}

@test "a check within 5s of the last is skipped" {
  write_state "$NOW" $((NOW-100)) 40 15 200
  write_cache 90 $((NOW+9000)) 90 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]
}

@test "max_sleep_s=0 disables throttling (the ceiling clamps every sleep to 0)" {
  export WR_QUOTA_THROTTLE_MAX_SLEEP=0
  write_state $((NOW-100)) $((NOW-100)) 10 5 0
  write_cache 99 $((NOW+100)) 99 $((NOW+100))   # maximally over pace
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

@test "5h window can govern when it is the tighter constraint (and over its line)" {
  # 5h at 70% ~2.5h into the 5h window (linear pace 50%) → over its line AND over-rate
  # (15->70 in 100s); week behind. Should throttle on the 5h.
  write_state $((NOW-100)) $((NOW-100)) 10 15 0
  write_cache 70 $((NOW+9000)) 12 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 0 ]
}

@test "behind the pace line does NOT throttle on a mild sub-guard burn (P446 deficit-aware)" {
  # Both windows well behind their line with banked surplus, and burning at a rate
  # that projects comfortably within the window (under the GUARD=4 threshold): week
  # 39->40 with ~2.8h to reset, 5h 9->10 at 2.5h in. Surplus is there to be spent —
  # a mild burn must NOT brake. (A sustained SPRINT, ratio ≥ 4, is a separate test.)
  write_state $((NOW-100)) $((NOW-100)) 39 9 0
  write_cache 10 $((NOW+9000)) 40 $((NOW+10000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]        # no sleep — mild burn, behind pace
  grep -qE " 0$" "$WR_QUOTA_MARKER"                 # cur_s stays at 0
}

@test "behind the pace line, a sustained sprint DOES brake (rec 4 burn guard, default 4x)" {
  # Week 10% used ~24h into a 168h window → BEHIND the ~13% line (surplus banked), but
  # burning +8% in 100s projects to exhaust the window in well under 1/4 the time left,
  # far over the GUARD=4 threshold. The guard engages even though position is behind pace.
  # (5h quiet and behind: 5% used, no measurable delta.)
  write_state $((NOW-100)) $((NOW-100)) 2 5 0
  write_cache 5 $((NOW+9000)) 10 $((NOW+520000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -gt 0 ]         # guard braked the behind-line sprint
}

@test "burn_guard_multiple=0 disables the behind-line guard" {
  export WR_QUOTA_BURN_GUARD_MULTIPLE=0
  write_state $((NOW-100)) $((NOW-100)) 2 5 0
  write_cache 5 $((NOW+9000)) 10 $((NOW+520000))   # same behind-line sprint as above
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]        # guard off → surplus spendable, no brake
  grep -qE " 0$" "$WR_QUOTA_MARKER"
}

@test "the behind-line guard releases at once when the sprint falls back (asymmetric recovery)" {
  # A guard sleep ramped to 200; still behind the line but the burn has fallen back under
  # threshold (week 9->10 over a long baseline → sustainable). Must drop to 0 at once.
  write_state $((NOW-100000)) $((NOW-100000)) 9 5 200
  write_cache 5 $((NOW+9000)) 10 $((NOW+520000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  grep -qE " 0$" "$WR_QUOTA_MARKER"                 # cur_s := 0 immediately
}

@test "behind pace drops a high sleep to 0 at once, not eased over calls (P446 sticky-recovery)" {
  # cur_s ramped to 200 during an earlier over-pace window; now behind pace on both
  # windows with no fresh burst. Old controller eased 200->123->..., leaving a session
  # slow for minutes; the fix drops the grip straight to 0.
  write_state $((NOW-100)) $((NOW-100)) 13 8 200
  write_cache 8 $((NOW+9000)) 13 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  grep -qE " 0$" "$WR_QUOTA_MARKER"                # cur_s := 0 immediately
}

@test "too-soon firing behind pace drops the stale grip instead of re-sleeping it (P446)" {
  # dt=10s < BASELINE_MIN → too soon to remeasure a rate; a big stale cur_s must NOT
  # be re-slept while behind pace (position gate applies without a rate).
  write_state $((NOW-10)) $((NOW-10)) 13 8 300
  write_cache 8 $((NOW+9000)) 13 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ ! -f "$TMP/slept" ]       # stale grip dropped, no sleep
  grep -qE " 0$" "$WR_QUOTA_MARKER"
}

@test "too-soon firing AT/over the line keeps the established pace (P446 asymmetry is recovery-only)" {
  # dt=10s < BASELINE_MIN, but at/over the line (70% used ~2.5h into the 5h window):
  # recovery-to-0 must NOT fire — the established sleep is kept so braking holds.
  write_state $((NOW-10)) $((NOW-10)) 12 70 40
  write_cache 70 $((NOW+9000)) 12 $((NOW+500000))
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]; [ "$(slept)" -eq 40 ]       # over the line → keep sleeping 40
}

@test "concurrent sessions keep independent throttle grip (STORY-042 per-session state)" {
  # State lives at \$TMPDIR/wr-quota-throttle-<sid>: each session has its own file,
  # so one session's fresh recent-check must NOT short-circuit another's throttle.
  export TMPDIR="$TMP"; unset WR_QUOTA_MARKER
  write_cache 90 $((NOW+9000)) 90 $((NOW+500000))          # both windows heavily over pace
  # Seed each session a baseline 100s old (so a firing throttles, not just baselines).
  printf '%s %s %s %s %s\n' $((NOW-100)) $((NOW-100)) 10 5 20 > "$TMP/wr-quota-throttle-sessA"
  printf '%s %s %s %s %s\n' $((NOW-100)) $((NOW-100)) 10 5 20 > "$TMP/wr-quota-throttle-sessB"
  CLAUDE_SESSION_ID=sessA bash "$HOOK" </dev/null; a="$(slept)"; rm -f "$TMP/slept"
  # Session B fires right after A. A machine-wide marker would make B's recent-check
  # (< 5s since A wrote its marker) skip → no sleep. Per-session state keeps them independent.
  CLAUDE_SESSION_ID=sessB bash "$HOOK" </dev/null; b="$(slept)"
  [ "$a" -gt 0 ]        # session A throttled
  [ "$b" -gt 0 ]        # session B throttled independently (not suppressed by A)
}
