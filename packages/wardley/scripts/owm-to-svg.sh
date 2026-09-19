#!/usr/bin/env bash
# Thin bash entry point for the OWM-to-SVG converter, so the ADR-049/ADR-080
# shim machinery (which resolves `scripts/<NAME>.sh`) reaches the Node
# implementation without the generator needing to learn about .mjs.
#
# The converter body stays beside its SKILL.md under skills/generate/ because
# ADR-083 has Codex resolve bundled scripts relative to the installed SKILL.md;
# this entry point reaches across to it, resolving from its own location so no
# caller has to be in any particular directory.
#
# Usage: wr-wardley-owm-to-svg [input.owm] [output.svg]
#
# Defaults: docs/wardley-map.owm -> docs/wardley-map.svg (+ .png via sips).
#
# @adr ADR-049 (plugin scripts resolve via bin/ on $PATH)
# @adr ADR-080 (highest-version-wins shim wrapper)
# @adr ADR-083 (Codex CLI as second runtime)
# @problem P437 (no version-stable invocation path for the converter)

set -euo pipefail
exec node "$(cd "$(dirname "$0")" && pwd)/../skills/generate/owm-to-svg.mjs" "$@"
