#!/usr/bin/env bats
#
# No published package ships a tool that writes the retired problem type field.
#
# The type classification was retired across the corpus in June: 347 tickets
# stripped, nothing branching on it, and a guard asserting it stays gone. That
# guard checks `docs/problems/`, the capture-problem skill and the shared
# dispatch helper — it does not check what the packages ship.
#
# It missed one. `migrate-problems-add-type.sh` shipped in the itil tarball for
# two months after the retirement was called complete, and its apply mode wrote
# `**Type**: technical` into every ticket it touched. A bats file asserted that
# behaviour green, alongside the guard asserting the opposite. Both passed.
#
# So this asserts the shipped surface, which is the axis the corpus guard has
# no view of. Verified against `npm pack --dry-run` rather than against the
# `files` array: the array is the input and the tarball is the outcome, and a
# negation that fails to match shows up only here.
#
# @problem P287
# @adr ADR-060 (the problem type classification is retired)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  [ -d "$REPO_ROOT/packages" ]
}

@test "no published package ships a tool that writes the retired type field" {
  local offenders=""
  for dir in "$REPO_ROOT"/packages/*/; do
    [ -f "$dir/package.json" ] || continue
    node -e "process.exit(require('$dir/package.json').private ? 0 : 1)" 2>/dev/null && continue

    local name listing
    name="$(basename "$dir")"
    listing="$(cd "$dir" && npm pack --dry-run 2>&1 || true)"

    # Positive control. A failed pack yields no listing, and a search over no
    # listing finds nothing — indistinguishable from a clean tarball.
    printf '%s' "$listing" | grep -qE 'package\.json' || {
      echo "npm pack produced no listing for ${name} — cannot assert anything:"
      printf '%s\n' "$listing"
      return 1
    }

    # Read each packed file that could write a ticket and look for the field.
    # npm prints `npm notice <size> <path>`. Take the last field so the size
    # unit (B/kB/MB) cannot break the match — an earlier version anchored on
    # the unit and silently extracted nothing, which made this whole assertion
    # pass over an empty list.
    local packed
    packed="$(printf '%s' "$listing" | awk '/^npm notice +[0-9]/ { print $NF }' \
      | grep -E '\.(sh|mjs|js)$' || true)"

    [ -n "$packed" ] || {
      echo "extracted no packed script paths for ${name} — the parse is wrong, not the tarball"
      printf '%s\n' "$listing" | head -5
      return 1
    }

    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      [ -f "$dir/$rel" ] || continue
      if grep -qF '**Type**:' "$dir/$rel"; then
        offenders="${offenders}${name}/${rel}"$'\n'
      fi
    done <<EOF
$packed
EOF
  done

  if [ -n "$offenders" ]; then
    echo "shipped files writing the retired type field:"
    echo "$offenders"
    return 1
  fi
}
