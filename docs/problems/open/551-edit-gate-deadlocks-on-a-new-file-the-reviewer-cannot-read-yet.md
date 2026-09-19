# Problem 551: Edit gate deadlocks on a new file the reviewer cannot read yet, so each gated new file costs an extra reviewer round

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description
**Origin**: internal
**Effort**: S — derived at capture. The cheap fix is prose: name the technique in the deny message and in the authoring skills. The expensive option (a gate that accepts a verdict keyed to a staged draft path) is a real change and would re-rate to M.
**JTBD**: JTBD-001
**Persona**: developer

## Description

The architect and JTBD edit gates write their unlock marker only on a clean PASS.
An ISSUES FOUND verdict writes nothing, so the edit stays blocked. That is
workable while the reviewer can read what you propose — but for a **new** file
under a gated path it is circular: the file cannot be written without a marker,
and the reviewers keep returning ISSUES FOUND because they are judging a prose
description of the artefact rather than the artefact itself.

Observed 2026-09-19 on the P441 iter, writing a new decision record: two
architect rounds and two JTBD rounds. Each reviewer's first pass judged a prose
summary and raised findings partly about substance the summary had elided; each
second pass read the actual draft and discharged them citing line numbers. The
JTBD reviewer's pre-draft pass raised five findings; its post-draft pass
discharged all five.

The working technique is to stage the full draft in the session scratchpad, give
the reviewer its absolute path, state that it lands at the gated path verbatim on
PASS, then copy it across on PASS. Both reviewers read files outside the repo
without complaint. But nothing in the gate's deny message or in the authoring
skills says so, so every agent rediscovers it, and the default behaviour —
describe the file in prose, get ISSUES FOUND, describe it again — burns a
reviewer round per gated new file.

## Symptoms

- A `Write` to a new path under `docs/decisions/` or `docs/stories/` is denied for
  a missing review marker; the review cannot produce one because there is nothing
  to review.
- Reviewer findings on the first pass are about elisions in the summary rather
  than defects in the design, and evaporate once the draft is readable.
- Two reviewer rounds per gated new file per reviewer, where one would do.

## Workaround

Write the complete draft to the session scratchpad, pass the reviewer its
absolute path, say explicitly that it lands at the gated path verbatim once
passed, and copy it across on PASS. Budget two rounds per gated new file anyway:
one on the description to shape it, one on the draft to clear it.

## Impact Assessment

- **Who is affected**: anyone authoring a new file under a gated path — every new
  decision record, every new story. Unattended loops pay it in full.
- **Frequency**: every gated new file. Two of two reviewers, twice, in the one
  session that surfaced it.
- **Severity**: Medium — no incorrect output, but a reliable per-artefact tax on
  exactly the artefacts governance most wants written.

## Root Cause Analysis

The gate's precondition is a marker; the marker's precondition is a PASS; the
PASS's precondition is something to read. For an existing file all three are
satisfiable in order. For a new one the chain has no base case, and the
substitute input the agent reaches for by default — a prose description — is
lossy in exactly the way that produces substantive findings.

### Investigation Tasks

- [ ] Decide the fix locus: deny-message + skill prose naming the
      stage-in-scratchpad technique (cheap), or a gate that accepts a review
      verdict keyed to a staged draft path for a target that does not yet exist
      (the P303 facet-2 shape).
- [ ] Create a reproduction: attempt a `Write` to a new `docs/decisions/` path
      with no marker and confirm the deny message offers no recovery for a
      non-existent target.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P313 (pre-edit verdict grammar), P303 facet 2 (plan-level approval marker).

## Related

- This ticket is the **live owner of P303's deferred facet 2** — the
  disk-state-review deadlock. P303 closed 2026-07-25 having released only its
  drift-relock facet; its closure note records that facet 2 "remains tracked
  separately", and its unticked investigation task — *"the gate should accept a
  plan-level approval marker distinct from the post-edit drift check"* — is
  verbatim this ticket's second fix option.
- **Sibling, not child, of P313** (pre-edit governance-gate catch-22). P313's
  root cause is verdict *grammar*: a reviewer withholding PASS whose sole
  substance is "the change isn't applied yet". Its shipped fix explicitly does
  not relax any substantive check, so a fully P313-compliant reviewer still
  produces the findings seen here — those were about content the prose proxy
  elided, not about the baseline. P313 is grammar; this is input fidelity.
- The 2026-09-19 two-rounds-per-reviewer observation is worth weighing as
  **contra-verification evidence on P313** at the next `/wr-itil:review-problems`
  pass, though it does not by itself fail P313's stated close criterion.
- **P468** (architect PASS marker hook misses a markdown-heading verdict) shares
  the deny-message surface but is a parse failure — a genuine PASS discarded.
  Here no PASS is ever earned.
- **P503** (edit gates bound to the Edit|Write matcher) shares the five-gate
  surface and is the opposite direction: the gate is never reached. Shared
  surface, not shared cause.
- Captured via /wr-itil:capture-problem during the P441 iter retro.
  Hang-off arbitration returned PROCEED_NEW over P503, P178, P276 and P313.
