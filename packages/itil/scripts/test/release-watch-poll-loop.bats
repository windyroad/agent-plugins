#!/usr/bin/env bats

# P143: scripts/release-watch.sh must absorb changesets/action workflow
# latency by polling `gh pr list` for up to 120s before exiting "no open
# release PR found". The release PR is created/updated asynchronously by
# the changesets/action GitHub workflow ~30-120s after `git push`; the
# script's first call routinely raced this window and exited 1.
#
# Behavioural test (ADR-037 + P081 — behavioural over structural grep).
# Extracts `find_release_pr` from the script via awk, sources it, and
# exercises it against a PATH-shadowed `gh` mock + stubbed `sleep`. The
# mock consumes a comma-delimited iteration sequence (e.g. "empty,empty,ok")
# so each iteration's `gh pr list` payload is deterministic.
#
# Mirrors the extraction + PATH-shadow pattern in
# scripts/repo-local-skills/install-updates/test/install-updates-step-7-retry-rollback.bats.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/release-watch.sh"

  FN_FILE="$BATS_TEST_TMPDIR/find-release-pr.sh"
  awk '
    /^find_release_pr\(\) \{/ { in_fn=1 }
    in_fn { print }
    in_fn && /^\}/ { exit }
  ' "$SCRIPT" > "$FN_FILE"
}

# Stand up a PATH-shadowing `gh` mock that consumes a comma-delimited
# iteration sequence ("empty" / "ok"). Each `gh pr list` call advances the
# pointer; "empty" returns `[]`, "ok" returns a one-PR JSON array.
make_gh_mock() {
  local pattern="$1"
  local bindir="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bindir"
  printf '%s' "$pattern" > "$BATS_TEST_TMPDIR/gh-pattern"
  printf '0' > "$BATS_TEST_TMPDIR/gh-counter"
  : > "$BATS_TEST_TMPDIR/gh-log"
  cat > "$bindir/gh" <<'MOCK'
#!/usr/bin/env bash
echo "$*" >> "$BATS_TEST_TMPDIR/gh-log"
case "$1 $2" in
  "pr list")
    pattern=$(cat "$BATS_TEST_TMPDIR/gh-pattern")
    count=$(cat "$BATS_TEST_TMPDIR/gh-counter")
    count=$((count + 1))
    printf '%s' "$count" > "$BATS_TEST_TMPDIR/gh-counter"
    next=$(printf '%s' "$pattern" | cut -d, -f"$count")
    if [ "$next" = "ok" ]; then
      echo '[{"number":99,"url":"https://github.com/example/repo/pull/99"}]'
    else
      echo '[]'
    fi
    exit 0
    ;;
  *) exit 0 ;;
esac
MOCK
  chmod +x "$bindir/gh"
  PATH="$bindir:$PATH"
  export PATH
}

# Suppress real sleeps during tests — 120s wall-clock is unacceptable.
# Records each call so we can count iterations.
stub_sleep() {
  : > "$BATS_TEST_TMPDIR/sleep-log"
  eval 'sleep() { echo "$1" >> "$BATS_TEST_TMPDIR/sleep-log"; }'
  export -f sleep
}

count_gh_pr_list_calls() {
  [ -f "$BATS_TEST_TMPDIR/gh-log" ] || { echo 0; return; }
  awk '/^pr list/ { n++ } END { print n+0 }' "$BATS_TEST_TMPDIR/gh-log"
}

count_sleep_calls() {
  [ -f "$BATS_TEST_TMPDIR/sleep-log" ] || { echo 0; return; }
  awk 'END { print NR+0 }' "$BATS_TEST_TMPDIR/sleep-log"
}

@test "find_release_pr extracted from release-watch.sh is non-empty" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
}

@test "P143: PR exists on first iteration — fast path, one gh call, no sleep" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  make_gh_mock "ok"
  stub_sleep

  run find_release_pr
  [ "$status" -eq 0 ]
  # stdout is "<number>\t<url>"
  [[ "$output" == *"99"* ]]
  [[ "$output" == *"https://github.com/example/repo/pull/99"* ]]

  [ "$(count_gh_pr_list_calls)" -eq 1 ]
  [ "$(count_sleep_calls)" -eq 0 ]
}

@test "P143: PR appears on iteration 3 — three gh calls, two sleeps, returns the PR" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  make_gh_mock "empty,empty,ok"
  stub_sleep

  run find_release_pr
  [ "$status" -eq 0 ]
  [[ "$output" == *"99"* ]]

  [ "$(count_gh_pr_list_calls)" -eq 3 ]
  [ "$(count_sleep_calls)" -eq 2 ]
}

@test "P143: empty for full 12 iterations — 12 gh calls, exit 1" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  # 12 empties, no 13th column needed — function should give up after 12.
  make_gh_mock "empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty"
  stub_sleep

  run find_release_pr
  [ "$status" -ne 0 ]

  [ "$(count_gh_pr_list_calls)" -eq 12 ]
  # 11 sleeps between 12 iterations (no trailing sleep after the final
  # empty result — that would burn 10s for nothing).
  [ "$(count_sleep_calls)" -eq 11 ]
}

@test "P143: RELEASE_WATCH_VERBOSE=1 prints poll progress to stderr" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  make_gh_mock "empty,empty,ok"
  stub_sleep

  RELEASE_WATCH_VERBOSE=1 run find_release_pr
  [ "$status" -eq 0 ]
  # `bats run` merges stdout + stderr in $output by default.
  [[ "$output" == *"Polling"* ]] || [[ "$output" == *"attempt"* ]]
}

@test "P143: default (verbose unset) does NOT print poll progress" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  make_gh_mock "empty,empty,ok"
  stub_sleep

  unset RELEASE_WATCH_VERBOSE
  run find_release_pr
  [ "$status" -eq 0 ]
  # Output is the final tab-separated PR line ONLY — no progress lines.
  [[ "$output" != *"Polling"* ]]
  [[ "$output" != *"attempt"* ]]
}

@test "P143: returns tab-separated number and URL on success (parseable)" {
  [ -s "$FN_FILE" ] || { echo "find_release_pr missing from $SCRIPT"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"
  make_gh_mock "ok"
  stub_sleep

  run find_release_pr
  [ "$status" -eq 0 ]
  # Caller parses with `cut -f1` / `cut -f2` — the contract is one line,
  # tab-separated.
  local first_field second_field
  first_field=$(printf '%s\n' "$output" | head -1 | cut -f1)
  second_field=$(printf '%s\n' "$output" | head -1 | cut -f2)
  [ "$first_field" = "99" ]
  [ "$second_field" = "https://github.com/example/repo/pull/99" ]
}
