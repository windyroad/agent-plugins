#!/usr/bin/env bats
# Behavioural tests for check-amends-backreference.sh.
# Runs the real script against real fixture trees and asserts on exit status and
# stderr — never on the script's source text (ADR-052 / P081).
#
# @adr ADR-051 ADR-052  @problem P456

setup() {
  CHECK="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/check-amends-backreference.sh"
  TMP="$(mktemp -d)"; cd "$TMP"; mkdir -p d
}
teardown() { cd /; rm -rf "$TMP"; }

amender() { printf -- '---\nstatus: "proposed"\namends: [%s]\n---\n\n# ADR-%s\n' "$2" "$1" > "d/$1-amender.md"; }
amended() { printf -- '---\nstatus: "proposed"\n---\n\n# ADR-%s\n\n%s\n' "$1" "$2" > "d/$1-amended.md"; }

@test "passes when the amended ADR back-references the amending one" {
  amender 101 "ADR-090"
  amended 090 "Exercised 2026-07-26 by ADR-101, which coarsens this rule."
  run bash "$CHECK" d
  [ "$status" -eq 0 ]
}

@test "fails when the amended ADR never mentions the amending one" {
  amender 101 "ADR-090"
  amended 090 "This decision stands unqualified."
  run bash "$CHECK" d
  [ "$status" -eq 1 ]
  echo "$output" | grep -q '090'
  echo "$output" | grep -q 'ADR-101'
}

@test "does not require an in-place back-reference on a confirmed target" {
  amender 101 "ADR-090"
  printf -- '---\nstatus: "proposed"\nhuman-oversight: confirmed\n---\n\n# ADR-090\n\nThis ratified record is immutable.\n' > d/090-amended.md
  run bash "$CHECK" d
  [ "$status" -eq 0 ]
}

@test "a body-only confirmation marker does not make the target immutable" {
  amender 101 "ADR-090"
  amended 090 $'This target is mutable.\n\nhuman-oversight: confirmed'
  run bash "$CHECK" d
  [ "$status" -eq 1 ]
}

@test "checks EVERY entry in a multi-target amends list, not just the first" {
  amender 101 "ADR-090, ADR-095, ADR-096"
  amended 090 "Amended by ADR-101."
  amended 095 "Amended by ADR-101."
  amended 096 "This decision stands unqualified."
  run bash "$CHECK" d
  [ "$status" -eq 1 ]
  echo "$output" | grep -q '096'
  ! echo "$output" | grep -q '095'
}

@test "fails when an amends: target does not resolve at all" {
  amender 101 "ADR-777"
  run bash "$CHECK" d
  [ "$status" -eq 1 ]
  echo "$output" | grep -q 'ADR-777'
}

@test "an ADR with no amends: declaration is not checked" {
  amended 090 "A decision that amends nothing."
  run bash "$CHECK" d
  [ "$status" -eq 0 ]
}

@test "a body mention of the word amends is not read as a declaration" {
  printf -- '---\nstatus: "proposed"\n---\n\n# ADR-101\n\nThis amends: nothing in particular, per ADR-999.\n' > d/101-prose.md
  run bash "$CHECK" d
  [ "$status" -eq 0 ]
}

@test "the live corpus satisfies the invariant" {
  repo="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  [ -d "$repo/docs/decisions" ] || skip "not running in the source repo"
  run bash "$CHECK" "$repo/docs/decisions"
  [ "$status" -eq 0 ]
}
