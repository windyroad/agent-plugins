#!/usr/bin/env bats
# Every lib the commit gate sources must actually ship in the published tarball.
#
# `itil-no-implement-draft-gate.sh` sources its libs under `2>/dev/null || exit 0`,
# and both guards are terminal and sit above every check. So if a packaging
# change stopped shipping one of them, the gate would silently become a no-op in
# every adopter install — no error, no deny, nothing — while every source-tree
# test stayed green, because in the source tree the libs are always there.
#
# That is the only failure mode this file exists for, and it is not theoretical:
# `itil-no-implement-draft-gate.sh` is the only hook in the repo that sources a
# PACKAGE-ROOT `lib/` rather than `hooks/lib/`, so `lib/` leaving the `files`
# array would strand exactly this one gate and nothing else would notice.
#
# Targets are DERIVED from the hook, never hardcoded: a hardcoded path goes
# quietly stale the day the hook is renamed, which is the vacuous-test class this
# repo has been bitten by before. The parse is itself asserted non-empty.
#
# @adr ADR-049 (plugin scripts resolve via bin/ on PATH — same shipping concern)
# @adr ADR-052 (behavioural: runs the real publish mechanism, not a source grep)
# @problem P369 (registered-but-absent: hook registered, file not shipped)

setup() {
  PKG="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  HOOK="$PKG/hooks/itil-no-implement-draft-gate.sh"
}

# Every `source "$SCRIPT_DIR/..."` target in the hook, as a package-relative
# path. `$SCRIPT_DIR` is the hooks/ directory, so `$SCRIPT_DIR/lib/x` is
# `hooks/lib/x` and `$SCRIPT_DIR/../lib/x` is `lib/x`.
#
# awk, not sed: BSD sed has no `t label` and the branch form silently errors on
# macOS while working on CI — the P334 portability class.
_sourced_targets() {
  grep -oE 'source "\$SCRIPT_DIR/[^"]+"' "$HOOK" \
    | awk '{
        sub(/^source "\$SCRIPT_DIR\//, ""); sub(/"$/, "")
        if (sub(/^\.\.\//, "")) print; else print "hooks/" $0
      }'
}

@test "the target parse finds something — a renamed hook must redden, not go quiet" {
  # Without this the whole file passes vacuously the moment the grep stops
  # matching, which is exactly how a shipping check stops being a check.
  run _sourced_targets
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  # Both libs are load-bearing: each guard is terminal, so either one missing
  # means no gate at all. Neither is the "safe" one to lose.
  [ "$(echo "$output" | wc -l | tr -d ' ')" -ge 2 ]
}

@test "every lib the gate sources is in the published tarball" {
  command -v npm >/dev/null 2>&1 || skip "npm not available"
  local packed
  packed="$(cd "$PKG" && npm pack --dry-run --json 2>/dev/null \
    | node -e "
      let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
        try{
          const j=JSON.parse(s);
          const entry=Array.isArray(j) ? j[0] : Object.values(j)[0];
          process.stdout.write((entry?.files||[]).map(f=>f.path).join('\n'));
        }
        catch(e){ process.exit(3); }
      })")"
  [ -n "$packed" ]

  # The hook itself must ship, or the targets are moot.
  echo "$packed" | grep -qx 'hooks/itil-no-implement-draft-gate.sh'

  local target seen=0
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    seen=$((seen + 1))
    echo "$packed" | grep -qx "$target" || {
      echo "gate sources '$target' but it is NOT in the tarball —" \
           "the gate would degrade to a no-op in every adopter install"
      return 1
    }
  done < <(_sourced_targets)
  # Without this the loop reads nothing and the test passes having asserted
  # nothing — the same vacuity the sibling test guards, restated at the locus
  # that would actually go quiet. (It already happened once during authoring: a
  # BSD-sed parse failure made this test green while checking zero targets.)
  [ "$seen" -ge 2 ]
}
