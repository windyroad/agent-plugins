#!/usr/bin/env bats

setup() {
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/check-published-internal-ids.sh"
  [ -x "$SCRIPT" ] || fail "missing $SCRIPT"
  FIXTURE="$(mktemp -d)/demo-plugin"
  mkdir -p "$FIXTURE/skills/demo" "$FIXTURE/hooks"
  printf '{"name":"fixture","version":"1.0.0","files":["skills/","hooks/"]}\n' > "$FIXTURE/package.json"
  printf '# @adr ADR-001\nA self-contained rule.\n' > "$FIXTURE/skills/demo/SKILL.md"
  printf '# ADR-002 source annotation\necho "self-contained recovery"\n' > "$FIXTURE/hooks/demo.sh"
}

teardown() {
  rm -rf "$(dirname "$FIXTURE")"
}

leak_the_fixture() {
  printf 'See STORY-MAP-123 for the rule.\n' >> "$FIXTURE/skills/demo/SKILL.md"
  printf 'echo "Blocked by P456"\n' >> "$FIXTURE/hooks/demo.sh"
}

@test "exact tarball check permits source comments and rejects published prose or output IDs" {
  run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]

  leak_the_fixture
  run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'skills/demo/SKILL.md'* ]]
  [[ "$output" == *'hooks/demo.sh'* ]]
}

@test "a package still awaiting migration reports its drift count instead of failing" {
  leak_the_fixture
  WR_PUBLISHED_IDS_PENDING="demo-plugin" run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *'PENDING demo-plugin drift=2'* ]]
}

@test "the pending list does not excuse a package that is not on it" {
  leak_the_fixture
  WR_PUBLISHED_IDS_PENDING="some-other-plugin" run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" != *'PENDING'* ]]
}

@test "leaks are reported against the package that produced them" {
  leak_the_fixture
  run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'demo-plugin/skills/demo/SKILL.md'* ]]
}
