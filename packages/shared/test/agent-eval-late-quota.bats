#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
}

@test "late pure quota stops later campaigns without crediting model passes" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" late
}

@test "only actual unsuccessful pure quota can latch unavailable state" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" classification
}

@test "concurrent ordinary and assertion failures remain blocking after quota" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" mixed
}

@test "missing malformed and stale partial results stay blocking" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" results
}

@test "available campaigns preserve selection command arguments and later recovery" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" campaigns
}

@test "Claude shim preserves ordinary arguments environment input streams and exit" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" forwarding
}

@test "real Promptfoo quota errors preserve JSON and satisfy the subprocess boundary" {
  python3 "$BATS_TEST_DIRNAME/agent-eval-quota-fixture.py" "$ROOT" promptfoo
}
