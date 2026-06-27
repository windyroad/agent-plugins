#!/usr/bin/env bash
# Resolve --plugin-dir arguments for the governance plugins an AFK iter
# subprocess needs.
#
# P382: headless `claude -p` loads only USER-scoped enabledPlugins, NOT
# project-scoped ones. When the windyroad plugins are enabled at project scope
# (the common adopter setup), an iter subprocess dispatched by work-problems
# Step 5 receives no windyroad agents/hooks — it commits ungated and cannot run
# retro-on-exit. `--setting-sources user,project` is insufficient (project
# activation is trust-gated; headless skips trust). Passing `--plugin-dir
# <plugin-root>` for each governance plugin DOES make it available. This script
# emits those `--plugin-dir` argument pairs for the Step 5 dispatch to splice
# into its `claude -p` invocation.
#
# Resolution: each plugin's cache parent is located from its bin dir on $PATH
# (ADR-049 bin-on-PATH precedent — present in adopter marketplace-cache trees
# and source-dev alike), then the HIGHEST-SEMVER sibling under that cache parent
# is selected (ADR-080 highest-version-wins). $PATH order is frozen at session
# init and goes stale mid-session (P343 / ADR-080 / ADR-081), so it MUST NOT be
# trusted for version selection — only to discover the cache parent.
#
# Output: two lines per resolvable plugin — `--plugin-dir` then the plugin root
# dir — for `mapfile -t` consumption (one token per line tolerates paths with
# spaces). Unresolvable plugins are skipped silently: graceful degradation when
# an adopter has not installed the full governance surface. (This is a
# deliberate divergence from the canonical shim's loud exit-127 — a missing
# governance plugin must not abort the whole AFK orchestrator dispatch.)
#
# Override the plugin set via WR_GOVERNANCE_PLUGINS (space-separated).
#
# @adr ADR-032 (governance skill invocation — Step 5 dispatch contract, P382 amendment)
# @adr ADR-049 (plugin-bundled scripts resolve via bin/ on $PATH)
# @adr ADR-080 (highest-version-wins resolution — $PATH order is not authoritative)
# @adr ADR-052 (behavioural test — resolve-governance-plugin-dirs.bats)
# @problem P382
set -euo pipefail

PLUGINS="${WR_GOVERNANCE_PLUGINS:-wr-architect wr-jtbd wr-risk-scorer wr-voice-tone wr-itil wr-retrospective wr-style-guide}"
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'

IFS=':' read -r -a path_entries <<< "$PATH"

for plugin in $PLUGINS; do
  # Discover this plugin's cache parent from any of its bin dirs on $PATH.
  # A bin entry has the shape <cache_parent>/<version>/bin.
  cache_parent=""
  for entry in "${path_entries[@]}"; do
    case "$entry" in
      */"$plugin"/*/bin)
        cache_parent="$(dirname "$(dirname "$entry")")"
        break
        ;;
    esac
  done
  [ -n "$cache_parent" ] || continue

  # Select the highest-semver sibling under <cache_parent> (ADR-080). PATH order
  # may name a stale version after a mid-session /install-updates, so re-resolve
  # the version here rather than reading it from the PATH entry.
  highest=""
  while IFS= read -r dir; do
    name="$(basename "$dir")"
    [[ "$name" =~ $SEMVER_RE ]] || continue
    if [ -z "$highest" ] || [ "$(printf '%s\n%s\n' "$highest" "$name" | sort -V | tail -1)" = "$name" ]; then
      highest="$name"
    fi
  done < <(find "$cache_parent" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  [ -n "$highest" ] || continue
  printf '%s\n%s\n' "--plugin-dir" "$cache_parent/$highest"
done
