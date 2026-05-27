#!/usr/bin/env bash
# wr-itil — write the problem-tier create-gate marker (P119) under every
# candidate session SID (P260 / ADR-050 Option C).
#
# Internalises the source+pipe that capture-problem / manage-problem Step 2
# previously ran INLINE with repo-relative `source packages/itil/hooks/lib/*.sh`
# — which only resolved in the source monorepo and broke in adopter installs
# (P317 / RFC-009). This script resolves its sibling libs RELATIVE TO ITS OWN
# LOCATION (`$(dirname)/../hooks/lib`), so it works wherever the plugin is
# installed. SKILLs invoke it by name via the `wr-itil-mark-create-gate` PATH
# shim (ADR-049) instead of sourcing repo-relative lib files.
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks/lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-mark-create-gate: cannot locate hooks/lib next to the script" >&2
  exit 2
}

# shellcheck source=/dev/null
source "$LIB/session-id.sh"
# shellcheck source=/dev/null
source "$LIB/create-gate.sh"

# Writes /tmp/manage-problem-grep-<SID> under each recent candidate SID; returns
# non-zero only if no candidate SID was discoverable (fail-closed parity).
get_candidate_session_ids | mark_step2_complete_candidates
