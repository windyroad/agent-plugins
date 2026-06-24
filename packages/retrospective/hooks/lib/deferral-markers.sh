#!/usr/bin/env bash
# P375 — single source of truth for the deferred-work marker vocabulary.
#
# A "deferred-work marker" is prose that parks work against a named-but-not-
# self-firing re-entry point (a /skill, a lifecycle transition, "next review").
# Per P375 the rot test is: does the trigger chain reach a SELF-FIRING event?
# This vocabulary is what the SessionStart census (retrospective-deferral-
# census.sh) greps for so the parked work cannot silently rot.
#
# Sourced, not executed. Defines DEFERRAL_MARKER_RE (grep -E, case-insensitive
# at the call site).
#
# Convergence note: itil-fictional-defer-detect.sh keeps its own retro-specific
# DEFER_RATIONALE_RE for now; folding it onto this vocabulary is a tracked P375
# investigation task, NOT refactored cross-plugin here (ADR-002/003 plugin
# self-containment — a retrospective lib must not become an itil runtime dep).
# P378 fold: slice/phase-deferral phrasing ("lands in Slice N", "future slice",
# "deferred to a hook-source slice", "<lands|deferred> ... in a future <slice|
# pass|iter>") was MISSED by the original vocabulary — that blind spot let the
# never-built RFC commit-trailer executor ("lands in Slice 3 task B5.T9") hide
# from the census. Added so slice/phase-deferred-and-unbuilt work surfaces too.
DEFERRAL_MARKER_RE='\(deferred|deferred to|pending review|re-rate at next|: deferred|lands in [Ss]lice|future slice|hook-source slice|in a future (slice|pass|iter|session)'
