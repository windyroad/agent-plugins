---
status: proposed
job-id: keep-assistant-responses-in-my-chosen-voice
persona: developer
date-created: 2026-09-16
human-oversight: confirmed
oversight-date: 2026-09-17
---

# JTBD-013: Keep Assistant Responses in My Chosen Voice

## Job Statement

When I use an AI coding agent, I want every response to follow project-specific
voice-and-tone guidance and receive one semantic self-review before the turn
stops, so the interaction consistently fits how I read and work without me
restating the guidance.

## Desired Outcomes

- Adding `docs/ASSISTANT-VOICE-AND-TONE.md` opts in. When the file is absent,
  the feature adds no hook output and no review turn.
- The guide is prose expressive enough for formal plain-language guidance and
  creative traits without requiring profiles, deterministic rules, or separate
  enablement and enforcement settings.
- The same language model assesses its completed response against the whole
  guide and can produce one complete corrected response. It never retries a
  second time.
- While opted in, I knowingly accept one additional model turn and its latency
  and token cost in exchange for consistent responses.
- Claude Code and Codex behavior, including whether the first response can be
  visible before correction, is documented instead of presented as identical.
- One guided skill creates or updates the guide. Deleting the guide remains an
  explicit opt-out action.
- Reviews claim alignment with the supplied prose, never certification against
  a named standard.

## Persona Constraints

- Wants speed without sacrificing quality. The extra review cost is acceptable
  only while the project has explicitly opted in.
- Works across runtimes and should not have to infer differences in their hook
  behavior.
- May name a formal standard in the guide, but reliable assessment requires the
  applicable rules to be present or otherwise available to the model.

## Current Solutions

- Repeat the same voice-and-tone instructions in every conversation.
- Put response preferences in a general agent instruction file, where they can
  become mixed with unrelated development rules.
- Manually correct responses after they drift.
- Accept inconsistent response style between turns, sessions, and projects.

## Related

- **JTBD-003: Compose Only the Guardrails I Need** — file existence makes this
  response guardrail explicitly opt-in.
- **JTBD-011: Have a Correction to the Agent's Conduct Hold Everywhere** — this
  job differs by deliberately accepting per-response review cost while enabled.
- **JTBD-101: Extend the Suite with New Plugins** — the guided authoring skill
  is a new surface inside the existing voice-tone plugin.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-090 | STORY-090: Keep assistant responses in my chosen voice | accepted |
