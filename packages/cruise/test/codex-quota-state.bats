#!/usr/bin/env bats

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../scripts/codex-quota-state.mjs"
  HOOK="${BATS_TEST_DIRNAME}/../hooks/quota-state-producer-install.sh"
  THROTTLE="${BATS_TEST_DIRNAME}/../hooks/quota-pace-throttle.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  export CODEX_HOME="$HOME/.codex"
  export CODEX_THREAD_ID=test-codex
  export CODEX_BINARY="$TMP/fake-codex"
  export CLAUDE_PLUGIN_ROOT="${BATS_TEST_DIRNAME}/.."
  mkdir -p "$CODEX_HOME"
  cat > "$CODEX_BINARY" <<'SH'
#!/usr/bin/env bash
while IFS= read -r line; do
  case "$line" in
    *'"id":0'*) printf '{"id":0,"result":{"userAgent":"test"}}\n' ;;
    *'account/rateLimits/read'*) printf '{"id":1,"result":%s}\n' "$FAKE_RATE_LIMITS" ;;
  esac
done
SH
  chmod +x "$CODEX_BINARY"
}

teardown() { rm -rf "$TMP"; }

@test "normalizes one Codex window and disables the absent slot" {
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":7,"windowDurationMins":10080,"resetsAt":1785258703},"secondary":null}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.source' "$CODEX_HOME/quota-state.json")" = "codex-app-server" ]
  [ "$(jq -r '.five_window_s' "$CODEX_HOME/quota-state.json")" = "0" ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "7" ]
  [ "$(jq -r '.week_window_s' "$CODEX_HOME/quota-state.json")" = "604800" ]
  [ "$(awk '{print $1, $2, $3, $4, $5, $6}' "$CODEX_HOME/quota-state.json.pace")" = "0 0 7 1785258703 0 604800" ]
}

@test "maps two Codex windows shortest then longest" {
  export FAKE_RATE_LIMITS='{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":20,"windowDurationMins":10080,"resetsAt":1785258703},"secondary":{"usedPercent":40,"windowDurationMins":300,"resetsAt":1784700000}}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.five_used_pct' "$CODEX_HOME/quota-state.json")" = "40" ]
  [ "$(jq -r '.five_window_s' "$CODEX_HOME/quota-state.json")" = "18000" ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "20" ]
}

@test "malformed quota response fails open without replacing cache" {
  printf '{"source":"keep"}\n' > "$CODEX_HOME/quota-state.json"
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":null}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.source' "$CODEX_HOME/quota-state.json")" = "keep" ]
}

@test "CODEX_BINARY wins over the bundled and PATH candidates" {
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/codex" <<SH
#!/usr/bin/env bash
touch "$TMP/path-codex-ran"
SH
  chmod +x "$TMP/bin/codex"
  export PATH="$TMP/bin:$PATH"
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":8,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "8" ]
  [ ! -e "$TMP/path-codex-ran" ]
}

@test "producer timeout fails open and preserves the previous cache" {
  printf '{"source":"keep"}\n' > "$CODEX_HOME/quota-state.json"
  cat > "$CODEX_BINARY" <<'SH'
#!/usr/bin/env bash
sleep 2
SH
  chmod +x "$CODEX_BINARY"
  export WR_CRUISE_CODEX_BINARY_ONLY=1
  export WR_CRUISE_CODEX_TIMEOUT_MS=50
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.source' "$CODEX_HOME/quota-state.json")" = "keep" ]
}

@test "producer atomically replaces private cache and pace files" {
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":9,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  run jq -e '.source == "codex-app-server"' "$CODEX_HOME/quota-state.json"
  [ "$status" -eq 0 ]
  mode=$(/usr/bin/stat -f %Lp "$CODEX_HOME/quota-state.json" 2>/dev/null || /usr/bin/stat -c %a "$CODEX_HOME/quota-state.json")
  [ "$mode" = "600" ]
  mode=$(/usr/bin/stat -f %Lp "$CODEX_HOME/quota-state.json.pace" 2>/dev/null || /usr/bin/stat -c %a "$CODEX_HOME/quota-state.json.pace")
  [ "$mode" = "600" ]
  [ -z "$(find "$CODEX_HOME" -name '*.tmp' -print -quit)" ]
}

@test "Codex SessionStart writes no Claude config" {
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":7,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run bash "$HOOK" </dev/null
  [ "$status" -eq 0 ]
  [ -f "$CODEX_HOME/quota-state.json" ]
  [ ! -e "$HOME/.claude" ]
}

@test "fresh Codex cache recomputation stays under 50ms and off app-server" {
  export WR_QUOTA_CACHE_FILE="$CODEX_HOME/quota-state.json"
  export WR_QUOTA_MARKER="$TMP/state"
  printf '{"five_used_pct":0,"five_resets_at":0,"five_window_s":0,"week_used_pct":7,"week_resets_at":1785258703,"week_window_s":604800}\n' > "$WR_QUOTA_CACHE_FILE"
  printf '0 0 7 1785258703 0 604800 %s\n' "$(date +%s)" > "$WR_QUOTA_CACHE_FILE.pace"
  export CODEX_BINARY="$TMP/must-not-run"
  printf '#!/usr/bin/env bash\ntouch "%s/app-server-ran"\n' "$TMP" > "$CODEX_BINARY"
  chmod +x "$CODEX_BINARY"
  export THROTTLE
  run perl -MTime::HiRes=time -e '@ms=(); for (1..31) { $now=time; open $fh, ">", $ENV{WR_QUOTA_MARKER}; print $fh int($now)-6," ",int($now)," 7 0 0\n"; close $fh; $start=time; system "bash", $ENV{THROTTLE}; push @ms, (time-$start)*1000; } @ms=sort {$a<=>$b} @ms; printf "%.0f", $ms[15]'
  [ "$status" -eq 0 ]
  [ ! -e "$TMP/app-server-ran" ]
  [ "$output" -lt 50 ]
}

@test "Codex hook payload selects Codex cache and session without Codex env vars" {
  unset CODEX_THREAD_ID CODEX_HOME CLAUDE_SESSION_ID WR_QUOTA_MARKER WR_QUOTA_CACHE_FILE
  export HOME="$TMP/payload-home"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$HOME/.codex" "$HOME/.claude" "$TMPDIR"
  printf '{"five_used_pct":0,"five_resets_at":0,"five_window_s":0,"week_used_pct":29,"week_resets_at":%s,"week_window_s":604800}\n' "$(( $(date +%s) + 500000 ))" > "$HOME/.codex/quota-state.json"
  printf '0 0 29 %s 0 604800 %s\n' "$(( $(date +%s) + 500000 ))" "$(date +%s)" > "$HOME/.codex/quota-state.json.pace"
  printf '{"five_used_pct":11,"five_resets_at":1,"week_used_pct":42,"week_resets_at":1}\n' > "$HOME/.claude/quota-state.json"

  run bash "$THROTTLE" <<< '{"session_id":"codex-payload-session","turn_id":"codex-turn","transcript_path":null,"cwd":"/tmp/project","hook_event_name":"PreToolUse","model":"gpt-test","permission_mode":"bypassPermissions","tool_name":"Bash","tool_input":{"command":"pwd"},"tool_use_id":"exec-test"}'

  [ "$status" -eq 0 ]
  [ -f "$TMPDIR/wr-quota-throttle-codex-payload-session" ]
  [ "$(awk '{print $3}' "$TMPDIR/wr-quota-throttle-codex-payload-session")" = "29" ]
  [ ! -e "$TMPDIR/wr-quota-throttle-shared" ]
}

@test "Codex config precedence is env then project then machine then default" {
  project="$TMP/project"
  mkdir -p "$project/.codex"
  for pair in default:44 machine:11 project:22 env:33; do
    name=${pair%%:*}; used=${pair##*:}; cache="$TMP/$name.json"
    printf '{}\n' > "$cache"
    printf '0 0 %s 1785258703 0 604800 %s\n' "$used" "$(date +%s)" > "$cache.pace"
  done
  cp "$TMP/default.json" "$CODEX_HOME/quota-state.json"
  cp "$TMP/default.json.pace" "$CODEX_HOME/quota-state.json.pace"
  printf '{"cache_path":"%s"}\n' "$TMP/machine.json" > "$CODEX_HOME/cruise.config.json"
  printf '{"cache_path":"%s"}\n' "$TMP/project.json" > "$project/.codex/cruise.config.json"
  export WR_QUOTA_MARKER="$TMP/state"

  export WR_QUOTA_CACHE_FILE="$TMP/env.json"
  (cd "$project" && bash "$THROTTLE")
  [ "$(awk '{print $3}' "$WR_QUOTA_MARKER")" = "33" ]
  unset WR_QUOTA_CACHE_FILE; rm -f "$WR_QUOTA_MARKER"
  (cd "$project" && bash "$THROTTLE")
  [ "$(awk '{print $3}' "$WR_QUOTA_MARKER")" = "22" ]
  rm -f "$project/.codex/cruise.config.json" "$WR_QUOTA_MARKER"
  (cd "$project" && bash "$THROTTLE")
  [ "$(awk '{print $3}' "$WR_QUOTA_MARKER")" = "11" ]
  rm -f "$CODEX_HOME/cruise.config.json" "$WR_QUOTA_MARKER"
  (cd "$project" && bash "$THROTTLE")
  [ "$(awk '{print $3}' "$WR_QUOTA_MARKER")" = "44" ]
}

@test "Claude and Codex config roots remain isolated" {
  project="$TMP/project"
  mkdir -p "$project/.claude" "$project/.codex"
  printf '{}\n' > "$TMP/claude.json"
  printf '{"five_used_pct":0,"five_resets_at":0,"week_used_pct":55,"week_resets_at":1785258703}\n' > "$TMP/claude.json"
  printf '{"cache_path":"%s"}\n' "$TMP/claude.json" > "$project/.claude/cruise.config.json"
  printf '{"cache_path":"%s"}\n' "$TMP/missing-codex.json" > "$project/.codex/cruise.config.json"
  unset CODEX_THREAD_ID
  export CLAUDE_SESSION_ID=test-claude
  export WR_QUOTA_MARKER="$TMP/state"
  (cd "$project" && bash "$THROTTLE")
  [ "$(awk '{print $3}' "$WR_QUOTA_MARKER")" = "55" ]
}

@test "Codex uninstall removes only Cruise-owned cache artifacts" {
  mkdir -p "$TMP/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/codex"
  chmod +x "$TMP/bin/codex"
  export PATH="$TMP/bin:$PATH"
  printf '{"source":"codex-app-server"}\n' > "$CODEX_HOME/quota-state.json"
  printf 'pace\n' > "$CODEX_HOME/quota-state.json.pace"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --uninstall
  [ "$status" -eq 0 ]
  [ ! -e "$CODEX_HOME/quota-state.json" ]
  [ ! -e "$CODEX_HOME/quota-state.json.pace" ]

  printf '{"source":"user-owned"}\n' > "$CODEX_HOME/quota-state.json"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --uninstall
  [ "$status" -eq 0 ]
  [ -e "$CODEX_HOME/quota-state.json" ]
}

@test "Codex installer accepts an explicit binary outside PATH" {
  node_binary=$(command -v node)
  mkdir -p "$TMP/codex-bin"
  cat > "$TMP/codex-bin/codex" <<SH
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$TMP/codex-install.log"
SH
  chmod +x "$TMP/codex-bin/codex"
  run env PATH="/usr/bin:/bin" CODEX_BINARY="$TMP/codex-bin/codex" HOME="$HOME" CODEX_HOME="$CODEX_HOME" \
    "$node_binary" "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex
  [ "$status" -eq 0 ]
  grep -q '^--version$' "$TMP/codex-install.log"
  grep -q '^plugin marketplace add ' "$TMP/codex-install.log"
  grep -q '^plugin add wr-cruise@windyroad-local$' "$TMP/codex-install.log"
}

@test "stale Codex calls start at most one background refresh" {
  export WR_QUOTA_CACHE_FILE="$CODEX_HOME/quota-state.json"
  export WR_QUOTA_MARKER="$TMP/state"
  export WR_QUOTA_THROTTLE_MAX_SLEEP=0
  printf '{"five_used_pct":0,"five_resets_at":0,"five_window_s":0,"week_used_pct":7,"week_resets_at":1785258703,"week_window_s":604800}\n' > "$WR_QUOTA_CACHE_FILE"
  perl -e 'utime time-120, time-120, $ARGV[0]' "$WR_QUOTA_CACHE_FILE"
  mkdir -p "$TMP/bin"
  cat > "$TMP/bin/node" <<SH
#!/usr/bin/env bash
printf 'x\n' >> "$TMP/refresh-calls"
sleep 1
SH
  chmod +x "$TMP/bin/node"
  export PATH="$TMP/bin:$PATH"
  bash "$THROTTLE" </dev/null
  rm -f "$WR_QUOTA_MARKER"
  bash "$THROTTLE" </dev/null
  sleep 2
  [ "$(wc -l < "$TMP/refresh-calls")" -eq 1 ]
}

@test "Cruise Codex packaging and installer are wired" {
  PACKAGE="${BATS_TEST_DIRNAME}/.."
  [ -f "$PACKAGE/.codex-plugin/plugin.json" ]
  grep -q '".codex-plugin/"' "$PACKAGE/package.json"
  grep -q -- '--runtime' "$PACKAGE/bin/install.mjs"
  grep -q 'runtime: flags.runtime' "$PACKAGE/bin/install.mjs"
  grep -q '"name": "wr-cruise"' "$PACKAGE/.agents/plugins/marketplace.json"
}
