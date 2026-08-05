#!/usr/bin/env bash
# Thin bash entry point for the story-map renderer, so the ADR-049/ADR-080
# shim machinery (which resolves `scripts/<NAME>.sh`) reaches the Node
# implementation without the generator needing to learn about .mjs.
#
# Usage: wr-itil-render-story-map <map.html>
#
# One mode: renders a map in place from its own data island. To create a map,
# write a file containing just the island and render it.
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-049 (plugin scripts resolve via bin/ on $PATH)

set -euo pipefail
exec node "$(cd "$(dirname "$0")" && pwd)/render-story-map.mjs" "$@"
