---
status: proposed
rfc-id: correction-detector-provenance-guard
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P430]
adrs: [ADR-032, ADR-047, ADR-066, ADR-068, ADR-084, ADR-087]
jtbd: [JTBD-006, JTBD-001]
stories: []
---

# RFC-050: Correction-detector provenance guard

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P430 (itil-correction-detect UserPromptSubmit hook false-positives on orchestrator / AFK prompt text)
**ADRs**: ADR-032 (governance skill invocation patterns — the AFK-iter self-suppress clause), ADR-047 (install-updates scaffolds governance artefacts — the category-axis guard-sharing constraint), ADR-066 / ADR-068 (human-oversight markers — the oversight-nudge guard family), ADR-084 (self-firing deferral census), ADR-087 (authoring-time cadence-annotation contract)
**JTBD**: JTBD-006 (progress the backlog while I'm away), JTBD-001 (enforce governance without slowing down)
**Story maps**: STORY-MAP-005 (Trust the capture-on-correction signal)

## Summary

`packages/itil/hooks/itil-correction-detect.sh` decides whether to inject its MANDATORY
capture-offer block from prompt **content** alone. It has no signal for who authored the
prompt, so the framework's own AFK iteration prompts — which routinely carry imperatives
like "Do NOT invoke capture-* mid-iter" — trip the detector and open nearly every
autonomous iteration with a correction nudge that has no correction behind it.

This RFC is the fix vehicle for P430 (ADR-071 / ADR-072 / ADR-073: a fix proposed on a
Known Error requires a problem-traced RFC, authored as a deliberate pre-implementation
step). It carries a single story: add the missing provenance signal at the dispatcher.

## Driving problem trace

- **P430** (Known Error) — arrived as inbound report #257. Its Root Cause Analysis confirms
  the detector is content-only (`itil-correction-detect.sh` lines 30-40 guard on non-empty
  prompt and pattern match, nothing else; `detectors.sh` `detect_correction_signal` walks
  `CORRECTION_SIGNAL_PATTERNS` with `grep -Eqi`, so bare `\bDO NOT\b` matches ordinary
  imperative prose case-insensitively). Iter subprocesses are dispatched `< /dev/null`, so a
  correction-shaped token in an iter prompt can never be a correction.

## Scope

**The fix being proposed**: a dispatcher-side provenance guard, matching the shape this repo
has chosen four times for the same AFK-iter cross-context class.

1. `itil-correction-detect.sh` self-suppresses when `WR_SUPPRESS_CORRECTION_DETECT=1`
   (literal `1` only), placed ahead of the `jq` parses so the suppressed path costs one
   string comparison.
2. `/wr-itil:work-problems` Step 5 exports that variable before each `claude -p` iter spawn,
   alongside the two guards already exported there.
3. Behavioural bats coverage, plus `unset` in `setup` / `teardown` for hermeticity — the
   guard otherwise leaks from the orchestrator into any bats run inside an iter.
4. The AFK-guard registry line in `docs/briefing/afk-subprocess.md` moves from two exported
   guards to three.

**Why no new ADR** (ADR-073's default reflex — lean on what is already decided): the
approach choice is covered by the existing corpus. `WR_SUPPRESS_PENDING_QUESTIONS`
(ADR-032's self-suppress clause), `WR_SUPPRESS_OVERSIGHT_NUDGE` (ADR-066 / ADR-068),
`WR_SUPPRESS_DEFERRAL_CENSUS` (ADR-084), and `WR_SUPPRESS_DEFERRAL_CADENCE_GATE` (ADR-087)
all resolve it the same way. This RFC cites them and proceeds rather than re-deciding.

**Why a new variable rather than reusing an existing one.** ADR-068 forbids splitting a
guard into per-plugin variables, and ADR-047 extends that constraint along the *category*
axis — one variable silences a whole nudge category. Correction-capture sits outside the
oversight-nudge category those clauses govern: an oversight nudge fires because an
**artefact is missing its ratification**, whereas this detector fires in response to an
**observed behavioural signal in the prompt**. Different trigger class, different lifetime,
different audience. That is the same distinct-class reasoning ADR-084 and ADR-087 used when
each minted its own guard, and it is why folding this into `WR_SUPPRESS_OVERSIGHT_NUDGE`
would silence correction capture whenever a user only meant to silence ratification nudges.

**Empty `stories:` is transient, not the atomic shape.** P430 already carries a full Fix
Strategy, so this RFC is scoped, not pre-scoped. The array is empty only until STORY-047 is
ratified — ADR-090 forbids an RFC referencing an unratified story — and is wired before the
`accepted` transition, where ADR-089's at-least-one-story criterion binds. This is not the
`stories: []` atomic fallback that ADR-089 and ADR-071 disavowed.

## Out of scope

The rejected alternative — sniffing the prompt text for framework markers such as
`ITERATION_SUMMARY` — is recorded with its reasoning in P430's Fix Strategy, which is its
home. Per ADR-070 an RFC holds no independent decisions, so it is not re-argued here.

## Stories

Decomposed as STORY-047 (Gate the correction nudge on prompt authorship) on STORY-MAP-005.
The story is authored and awaiting ratification; the `stories:` array is wired once it is
ratified, before this RFC transitions to `accepted`.

## Commits

(rendered from `git log --grep "Refs: RFC-050"` at `/wr-itil:manage-rfc`. At capture there
are no commits yet.)

## Related

- **P430** — driving problem, inbound report #257.
- **STORY-MAP-005** — the story map this RFC's work sits on.
