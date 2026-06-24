#!/usr/bin/env bats

# P378/RFC-030 Piece 2: itil-commit-trailer-transition-advisory.sh — the shared
# RFC+story commit-trailer auto-transition DETECTOR. Advises (ADR-014: does not
# perform) proposed/accepted RFC → in-progress and draft story → in-progress on
# the first non-capture commit carrying the Refs trailer. Behavioural.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-commit-trailer-transition-advisory.sh"
  DIR="$(mktemp -d)"; cd "$DIR"
  git init -q; git config user.email t@e.x; git config user.name t
  mkdir -p docs/rfcs docs/stories/draft
  echo x > seed; git add -A; git commit -qm "chore: seed"
}
teardown() { cd /; rm -rf "$DIR"; }

# Feed the hook a PostToolUse Bash payload for a `git commit` command.
run_hook() {
  printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}' | bash "$HOOK"
}

commit() { git commit -q --allow-empty -m "$1"; }

@test "advises proposed RFC → in-progress on a non-capture Refs commit" {
  echo "---" > docs/rfcs/RFC-201-x.proposed.md; git add -A; commit "$(printf 'docs(rfcs): capture RFC-201 x\n\nRefs: RFC-201')"
  commit "$(printf 'feat(itil): do slice 1\n\nRefs: RFC-201')"
  run run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"RFC-201"* ]]
  [[ "$output" == *"in-progress"* ]]
  [[ "$output" == *"manage-rfc"* ]]
}

@test "silent on the capture commit itself" {
  echo "---" > docs/rfcs/RFC-201-x.proposed.md; git add -A; commit "$(printf 'docs(rfcs): capture RFC-201 x\n\nRefs: RFC-201')"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when the RFC is already in-progress (no .proposed/.accepted file)" {
  echo "---" > docs/rfcs/RFC-201-x.in-progress.md; git add -A; commit "$(printf 'feat(itil): more\n\nRefs: RFC-201')"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "advises draft story → in-progress on a non-capture Refs commit" {
  echo "---" > docs/stories/draft/STORY-201-y.md; git add -A; commit "$(printf 'feat(itil): capture STORY-201 y\n\nRefs: STORY-201')"
  commit "$(printf 'feat(itil): implement\n\nRefs: STORY-201')"
  run run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"STORY-201"* ]]
  [[ "$output" == *"manage-story"* ]]
}

@test "bypass env var suppresses the advisory" {
  echo "---" > docs/rfcs/RFC-201-x.proposed.md; git add -A; commit "$(printf 'feat: s\n\nRefs: RFC-201')"
  run env BYPASS_TRANSITION_ADVISORY=1 bash -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m x\"}}" | bash "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when commit carries no Refs trailer" {
  echo "---" > docs/rfcs/RFC-201-x.proposed.md; git add -A; commit "chore: untagged"
  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
