# Problem 430: itil-correction-detect UserPromptSubmit hook false-positives on orchestrator / AFK prompt text

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Origin**: inbound-reported (#257)
**Effort**: S. WSJF = (8 × 2.0) / 1 = 16.0.
**WSJF**: 16 — (8 × 2.0) / 1 (known-error multiplier applied 2026-07-26)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`itil-correction-detect.sh`'s `CORRECTION_SIGNAL_PATTERNS` (DO NOT / NEVER / MUST NOT / all-caps) has no provenance check: it fires on orchestrator- and AFK-generated prompt text that legitimately contains those tokens, mis-classifying framework prose as a user correction and nudging a capture-problem offer on nearly every AFK iter.

## Symptoms

- An AFK iter prompt or orchestrator instruction containing "MUST NOT"/"NEVER" trips the correction detector → spurious capture-on-correction nudge with no real user correction.

## Impact Assessment

- **Who is affected**: AFK loops; noise + spurious ticket-capture offers.
- **Frequency**: most AFK iters (orchestrator prompts routinely carry imperative tokens).
- **Severity**: Medium — noise, not incorrect action, but erodes the signal.

## Root Cause Analysis

**Confirmed root cause.** `packages/itil/hooks/itil-correction-detect.sh` decides whether to inject its
MANDATORY capture-offer block on **content alone**. Its only guards are "prompt is non-empty" (line 33)
and "`detect_correction_signal` matched a pattern" (line 37). There is no check on **who authored the
prompt**. `detect_correction_signal` (`packages/itil/hooks/lib/detectors.sh` line 205) walks
`CORRECTION_SIGNAL_PATTERNS` — which includes bare `\bDO NOT\b`, `\bSTOP\b`, `\bDON'T\b` — with
`grep -Eqi`, i.e. case-insensitively, so ordinary imperative framework prose matches as readily as a
shouted correction.

The `/wr-itil:work-problems` iteration prompt is framework-authored and routinely carries exactly those
tokens ("Do NOT invoke capture-* background skills mid-iter", "Do NOT use ScheduleWakeup", "Do NOT poll
bats/subprocess completion"). Every such iter therefore opens with a full ~1.2 KB MANDATORY block
instructing the agent to offer a ticket capture for a correction that never happened.

**Direct evidence (this session).** The iter subprocess working this very ticket received the hook's
full block at prompt 1, reporting `matched pattern: \bDO NOT\b`. No user correction was present — the
iter prompt has no user author at all. This is the reported symptom reproduced in situ.

**Why the signal is structurally absent, not merely weak.** Iters are dispatched
`--permission-mode bypassPermissions ... < /dev/null` (work-problems SKILL.md Step 5). There is no
keyboard on that context by construction, so a correction-shaped token in an iter prompt can never be a
correction. Provenance is a property of the **dispatcher**, and only the dispatcher can assert it — it
is not recoverable from the prompt text.

### Investigation Tasks

- [x] Skip prompts carrying AFK/orchestrator markers, or add an AFK branch to the injected instruction;
  require a user-authored provenance signal before the correction nudge fires.
- [x] Confirm the detector is content-only with no provenance guard (`itil-correction-detect.sh` lines
  30-40; `detectors.sh` lines 68-80, 205-216).
- [x] Confirm the sibling AFK-iter suppression idiom already exists and is ADR-sanctioned.

## Workaround

Ignore the block when it fires inside an AFK iter — it is advisory and non-blocking, so the iter can
proceed without capturing a ticket. No configuration change avoids it today: the hook reads only the
prompt text and has no opt-out.

## Fix Strategy

Add the missing provenance signal at the **dispatcher**, matching the repo's established idiom for this
exact class:

1. `packages/itil/hooks/itil-correction-detect.sh` — self-suppress on `WR_SUPPRESS_CORRECTION_DETECT=1`
   (literal `1` only), placed ahead of the `jq` parses so the suppressed path costs one string compare.
2. `packages/itil/skills/work-problems/SKILL.md` Step 5 — export that variable before each `claude -p`
   iter spawn, alongside the two guards already exported there.
3. Behavioural bats in `packages/itil/hooks/test/itil-correction-detect.bats`: a user-authored
   correction still fires; the same prompt under the guard emits nothing and writes no announce marker;
   a non-`1` value does not suppress. Plus `unset` in `setup`/`teardown` for P391 hermeticity.
4. Update the AFK-guard registry line in `docs/briefing/afk-subprocess.md` (two guards listed → three).

Precedent, all four of which chose dispatcher-side env-var self-suppress over content heuristics:
`WR_SUPPRESS_PENDING_QUESTIONS`, `WR_SUPPRESS_OVERSIGHT_NUDGE`, `WR_SUPPRESS_DEFERRAL_CENSUS`,
`WR_SUPPRESS_DEFERRAL_CADENCE_GATE`. A new variable is correct here because correction-capture is a
distinct class, not a per-plugin split of an existing guard (the ADR-068 constraint).

**Rejected alternative — sniff the prompt text for framework markers** ("ITERATION_SUMMARY", "the user
is AFK"). It risks false-negatives on genuine corrections that mention AFK, and it would close one
over-fire by opening another in the same detector family this ticket's Dependencies section names.

Preserves P078: a real correction reaches the **orchestrator** session, where the guard is not set and
the hook still fires.

## Dependencies

- **Composes with**: (distinct from the P268 / P272–275 "substring-matches git commit" hook-detector family — same over-fire class, different hook).

## Related

- Inbound issue #257. Pattern vocabulary: `packages/itil/hooks/lib/detectors.sh::CORRECTION_SIGNAL_PATTERNS`.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-050 | proposed | Correction-detector provenance guard |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-047 | STORY-047: Gate the correction nudge on prompt authorship | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
