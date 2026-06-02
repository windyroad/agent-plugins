#!/usr/bin/env bats
# Behavioural-fixture coverage for packages/risk-scorer/scripts/restage-commit.sh
# per ADR-052 (behavioural tests default) and P326 (re-stage-after-scorer-delegation).
#
# The script is invoked AFTER the agent delegates to wr-risk-scorer:pipeline
# to land the commit atomically — re-stages paths the Agent-tool boundary cleared
# from the index, asserts staging is non-empty, then runs `git commit` with the
# caller's -m args. Eliminates the silent re-add round-trip P326 documented.
#
# Surface:
#   wr-risk-scorer-restage-commit -m "<msg>" [-m "<trailer>"] -- <path1> [<path2>...]

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/risk-scorer/scripts/restage-commit.sh"
  SHIM="$REPO_ROOT/packages/risk-scorer/bin/wr-risk-scorer-restage-commit"
  WORK_DIR="$(mktemp -d)"
  cd "$WORK_DIR"
  git init --quiet
  git config user.email "restage-test@example.com"
  git config user.name "Restage Test"
  git config commit.gpgsign false
  git commit --quiet --allow-empty -m "init"
}

teardown() {
  cd /
  rm -rf "$WORK_DIR"
}

@test "shim wrapper exists and is executable" {
  [ -x "$SHIM" ]
}

@test "shim resolves canonical script (not exit 127)" {
  echo "seed" > seed.txt
  run "$SHIM" -m "test" -- seed.txt
  [ "$status" -ne 127 ]
}

@test "single path: re-stages and commits (the P326 happy path)" {
  echo "content" > file.txt
  run bash "$SCRIPT" -m "test: commit file" -- file.txt
  [ "$status" -eq 0 ]
  run git log -1 --name-only --format=
  echo "$output" | grep -q '^file\.txt$'
}

@test "multi-path: re-stages all paths and commits them in one commit" {
  echo "a" > a.txt
  echo "b" > b.txt
  echo "c" > c.txt
  run bash "$SCRIPT" -m "test: multi" -- a.txt b.txt c.txt
  [ "$status" -eq 0 ]
  run git log -1 --name-only --format=
  echo "$output" | grep -q '^a\.txt$'
  echo "$output" | grep -q '^b\.txt$'
  echo "$output" | grep -q '^c\.txt$'
}

@test "multiple -m flags pass through (trailer like RISK_BYPASS)" {
  echo "x" > x.txt
  run bash "$SCRIPT" \
    -m "docs(problems): capture P999 test" \
    -m "RISK_BYPASS: capture-deferred-readme" \
    -- x.txt
  [ "$status" -eq 0 ]
  run git log -1 --format=%B
  echo "$output" | grep -q '^docs(problems): capture P999 test'
  echo "$output" | grep -q 'RISK_BYPASS: capture-deferred-readme'
}

@test "missing -m flag → exit 1, no commit" {
  echo "x" > x.txt
  run bash "$SCRIPT" -- x.txt
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi 'message\|usage'
  run git log --oneline
  [ "$(echo "$output" | wc -l | tr -d ' ')" = "1" ]
}

@test "missing -- separator → exit 1" {
  echo "x" > x.txt
  run bash "$SCRIPT" -m "test" x.txt
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi 'separator\|usage'
}

@test "no paths after -- → exit 1, no commit" {
  run bash "$SCRIPT" -m "test" --
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi 'path\|usage'
  run git log --oneline
  [ "$(echo "$output" | wc -l | tr -d ' ')" = "1" ]
}

@test "nothing staged after re-add → exit 1, no commit (e.g. unchanged file)" {
  echo "tracked" > tracked.txt
  git add tracked.txt
  git commit --quiet -m "seed tracked"
  run bash "$SCRIPT" -m "test: should fail" -- tracked.txt
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi 'nothing staged\|empty'
  run git log --oneline
  [ "$(echo "$output" | wc -l | tr -d ' ')" = "2" ]
}

@test "path that doesn't exist → exit non-zero (git add propagates)" {
  run bash "$SCRIPT" -m "test" -- nonexistent.txt
  [ "$status" -ne 0 ]
}

@test "rename via git mv survives the re-stage-and-commit (P057 + P326 compose)" {
  echo "v1" > orig.md
  git add orig.md
  git commit --quiet -m "seed"
  git mv orig.md renamed.md
  echo "v2" >> renamed.md
  run bash "$SCRIPT" -m "test: rename+edit" -- renamed.md
  [ "$status" -eq 0 ]
  run git log -1 --name-only --format=
  echo "$output" | grep -q '^renamed\.md$'
  [ ! -f orig.md ]
  run cat renamed.md
  echo "$output" | grep -q 'v2'
}

@test "doesn't touch unrelated unstaged changes" {
  echo "subject" > subject.txt
  echo "bystander" > bystander.txt
  run bash "$SCRIPT" -m "test: subject only" -- subject.txt
  [ "$status" -eq 0 ]
  run git status --porcelain bystander.txt
  echo "$output" | grep -q '^?? bystander\.txt'
  run git log -1 --name-only --format=
  ! echo "$output" | grep -q '^bystander\.txt$'
}
