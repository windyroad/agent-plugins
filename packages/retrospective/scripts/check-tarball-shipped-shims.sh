#!/usr/bin/env bash
# packages/retrospective/scripts/check-tarball-shipped-shims.sh
#
# Diagnose-only advisory script for plugin-published tarball-shipped-shim
# integrity per WR-P154 (P137 detector must run against npm pack output not
# source tree) and the WR-ADR-049 plugin-script-resolution-via-bin-on-PATH
# contract.
#
# Walks workspace packages under `<root-dir>/packages/<plugin>/`. For each
# workspace, runs `npm pack --dry-run --json` to enumerate the file set that
# WOULD ship to npm (per `package.json#files` filtering). For every
# WR-ADR-049-grammar bin shim (`bin/wr-<plugin>-<name>`) in that file set,
# parses the shim source to extract the `exec`'d `scripts/<name>.sh` target
# and asserts the target path is also in the tarball file set.
#
# The asymmetry between source-tree state and tarball state is the gap
# WR-P137 Phase 1 (check-internal-id-leaks.sh, source-tree-walking) does
# not see — `scripts/` exists on disk but is omitted from `package.json#files`
# so the shim shipped to adopters exec-fails with `no such file or directory`
# at invocation time. WR-P154 closes the prevention surface from the
# publish-manifest side.
#
# Usage:
#   check-tarball-shipped-shims.sh [<root-dir>]
#
# Default <root-dir> is `.`.
#
# WR-ADR-049-grammar shims that this script considers:
#   bin/wr-<plugin>-<name>
# Non-grammar bins (e.g. `bin/install.mjs`, `bin/check-deps.sh`,
# `bin/windyroad-<plugin>` legacy installers) are skipped — they don't
# follow the script-resolution-via-bin-on-PATH WR-ADR-049 contract.
#
# Exit codes:
#   0 = always (advisory only — drift is signal, not failure)
#   2 = parse error (root dir missing or unreadable, npm unavailable)
#
# Output format on drift (terse machine-readable per WR-ADR-038):
#   TARBALL_DRIFT package=<name> shim=<bin/wr-...> target=<scripts/...> tarball-status=missing
#
# Followed by a final aggregate summary line:
#   TOTAL packages=<N> with_drift=<M> missing_targets=<K>
#
# Output is empty (no lines) when no shipped artefact carries broken
# shims — silent-on-pass per WR-ADR-045 hook injection budget discipline.
#
# Output ordering (deterministic for stable retro-summary diffs):
#   TARBALL_DRIFT lines sorted by `<package>/<shim>` identifier.
#   TOTAL line last.
#
# Read-only — does NOT mutate any artefact. Per WR-ADR-052, the bats
# fixture at scripts/test/check-tarball-shipped-shims.bats is BEHAVIOURAL —
# asserts script output on temp-fixture trees, NOT script source content.
#
# @problem P154 (P137 namespace-prefix detector must run against
#   npm pack output not source tree)
# @problem P140 (Step 6.5 fix-and-continue — same prevention surface
#   from the publisher side)
# @adr ADR-049 (Plugin script resolution via bin/ on PATH)
# @adr ADR-038 (Progressive disclosure — terse machine-readable signal)
# @adr ADR-045 (Hook injection budget — silent-on-pass discipline)
# @adr ADR-052 (Behavioural-tests-default — fixture pattern)
# @adr ADR-055 (Plugin-published namespace-prefixed permalinks —
#   sibling adopter-context decision)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just
#   Installed — executable correctness axis of adopter-facing content)
# @jtbd JTBD-101 (Extend the Suite with New Plugins — secondary
#   plugin-developer feedback surface)

set -uo pipefail

ROOT_DIR="${1:-.}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$ROOT_DIR" ]; then
  echo "check-tarball-shipped-shims: root dir not found: $ROOT_DIR" >&2
  exit 2
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "check-tarball-shipped-shims: npm not found on PATH" >&2
  exit 2
fi

# ── Walk workspaces ─────────────────────────────────────────────────────────

shopt -s nullglob
declare -a workspaces=()
for pkg_json in "$ROOT_DIR"/packages/*/package.json; do
  workspaces+=("$(dirname "$pkg_json")")
done
shopt -u nullglob

if [ "${#workspaces[@]}" -eq 0 ]; then
  exit 0
fi

# ── Per-workspace pack + drift detection ────────────────────────────────────
# For each workspace:
#   1. cd into workspace dir; run `npm pack --dry-run --json` to get the
#      shipped file list. Independent of monorepo workspaces config — works
#      in adopter trees too.
#   2. Parse JSON via python3 (always available on the host) to extract
#      the file paths AND the package name.
#   3. For each `bin/wr-<plugin>-<name>` shim in the file list, parse the
#      shim source on disk (NOT from the tarball — same content) to find
#      the `exec`'d `../scripts/<name>.sh` target.
#   4. Check whether the resolved target path is in the tarball file list.
#   5. Emit `TARBALL_DRIFT` lines for missing targets.

declare -a drifts=()
declare -A package_set=()
declare -i missing_total=0

for ws in "${workspaces[@]}"; do
  # Pack the workspace. Capture stdout; suppress stderr (npm chatter).
  pack_json=$(cd "$ws" && npm pack --dry-run --json 2>/dev/null) || continue
  if [ -z "$pack_json" ]; then
    continue
  fi

  # Extract package name + file path list via python3.
  # Output format (one record per line):
  #   NAME <package-name>
  #   FILE <relative-path>
  #   ...
  parsed=$(printf '%s' "$pack_json" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data:
    sys.exit(0)
entry = data[0] if isinstance(data, list) else data
name = entry.get("name", "")
files = entry.get("files", []) or []
print("NAME " + name)
for f in files:
    p = f.get("path", "")
    if p:
        print("FILE " + p)
') || continue

  pkg_name=""
  declare -a tarball_files=()
  while IFS= read -r line; do
    case "$line" in
      "NAME "*)
        pkg_name="${line#NAME }"
        ;;
      "FILE "*)
        tarball_files+=("${line#FILE }")
        ;;
    esac
  done <<< "$parsed"

  if [ -z "$pkg_name" ]; then
    continue
  fi

  # Build a lookup set of tarball file paths.
  declare -A tarball_set=()
  for f in "${tarball_files[@]}"; do
    tarball_set["$f"]=1
  done

  # Find WR-ADR-049-grammar shims in the tarball file list.
  # Grammar: bin/wr-<plugin>-<name>  (excludes bin/install.mjs, bin/check-deps.sh,
  # bin/windyroad-<plugin>, bin/anything-without-wr-prefix).
  workspace_has_drift=0
  for f in "${tarball_files[@]}"; do
    case "$f" in
      bin/wr-*)
        # Parse the shim source on disk for the exec target.
        shim_path="$ws/$f"
        if [ ! -f "$shim_path" ]; then
          continue
        fi
        # Heuristic: extract the `scripts/<name>.sh` exec target. Matches:
        #   - Legacy WR-ADR-049 3-line shape: `exec "$(dirname "$0")/../scripts/<name>.sh" "$@"`
        #   - WR-ADR-080 highest-version-wins wrapper source-repo-guard branch:
        #     `exec "$SHIM_DIR/../scripts/<name>.sh" "$@"`
        #   - WR-ADR-080 cache-execution branch (parsed as fallback —
        #     same `<name>.sh` resolves the same tarball entry):
        #     `exec "$CACHE_PARENT/$HIGHEST/scripts/<name>.sh" "$@"`
        # Anchored on the first `exec`-prefixed line containing `scripts/<name>.sh`.
        target=$(perl -ne '
          next unless /^\s*exec\s/;
          if (/scripts\/([A-Za-z0-9._-]+\.sh)/) {
            print "scripts/" . $1; exit;
          }
        ' "$shim_path")

        if [ -z "$target" ]; then
          continue
        fi

        if [ -z "${tarball_set[$target]:-}" ]; then
          drifts+=("$pkg_name|$f|$target")
          missing_total=$((missing_total + 1))
          workspace_has_drift=1
        fi
        ;;
    esac
  done

  if [ "$workspace_has_drift" -eq 1 ]; then
    package_set["$pkg_name"]=1
  fi

  unset tarball_set
  unset tarball_files
done

if [ "${#drifts[@]}" -eq 0 ]; then
  exit 0
fi

# ── Emit TARBALL_DRIFT lines (sorted) ───────────────────────────────────────

IFS=$'\n' sorted=($(printf '%s\n' "${drifts[@]}" | sort))
unset IFS

for entry in "${sorted[@]}"; do
  IFS='|' read -r pkg shim target <<< "$entry"
  echo "TARBALL_DRIFT package=$pkg shim=$shim target=$target tarball-status=missing"
done

# ── Emit TOTAL summary ──────────────────────────────────────────────────────

echo "TOTAL packages=${#package_set[@]} with_drift=${#package_set[@]} missing_targets=$missing_total"

exit 0
