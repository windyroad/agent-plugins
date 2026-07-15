# Problem 444: Agent buries granular design decisions in artefacts — default values, thresholds, and policy choices pass artefact-level ratification unsurfaced, escaping real oversight

**Status**: Open
**Reported**: 2026-07-08
**Priority**: 15 (High) — Impact: 3 (Moderate — real loss of user oversight over design/policy choices; recurs across the suite's own governance artefacts) × Likelihood: 5 (Certain — it is the default authoring behaviour) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — a surfacing discipline (per-embedded-choice flag) + possibly a lightweight checklist/gate; not a large build.
**WSJF**: 7.5 — (15 × 1.0) / 2 (added 2026-07-15 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

When the agent mechanises a decision, it embeds **granular design choices** — default values, thresholds, policy constants, config defaults — inside an artefact (ADR mechanics, story acceptance criteria, a hook constant) **without surfacing each choice as an explicit decision point.** Ratifying the *artefact* (approving an ADR or story) does NOT ratify the micro-decisions buried in it, so they "slip in without real oversight" — the user only catches them by reading the file deeply.

**Driving witness (user, 2026-07-08):** the quota-pace throttle's **5pp weekly / 0pp 5-hour headroom** — a genuine policy choice about how much of the user's weekly quota to reserve — was buried in ADR-093's Mechanics section and a STORY-039 acceptance criterion. ADR-093 was "ratified", but that specific value was never surfaced for the user's call; they only found it by opening the story file. Verbatim: *"while the headroom is a good idea, you should ask me about stuff like that. If I didn't ask to read the story file, it would have slipped in without real oversight."*

This is the same meta-class the whole 2026-07-08 session surfaced (things "solved / decided for the maintainer" without adopter/user oversight): the *artefact* passes ratification, but the *decisions inside it* were never individually offered to the human.

## Symptoms

- A default value / threshold / policy constant appears in shipped mechanics or a story criterion that the user never explicitly approved.
- The user discovers it only by reading the artefact, not via a decision prompt.
- "Ratified" artefacts contain unsurfaced agent-chosen policy values.

## Impact Assessment

- **Who is affected**: developer / maintainer (loses oversight over policy choices that ride into ratified artefacts); adopters (inherit agent-chosen defaults as de-facto policy).
- **Frequency**: Continuous — every artefact that mechanises a decision embeds such choices.
- **Severity**: Moderate — no runtime break, but a real erosion of the human-oversight guarantee the governance suite exists to provide.

## Root Cause Analysis

### Preliminary Hypothesis

Ratification operates at the artefact grain (approve this ADR / story), not the decision grain. There is no discipline or gate that enumerates the embedded design choices (values, thresholds, defaults) and offers each for explicit oversight. The agent treats "the user approved the artefact" as covering every choice inside it — the P357 hollow-ratification failure, one level finer.

### Investigation Tasks

- [ ] Define a **surfacing discipline**: when authoring/mechanising a decision, flag each embedded choice (value / threshold / default that becomes de-facto policy) as an explicit decision point — an `AskUserQuestion` or a briefed "I picked X; OK?" line — before it rides into a ratified artefact.
- [ ] Prefer **configurability over hard-coding** for such values (per machine AND per project), and surface the config *mechanism* itself as a decision (see the 2026-07-08 quota-headroom config-file request — env vars judged inconvenient; a config file wanted).
- [ ] Consider a lightweight checklist/gate at ADR/story authoring that asks "what defaults/thresholds/policy values does this introduce, and were they each surfaced?"
- [ ] Reconcile with P357 (brief-and-ratify AFTER changes): the post-change brief must *enumerate* embedded design choices, not just describe artefact-level changes.

## Dependencies

- **Blocks**: (none directly)
- **Blocked by**: (none)
- **Composes with**: P357 (user direction ≠ substance ratification — this is the finer, per-embedded-choice grain), P422 (agent ships X-prime / a lesser version without asking), ADR-066 / ADR-068 (lift auto-made artefacts to human oversight — same spirit at the artefact grain), ADR-093 / STORY-039 (the driving witness — the 5pp/0pp headroom).

## Related

- Driving witness: the 5pp/0pp quota headroom (ADR-093 Mechanics + STORY-039 acceptance criterion), caught by the user 2026-07-08.
- Maintainer memory `feedback_surface_embedded_design_decisions`.
- P357 (`docs/problems/known-error/357-...md`) — sibling class (ratification granularity, user-direction path).
- P422 (`docs/problems/open/422-...md`) — sibling class (agent ships a hedged/lesser version without asking before deviating).
