#!/usr/bin/env bats

# Tests for architect-enforce-edit.sh — verifies peer-plugin policy files are
# exempt from the architect gate (P009). Each plugin governs its own policy
# docs via its own enforce hook; the architect should not re-gate them.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/architect-enforce-edit.sh"
}

file_is_excluded() {
  local pattern="$1"
  grep -q "$pattern" "$HOOK"
}

@test "architect: exempts JTBD policy file (P009)" {
  file_is_excluded 'JOBS_TO_BE_DONE.md'
}

@test "architect: exempts JTBD directory (P009)" {
  file_is_excluded 'docs/jtbd'
}

@test "architect: exempts PRODUCT_DISCOVERY.md (P009)" {
  file_is_excluded 'PRODUCT_DISCOVERY.md'
}

@test "architect: exempts voice-tone policy file (P009)" {
  file_is_excluded 'VOICE-AND-TONE.md'
}

@test "architect: exempts style-guide policy file (P009)" {
  file_is_excluded 'STYLE-GUIDE.md'
}
