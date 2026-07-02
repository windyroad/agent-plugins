#!/usr/bin/env bats
# Behavioural test for check-rfc-has-stories.sh (ADR-089 — every RFC has >=1 story).
# The predicate exits non-zero when an RFC's `stories:` frontmatter is empty or
# missing (the empty-stories fallback ADR-089 removes); exit 0 when >=1 story is
# listed. This is the load-bearing detection half of the proposed->accepted gate.
#
# @adr ADR-089 (every RFC has at least one story)
# @problem P404 (implement ADR-089 + ADR-090)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/check-rfc-has-stories.sh"
  TMPD="$(mktemp -d)"
}
teardown() { rm -rf "$TMPD"; }

@test "check-rfc-has-stories: empty stories: [] is REJECTED (exit non-zero + directive)" {
  cat > "$TMPD/RFC-901-empty.proposed.md" <<'EOF'
---
status: proposed
problems: [P170]
stories: []
---
# RFC-901: empty
EOF
  run bash "$SCRIPT" "$TMPD/RFC-901-empty.proposed.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"stories"* ]]
}

@test "check-rfc-has-stories: missing stories: field is REJECTED" {
  cat > "$TMPD/RFC-902-none.proposed.md" <<'EOF'
---
status: proposed
problems: [P170]
---
# RFC-902: no stories field
EOF
  run bash "$SCRIPT" "$TMPD/RFC-902-none.proposed.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"stories"* ]]
}

@test "check-rfc-has-stories: inline >=1 story is ACCEPTED (exit 0)" {
  cat > "$TMPD/RFC-903-ok.proposed.md" <<'EOF'
---
status: proposed
problems: [P170]
stories: [STORY-020, STORY-021]
---
# RFC-903: has stories
EOF
  run bash "$SCRIPT" "$TMPD/RFC-903-ok.proposed.md"
  [ "$status" -eq 0 ]
}

@test "check-rfc-has-stories: block-list >=1 story is ACCEPTED (exit 0)" {
  cat > "$TMPD/RFC-904-block.proposed.md" <<'EOF'
---
status: proposed
problems: [P170]
stories:
  - STORY-020
---
# RFC-904: block-list stories
EOF
  run bash "$SCRIPT" "$TMPD/RFC-904-block.proposed.md"
  [ "$status" -eq 0 ]
}
