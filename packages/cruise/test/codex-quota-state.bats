#!/usr/bin/env bats

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../scripts/codex-quota-state.mjs"
  HOOK="${BATS_TEST_DIRNAME}/../hooks/quota-state-producer-install.sh"
  THROTTLE="${BATS_TEST_DIRNAME}/../hooks/quota-pace-throttle.sh"
  STATUS="${BATS_TEST_DIRNAME}/../scripts/cruise-status.sh"
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

@test "persisted installer binary works when CODEX_BINARY and PATH do not provide Codex" {
  printf '{"codex_binary":"%s"}\n' "$CODEX_BINARY" > "$CODEX_HOME/cruise.config.json"
  unset CODEX_BINARY
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":8,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "8" ]
}

@test "project config cannot override the machine-managed Codex binary" {
  project="$TMP/project"
  mkdir -p "$project/.codex"
  printf '{"codex_binary":"%s"}\n' "$TMP/missing-project-codex" > "$project/.codex/cruise.config.json"
  printf '{"codex_binary":"%s"}\n' "$CODEX_BINARY" > "$CODEX_HOME/cruise.config.json"
  unset CODEX_BINARY
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":10,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run bash -c 'cd "$1" && node "$2"' _ "$project" "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "10" ]
}

@test "unusable first candidate falls through to the persisted binary" {
  persisted="$TMP/persisted-codex"
  cp "$CODEX_BINARY" "$persisted"
  printf '#!/usr/bin/env bash\nwhile IFS= read -r line; do case "$line" in *"id\":0"*) printf '\''{"id":0,"result":{}}\\n'\'';; *account/rateLimits/read*) printf '\''{"id":1,"result":{"rateLimits":{"primary":null}}}\\n'\'';; esac; done\n' > "$CODEX_BINARY"
  chmod +x "$CODEX_BINARY"
  printf '{"codex_binary":"%s"}\n' "$persisted" > "$CODEX_HOME/cruise.config.json"
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":12,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.week_used_pct' "$CODEX_HOME/quota-state.json")" = "12" ]
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

@test "producer failure writes a private bounded diagnostic and success clears it" {
  export CODEX_BINARY="$TMP/missing-codex"
  export WR_CRUISE_CODEX_BINARY_ONLY=1
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.source' "$CODEX_HOME/quota-state.error.json")" = "wr-cruise" ]
  [ "$(jq -r '.error' "$CODEX_HOME/quota-state.error.json")" = "No usable Codex binary found" ]
  mode=$(/usr/bin/stat -f %Lp "$CODEX_HOME/quota-state.error.json" 2>/dev/null || /usr/bin/stat -c %a "$CODEX_HOME/quota-state.error.json")
  [ "$mode" = "600" ]

  unset WR_CRUISE_CODEX_BINARY_ONLY
  export CODEX_BINARY="$TMP/fake-codex"
  export FAKE_RATE_LIMITS='{"rateLimits":{"primary":{"usedPercent":9,"windowDurationMins":10080,"resetsAt":1785258703}}}'
  run node "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -e "$CODEX_HOME/quota-state.error.json" ]
}

@test "status reports the producer failure when the Codex cache is absent" {
  export CODEX_BINARY="$TMP/missing-codex"
  export WR_CRUISE_CODEX_BINARY_ONLY=1
  run bash "$STATUS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No quota cache"* ]]
  [[ "$output" == *"Producer error: No usable Codex binary found"* ]]
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

  run bash "$THROTTLE" <<< '{"session_id":"codex-payload-session","turn_id":"codex-turn","transcript_path":"/tmp/codex-transcript.jsonl","cwd":"/tmp/project","hook_event_name":"PreToolUse","model":"gpt-test","permission_mode":"bypassPermissions","tool_name":"Bash","tool_input":{"command":"pwd"},"tool_use_id":"exec-test"}'

  [ "$status" -eq 0 ]
  [ -f "$TMPDIR/wr-quota-throttle-codex-payload-session" ]
  [ "$(awk '{print $3}' "$TMPDIR/wr-quota-throttle-codex-payload-session")" = "29" ]
  [ "$(awk '{print $5}' "$TMPDIR/wr-quota-throttle-codex-payload-session")" = "10" ]
  [ ! -e "$TMPDIR/wr-quota-throttle-shared" ]
}

@test "Claude hook payload with model still selects Claude cache" {
  unset CODEX_THREAD_ID CODEX_HOME CLAUDE_SESSION_ID WR_QUOTA_MARKER WR_QUOTA_CACHE_FILE
  export HOME="$TMP/payload-home"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$HOME/.codex" "$HOME/.claude" "$TMPDIR"
  printf '{"five_used_pct":0,"five_resets_at":0,"week_used_pct":29,"week_resets_at":1}\n' > "$HOME/.codex/quota-state.json"
  printf '{"five_used_pct":11,"five_resets_at":1,"week_used_pct":42,"week_resets_at":1}\n' > "$HOME/.claude/quota-state.json"

  run bash "$THROTTLE" <<< '{"session_id":"claude-payload-session","transcript_path":"/tmp/claude-transcript.jsonl","cwd":"/tmp/project","hook_event_name":"PreToolUse","model":"claude-test","permission_mode":"default","tool_name":"Bash","tool_input":{"command":"pwd"},"tool_use_id":"tool-test"}'

  [ "$status" -eq 0 ]
  [ "$(awk '{print $3}' "$TMPDIR/wr-quota-throttle-claude-payload-session")" = "42" ]
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
  printf '{"source":"wr-cruise","error":"test"}\n' > "$CODEX_HOME/quota-state.error.json"
  printf '{"max_sleep_s":0,"codex_binary":"%s"}\n' "$TMP/bin/codex" > "$CODEX_HOME/cruise.config.json"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --uninstall
  [ "$status" -eq 0 ]
  [ ! -e "$CODEX_HOME/quota-state.json" ]
  [ ! -e "$CODEX_HOME/quota-state.json.pace" ]
  [ ! -e "$CODEX_HOME/quota-state.error.json" ]
  [ "$(jq -r '.max_sleep_s' "$CODEX_HOME/cruise.config.json")" = "0" ]
  [ "$(jq -r '.codex_binary // empty' "$CODEX_HOME/cruise.config.json")" = "" ]

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
  printf '{"max_sleep_s":0}\n' > "$CODEX_HOME/cruise.config.json"
  run env PATH="/usr/bin:/bin" CODEX_BINARY="$TMP/codex-bin/codex" HOME="$HOME" CODEX_HOME="$CODEX_HOME" \
    "$node_binary" "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex
  [ "$status" -eq 0 ]
  grep -q '^--version$' "$TMP/codex-install.log"
  grep -q '^plugin marketplace add ' "$TMP/codex-install.log"
  grep -q '^plugin add wr-cruise@windyroad-local$' "$TMP/codex-install.log"
  [ "$(jq -r '.max_sleep_s' "$CODEX_HOME/cruise.config.json")" = "0" ]
  [ "$(jq -r '.codex_binary' "$CODEX_HOME/cruise.config.json")" = "$(realpath "$TMP/codex-bin/codex")" ]
}

@test "Codex installer falls through after a stale persisted binary" {
  node_binary=$(command -v node)
  mkdir -p "$TMP/fallback-bin"
  cat > "$TMP/stale-codex" <<'SH'
#!/usr/bin/env bash
exit 1
SH
  cat > "$TMP/fallback-bin/codex" <<SH
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$TMP/codex-fallback.log"
SH
  chmod +x "$TMP/stale-codex" "$TMP/fallback-bin/codex"
  printf '{"codex_binary":"%s"}\n' "$TMP/stale-codex" > "$CODEX_HOME/cruise.config.json"
  run env PATH="$TMP/fallback-bin:/usr/bin:/bin" HOME="$HOME" CODEX_HOME="$CODEX_HOME" \
    "$node_binary" "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex
  [ "$status" -eq 0 ]
  [ "$(jq -r '.codex_binary' "$CODEX_HOME/cruise.config.json")" != "$(realpath "$TMP/stale-codex")" ]
}

@test "Codex update uses the persisted binary without env or PATH support" {
  node_binary=$(command -v node)
  printf '{"codex_binary":"%s"}\n' "$CODEX_BINARY" > "$CODEX_HOME/cruise.config.json"
  run env PATH="/usr/bin:/bin" HOME="$HOME" CODEX_HOME="$CODEX_HOME" \
    "$node_binary" "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --update
  [ "$status" -eq 0 ]
  [ "$(jq -r '.codex_binary' "$CODEX_HOME/cruise.config.json")" = "$(realpath "$CODEX_BINARY")" ]
}

@test "Codex installer preserves malformed and non-object machine config" {
  node_binary=$(command -v node)
  for value in 'null' '[]' '"string"'; do
    printf '%s\n' "$value" > "$CODEX_HOME/cruise.config.json"
    before=$(cat "$CODEX_HOME/cruise.config.json")
    run env CODEX_BINARY="$CODEX_BINARY" HOME="$HOME" CODEX_HOME="$CODEX_HOME" \
      "$node_binary" "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex
    [ "$status" -eq 1 ]
    [ "$(cat "$CODEX_HOME/cruise.config.json")" = "$before" ]
  done
}

@test "Codex installer dry-run does not write machine config" {
  rm -f "$CODEX_HOME/cruise.config.json"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$CODEX_HOME/cruise.config.json" ]
}

@test "Codex dry-run uninstall leaves cache diagnostic and config untouched" {
  printf '{"source":"codex-app-server"}\n' > "$CODEX_HOME/quota-state.json"
  printf '{"source":"wr-cruise","error":"test"}\n' > "$CODEX_HOME/quota-state.error.json"
  printf '{"codex_binary":"%s"}\n' "$CODEX_BINARY" > "$CODEX_HOME/cruise.config.json"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --uninstall --dry-run
  [ "$status" -eq 0 ]
  [ -e "$CODEX_HOME/quota-state.json" ]
  [ -e "$CODEX_HOME/quota-state.error.json" ]
  [ "$(jq -r '.codex_binary' "$CODEX_HOME/cruise.config.json")" = "$CODEX_BINARY" ]
}

@test "failed Codex uninstall preserves producer state" {
  cat > "$CODEX_BINARY" <<'SH'
#!/usr/bin/env bash
case "$*" in
  --version) exit 0 ;;
  plugin\ remove\ *) exit 1 ;;
  *) exit 0 ;;
esac
SH
  chmod +x "$CODEX_BINARY"
  printf '{"source":"codex-app-server"}\n' > "$CODEX_HOME/quota-state.json"
  printf '{"source":"wr-cruise","error":"test"}\n' > "$CODEX_HOME/quota-state.error.json"
  printf '{"codex_binary":"%s"}\n' "$CODEX_BINARY" > "$CODEX_HOME/cruise.config.json"
  run node "${BATS_TEST_DIRNAME}/../bin/install.mjs" --runtime codex --uninstall
  [ "$status" -eq 1 ]
  [ -e "$CODEX_HOME/quota-state.json" ]
  [ -e "$CODEX_HOME/quota-state.error.json" ]
  [ "$(jq -r '.codex_binary' "$CODEX_HOME/cruise.config.json")" = "$CODEX_BINARY" ]
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
  grep -q 'execFileSync(binary' "$PACKAGE/bin/install.mjs"
  grep -q '"name": "wr-cruise"' "$PACKAGE/.agents/plugins/marketplace.json"
}
