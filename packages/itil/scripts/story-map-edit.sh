#!/usr/bin/env bash
# Bash entry point for the story-map card editor, so the ADR-049/ADR-080 shim
# machinery (which resolves `scripts/<NAME>.sh`) reaches the Node implementation.
#
# Usage: wr-itil-story-map-edit <map.html> <operation> [flags]
#
# @adr ADR-102 (story maps render from JSON through a canonical template)
# @adr ADR-049 (plugin scripts resolve via bin/ on $PATH)
set -euo pipefail
exec node "$(cd "$(dirname "$0")" && pwd)/story-map-edit.mjs" "$@"
