#!/usr/bin/env bash
# packages/retrospective/scripts/check-autocreate-rfc-scope.sh
#
# Diagnose-only advisory script for ADR-073 (Fix-time gate auto-creates a
# missing RFC). ADR-073's Reassessment Criteria say to revisit the
# auto-create decision "if auto-created RFCs are systematically under-scoped
# (a recurring 'the auto-RFC didn't capture the real fix' signal)". The I13
# fix-time gate auto-creates problem-traced *skeleton* RFCs via
# /wr-itil:capture-rfc whenever a Known Error has no RFC trace; the
# auto-create event is otherwise only logged ephemerally to the work-problems
# iter-summary `notes`. This detector makes the reassessment signal durable
# and observable: it reads the auto-created RFCs left on disk and surfaces the
# ones whose traced problem's fix has already shipped while the RFC scope was
# never fleshed out — exactly the under-scoped population. RFC-005 B9 wires it
# into /wr-retrospective:run-retro Step 2b as an advisory sub-block (mirroring
# the README inventory-currency advisory, ADR-069/P294).
#
# An RFC is a SKELETON when its `## Scope` section still carries the
# capture-rfc placeholder `(deferred — populate at /wr-itil:manage-rfc
# accepted transition)` (capture-rfc/SKILL.md skeleton contract).
#
# A skeleton RFC is UNDER-SCOPED (a reassessment candidate) when its
# `problems:` frontmatter traces at least one FIX-SHIPPED problem, where
# fix-shipped means any of (broadened so the gate-on-next-touch population —
# fixes shipped before the gate existed, recorded as `## Fix Strategy` in a
# `known-error/` ticket — is caught; the canonical P361/RFC-026 dogfood case):
#   - the problem file lives under <problems-dir>/verifying/ or .../closed/, OR
#   - the problem body has a `## Fix Released` heading, OR
#   - the problem body has a POPULATED `## Fix Strategy` section (heading with
#     non-blank body content — a bare stub heading does not count). Fix-
#     *proposed* is sufficient for the under-scoped signal: the RFC should have
#     been fleshed out the moment a fix was scoped (ADR-073 Consequences — the
#     RFC body is fleshed out as fix work proceeds).
#
# Output (one line per under-scoped candidate, then a trailing summary):
#   AUTOCREATE-RFC under-scoped rfc=<RFC-NNN> problems=<csv> shipped=<pid:basis>
#   TOTAL proposed_skeletons=<N> under_scoped=<K>
# where <basis> is one of: verifying | closed | fix-released | fix-strategy.
#
# Exit codes:
#   0 = always (advisory only — count is signal, not failure; ADR-013 Rule 6)
#   2 = parse error (rfcs-dir missing or unreadable)
#
# Usage:
#   check-autocreate-rfc-scope.sh [<rfcs-dir>] [<problems-dir>]
# Defaults:
#   <rfcs-dir> = docs/rfcs     <problems-dir> = docs/problems
#
# @problem P314 (rework the fix-time RFC-trace gate — RFC-005 B9)
# @adr ADR-073 (fix-time gate auto-creates a missing RFC — this script's
#               normative source; its Reassessment Criteria are what B9 wires)
# @adr ADR-060 (Problem-RFC-Story framework; I13 fix-time trace invariant)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory script never blocks)
# @adr ADR-040 (declarative-first / advisory-then-escalate precedent)
# @adr ADR-049 (bin/-on-PATH script resolution — paired
#               wr-retrospective-check-autocreate-rfc-scope shim)
# @adr ADR-052 / P081 (behavioural tests via bats; no structural-grep on source)

set -uo pipefail

RFCS_DIR="${1:-docs/rfcs}"
PROBLEMS_DIR="${2:-docs/problems}"

# The capture-rfc skeleton placeholder (em-dash is U+2014, matching the
# capture-rfc skeleton contract and the live RFC-026 skeleton).
PLACEHOLDER='deferred — populate at /wr-itil:manage-rfc accepted transition'

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$RFCS_DIR" ]; then
  echo "check-autocreate-rfc-scope: rfcs dir not found: $RFCS_DIR" >&2
  exit 2
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

# Extract a markdown section body: lines after the `## <heading>` line up to
# (but excluding) the next `## ` heading. Heading matched whole-line.
section_body() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    $0 ~ "^## " h "([[:space:]]*$)" { f=1; next }
    /^## / && f { f=0 }
    f { print }
  ' "$file"
}

# True when a section has non-blank body content beyond the skeleton
# placeholder — i.e. it is genuinely populated, not a bare stub heading.
section_populated() {
  local file="$1" heading="$2"
  section_body "$file" "$heading" \
    | grep -qv -e '^[[:space:]]*$' -e "$PLACEHOLDER"
}

# Echo a fix-shipped basis (verifying|closed|fix-released|fix-strategy) for a
# problem id, or empty when the problem is not fix-shipped / not found.
problem_fix_shipped() {
  local pid="$1" num pfile
  num="${pid#P}"
  pfile="$(find "$PROBLEMS_DIR" -type f -name "${num}-*.md" 2>/dev/null | head -1)"
  [ -n "$pfile" ] || { echo ""; return; }
  case "$pfile" in
    */verifying/*) echo "verifying"; return ;;
    */closed/*)    echo "closed";    return ;;
  esac
  if grep -qE '^## Fix Released([[:space:]]*$)' "$pfile"; then
    echo "fix-released"; return
  fi
  if grep -qE '^## Fix Strategy([[:space:]]*$)' "$pfile" \
      && section_populated "$pfile" "Fix Strategy"; then
    echo "fix-strategy"; return
  fi
  echo ""
}

# Echo space-separated problem ids from an RFC's `problems:` frontmatter.
rfc_problems() {
  grep -m1 '^problems:' "$1" 2>/dev/null | grep -oE 'P[0-9]+'
}

# ── Scan proposed RFCs ──────────────────────────────────────────────────────

total_skeletons=0
under_scoped=0

shopt -s nullglob
rfcs=("$RFCS_DIR"/*.proposed.md)
shopt -u nullglob

# Stable alphabetical order for deterministic output.
IFS=$'\n' rfcs=($(printf '%s\n' "${rfcs[@]}" | sort))
unset IFS

for rfc in "${rfcs[@]}"; do
  [ -f "$rfc" ] || continue

  # Skeleton = `## Scope` section still carries the placeholder.
  if ! section_body "$rfc" "Scope" | grep -qF "$PLACEHOLDER"; then
    continue
  fi
  total_skeletons=$(( total_skeletons + 1 ))

  rfc_id="$(basename "$rfc" | grep -oE '^RFC-[0-9]+')"

  pids="$(rfc_problems "$rfc")"
  [ -n "$pids" ] || continue

  csv=""
  shipped_pid=""
  shipped_basis=""
  for pid in $pids; do
    csv="${csv:+$csv,}$pid"
    if [ -z "$shipped_pid" ]; then
      basis="$(problem_fix_shipped "$pid")"
      if [ -n "$basis" ]; then
        shipped_pid="$pid"
        shipped_basis="$basis"
      fi
    fi
  done

  if [ -n "$shipped_pid" ]; then
    under_scoped=$(( under_scoped + 1 ))
    echo "AUTOCREATE-RFC under-scoped rfc=$rfc_id problems=$csv shipped=$shipped_pid:$shipped_basis"
  fi
done

echo "TOTAL proposed_skeletons=$total_skeletons under_scoped=$under_scoped"
exit 0
