---
status: proposed
rfc-id: detect-mechanical-step-framed-as-optional
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P403]
adrs: []
jtbd: []
stories: []
---

# RFC-042: Detect mechanical-step-framed-as-user-optional in agent end-of-turn prose

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P403
**ADRs**: (none)
**JTBD**: (none)

## Summary

Add a structural detector that catches the agent re-framing a framework-mandated mechanical step as a user decision in end-of-turn prose (e.g. *"Step 7 auto-release skipped — your call whether to drain"*, *"skipped the full re-rank to stay within budget"*). Extends the existing itil assistant-output-review Stop hook + its detector registry rather than adding a new hook.

## Driving problem trace

- **P403** — Agent frames skill-mandatory mechanical steps as user-optional. Standing `feedback_*` memories capture the anti-pattern but rely on the agent reading them each turn; no structural detector exists. Confirmed root cause: the existing `itil-assistant-output-review.sh` Stop hook scans for prose-ask phrasings but has no pattern for the mechanical-step-as-optional closer shape.

## Scope

The fix being proposed: a **non-blocking Stop-hook detector**, budget-neutral under ADR-045 (extends an already-registered hook, adds no new hook registration).

Chosen implementation approach (from P403 Fix Strategy, architect-approved 2026-07-03):

1. **`packages/itil/hooks/lib/detectors.sh`** — add two pattern arrays and one pure detector function mirroring the existing `detect_prose_ask` shape:
   - `MECHANICAL_OPTIONAL_PATTERNS` — user-optional closer phrases (`your call`, `up to you`, `worth doing`, `user's call`, `if you want`, `feel free to`).
   - `STEP_SKIP_PATTERNS` — signals that a mechanical step was skipped/deferred (`Step <N> … skip`, `skipped … Step`, `skipped the … re-rank|pass|pipeline|release|drain`).
   - `detect_mechanical_optional()` — fires **only when a step-skip signal AND an optional-framing closer co-occur** in the turn text. The AND-discriminator is the anti-false-positive guard (a legitimately user-owned decision with no skipped-step context does not fire), matching the accepted false-positive posture already documented for `CORRECTION_SIGNAL_PATTERNS`.
2. **`packages/itil/hooks/itil-assistant-output-review.sh`** — after the existing `detect_prose_ask` scan (which `exit 0`s on match, so this sits on the no-prose-ask path — at most one nudge per turn), run `detect_mechanical_optional` on the same last-assistant-turn text; on match emit a distinct `stopReason` nudge citing P132 / ADR-044 (act on the framework-resolved step; do not re-surface it as a user decision).
3. **`packages/itil/hooks/test/itil-assistant-output-review.bats`** — behavioural coverage: the two P403 evidence phrasings fire the nudge; a clean turn stays silent; an optional-closer-without-step-skip turn stays silent (proves the AND-discriminator); an ADR-045 byte-budget assertion on the new nudge.

Out of scope: a PostToolUse blocking hook, a SKILL.md prose amendment, and enumerating every mechanical-step contract (the detector is phrasing-based, not contract-aware).

## Tasks

- [ ] Add `MECHANICAL_OPTIONAL_PATTERNS`, `STEP_SKIP_PATTERNS`, and `detect_mechanical_optional()` to `packages/itil/hooks/lib/detectors.sh`.
- [ ] Wire `detect_mechanical_optional` into `packages/itil/hooks/itil-assistant-output-review.sh` with a distinct `stopReason` nudge.
- [ ] Add behavioural bats (positive ×2 evidence phrasings, negative clean, negative AND-discriminator, byte-budget) to `itil-assistant-output-review.bats`.
- [ ] `@windyroad/itil` patch changeset.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc --fix-time; expand at next /wr-itil:manage-rfc invocation)
