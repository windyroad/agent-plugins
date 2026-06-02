#!/usr/bin/env bash
# check-locale-discipline.sh — advisory lint for P328 (BSD locale UTF-8
# friction on macOS).
#
# BSD `grep` / `sed` / `awk` on macOS silently fail (or emit
# `multibyte conversion failure` / `illegal byte sequence`) when processing
# UTF-8 multi-byte characters (em-dash `—`, smart quotes, en-dash) without
# `LC_ALL=en_US.UTF-8` set. Our prose surfaces (ADRs, problem-ticket bodies,
# briefing entries, SKILL.md files) are pervasively em-dash / smart-quote
# rich, so any script that grep / sed / awks those surfaces is exposed.
# P328 captures three distinct incident classes from the 2026-05-30
# ADR-077 compendium session.
#
# This lint walks `packages/*/scripts/*.sh`, `packages/*/hooks/*.sh`, and
# `packages/*/lib/*.sh` (including `packages/*/hooks/lib/*.sh`) and reports
# any line invoking `grep` / `sed` / `awk` that is NOT preceded — in the
# same script — by an `export LC_ALL=` statement OR an inline `LC_ALL=`
# prefix on the same line. `git grep` is skipped (different binary).
#
# Usage:
#   check-locale-discipline.sh [<repo-root>]
#     <repo-root> defaults to the current working directory.
#
# Environment:
#   WR_LOCALE_DISCIPLINE_WARN_ONLY=1   Phase 1 advisory (default) — exit 0
#                                       even when violations exist.
#   WR_LOCALE_DISCIPLINE_WARN_ONLY=0   Phase 2 load-bearing — exit 1 when
#                                       violations exist.
#
# Exit codes:
#   0 = clean OR Phase 1 advisory with violations
#   1 = Phase 2 load-bearing with violations
#   2 = usage / path error
#
# Output format (one line per violation, to stderr):
#   WARN  <relpath>:<line>  <tool> without preceding LC_ALL=en_US.UTF-8
#
# Promotion criteria (Phase 1 → Phase 2):
#   Promote `WR_LOCALE_DISCIPLINE_WARN_ONLY=0` once existing scripts have
#   been migrated. Until then, the warnings are signal-only — they identify
#   scripts that may silently mis-process UTF-8 input on macOS.
#
# @adr ADR-040 (advisory-then-load-bearing reusable pattern)
# @adr ADR-049 (plugin-bundled scripts; PATH shim)
# @adr ADR-052 (behavioural-tests-default)
# @adr ADR-080 (highest-version-wins shim wrapper)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory exit 0)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-101 (Extend the Suite with New Plugins)
# @problem P328 (BSD grep/sed/awk on macOS friction with UTF-8)

set -uo pipefail

# Self-application: this lint itself grep / sed / awks script content.
export LC_ALL=en_US.UTF-8

REPO_ROOT="${1:-$(pwd)}"
WARN_ONLY="${WR_LOCALE_DISCIPLINE_WARN_ONLY:-1}"

if [ ! -d "$REPO_ROOT" ]; then
  echo "check-locale-discipline: not a directory: $REPO_ROOT" >&2
  exit 2
fi

if [ ! -d "$REPO_ROOT/packages" ]; then
  echo "check-locale-discipline: no packages/ subdir under $REPO_ROOT" >&2
  exit 2
fi

# Enumerate target scripts: any *.sh under packages/<pkg>/scripts/,
# packages/<pkg>/hooks/ (incl. nested lib/), packages/<pkg>/lib/.
# Depth 3-5 covers packages/<pkg>/scripts/foo.sh and
# packages/<pkg>/hooks/lib/foo.sh.
mapfile -t TARGETS < <(
  find "$REPO_ROOT/packages" \
    -mindepth 3 -maxdepth 5 \
    -type f -name '*.sh' \
    \( -path '*/scripts/*' -o -path '*/hooks/*' -o -path '*/lib/*' \) \
    2>/dev/null | sort
)

violations=0
scanned=0

scan_one() {
  local file="$1"
  local rel="${file#"$REPO_ROOT"/}"
  local line_no=0
  local lc_all_set=0
  local in_heredoc=0
  local heredoc_token=''
  local line

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))

    # Heredoc body — skip until the closing token. The closing token
    # appears on a line of its own (optionally leading whitespace when
    # opened with `<<-`).
    if [ "$in_heredoc" -eq 1 ]; then
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      if [ "$trimmed" = "$heredoc_token" ]; then
        in_heredoc=0
        heredoc_token=''
      fi
      continue
    fi

    # Comment-only line — skip.
    if [[ "$line" =~ ^[[:space:]]*\# ]]; then
      continue
    fi

    # LC_ALL set state. An `export LC_ALL=...` line flips the file-wide
    # protection on. An inline `LC_ALL=...` prefix on the same line as a
    # grep / sed / awk invocation protects only that line.
    if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+LC_ALL= ]]; then
      lc_all_set=1
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*LC_ALL= ]]; then
      continue
    fi

    # Detect a heredoc-open ON THIS LINE (before deciding it's a violation
    # — heredoc-open lines may carry a grep/sed/awk invocation that runs).
    # Grammar: `<<` or `<<-` followed by optional single/double quote then
    # an identifier-shaped token. Set state for subsequent lines.
    local opened_heredoc=0
    if [[ "$line" =~ \<\<-?[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]? ]]; then
      heredoc_token="${BASH_REMATCH[1]}"
      opened_heredoc=1
    fi

    # If file-wide LC_ALL is set above this point, no violation possible.
    if [ "$lc_all_set" -eq 1 ]; then
      [ "$opened_heredoc" -eq 1 ] && in_heredoc=1
      continue
    fi

    # Tool-invocation detector. Word-boundary match on grep / sed / awk
    # at a command position: start of line, after a pipe, semicolon,
    # ampersand, open-paren, backtick, or whitespace. Followed by
    # whitespace (so we skip `grep_helper`, `$grep`, etc.). We scan
    # for ALL three tools by checking each in turn so multiple
    # invocations on one line still flag the line once per distinct
    # tool — keeps output deterministic and bounded.
    local matched_tool=''
    if [[ "$line" =~ (^|[[:space:]\|\;\&\(\`\$\{])(grep|sed|awk)([[:space:]]|$) ]]; then
      matched_tool="${BASH_REMATCH[2]}"
    fi

    if [ -n "$matched_tool" ]; then
      # Skip `git grep` (different binary; uses git's own pattern engine).
      if [ "$matched_tool" = "grep" ] && [[ "$line" =~ git[[:space:]]+grep ]]; then
        [ "$opened_heredoc" -eq 1 ] && in_heredoc=1
        continue
      fi
      printf 'WARN  %s:%d  %s without preceding LC_ALL=en_US.UTF-8\n' \
        "$rel" "$line_no" "$matched_tool" >&2
      violations=$((violations + 1))
    fi

    [ "$opened_heredoc" -eq 1 ] && in_heredoc=1
  done < "$file"
}

for f in "${TARGETS[@]}"; do
  scanned=$((scanned + 1))
  scan_one "$f"
done

if [ "$violations" -gt 0 ]; then
  printf 'check-locale-discipline: %d violation(s) across %d script(s) — add `export LC_ALL=en_US.UTF-8` at the top of each script that calls grep/sed/awk on UTF-8 content, or use an inline `LC_ALL=...` prefix per invocation (P328).\n' \
    "$violations" "$scanned" >&2
  if [ "$WARN_ONLY" = "1" ]; then
    exit 0
  else
    exit 1
  fi
fi

printf 'check-locale-discipline: clean (%d script(s) scanned; no unprotected grep/sed/awk invocations).\n' "$scanned"
exit 0
