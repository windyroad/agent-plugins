#!/usr/bin/env bash
# wr-itil — echo the deferred-placeholder + README-cadence promotion reason,
# or empty if promotion is not warranted (P271 / P317 RFC-009 adopter-safe).
#
# Adopter-safe wrapper: sources the canonical lib RELATIVE TO THIS SCRIPT
# (`$(dirname)/../lib`), then echoes the function's result on stdout (the SKILL
# captures it via `$(...)`). Mirrors the
# `run-check-upstream-cache-staleness.sh` precedent — never `source
# packages/...` repo-relative from a SKILL; those paths only resolve in the
# source monorepo, not adopter installs.
#
# SKILLs invoke this by name via the
# `wr-itil-check-deferred-placeholder-staleness` PATH shim (ADR-049 +
# ADR-080). Operates on the directory given as $1 (defaults to $PWD).
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-check-deferred-placeholder-staleness: cannot locate lib next to the script" >&2
  exit 2
}
# shellcheck source=/dev/null
source "$LIB/check-deferred-placeholder-staleness.sh"
should_promote_review_problems_dispatch "${1:-$PWD}"
