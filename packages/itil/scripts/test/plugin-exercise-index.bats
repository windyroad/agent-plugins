#!/usr/bin/env bats

# @problem P087 — Phase 2b git-axis script behavioural confirmation.
#
# Contract under test: `packages/itil/scripts/plugin-exercise-index.sh` runs
# `git log --since=<N>d --name-only --pretty=format:%H|%aI|%s` once at the
# project root, auto-discovers plugins by listing `packages/*/`, and emits
# one NDJSON record per plugin with the v1.0 schema fields per ADR-058
# §Script contracts (line 87-113). Exit code 0 always per ADR-013 Rule 6
# fail-safe (outside-git-repo, missing `packages/`, opt-out marker all hit
# the zero-records/stderr-comment path).
#
# Confirmation criteria 6-8 from ADR-058 §Confirmation are the load-bearing
# behavioural assertions in this file. Sibling to Phase 2a's
# `skill-invocations.bats` (criteria 1-5).
#
# @adr ADR-058 (Plugin maturity measurement mechanism)
# @adr ADR-049 (Shim grammar — `wr-itil-plugin-exercise-index` on $PATH)
# @adr ADR-035 (Privacy posture — opt-out marker, no network primitive,
#   content sanitisation — commit subjects parsed only for `BREAKING|feat!|fix!`
#   token presence, never echoed to stdout)
# @adr ADR-052 (Behavioural tests default — NDJSON-output-driven against
#   fixture git repos, not source-greps on script body; the no-network
#   negative-grep at Confirmation #3 is the documented carve-out)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — exit 0 always)
# @jtbd JTBD-101 (Extend the Suite — hardening-prioritisation outcome,
#   commits_window + closed_tickets_window + days_shipped serve the
#   git-axis half of the 2026-05-04 outcome amendment)
# @jtbd JTBD-201 (Restore Service Fast — audit-trail composition)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/plugin-exercise-index.sh"
  FIXTURE_DIR="$(mktemp -d)"
  REPO_ROOT="$FIXTURE_DIR/repo"
  mkdir -p "$REPO_ROOT"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# Helper: initialise a temp git repo at REPO_ROOT with a stable author/email
# (otherwise `git commit` aborts on systems without user.name configured).
init_repo() {
  (
    cd "$REPO_ROOT"
    git init -q -b main
    git config user.email "bats@example.com"
    git config user.name "bats"
    git config commit.gpgsign false
  )
}

# Helper: stage a file under packages/<plugin>/ and commit at a given date.
# Date is ISO 8601 (e.g. 2026-05-01T12:00:00) — fed to GIT_AUTHOR_DATE /
# GIT_COMMITTER_DATE so log --since works deterministically.
commit_under_plugin() {
  local plugin="$1"; local relpath="$2"; local subject="$3"; local date="$4"
  local full="$REPO_ROOT/packages/$plugin/$relpath"
  mkdir -p "$(dirname "$full")"
  echo "content-$RANDOM" >> "$full"
  (
    cd "$REPO_ROOT"
    GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
      git -c user.email=bats@example.com -c user.name=bats \
      add "packages/$plugin/$relpath" >/dev/null
    GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
      git -c user.email=bats@example.com -c user.name=bats \
      commit -q -m "$subject"
  )
}

# Helper: ISO timestamp N days ago (UTC). Cross-platform — uses python3.
days_ago_iso() {
  python3 -c "import sys, datetime; print((datetime.datetime.utcnow() - datetime.timedelta(days=int(sys.argv[1]))).strftime('%Y-%m-%dT%H:%M:%S'))" "$1"
}

# ── Existence / executable ──────────────────────────────────────────────────

@test "plugin-exercise-index: canonical script exists" {
  [ -f "$SCRIPT" ]
}

@test "plugin-exercise-index: canonical script is executable" {
  [ -x "$SCRIPT" ]
}

@test "plugin-exercise-index: shim file exists with ADR-049 grammar" {
  local shim="$SCRIPTS_DIR/../bin/wr-itil-plugin-exercise-index"
  [ -f "$shim" ]
  [ -x "$shim" ]
  grep -q 'exec.*scripts/plugin-exercise-index.sh' "$shim"
}

# ── Confirmation #6: git-axis composite fixture ─────────────────────────────
# Seed a temp git repo with packages/dummy/ + three commits (one in window,
# two out of window). Assert NDJSON record for plugin="dummy" has
# commits_window=1 under the 60-day default window.

@test "Confirmation #6: three commits, one in window, commits_window=1" {
  init_repo
  local in_window=$(days_ago_iso 10)
  local out_window_1=$(days_ago_iso 90)
  local out_window_2=$(days_ago_iso 120)
  commit_under_plugin "dummy" "src/a.txt" "feat: in-window change" "$in_window"
  commit_under_plugin "dummy" "src/b.txt" "feat: out-of-window 1" "$out_window_1"
  commit_under_plugin "dummy" "src/c.txt" "feat: out-of-window 2" "$out_window_2"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  # Exactly one NDJSON record for plugin="dummy"
  local rec
  rec="$(echo "$output" | grep '"plugin":"dummy"')"
  [ -n "$rec" ]
  echo "$rec" | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['schema_version'] == '1.0', r
assert r['axis'] == 'plugin-exercise-index', r
assert r['plugin'] == 'dummy', r
assert r['commits_window'] == 1, r
assert r['window_days'] == 60, r
assert r['days_shipped'] >= 120, r
"
}

@test "Confirmation #6: emits one record per discovered plugin" {
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "alpha" "src/a.txt" "feat: alpha change" "$ts"
  commit_under_plugin "beta" "src/b.txt" "feat: beta change" "$ts"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"plugin":"alpha"'
  echo "$output" | grep -q '"plugin":"beta"'
  # Line count = number of discovered plugins (alpha + beta)
  local line_count
  line_count="$(printf '%s' "$output" | grep -c .)"
  [ "$line_count" -eq 2 ]
}

@test "Confirmation #6: commit subject containing literal pipe parses correctly" {
  # ADR-058 line 89 pins `--pretty=format:%H|%aI|%s` — the parser must
  # split on first two `|` only (line.split('|', 2)) so subjects with
  # literal `|` characters do not corrupt parsing. Architect advisory.
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "pipey" "src/a.txt" "feat: subject with | pipe in it" "$ts"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"plugin":"pipey"'
  echo "$output" | grep -q '"commits_window":1'
}

# ── Confirmation #7: outside-git-repo fixture ───────────────────────────────

@test "Confirmation #7: outside-git-repo emits zero records, stderr comment, exit 0" {
  # REPO_ROOT exists but no `git init` ran — it is not a git repo.
  local stdout_file="$FIXTURE_DIR/nogit.out"
  local stderr_file="$FIXTURE_DIR/nogit.err"
  "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT" >"$stdout_file" 2>"$stderr_file"
  local rc=$?
  [ "$rc" -eq 0 ]
  [ ! -s "$stdout_file" ]
  grep -q "not a git repository" "$stderr_file"
}

@test "Confirmation #7: missing packages/ directory emits zero records, exit 0" {
  init_repo
  # Repo has no packages/ directory at all. Make a non-packages commit so
  # `git log` returns something but no plugins are discovered.
  (
    cd "$REPO_ROOT"
    echo readme > README.md
    GIT_AUTHOR_DATE="$(days_ago_iso 5)" GIT_COMMITTER_DATE="$(days_ago_iso 5)" \
      git -c user.email=bats@example.com -c user.name=bats add README.md >/dev/null
    GIT_AUTHOR_DATE="$(days_ago_iso 5)" GIT_COMMITTER_DATE="$(days_ago_iso 5)" \
      git -c user.email=bats@example.com -c user.name=bats commit -q -m "feat: readme"
  )

  local stdout_file="$FIXTURE_DIR/nopkg.out"
  local stderr_file="$FIXTURE_DIR/nopkg.err"
  "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT" >"$stdout_file" 2>"$stderr_file"
  local rc=$?
  [ "$rc" -eq 0 ]
  [ ! -s "$stdout_file" ]
  grep -q "no packages/ directory" "$stderr_file"
}

# ── Confirmation #8: schema-version contract ────────────────────────────────

@test "Confirmation #8: every NDJSON record has schema_version=1.0" {
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "p1" "src/a.txt" "feat: p1" "$ts"
  commit_under_plugin "p2" "src/b.txt" "feat: p2" "$ts"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  # Validate every line carries schema_version="1.0"
  echo "$output" | python3 -c "
import json, sys
for line in sys.stdin:
  line = line.strip()
  if not line: continue
  r = json.loads(line)
  assert r['schema_version'] == '1.0', r
  assert r['axis'] == 'plugin-exercise-index', r
"
}

# ── Privacy: opt-out marker ─────────────────────────────────────────────────

@test "opt-out marker disables reads, stderr comment, exit 0" {
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "x" "src/a.txt" "feat: would-be-recorded" "$ts"
  mkdir -p "$REPO_ROOT/.claude"
  touch "$REPO_ROOT/.claude/.skill-metrics-opt-out"

  local stdout_file="$FIXTURE_DIR/opt.out"
  local stderr_file="$FIXTURE_DIR/opt.err"
  "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT" >"$stdout_file" 2>"$stderr_file"
  local rc=$?
  [ "$rc" -eq 0 ]
  [ ! -s "$stdout_file" ]
  grep -q "opt-out marker present at" "$stderr_file"
}

# ── Privacy: no-network-primitive (ADR-052 negative-grep carve-out) ─────────

@test "canonical body contains no network primitives" {
  run grep -nE '\bcurl\b|\bwget\b|\bnc[[:space:]]|\bfetch\b|http\.client|\burllib\b' "$SCRIPT"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# ── Privacy: commit-subject prose never leaks beyond breaking-marker test ───

@test "commit subjects never appear in NDJSON output beyond BREAKING/feat!/fix! parse" {
  init_repo
  local ts=$(days_ago_iso 5)
  # Subject contains a recognisable token that must NOT echo to stdout.
  commit_under_plugin "secrety" "src/a.txt" "feat: contains SECRETPROSEXYZ token" "$ts"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"plugin":"secrety"'
  ! echo "$output" | grep -q "SECRETPROSEXYZ"
}

# ── composite_index calculation ─────────────────────────────────────────────

@test "composite_index = log10(commits+1) + log10(closed+1) + days_shipped_bonus" {
  init_repo
  # Set the OLDEST commit > 60 days ago to earn the days_shipped >= 60 bonus
  # of +1.0. Then add 9 in-window commits so log10(9+1) = 1.0.
  commit_under_plugin "calc" "src/old.txt" "feat: old" "$(days_ago_iso 90)"
  for i in 1 2 3 4 5 6 7 8 9; do
    commit_under_plugin "calc" "src/n$i.txt" "feat: n$i" "$(days_ago_iso 5)"
  done

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  # commits_window=9 (only the 9 recent ones), days_shipped >= 60 (90 days
  # since oldest), closed_tickets_window=0 (no docs/problems/).
  # composite_index = log10(10) + log10(1) + 1.0 = 1.0 + 0.0 + 1.0 = 2.0
  echo "$output" | grep '"plugin":"calc"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['commits_window'] == 9, r
assert r['days_shipped'] >= 60, r
assert r['closed_tickets_window'] == 0, r
assert abs(r['composite_index'] - 2.0) < 0.01, r
"
}

@test "composite_index respects days_shipped < 60 (no bonus)" {
  init_repo
  # All commits within last 30 days; days_shipped < 60.
  for i in 1 2 3 4 5 6 7 8 9; do
    commit_under_plugin "young" "src/n$i.txt" "feat: n$i" "$(days_ago_iso 5)"
  done

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  # commits_window=9, days_shipped=5, closed_tickets_window=0
  # composite_index = log10(10) + log10(1) + 0.0 = 1.0
  echo "$output" | grep '"plugin":"young"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['commits_window'] == 9, r
assert r['days_shipped'] < 60, r
assert abs(r['composite_index'] - 1.0) < 0.01, r
"
}

# ── closed_tickets_window ──────────────────────────────────────────────────

@test "closed_tickets_window counts .closed/.verifying tickets citing the plugin" {
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "cited" "src/a.txt" "feat: cited" "$ts"
  # Seed two closed tickets in docs/problems/ — one cites packages/cited/,
  # one does not. Both have recent mtime so the 90-day window includes them.
  mkdir -p "$REPO_ROOT/docs/problems"
  echo "## Related
- packages/cited/scripts/foo.sh" > "$REPO_ROOT/docs/problems/100-something.closed.md"
  echo "## Related
- packages/other/scripts/bar.sh" > "$REPO_ROOT/docs/problems/101-other.closed.md"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep '"plugin":"cited"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['closed_tickets_window'] == 1, r
"
}

# ── breaking_change_age_days ───────────────────────────────────────────────

@test "breaking_change_age_days surfaces BREAKING/feat!/fix! marker presence" {
  init_repo
  local recent=$(days_ago_iso 3)
  local older=$(days_ago_iso 20)
  commit_under_plugin "brk" "src/a.txt" "feat: normal change" "$older"
  commit_under_plugin "brk" "src/b.txt" "feat!: breaking change" "$recent"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep '"plugin":"brk"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
v = r['breaking_change_age_days']
assert v is not None, r
assert 0 <= v <= 7, r
"
}

@test "breaking_change_age_days is null when no breaking marker in window" {
  init_repo
  local ts=$(days_ago_iso 5)
  commit_under_plugin "nobreak" "src/a.txt" "feat: ordinary" "$ts"
  commit_under_plugin "nobreak" "src/b.txt" "fix: ordinary" "$ts"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep '"plugin":"nobreak"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['breaking_change_age_days'] is None, r
"
}

# ── Forward-extension flag: --category-overrides ────────────────────────────

@test "category-overrides flag is accepted without functional effect" {
  init_repo
  commit_under_plugin "cat" "src/a.txt" "feat: cat" "$(days_ago_iso 5)"
  echo '{}' > "$FIXTURE_DIR/overrides.json"

  run "$SCRIPT" --window-days=60 --project-root="$REPO_ROOT" --category-overrides="$FIXTURE_DIR/overrides.json"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"plugin":"cat"'
}

# ── Window-days filter ──────────────────────────────────────────────────────

@test "window-days filter excludes commits older than the window" {
  init_repo
  commit_under_plugin "win" "src/old.txt" "feat: old" "$(days_ago_iso 30)"
  commit_under_plugin "win" "src/new.txt" "feat: new" "$(days_ago_iso 1)"

  run "$SCRIPT" --window-days=7 --project-root="$REPO_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep '"plugin":"win"' | python3 -c "
import json, sys
r = json.loads(sys.stdin.read().strip())
assert r['commits_window'] == 1, r
assert r['window_days'] == 7, r
"
}
