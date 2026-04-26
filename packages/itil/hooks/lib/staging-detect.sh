#!/bin/bash
# P125: shared staging-trap detection helper.
#
# `detect_p057_trap` returns 0 (no trap detected — allow) / 1 (trap
# detected — caller should deny). On 1, the trap'd path is echoed on
# stdout and a one-line recovery hint is emitted on stderr so callers
# can surface both in deny messages without re-parsing diff output.
#
# Trap shape (P057):
#   `git mv A B` stages the rename atomically. If the agent then
#   modifies B via the Edit tool (or any other working-tree edit),
#   git's index still carries only the rename — the post-rename
#   content edit is a working-tree modification needing a separate
#   `git add B`. Without that re-stage, only the rename lands at
#   commit time and the edit leaks into the next commit (audit-trail
#   corruption — the original P057 concern).
#
# Detection logic:
#   - `git diff --staged --name-status` enumerates staged changes;
#     rename rows start with `R<num>\t<old>\t<new>`.
#   - `git diff --name-only` enumerates working-tree modifications.
#   - If any rename's `<new>` path also appears in the working-tree
#     modification list, the trap shape is present.
#
# Cost: two `git diff` invocations per check (~10-50ms on this repo's
# working tree; bounded by repo size, not commit batch size). Per
# architect verdict on P125: cheaper than a session-marker variant
# and deterministic — runs on every `git commit` invocation rather
# than relying on per-tool-call session state tracking.
#
# Fail-open contract:
#   - Outside a git working tree, or when `git diff` fails for any
#     reason (parse error, broken index, permissions), return 0
#     (allow). Mirrors `lib/create-gate.sh`'s exit-0 fallback on
#     parse-incomplete input — a hook that fails-closed on hostile
#     environments would block legitimate commits in non-git contexts
#     (e.g. agent-driven scripts that happen to mention `git commit`
#     in unrelated contexts).
#
# References:
#   ADR-005 — plugin testing strategy (hook bats live under hooks/test/).
#   ADR-009 — gate marker lifecycle (this helper deliberately does NOT
#             use markers; detection is per-invocation deterministic,
#             not per-session trust window).
#   ADR-013 Rule 1 — deny redirects with mechanical recovery (the deny
#                    text names the file + the literal `git add <new>`
#                    recovery; no skill round-trip required).
#   ADR-038 — progressive disclosure / deny-message terseness.
#   P057    — original staging-trap ticket (closed; documentation fix).
#   P119    — sibling create-gate hook + lib/create-gate.sh helper
#             (precedent for the deny + helper-pair shape).
#   P125    — this helper.

# Detect the P057 staging trap in the current git working tree.
#
# Echoes the trap'd path on stdout when detected; emits a one-line
# recovery hint on stderr.
#
# Returns:
#   0 — no trap (allow / fail-open)
#   1 — trap detected (caller should deny)
#
# Usage:
#   if trapped=$(detect_p057_trap 2>/dev/null); then
#     echo "no trap"
#   else
#     echo "trap on $trapped"
#   fi
detect_p057_trap() {
  # Fail-open if not inside a git working tree.
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  # Staged renames: rows shaped `R<num>\t<old>\t<new>`.
  local staged_renames
  staged_renames=$(git diff --staged --name-status 2>/dev/null) || return 0

  # Working-tree modifications: one path per line.
  local wt_mods
  wt_mods=$(git diff --name-only 2>/dev/null) || return 0

  # No working-tree mods at all => nothing can be the post-rename
  # content edit. Fast bail.
  [ -n "$wt_mods" ] || return 0

  # Walk staged renames; if any `<new>` path also appears in the
  # working-tree mod list, the trap is present.
  local line new_path
  while IFS= read -r line; do
    case "$line" in
      R*)
        # Tab-delimited: status \t old \t new — take the third field.
        new_path=$(printf '%s' "$line" | awk -F'\t' '{print $3}')
        [ -n "$new_path" ] || continue
        # Match against working-tree mod list (full-line match).
        if printf '%s\n' "$wt_mods" | grep -Fxq "$new_path"; then
          printf '%s\n' "$new_path"
          echo "P057 staging-trap: re-stage with: git add $new_path" >&2
          return 1
        fi
        ;;
    esac
  done <<EOF
$staged_renames
EOF

  return 0
}
