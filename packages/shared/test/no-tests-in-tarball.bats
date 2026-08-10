#!/usr/bin/env bats
#
# A published package must not carry its own tests.
#
# The tests exist to verify the plugin. They are not part of it, and shipping
# them has a cost beyond weight: several assert against THIS repository's
# `docs/` tree — decisions and tickets by filename — so an adopter running them
# is told about artefacts they have never had. The taxonomy that separates a
# plugin test from a project-conformance test is P494; this guard is the half
# that stops either kind reaching a tarball.
#
# Asserted against `npm pack --dry-run` rather than against the `files` array,
# because the array is the input and the tarball is the outcome. A negation
# that does not match, a test directory in a location nobody thought of, or a
# new package that forgets the exclusions all show up here and in none of the
# obvious places.
#
# @adr ADR-052 (behavioural tests default — this asserts the packed output, not
#   the manifest that produced it)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "no published package ships its own tests" {
  local offenders=""
  for dir in "$REPO_ROOT"/packages/*/; do
    [ -f "$dir/package.json" ] || continue
    node -e "process.exit(require('$dir/package.json').private ? 0 : 1)" 2>/dev/null && continue

    local name listing count
    name="$(basename "$dir")"
    listing="$(cd "$dir" && npm pack --dry-run 2>&1 || true)"

    # Positive control FIRST. A failed `npm pack` produces no listing, and a
    # grep over no listing matches nothing — which is indistinguishable from a
    # clean tarball. Without this the assertion passes green having inspected
    # nothing, which is the failure this whole guard exists to prevent one
    # level down.
    if ! printf '%s' "$listing" | grep -qE 'package\.json'; then
      echo "npm pack produced no listing for ${name} — cannot assert anything:"
      printf '%s\n' "$listing"
      return 1
    fi

    # `test/`, `tests/` and `__tests__/`. Matching only the first would let a
    # directory named by a different convention through unseen.
    count="$(printf '%s' "$listing" | grep -cE '(^|/)(test|tests|__tests__)/' || true)"
    [ "$count" -eq 0 ] || offenders="${offenders}${name} (${count} entries)"$'\n'
  done

  if [ -n "$offenders" ]; then
    echo "packages shipping test files:"
    echo "$offenders"
    echo "Add the missing '!<dir>/test/' negations to that package's files array."
    return 1
  fi
}
