#!/usr/bin/env bash
# packages/risk-scorer/scripts/restage-commit.sh
#
# Atomic re-stage-and-commit helper for the ADR-014 commit-gate flow.
#
# After the caller delegates to `wr-risk-scorer:pipeline` via the Agent tool
# (or invokes `/wr-risk-scorer:assess-release`), the Agent-tool boundary
# sometimes clears the parent index — a previously-staged set comes back as
# `Changes not staged for commit` and the subsequent `git commit` fails with
# "no changes added to commit" (P326). The workaround is a re-`git add` before
# the commit; this helper bundles the re-add + commit into a single atomic call
# so the SKILL.md surface no longer documents the double-tap.
#
# Surface:
#   wr-risk-scorer-restage-commit -m "<msg>" [-m "<trailer>"] -- <path1> [<path2>...]
#
# Behaviour:
#   - Accumulates all -m flags (repeatable; supports RISK_BYPASS-style trailers).
#   - Requires `--` separator before paths (P326 grammar — avoids the path-vs-flag
#     ambiguity when a path begins with `-`).
#   - Runs `git add -- <paths>` (propagates `git add` exit code on bad paths).
#   - Asserts the cached diff is non-empty (`git diff --cached --name-only`); exits
#     1 if nothing got staged, so the caller sees the empty-stage condition rather
#     than committing an empty-or-misordered set.
#   - Runs `git commit "${msg_args[@]}"` with the accumulated -m flags.
#
# Exit codes:
#   0 — commit landed
#   1 — usage error (missing -m, missing --, no paths) OR empty staging
#   non-zero — propagated from `git add` or `git commit`
#
# @adr ADR-014 (governance skills commit their own work)
# @adr ADR-049 (resolved via bin/wr-risk-scorer-restage-commit shim)
# @adr ADR-052 (behavioural-fixture coverage at scripts/test/restage-commit.bats)
# @problem P326 (staged index cleared after risk-scorer pipeline delegation)
# @problem P057 (git mv + Edit re-stage discipline — composes with this helper)

set -uo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: wr-risk-scorer-restage-commit -m "<msg>" [-m "<trailer>"] -- <path1> [<path2>...]

Atomic re-stage-and-commit after a wr-risk-scorer:pipeline Agent-tool delegation.
At least one -m flag is required. The `--` separator is mandatory before paths.

Examples:
  wr-risk-scorer-restage-commit -m "docs(problems): open P999 widget" -- docs/problems/open/999-widget.md docs/problems/README.md

  wr-risk-scorer-restage-commit \
    -m "docs(problems): capture P999 widget" \
    -m "RISK_BYPASS: capture-deferred-readme" \
    -- docs/problems/open/999-widget.md
USAGE
}

msg_args=()
saw_separator=0
paths=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -m)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: -m requires a message argument" >&2
        usage
        exit 1
      fi
      msg_args+=( -m "$2" )
      shift 2
      ;;
    --)
      saw_separator=1
      shift
      while [ "$#" -gt 0 ]; do
        paths+=( "$1" )
        shift
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unexpected argument '$1' — paths must follow a '--' separator" >&2
      usage
      exit 1
      ;;
  esac
done

if [ "${#msg_args[@]}" -eq 0 ]; then
  echo "ERROR: at least one -m message flag is required" >&2
  usage
  exit 1
fi

if [ "$saw_separator" -eq 0 ]; then
  echo "ERROR: missing '--' separator before paths" >&2
  usage
  exit 1
fi

if [ "${#paths[@]}" -eq 0 ]; then
  echo "ERROR: no paths supplied after '--'" >&2
  usage
  exit 1
fi

git add -- "${paths[@]}"
ADD_STATUS=$?
if [ "$ADD_STATUS" -ne 0 ]; then
  exit "$ADD_STATUS"
fi

if [ -z "$(git diff --cached --name-only)" ]; then
  echo "ERROR: nothing staged after re-add — supplied paths produced an empty index diff" >&2
  exit 1
fi

git commit "${msg_args[@]}"
