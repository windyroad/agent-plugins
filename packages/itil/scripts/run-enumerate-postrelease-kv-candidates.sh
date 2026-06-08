#!/usr/bin/env bash
# wr-itil — emit `KV_CANDIDATE` lines for Known Error tickets whose
# Release-vehicle citation matches a just-shipped (deleted-from-tree)
# changeset (P228 / P317 RFC-009 adopter-safe).
#
# Adopter-safe wrapper: sources the canonical lib RELATIVE TO THIS SCRIPT
# (`$(dirname)/../lib`), then invokes the function. The SKILL parses the
# emitted lines via `$(...)`. Mirrors the
# `run-check-deferred-placeholder-staleness.sh` precedent — never `source
# packages/...` repo-relative from a SKILL; those paths only resolve in
# the source monorepo, not adopter installs.
#
# SKILLs invoke this by name via the
# `wr-itil-enumerate-postrelease-kv-candidates` PATH shim (ADR-049 +
# ADR-080).
#
# Arguments (positional, all optional):
#   $1 — problems-dir (defaults to ./docs/problems)
#   $2 — derive-helper command name (defaults to
#        `wr-itil-derive-release-vehicle`)
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-enumerate-postrelease-kv-candidates: cannot locate lib next to the script" >&2
  exit 2
}
# shellcheck source=/dev/null
source "$LIB/enumerate-postrelease-kv-candidates.sh"
enumerate_postrelease_kv_candidates "$@"
