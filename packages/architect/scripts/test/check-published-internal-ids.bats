#!/usr/bin/env bats

setup() {
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/check-published-internal-ids.sh"
  FIXTURE="$(mktemp -d)"
  mkdir -p "$FIXTURE/skills/demo" "$FIXTURE/hooks"
  printf '{"name":"fixture","version":"1.0.0","files":["skills/","hooks/"]}\n' > "$FIXTURE/package.json"
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "exact tarball check permits source comments and rejects published prose or output IDs" {
  printf '# @adr ADR-001\nA self-contained rule.\n' > "$FIXTURE/skills/demo/SKILL.md"
  printf '# ADR-002 source annotation\necho "self-contained recovery"\n' > "$FIXTURE/hooks/demo.sh"
  run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 0 ]

  printf 'See STORY-MAP-123 for the rule.\n' >> "$FIXTURE/skills/demo/SKILL.md"
  printf 'echo "Blocked by P456"\n' >> "$FIXTURE/hooks/demo.sh"
  run "$SCRIPT" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'skills/demo/SKILL.md'* ]]
  [[ "$output" == *'hooks/demo.sh'* ]]
}
