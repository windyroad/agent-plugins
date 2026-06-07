#!/usr/bin/env bash
# wr-itil — echo the outbound-responses-preflight promotion reason, or empty
# if promotion is not warranted (P220 + P317/RFC-009).
#
# Adopter-safe wrapper: sources the canonical lib RELATIVE TO THIS SCRIPT
# (`$(dirname)/../lib`), then echoes the function's result on stdout (the SKILL
# captures it via `$(...)`). Replaces any SKILL-inline
# `source packages/itil/lib/check-outbound-responses-staleness.sh;
#  preflight_reason="$(should_promote_outbound_responses_preflight "$PWD")"`,
# which only resolves in the source monorepo (P317). SKILLs invoke this by name
# via the `wr-itil-check-outbound-responses-staleness` PATH shim (ADR-049).
# Operates on the directory given as $1 (defaults to $PWD).
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-check-outbound-responses-staleness: cannot locate lib next to the script" >&2
  exit 2
}
# shellcheck source=/dev/null
source "$LIB/check-outbound-responses-staleness.sh"
should_promote_outbound_responses_preflight "${1:-$PWD}"
