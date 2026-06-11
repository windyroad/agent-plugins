# Problem 364: External-comms gate marker key mismatch on backtick-bearing gh bodies

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

External-comms gate marker key derivation mismatches on backtick-bearing gh bodies — a PASS-reviewed draft containing markdown backticks never unlocks the gh issue comment post, because the --body shell argument carries backslash-escaped backticks while the reviewed `<draft>` block carries plain ones; the PostToolUse marker key hash differs and the PreToolUse gate denies repeatedly. Witnessed 2026-06-11 AFK iter 3 (P228 upstream comment to windyroad/agent-plugins#42): two structured-format reviews (~21K subagent tokens each) blocked until the body was re-drafted without backticks, after which the identical flow passed both evaluators serially. Fix candidates: normalize/unescape the body before hashing on both PreToolUse + PostToolUse sides, or document a --body-file canonical contract, or strip markdown code-span formatting in the gate's hash input. Composes with P276 (over-fire on PASS-class content edits — different failure mode: this is key-mismatch, not over-fire) and P360 (serial evaluator discovery also witnessed this iter).

## Symptoms

(deferred to investigation)

## Workaround

Re-draft the outbound body WITHOUT backticks (plain names instead of code spans) so the double-quoted `--body "..."` shell argument is byte-identical to the reviewed `<draft>` content; then run the structured review (`SURFACE: gh-issue-comment` first line + `<draft>` wrapper) once per evaluator (risk, then voice-tone) and retry the post.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause (confirm the hash input is the raw command text vs parsed --body argument; identify the escaping layer)
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P276, P360

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P276** — external-comms gate marker over-fires on PASS-class content edits; different failure mode at the same gate surface (over-fire vs key-mismatch).
- **P360** — gates discover unmet evaluators serially (~19K tokens each round-trip); the serial risk-then-voice-tone discovery was re-witnessed during this capture's driver incident.
- **P163** (closed) — external-comms agent emitted placeholder marker key on first invocation; prior marker-key defect class at the same gate, fixed separately.
- Driver incident: 2026-06-11 AFK work-problems iter 3 — P228 fix-released lifecycle comment to windyroad/agent-plugins#42; two blocked posts with backticked body, success after backtick-free re-draft. Briefing entry added to `docs/briefing/hooks-and-gates.md` § What Will Surprise You same session.

## Fix Strategy

**Kind**: improve
**Shape**: hook
**Target file**: the external-comms gate hook pair (PreToolUse deny + PostToolUse marker-writer) in `packages/risk-scorer/hooks/` — marker-key derivation path.
**Edit summary**: make the marker-key hash input canonical across both sides — e.g. unescape shell backslash-escapes (or hash the parsed `--body` argument value rather than raw command text) so a PASS review of the literal draft unlocks the literal post; alternatively document and support a `--body-file` canonical contract.
**Evidence**: 2026-06-11 iter 3 — backticked body: review PASS, post BLOCKED (×2, ~21K subagent tokens each); backtick-free body: identical flow, both evaluators unlocked serially, post succeeded.
