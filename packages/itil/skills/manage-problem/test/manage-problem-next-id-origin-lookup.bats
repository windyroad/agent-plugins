#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md Step 3 origin-max lookup must use
# `git ls-tree --name-only` to avoid false-matching blob SHA digits (P056).
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). Default `git ls-tree` output shape is
# `<mode> <type> <sha>\t<path>`. A `grep -oE '[0-9]{3}'` over that line
# can match digits inside the 40-char blob SHA and return a wrong
# `origin_max` (observed 997 on 2026-04-20 when opening P055). `--name-only`
# drops mode/type/SHA columns leaving only the path, restoring the
# invariant ADR-019 and P043 presume.
#
# Cross-reference:
#   P056: docs/problems/056-ticket-creator-next-id-lookup-blob-sha-false-match.*.md
#   P043 (closed): next-ID collision guard in ticket-creator skills
#   ADR-019: docs/decisions/019-afk-orchestrator-preflight.*.md
#   @jtbd JTBD-002 (ship with confidence — audit trail)
#   @jtbd JTBD-006 (progress the backlog while I'm away — collision-free IDs)

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  REPO_ROOT="$(cd "${TEST_DIR}/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
}

@test "manage-problem SKILL.md exists (P056 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "manage-problem SKILL.md origin-max lookup uses git ls-tree --name-only (P056)" {
  # The fix: `git ls-tree --name-only` drops mode/type/SHA columns so the
  # digit-extraction regex cannot match SHA hex runs.
  run grep -nE "git ls-tree --name-only .* docs/problems" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem SKILL.md does not keep the buggy bare git ls-tree pattern (P056)" {
  # Regression guard: `git ls-tree <ref> docs/problems/` without `--name-only`
  # piped directly into a digit regex is the bug. Any remaining pipeline of
  # this shape in a bash code block is a regression.
  run grep -nE "git ls-tree [^-].* docs/problems/ .*\| *grep -oE '\[0-9\]\{3\}'" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "manage-problem SKILL.md cites P056 on the origin-max fix (P056)" {
  # Traceability: the fix must cite P056 so reviewers can chase the
  # correction back to the incident that motivated it.
  run grep -n "P056" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
