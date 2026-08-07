#!/usr/bin/env bash
# Read-only JSON query over the story-map corpus.
#
# Usage: wr-itil-story-map-query <list|get|find-story|unratified> [args] [--maps-dir DIR]
#
# WHY THIS IS A BASH ENTRY POINT AND NOT JUST A .mjs. Ratification state is
# drift-invalidated and must come from ONE hash definition — the one in
# lib/story-oversight.sh that detect-unratified-stories-maps.sh,
# check-rfc-stories-ratified.sh and mark-story-oversight-confirmed.sh all share.
# A JavaScript re-implementation would be a fourth definition, and the pair
# would disagree the first time either drifted. So this wrapper sources the lib,
# computes the oversight facts per map in bash, and pipes them to the Node half,
# which does presentation and island parsing only. No hashing in JavaScript.
#
# NOTE ON STDIN: this tool consumes stdin for facts fed in by this wrapper, so
# stdin is not available as a user input channel here. Its sibling
# story-map-edit reads an operation FROM stdin under `--json -`. The asymmetry
# is deliberate; do not assume symmetry between the two.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-090 (drift-invalidated human-oversight marker)
# @adr ADR-049 (plugin scripts resolve via bin/ on $PATH)

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/../lib/story-oversight.sh"

MAPS_DIR="docs/story-maps"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --maps-dir) MAPS_DIR="${2:-}"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# Same two globs as detect-unratified-stories-maps.sh, and the same default.
# A different corpus would make the two surfaces disagree about which maps
# exist while agreeing perfectly on every per-map verdict — the more confusing
# failure, and one this repo has already hit once via a subdirectory-glob miss.
shopt -s nullglob
MAPS=("$MAPS_DIR"/*.html "$MAPS_DIR"/*/*.html)
shopt -u nullglob

# One facts line per map. `reason` is decided HERE, not in JS: separating
# drift-reopened from never-ratified needs a hash comparison, and doing that on
# the JS side is exactly how a fourth hash definition appears.
facts() {
  local f confirmed stored fresh ratified reason
  for f in "${MAPS[@]}"; do
    [ -f "$f" ] || continue
    confirmed=false; stored=""; ratified=false; reason="never-ratified"
    if oversight_is_confirmed "$f" 2>/dev/null; then confirmed=true; fi
    stored="$(oversight_stored_hash "$f" 2>/dev/null || true)"
    if [ "$confirmed" = true ] && [ -z "$stored" ]; then
      reason="legacy-confirmed-without-fingerprint"
    elif [ "$confirmed" = true ]; then
      fresh="$(oversight_content_hash "$f" 2>/dev/null || true)"
      if [ "$stored" = "$fresh" ]; then ratified=true; reason="ratified"
      else reason="drift-reopened"; fi
    fi
    printf '%s\t%s\t%s\n' "$f" "$ratified" "$reason"
  done
}

facts | exec node "$HERE/story-map-query.mjs" "${ARGS[@]+"${ARGS[@]}"}"
