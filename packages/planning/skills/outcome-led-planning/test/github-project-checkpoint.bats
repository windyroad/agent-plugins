#!/usr/bin/env bats

@test "GitHub resume checkpoint exercises saved state and truthful publication through gh subprocesses" {
  run node --test "$(dirname "$BATS_TEST_FILENAME")/github-project-checkpoint.test.mjs"
  [ "$status" -eq 0 ]
}
