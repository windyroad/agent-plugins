#!/usr/bin/env bash
# verify-iter-summary.sh — detect ITERATION_SUMMARY over-claim against
# on-disk ADR Confirmation state.
#
# Closes P335: AFK iter subprocess over-claims completion in ITERATION_SUMMARY
# while on-disk Confirmation `[ ]` boxes remain. Step 6.75 of work-problems
# dispatches this script between iter completion and Step 7 loop-back.
#
# Contract:
#   verify-iter-summary.sh <commit_sha> <notes_file> [<repo_root>]
#
# Exit codes:
#   0 = OK (no completion-claim signal, OR signal but all items checked, OR
#           no ADR referenced)
#   1 = OVER-CLAIM detected — at least one cited ADR has a completion-claim
#           signal AND unchecked `- [ ]` items in its `## Confirmation`
#           section
#   2 = invocation error (missing args, missing notes file, bad sha)
#
# Per ADR-049, this script is invoked via the PATH shim
# `wr-itil-verify-iter-summary` from SKILL.md prose — never via the
# repo-relative `packages/itil/scripts/...` path.

set -u

commit_sha="${1:-}"
notes_file="${2:-}"
repo_root="${3:-}"

if [ -z "$commit_sha" ] || [ -z "$notes_file" ]; then
  echo "verify-iter-summary: missing required arg(s); usage: verify-iter-summary.sh <commit_sha> <notes_file> [<repo_root>]" >&2
  exit 2
fi

if [ ! -f "$notes_file" ]; then
  echo "verify-iter-summary: notes_file not found: $notes_file" >&2
  exit 2
fi

if [ -z "$repo_root" ]; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
fi

# Pull commit message; combine with notes for the full claim surface.
commit_message="$(git -C "$repo_root" log -1 --format=%B "$commit_sha" 2>/dev/null)"
if [ -z "$commit_message" ]; then
  echo "verify-iter-summary: could not read commit message for $commit_sha" >&2
  exit 2
fi
notes_content="$(cat "$notes_file")"
combined="$commit_message
$notes_content"

# Extract ADR identifiers (ADR-NNN, 1-4 digit numeric).
adr_ids="$(echo "$combined" | grep -oE 'ADR-[0-9]{1,4}' | sort -u || true)"

if [ -z "$adr_ids" ]; then
  exit 0
fi

# Detect completion-claim signal in the combined claim surface.
# Patterns (case-insensitive):
#   - "all <something> green|complete|done|checked|ticked"
#   - "every <something> green|complete|done|checked|ticked"
#   - "all (Confirmation|criteria) items <complete|green|done|ticked>"
#   - "(a)-(<letter>) green|complete|all"  (the ADR-077 witness shape)
#   - "Confirmation items (a)-(<letter>) all green at source"
has_signal=0
if echo "$combined" | grep -qiE '(all|every)[[:space:]]+[^.]{0,80}(green|complete|done|checked|ticked|landed)' ; then
  has_signal=1
fi
if [ "$has_signal" -eq 0 ] && echo "$combined" | grep -qiE '\([a-z]\)[[:space:]]*[-–][[:space:]]*\([a-z]\)[[:space:]]+(green|complete|all|done|landed)' ; then
  has_signal=1
fi
if [ "$has_signal" -eq 0 ] && echo "$combined" | grep -qiE '(green|complete|done|ticked|checked)[[:space:]]+at[[:space:]]+source' ; then
  has_signal=1
fi

if [ "$has_signal" -eq 0 ]; then
  exit 0
fi

# For each cited ADR, resolve the file path and inspect the Confirmation section.
over_claim_lines=""
while IFS= read -r adr_id; do
  [ -z "$adr_id" ] && continue
  # Extract the numeric portion (zero-padded to 3 digits where possible).
  adr_num="${adr_id#ADR-}"
  # Resolve to a file path; the ADR may use any status suffix.
  adr_files="$(find "$repo_root/docs/decisions" -maxdepth 1 -type f \
    \( -name "${adr_num}-*.md" -o -name "$(printf '%03d' "$adr_num" 2>/dev/null)-*.md" \) \
    2>/dev/null | head -1)"

  if [ -z "$adr_files" ]; then
    # Cited ADR doesn't exist on disk; this is suspicious but not an
    # over-claim per se. Skip silently — the architect/JTBD review surface
    # catches missing-ADR-reference issues separately.
    continue
  fi

  adr_file="$adr_files"

  # Slice out the `## Confirmation` section (between `## Confirmation` and
  # the next `^## ` heading, or EOF).
  confirmation_section="$(awk '
    /^## Confirmation/ { in_section = 1; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$adr_file")"

  if [ -z "$confirmation_section" ]; then
    continue
  fi

  # Count unchecked items: leading `- [ ]` markers.
  unchecked_count="$(echo "$confirmation_section" | grep -cE '^- \[ \]' || true)"

  if [ "$unchecked_count" -gt 0 ]; then
    over_claim_lines="${over_claim_lines}OVER-CLAIM: $adr_id has $unchecked_count unchecked Confirmation item(s) at $adr_file but iter claim language signals completion
"
  fi
done <<< "$adr_ids"

if [ -n "$over_claim_lines" ]; then
  printf '%s' "$over_claim_lines"
  exit 1
fi

exit 0
