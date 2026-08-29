#!/usr/bin/env bash
# wr-jtbd — mark a JTBD/persona's human-oversight: confirmed marker write as
# user-substance-confirmed (P348 / ADR-110).
#
# JTBD-side sibling of packages/architect/scripts/mark-oversight-confirmed.sh.
# Companion to jtbd-oversight-marker-discipline.sh. SKILLs invoke this as a
# standalone Bash command AFTER an AskUserQuestion lands the user's substance-
# confirm answer. The existing PostToolUse:Bash hook binds that exact command
# event's path and session id into the marker.
#
# Why the marker is required:
#   ADR-068 mirrors ADR-066's `human-oversight: confirmed` marker contract on
#   the JTBD/persona surface. P348 captured iter subprocesses silently
#   writing the `confirmed` value without a user confirmation event,
#   contradicting JTBD-006's audit-trail outcome and JTBD-201/202's
#   auditability persona constraints. The hook enforces the boundary
#   structurally; this script is the evidence-write side that legitimate
#   substance-confirm flows use.
#
# AFK iter subprocesses with no AskUserQuestion access MUST write
# `human-oversight: unconfirmed` instead (the new enum value codified in
# ADR-110), which the drain
# (/wr-jtbd:confirm-jobs-and-personas) later promotes.
#
# Usage:
#   wr-jtbd-mark-oversight-confirmed <artefact-path>
#     Must be the whole Bash command, with exactly one JTBD/persona path.
#
# Exit codes:
#   0 — command validated; PostToolUse writes the exact-session marker.
#   2 — bad argument count.
#
# @adr ADR-068 (JTBD/persona human-oversight marker)
# @adr ADR-049 (PATH shim grammar)
# @adr ADR-013 (Rule 6 fail-safe-defer in non-interactive contexts)
# @problem P348 (iter subprocesses set human-oversight: confirmed without user event)
# @problem P368 (candidate enumeration grants unrelated sessions)

set -uo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "wr-jtbd-mark-oversight-confirmed: expected exactly one <artefact-path>" >&2
  exit 2
fi

exit 0
