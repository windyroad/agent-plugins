#!/usr/bin/env bash
# wr-architect — mark a decision/ADR's human-oversight: confirmed marker write
# as user-substance-confirmed (P348 / ADR-110).
#
# Companion to the architect-oversight-marker-discipline.sh PreToolUse hook.
# SKILLs invoke this as a standalone Bash command AFTER an AskUserQuestion
# lands the user's substance-confirm answer. The existing PostToolUse:Bash
# hook binds that exact command event's path and session id into the marker.
#
# Why the marker is required:
#   ADR-066 establishes that `human-oversight: confirmed` is a write-once-
#   permanent durable record. ADR-074 + P340 tighten the substance-confirm
#   semantics: the marker MAY ONLY land in response to a user answer that
#   selects a specific option. AFK iter subprocesses have no AskUserQuestion
#   access (ADR-013 Rule 6 fail-safe-defer territory), so they MUST NOT write
#   the `confirmed` value — they write `human-oversight: unconfirmed` instead,
#   which the drain (/wr-architect:review-decisions) later promotes. The hook
#   enforces the boundary structurally; this script is the evidence-write
#   side that legitimate substance-confirm flows use.
#
# Usage:
#   wr-architect-mark-oversight-confirmed <artefact-path>
#     Must be the whole Bash command, with exactly one ADR path argument.
#
# Exit codes:
#   0 — command validated; PostToolUse writes the exact-session marker.
#   2 — bad argument count.
#
# @adr ADR-066 (human-oversight marker)
# @adr ADR-049 (PATH shim grammar)
# @adr ADR-013 (Rule 6 fail-safe-defer in non-interactive contexts)
# @problem P348 (iter subprocesses set human-oversight: confirmed without user event)
# @problem P368 (candidate enumeration grants unrelated sessions)

set -uo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "wr-architect-mark-oversight-confirmed: expected exactly one <artefact-path>" >&2
  exit 2
fi

exit 0
