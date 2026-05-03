#!/usr/bin/env bash
# packages/retrospective/scripts/check-readme-jtbd-currency.sh
#
# Diagnose-only advisory script for ADR-051 (JTBD-anchored README rule).
# Walks packages/*/README.md and emits a drift signal per package:
#
#   - has_jtbd_anchor=<yes|no>     — at least one JTBD-\d{3} match in the README
#   - cited_jobs=<count>           — count of distinct JTBD IDs cited
#   - known_jobs=<count>           — count of cited IDs that resolve to a current
#                                    docs/jtbd/<persona>/JTBD-NNN-*.md (any status)
#   - drift_hints=<comma-list>     — signal vocabulary:
#         missing-jtbd-section     (no JTBD-\d{3} at all)
#         stale-jtbd-citation      (cited ID has no resolving file)
#         deprecated-jtbd-citation (cited ID resolves only to .deprecated.md / .superseded.md)
#         skill-inventory-drift    (a directory under packages/<plugin>/skills/ is not named in README)
#
# Plus a trailing TOTAL line summarising the window:
#   TOTAL packages=<N> with_jtbd=<M> drift_instances=<K>
#
# Exit code is always 0 — the script is advisory per ADR-013 Rule 6
# fail-safe / ADR-040 declarative-first / ADR-051 Phase 1.
# Drift count is emitted as data on stdout; downstream consumers
# (run-retro Step 2b future wiring, release-pre-flight habit, Phase 2
# escalation per ADR-051 Phase 2 criterion) decide whether to act.
#
# Usage:
#   check-readme-jtbd-currency.sh [<packages-dir>] [<jtbd-dir>]
#
# Defaults:
#   <packages-dir> = ./packages
#   <jtbd-dir>     = ./docs/jtbd
#
# Exit codes:
#   0 = always (advisory only — count is signal, not failure)
#   2 = parse error (packages-dir or jtbd-dir missing or unreadable)
#
# Output format (one line per package, alphabetical):
#   README package=<name> has_jtbd_anchor=<yes|no> cited_jobs=<N> known_jobs=<M> drift_hints=<csv>
#
# @problem P152 (No pressure or nudge for documentation currency — the driver problem)
# @adr ADR-051 (JTBD-anchored README with declarative drift advisory — this script's normative source)
# @adr ADR-008 (JTBD directory structure — the resolution target layout)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory script never blocks AFK)
# @adr ADR-040 (declarative-first / advisory-then-escalate precedent)
# @adr ADR-049 (bin/-on-PATH script resolution — paired wr-retrospective-check-readme-jtbd-currency shim)
# @adr ADR-005 / ADR-037 (Plugin testing strategy — behavioural tests via bats)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just Installed — primary served job)
# @jtbd JTBD-007 (Keep Plugins Current Across Projects — currency expansion)
# @jtbd JTBD-101 (Extend the Suite with New Plugins — clear patterns the detector documents)

set -uo pipefail

PACKAGES_DIR="${1:-packages}"
JTBD_DIR="${2:-docs/jtbd}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$PACKAGES_DIR" ]; then
  echo "check-readme-jtbd-currency: packages dir not found: $PACKAGES_DIR" >&2
  exit 2
fi

if [ ! -d "$JTBD_DIR" ]; then
  echo "check-readme-jtbd-currency: jtbd dir not found: $JTBD_DIR" >&2
  exit 2
fi

# ── Build the JTBD index ────────────────────────────────────────────────────
# Map JTBD-NNN -> comma-separated status suffixes (proposed|validated|deprecated|superseded)
# A JTBD ID may resolve to multiple files (e.g. during a status transition);
# we record ALL status suffixes per ID for downstream use.

declare -A JTBD_STATUS_BY_ID
declare -A JTBD_RESOLVED

for jpath in "$JTBD_DIR"/*/JTBD-*.md; do
  [ -e "$jpath" ] || continue
  base="$(basename "$jpath")"
  if [[ "$base" =~ ^(JTBD-[0-9]{3})-.*\.([a-z]+)\.md$ ]]; then
    id="${BASH_REMATCH[1]}"
    status="${BASH_REMATCH[2]}"
    JTBD_RESOLVED["$id"]=1
    if [ -z "${JTBD_STATUS_BY_ID[$id]:-}" ]; then
      JTBD_STATUS_BY_ID["$id"]="$status"
    else
      JTBD_STATUS_BY_ID["$id"]="${JTBD_STATUS_BY_ID[$id]},$status"
    fi
  fi
done

# ── Helpers ─────────────────────────────────────────────────────────────────

append_hint() {
  local current="$1"
  local hint="$2"
  if [ -z "$current" ]; then
    echo "$hint"
  elif [[ ",$current," == *",$hint,"* ]]; then
    echo "$current"
  else
    echo "$current,$hint"
  fi
}

is_deprecated_only() {
  local statuses="$1"
  IFS=',' read -ra arr <<< "$statuses"
  for s in "${arr[@]}"; do
    case "$s" in
      deprecated|superseded) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# ── Scan packages ───────────────────────────────────────────────────────────

total_packages=0
total_with_jtbd=0
total_drift_instances=0

package_dirs=()
for pdir in "$PACKAGES_DIR"/*/; do
  [ -d "$pdir" ] || continue
  package_dirs+=("$pdir")
done

if [ "${#package_dirs[@]}" -eq 0 ]; then
  exit 0
fi

IFS=$'\n' sorted_dirs=($(printf '%s\n' "${package_dirs[@]}" | sort))
unset IFS

for pdir in "${sorted_dirs[@]}"; do
  package="$(basename "$pdir")"
  readme="$pdir/README.md"

  # Skip packages without a README — out of scope
  [ -f "$readme" ] || continue

  total_packages=$(( total_packages + 1 ))

  # Extract distinct JTBD-NNN matches from the README
  cited_ids=()
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    cited_ids+=("$id")
  done < <(grep -oE 'JTBD-[0-9]{3}' "$readme" 2>/dev/null | sort -u)

  cited_count="${#cited_ids[@]}"

  has_anchor="no"
  if [ "$cited_count" -gt 0 ]; then
    has_anchor="yes"
    total_with_jtbd=$(( total_with_jtbd + 1 ))
  fi

  hints=""
  known_count=0

  if [ "$cited_count" -eq 0 ]; then
    hints=$(append_hint "$hints" "missing-jtbd-section")
  else
    has_stale=0
    has_deprecated_only=0
    for id in "${cited_ids[@]}"; do
      if [ -n "${JTBD_RESOLVED[$id]:-}" ]; then
        known_count=$(( known_count + 1 ))
        if is_deprecated_only "${JTBD_STATUS_BY_ID[$id]}"; then
          has_deprecated_only=1
        fi
      else
        has_stale=1
      fi
    done
    [ "$has_stale" -eq 1 ] && hints=$(append_hint "$hints" "stale-jtbd-citation")
    [ "$has_deprecated_only" -eq 1 ] && hints=$(append_hint "$hints" "deprecated-jtbd-citation")
  fi

  # Soft heuristic: skill inventory drift — every directory under
  # packages/<plugin>/skills/ should be named in the README.
  if [ -d "$pdir/skills" ]; then
    for sdir in "$pdir/skills"/*/; do
      [ -d "$sdir" ] || continue
      skill="$(basename "$sdir")"
      if ! grep -q -F "$skill" "$readme" 2>/dev/null; then
        hints=$(append_hint "$hints" "skill-inventory-drift")
        break
      fi
    done
  fi

  # Drift instance: any non-empty hint set
  if [ -n "$hints" ]; then
    total_drift_instances=$(( total_drift_instances + 1 ))
  fi

  echo "README package=$package has_jtbd_anchor=$has_anchor cited_jobs=$cited_count known_jobs=$known_count drift_hints=$hints"
done

if [ "$total_packages" -gt 0 ]; then
  echo "TOTAL packages=$total_packages with_jtbd=$total_with_jtbd drift_instances=$total_drift_instances"
fi

exit 0
