#!/usr/bin/env bats

# @problem P382 — AFK work-problems `claude -p` iter subprocesses load only
#                 USER-scoped enabledPlugins; project-scoped governance plugins
#                 must be passed explicitly via --plugin-dir. This helper emits
#                 the --plugin-dir argument pairs the Step 5 dispatch splices
#                 into its claude -p invocation.
#
# Contract: `resolve-governance-plugin-dirs.sh` reads $PATH + WR_GOVERNANCE_PLUGINS
# and emits, per resolvable plugin, two stdout lines — `--plugin-dir` then the
# plugin root dir — for `mapfile -t` consumption.
#
# Load-bearing behaviour (ADR-080): the version is selected by HIGHEST-SEMVER
# walk of the cache parent, NOT by $PATH order (which is frozen-stale
# mid-session per P343). The fixture deliberately places a LOWER version's bin
# earlier on $PATH and asserts the HIGHER version's dir is still emitted.
#
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-080 (highest-version-wins resolution)
# @adr ADR-052 (behavioural test per P081)
# @adr ADR-032 (Step 5 dispatch contract — P382 amendment)
# @jtbd JTBD-001 (Enforce Governance — iter commits ship gated)
# @jtbd JTBD-006 (Progress Backlog AFK — full governance surface inside iters)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/resolve-governance-plugin-dirs.sh"
  CACHE="$(mktemp -d)"
  # Synthetic marketplace-cache layout (ADR-080 SQ-080-5 — no source-repo
  # cohabitation). wr-architect has two cached versions; wr-itil has one.
  mkdir -p "$CACHE/windyroad/wr-architect/0.16.0/bin"
  mkdir -p "$CACHE/windyroad/wr-architect/0.17.3/bin"
  mkdir -p "$CACHE/windyroad/wr-itil/0.51.0/bin"
}

teardown() {
  rm -rf "$CACHE"
}

@test "resolve-governance-plugin-dirs: script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "resolve-governance-plugin-dirs: emits --plugin-dir pairs for resolvable plugins" {
  PATH="$CACHE/windyroad/wr-architect/0.17.3/bin:$CACHE/windyroad/wr-itil/0.51.0/bin:/usr/bin:/bin" \
    WR_GOVERNANCE_PLUGINS="wr-architect wr-itil" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "--plugin-dir" ]
  [ "${lines[1]}" = "$CACHE/windyroad/wr-architect/0.17.3" ]
  [ "${lines[2]}" = "--plugin-dir" ]
  [ "${lines[3]}" = "$CACHE/windyroad/wr-itil/0.51.0" ]
}

@test "resolve-governance-plugin-dirs: picks highest semver, NOT \$PATH order (ADR-080)" {
  # Lower version (0.16.0) earlier on PATH than higher (0.17.3) — the resolver
  # must still emit 0.17.3 (cache-parent highest-semver walk, not PATH order).
  PATH="$CACHE/windyroad/wr-architect/0.16.0/bin:$CACHE/windyroad/wr-architect/0.17.3/bin:/usr/bin:/bin" \
    WR_GOVERNANCE_PLUGINS="wr-architect" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "--plugin-dir" ]
  [ "${lines[1]}" = "$CACHE/windyroad/wr-architect/0.17.3" ]
}

@test "resolve-governance-plugin-dirs: skips unresolvable plugins silently" {
  PATH="$CACHE/windyroad/wr-itil/0.51.0/bin:/usr/bin:/bin" \
    WR_GOVERNANCE_PLUGINS="wr-architect wr-itil wr-not-installed" run "$SCRIPT"
  [ "$status" -eq 0 ]
  # Only wr-itil is on PATH → exactly one pair, no wr-architect / wr-not-installed.
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[1]}" = "$CACHE/windyroad/wr-itil/0.51.0" ]
}

@test "resolve-governance-plugin-dirs: no governance plugins on PATH → empty output, exit 0" {
  PATH="/usr/bin:/bin" WR_GOVERNANCE_PLUGINS="wr-architect wr-itil" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
