#!/usr/bin/env bash
# Enumerate Known Error problem tickets whose Release-vehicle citation
# points at a just-shipped changeset — input to the work-problems
# Step 6.5 Post-release K→V auto-transition callback (P228).
#
# Driver: ADR-022 prescribes K→V transition on release, but until P228
# there was no auto-fire surface to back-fill the transition once a fix
# ships. Iter subprocesses defer K→V to "the next session" citing a
# misapplied P143 amendment, and tickets accumulate in
# `docs/problems/known-error/` with `## Fix Released` populated but no
# transition. The 2026-06-08 P220 empirical witness confirmed the gap.
#
# Composes with `wr-itil-derive-release-vehicle` (P267) — the derive
# helper's exit-code contract is the filter:
#   exit 0  → changeset has been deleted from the working tree AND has a
#             deletion commit in git history (released to npm). Emit as
#             KV_CANDIDATE.
#   exit 2  → no `.changeset/<name>.md` reference in ticket body
#             (legacy ticket pre-P330). Skip silently.
#   exit 3  → changeset still present in working tree (unreleased).
#             Skip silently.
#   other   → log to stderr, skip.
#
# Source this file, then call `enumerate_postrelease_kv_candidates`:
#   . packages/itil/lib/enumerate-postrelease-kv-candidates.sh
#   enumerate_postrelease_kv_candidates "$PWD/docs/problems" \
#     "wr-itil-derive-release-vehicle"
#
# Stdout (multi-line):
#   KV_CANDIDATE: P<NNN> | <changeset-path>
#   ...
#   KV_CANDIDATES_SUMMARY: total=<N>
#
# Exit: 0 always (idempotent — safe to invoke when the directory is
#        empty or absent). Stderr carries non-fatal warnings.
#
# Glob — targets `docs/problems/known-error/*.md` directly (per-state
# subdir layout per ADR-031). Flat-layout tickets are NOT in scope — the
# adopter has already migrated when this callback fires (work-problems
# Step 0a auto-migrate runs before Step 6.5).
#
# Cross-references:
#   @problem P228 (K→V auto-transition gap)
#   @problem P220 (empirical witness)
#   @problem P267 (derive-release-vehicle composed helper)
#   @problem P330 (Release vehicle seed reference — input signal)
#   @adr ADR-022 (Verifying lifecycle)
#   @adr ADR-018 (release-cadence host of the callback)
#   @adr ADR-031 (per-state subdir layout — glob target)
#   @adr ADR-049 (bin/ PATH shim — adopter-safe script resolution)
#   @adr ADR-005 (behavioural bats per P081)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary driver)
#   @jtbd JTBD-001 (Enforce Governance Without Slowing Down — audit trail)

enumerate_postrelease_kv_candidates() {
  local problems_dir="${1:-docs/problems}"
  local derive_cmd="${2:-wr-itil-derive-release-vehicle}"
  local kedir="$problems_dir/known-error"
  local total=0

  if [ ! -d "$kedir" ]; then
    printf 'KV_CANDIDATES_SUMMARY: total=0\n'
    return 0
  fi

  local saved_nullglob
  saved_nullglob="$(shopt -p nullglob)"
  shopt -s nullglob

  local f
  for f in "$kedir"/*.md; do
    local bn
    bn="$(basename "$f")"
    [ "$bn" = "README.md" ] && continue

    local nnn
    nnn="$(printf '%s\n' "$bn" | grep -oE '^[0-9]+' | head -1)"
    [ -z "$nnn" ] && continue

    local derive_out derive_exit
    derive_out="$("$derive_cmd" "$nnn" "$problems_dir" 2>/dev/null)"
    derive_exit=$?

    case "$derive_exit" in
      0)
        local changeset
        changeset="$(printf '%s\n' "$derive_out" \
          | grep -oE '\.changeset/[a-z0-9._-]+\.md' \
          | head -1)"
        printf 'KV_CANDIDATE: P%03d | %s\n' "$((10#$nnn))" "$changeset"
        total=$((total + 1))
        ;;
      2|3)
        ;;
      *)
        printf 'enumerate-postrelease-kv-candidates: derive helper exit=%d for P%03d (skipped)\n' \
          "$derive_exit" "$((10#$nnn))" >&2
        ;;
    esac
  done

  eval "$saved_nullglob"

  printf 'KV_CANDIDATES_SUMMARY: total=%d\n' "$total"
  return 0
}
