#!/bin/bash

# Print the one authoritative architect verdict. Exactly one canonical verdict
# must be the first nonblank line; examples and conflicting headings fail closed.
architect_verdict() {
  local output verdict first
  output="$(cat)"
  verdict="$(printf '%s\n' "$output" | sed -nE \
    -e 's/^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)\*\*[[:space:]]*$/\1/p' \
    -e 's/^[[:space:]]*>?[[:space:]]*##[[:space:]]+Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)[[:space:]]*$/\1/p')"
  first="$(printf '%s\n' "$output" | awk 'NF { print; exit }' | sed -nE \
    -e 's/^[[:space:]]*>?[[:space:]]*\*\*Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)\*\*[[:space:]]*$/\1/p' \
    -e 's/^[[:space:]]*>?[[:space:]]*##[[:space:]]+Architecture Review: (PASS|ISSUES FOUND|NEEDS DIRECTION)[[:space:]]*$/\1/p')"
  [ "$first" = "$verdict" ] || verdict=""
  [ "$verdict" != "ISSUES FOUND" ] || verdict="FAIL"
  printf '%s' "$verdict"
}
