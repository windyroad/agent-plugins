#!/usr/bin/env bash
# wr-itil — run the problems-layout flat→per-state migration (P317/RFC-009).
#
# Adopter-safe wrapper: sources the canonical lib RELATIVE TO THIS SCRIPT
# (`$(dirname)/../lib`), then invokes the function. Replaces the SKILL-inline
# `source packages/itil/lib/migrate-problems-layout.sh; migrate_... "$PWD"`,
# which only resolved in the source monorepo (P317). SKILLs invoke this by name
# via the `wr-itil-migrate-problems-layout` PATH shim (ADR-049). The migration
# routine is idempotent + partial-migration-safe (no-op when no flat-layout
# files exist). Operates on the directory given as $1 (defaults to $PWD).
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-migrate-problems-layout: cannot locate lib next to the script" >&2
  exit 2
}
# shellcheck source=/dev/null
source "$LIB/migrate-problems-layout.sh"
migrate_problems_to_per_state_layout "${1:-$PWD}"
