#!/bin/bash
# P165: shared README-refresh-discipline detection helper.
#
# `detect_readme_refresh_required` returns 0 (no change required —
# allow) / 1 (ticket change staged but README refresh not staged —
# caller should deny). On 1, the offending ticket file path is echoed
# on stdout so callers can name it in deny messages without re-parsing
# diff output.
#
# Trap shape (P165):
#   `manage-problem` SKILL.md Step 5 (P094) and Step 7 (P062) say every
#   ticket creation, ranking-bearing update, and status transition MUST
#   stage the refreshed `docs/problems/README.md` in the same commit as
#   the ticket change (ADR-014 single-commit grain). The contract is
#   declarative; iter subprocess commits have shipped `.verifying.md`
#   renames or Status edits without the README refresh (observed iter
#   3 commit d28bd51 — P156 row missing from VQ until iter 4 backfill).
#   Hook-level detection at `git commit` time replaces the declarative-
#   only enforcement.
#
# Detection logic:
#   - `git diff --staged --name-only` enumerates staged paths.
#   - Categorise each path:
#       * `docs/problems/(open|verifying|closed|known-error|parked)/NNN-*.md`
#         (new state-directory layout per ADR-031) — counts as a
#         ticket-state-transition surface; records the path.
#       * `docs/problems/NNN-*.(open|verifying|closed|known-error|parked).md`
#         (legacy flat layout) — also counts; supports adopter repos
#         and any residual flat-layout tickets.
#       * `docs/problems/README.md` — counts as a README refresh.
#       * `docs/problems/README-history.md` — ignored (rotated history
#         per P134; not a ticket file, not the load-bearing README).
#       * Anything else — ignored (non-ticket surface; the gate has no
#         opinion on retros, ADRs, source, etc.).
#   - If any ticket path is recorded AND README is NOT staged, return
#     1 + echo the first offending ticket path.
#
# Bypass:
#   - `BYPASS_README_REFRESH_GATE=1` env var → return 0 (allow). For
#     legitimate narrative-only ticket-body edits that don't change
#     ranking-bearing fields. Audit-traceable via shell history.
#
# Fail-open contract:
#   - Outside a git working tree, or when `git diff` fails for any
#     reason (parse error, broken index, permissions), return 0
#     (allow). Mirrors `lib/staging-detect.sh` + `lib/changeset-detect.sh`
#     fail-open precedent — a hook that fails-closed on hostile
#     environments would block legitimate commits in non-git contexts.
#
# Cost: one `git diff` invocation per check (~10ms on this repo's
# working tree). Per-invocation deterministic — runs on every
# `git commit` invocation rather than relying on per-tool-call session
# state tracking. Mirrors P125 `staging-detect.sh` + P141
# `changeset-detect.sh` precedent (architect-approved no-marker design
# per ADR-009 carve-out).
#
# References:
#   ADR-005  — plugin testing strategy (hook bats live under
#              `hooks/test/` per P081 behavioural-test discipline).
#   ADR-009  — gate marker lifecycle (this helper deliberately does
#              NOT use markers; detection is per-invocation
#              deterministic, not per-session trust window — same
#              precedent as P125 / P141).
#   ADR-013 Rule 1 — deny redirects with mechanical recovery (the deny
#              text names the offending ticket path + the literal
#              `git add docs/problems/README.md` recovery command +
#              the BYPASS env var override).
#   ADR-014  — single-commit grain (this hook enforces it for the
#              ticket-state-transition surface).
#   ADR-022  — `.verifying.md` lifecycle status (one of the surface
#              shapes the hook detects).
#   ADR-031  — per-state-subdir problem ticket layout (the new layout
#              the hook detects).
#   ADR-038  — progressive disclosure / deny-message terseness.
#   ADR-045  — hook injection budget (Pattern 1 silent-on-pass; deny
#              band ≤300 bytes for this hook).
#   P062     — parent (README refresh on transition contract — manage-
#              problem Step 7).
#   P094     — parent (README refresh on creation contract — manage-
#              problem Step 5).
#   P118     — sibling reconcile-readme recovery path (the after-the-
#              fact rescue this hook obviates).
#   P125     — sibling staging-trap helper (same enforcement-layer
#              shape — per-invocation deterministic, no markers).
#   P141     — sibling changeset-discipline helper (same shape).
#   P165     — this helper.

# Detect whether the current staged set requires a README refresh that
# is not staged.
#
# Echoes the offending ticket path on stdout when detected.
#
# Returns:
#   0 — no change required, or BYPASS env set, or fail-open (allow)
#   1 — ticket change staged + README not staged (caller should deny)
detect_readme_refresh_required() {
  # Bypass via env var — single most-common legitimate escape.
  if [ "${BYPASS_README_REFRESH_GATE:-}" = "1" ]; then
    return 0
  fi

  # Fail-open if not inside a git working tree.
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local staged
  staged=$(git diff --staged --name-only 2>/dev/null) || return 0

  # No staged paths — nothing to gate.
  [ -n "$staged" ] || return 0

  local has_readme=0
  local offending_ticket=""
  local path basename

  while IFS= read -r path; do
    [ -n "$path" ] || continue

    case "$path" in
      docs/problems/README.md)
        has_readme=1
        ;;
      docs/problems/README-history.md)
        # Rotated history file — not a ticket, not the load-bearing
        # README. Ignored.
        ;;
      docs/problems/open/*.md \
      | docs/problems/verifying/*.md \
      | docs/problems/closed/*.md \
      | docs/problems/known-error/*.md \
      | docs/problems/parked/*.md)
        # New state-directory layout (ADR-031). Filename must start
        # with digits to be a ticket file — exclude any future
        # state-directory-local README or similar.
        basename="${path##*/}"
        case "$basename" in
          [0-9]*.md)
            [ -z "$offending_ticket" ] && offending_ticket="$path"
            ;;
        esac
        ;;
      docs/problems/[0-9]*.md)
        # Legacy flat layout: docs/problems/NNN-*.<state>.md.
        # Excludes README.md and README-history.md (already cased
        # above; both start with `R`, not a digit).
        [ -z "$offending_ticket" ] && offending_ticket="$path"
        ;;
      *)
        # Non-ticket surface: ignored.
        ;;
    esac
  done <<EOF
$staged
EOF

  if [ -n "$offending_ticket" ] && [ "$has_readme" -eq 0 ]; then
    printf '%s\n' "$offending_ticket"
    return 1
  fi

  return 0
}
