#!/usr/bin/env bats
# Doc-lint guard: create-adr SKILL.md Step 3 origin-max lookup must use
# `git ls-tree --name-only` to avoid false-matching blob SHA digits (P056).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). Same defect as manage-problem: default `git ls-tree`
# output carries a 40-char blob SHA that can contain three-digit runs,
# which `grep -oE '[0-9]{3}'` picks up as a false origin_max. `--name-only`
# restores the invariant ADR-019 presumes.
#
# Cross-reference:
#   P056: docs/problems/056-ticket-creator-next-id-lookup-blob-sha-false-match.*.md
#   P043 (closed): next-ID collision guard in ticket-creator skills
#   ADR-019: docs/decisions/019-afk-orchestrator-preflight.*.md
#   @jtbd JTBD-002 (ship with confidence — audit trail)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/architect/skills/create-adr/SKILL.md"
}

@test "create-adr SKILL.md exists (P056 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "create-adr SKILL.md origin-max lookup uses git ls-tree --name-only (P056)" {
  # The fix: `git ls-tree --name-only` drops mode/type/SHA columns so the
  # digit-extraction regex cannot match SHA hex runs.
  run grep -nE "git ls-tree --name-only .* docs/decisions" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "create-adr SKILL.md does not keep the buggy bare git ls-tree pattern (P056)" {
  # Regression guard: `git ls-tree <ref> docs/decisions/` without `--name-only`
  # piped directly into a digit regex is the bug.
  run grep -nE "git ls-tree [^-].* docs/decisions/ .*\| *grep -oE '\[0-9\]\{3\}'" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "create-adr SKILL.md cites P056 on the origin-max fix (P056)" {
  # Traceability.
  run grep -n "P056" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
