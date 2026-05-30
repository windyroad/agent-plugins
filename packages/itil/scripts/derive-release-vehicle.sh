#!/usr/bin/env bash
# packages/itil/scripts/derive-release-vehicle.sh
#
# Derive the release-vehicle citation for a problem ticket by walking git
# history. Input: ticket ID (e.g. `P267` or `267`). The script reads the
# ticket body for a `.changeset/<name>.md` filename reference, finds the
# `chore: version packages` deletion commit via `git log --diff-filter=D`,
# resolves the merge PR via the ancestry-path merge commit (or `gh pr list`
# fallback when available), and emits a structured citation block on stdout.
#
# Usage:
#   derive-release-vehicle.sh <ticket-id> [<problems-dir>]
#
# <ticket-id>:     `P<NNN>` or bare `<NNN>`. Case-insensitive.
# <problems-dir>:  defaults to ./docs/problems. Dual-tolerant lookup spans
#                  flat layout (`<problems-dir>/<NNN>-*.md`) AND per-state
#                  subdir layout (`<problems-dir>/*/<NNN>-*.md`) per ADR-031.
#
# Output (stdout, multi-line key:value block):
#   RELEASE_VEHICLE:
#     changeset: .changeset/<name>.md
#     version-packages-commit: <SHA>
#     pr: #<N>
#     merge-commit: <SHA>
#     release-date: <YYYY-MM-DD>
#
# Exit codes:
#   0 = OK (full citation emitted)
#   1 = ticket file not found
#   2 = no changeset reference in ticket body
#   3 = changeset still present in working tree (unreleased)
#   4 = deletion commit found but no merge PR / merge commit resolvable
#
# @problem P267 — Codify derive-release-vehicle.sh helper for K→V release-
#                 cycle citation. K→V transitions composed by hand are
#                 fragile to wrong-release-cited errors when sessions
#                 pre-apply transitions across sibling tickets (observed
#                 2026-05-18 P250 K→V cited P247's release refs).
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution; helper
#               is invoked as `wr-itil-derive-release-vehicle`)
# @adr ADR-022 (Verifying lifecycle — citation supports the K→V transition's
#               `## Fix Released` section)
# @adr ADR-014 (single-commit grain — helper is read-only, no commit impact)
# @adr ADR-038 (progressive disclosure — short structured stdout block)
# @adr ADR-005 (Plugin testing strategy — behavioural bats per P081)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — deterministic
#                 citation prevents cross-cite errors)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — orchestrator per-iter
#                 K→V audit trail is trustworthy)
# @jtbd JTBD-101 (Extend the Plugin Suite — sibling shim naming grammar)

set -uo pipefail

usage() {
  cat >&2 <<'EOF'
USAGE: derive-release-vehicle.sh <ticket-id> [<problems-dir>]
  <ticket-id>    — P<NNN> or bare <NNN> (e.g. P267 or 267)
  <problems-dir> — defaults to ./docs/problems

Exit codes:
  0  ok (full citation emitted)
  1  ticket file not found
  2  no changeset reference in ticket body
  3  changeset still present in working tree (unreleased)
  4  deletion commit found but no merge PR / merge commit resolvable
EOF
}

RAW_ID="${1:-}"
PROBLEMS_DIR="${2:-docs/problems}"

if [ -z "$RAW_ID" ]; then
  usage
  exit 2
fi

# Normalise to three-digit numeric portion.
NNN="$(printf '%s\n' "$RAW_ID" | grep -oE '[0-9]+' | head -1)"
if [ -z "$NNN" ]; then
  echo "ERROR: ticket id must contain digits (got: $RAW_ID)" >&2
  exit 1
fi
NNN="$(printf '%03d' "$((10#$NNN))")"

# ── Locate ticket file (dual-tolerant per ADR-031) ──────────────────────────
TICKET_FILE=""
for candidate in \
  "$PROBLEMS_DIR/$NNN-"*.md \
  "$PROBLEMS_DIR"/*/"$NNN-"*.md; do
  if [ -f "$candidate" ]; then
    TICKET_FILE="$candidate"
    break
  fi
done

if [ -z "$TICKET_FILE" ]; then
  echo "ERROR: ticket P$NNN not found under $PROBLEMS_DIR" >&2
  exit 1
fi

# ── Extract changeset filename reference from ticket body ───────────────────
# Match `.changeset/<name>.md` — kebab + alphanumeric.
CHANGESET_PATH="$(
  grep -oE '\.changeset/[a-z0-9._-]+\.md' "$TICKET_FILE" 2>/dev/null \
    | head -1
)"

if [ -z "$CHANGESET_PATH" ]; then
  echo "ERROR: no .changeset/<name>.md reference in $TICKET_FILE" >&2
  exit 2
fi

# ── Released?  Changeset must be ABSENT from working tree (deleted by
#    chore: version packages) AND have a deletion commit in git history. ────
if [ -f "$CHANGESET_PATH" ]; then
  echo "ERROR: changeset $CHANGESET_PATH still present in working tree (unreleased)" >&2
  exit 3
fi

# ── Find the deletion commit (chore: version packages) ─────────────────────
# `--diff-filter=D` filters to the commit that deleted the file. `--all`
# searches across branches. First match (oldest deletion) is canonical.
DELETE_SHA="$(
  git log --all --diff-filter=D --format='%H' -- "$CHANGESET_PATH" 2>/dev/null \
    | tail -1
)"

if [ -z "$DELETE_SHA" ]; then
  echo "ERROR: changeset $CHANGESET_PATH has no deletion commit in git history (unreleased)" >&2
  exit 3
fi

# ── Resolve merge PR + merge commit ────────────────────────────────────────
# Strategy 1: walk first-parent merges from DELETE_SHA forward toward main,
# match the merge commit that introduced DELETE_SHA into main. The
# `git log --merges --first-parent --ancestry-path DELETE_SHA..HEAD` form
# enumerates merge commits on main whose history descends from DELETE_SHA.
MERGE_SHA=""
PR_NUMBER=""

# Determine the target ref — prefer origin/main, fall back to local main,
# fall back to HEAD's branch.
TARGET_REF=""
for ref in origin/main main HEAD; do
  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    TARGET_REF="$ref"
    break
  fi
done

if [ -n "$TARGET_REF" ]; then
  # First merge commit on the first-parent path from DELETE_SHA..TARGET_REF.
  # `tail -1` picks the closest ancestor (oldest merge that brought
  # DELETE_SHA into the target ref).
  MERGE_SHA="$(
    git log --merges --first-parent --ancestry-path \
      --format='%H' "$DELETE_SHA^..$TARGET_REF" 2>/dev/null \
      | tail -1
  )"
fi

if [ -n "$MERGE_SHA" ]; then
  # Extract `#<N>` from the merge commit subject (canonical PR-merge shape
  # `Merge pull request #<N> from ...`).
  MERGE_SUBJECT="$(git log -1 --format='%s' "$MERGE_SHA" 2>/dev/null)"
  PR_NUMBER="$(printf '%s\n' "$MERGE_SUBJECT" | grep -oE '#[0-9]+' | head -1)"
fi

# Strategy 2: gh pr list fallback when git-history path didn't resolve a
# PR number and `gh` is installed + authenticated.
if [ -z "$PR_NUMBER" ] && command -v gh >/dev/null 2>&1; then
  PR_NUMBER="$(
    gh pr list --state merged --search "$DELETE_SHA" \
      --json number --jq '.[0].number' 2>/dev/null \
      | sed 's/^/#/'
  )"
  [ "$PR_NUMBER" = "#" ] && PR_NUMBER=""
fi

if [ -z "$PR_NUMBER" ] || [ -z "$MERGE_SHA" ]; then
  echo "ERROR: deletion commit $DELETE_SHA found but no merge PR resolvable" >&2
  exit 4
fi

# ── Release date from the merge commit's committer date ────────────────────
RELEASE_DATE="$(git log -1 --format='%cs' "$MERGE_SHA" 2>/dev/null)"

# ── Emit the structured citation block ─────────────────────────────────────
cat <<EOF
RELEASE_VEHICLE:
  changeset: $CHANGESET_PATH
  version-packages-commit: $DELETE_SHA
  pr: $PR_NUMBER
  merge-commit: $MERGE_SHA
  release-date: $RELEASE_DATE
EOF
exit 0
