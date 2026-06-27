#!/usr/bin/env bash
# grade-llm-rubric.sh — promptfoo grading-provider driver for Tier-B
# llm-rubric assertions in the review-test agent eval (P290 / P324 / RFC-012).
#
# Tier-A deterministic substring assertions false-fail on the verdict's
# NEGATIVE clauses: a `not-icontains` for "structural" fires against the
# behaviourally-CORRECT answer "this is BEHAVIOURAL, not structural" (the
# forbidden substring appears inside a negation). A regex cannot distinguish
# "must-not-X satisfied" from "the token X appears in a negating clause".
# Those clauses are semantic and route to llm-rubric (Tier-B), per the P270
# not-regex-false-fail lesson recorded in docs/briefing/promptfoo-eval-
# authoring.md.
#
# promptfoo invokes the grading provider with the fully-rendered rubric
# grading prompt as the single argument and expects stdout to be a JSON
# object: {"pass": bool, "score": number, "reason": string}. claude -p tends
# to wrap JSON in ```json fences and/or add prose; this wrapper instructs
# strict-JSON output and then extracts the first balanced JSON object as a
# defensive post-process. Mirrors the architect / jtbd grader.
#
# Subscription auth — no API key (CI/release-only per ADR-075 §6).
#
# @adr ADR-075 (Tier-B llm-rubric grading; subscription auth)
# @rfc RFC-012
# @problem P290
# @problem P324
set -euo pipefail

GRADER_SYSTEM='You are a strict grading assistant for an automated test
harness. You will be given a rubric and a model output to grade against it.
Respond with ONLY a single minified JSON object and nothing else — no
markdown, no code fences, no commentary. The JSON schema is exactly:
{"pass": <true|false>, "score": <number 0..1>, "reason": "<one short sentence>"}.
Set "pass" true only if the output satisfies the rubric. Be literal about
negation: an output that says a thing does NOT happen SATISFIES a rubric
requiring that the thing must not happen.'

raw="$(claude -p --append-system-prompt "$GRADER_SYSTEM" "$@")"

# Defensive extraction: emit the first balanced {...} JSON object found in
# the response, stripping any code fences or surrounding prose. If no brace
# object is found, pass the raw through (promptfoo surfaces the parse error,
# which is the correct failure signal).
printf '%s' "$raw" | awk '
  BEGIN { depth = 0; started = 0 }
  {
    line = $0
    for (i = 1; i <= length(line); i++) {
      c = substr(line, i, 1)
      if (c == "{") { depth++; started = 1 }
      if (started) { buf = buf c }
      if (c == "}") { depth--; if (depth == 0 && started) { print buf; exit } }
    }
    if (started) { buf = buf "\n" }
  }
  END { if (started && depth != 0) print buf }
' || printf '%s' "$raw"
