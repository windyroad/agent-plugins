---
status: done
story-id: keep-assistant-responses-in-my-chosen-voice
reported: 2026-09-17
decision-makers: [Tom Howard]
problems: [P540]
jtbd: [JTBD-013]
rfcs: [RFC-094]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-090: Keep assistant responses in my chosen voice

**Reported**: 2026-09-17
**Problems**: P540
**JTBD**: JTBD-013
**RFCs**: RFC-094
**Story Maps**: STORY-MAP-008
**Estimated effort**: M — two bounded hooks, one guide-management skill, shared runtime projection, behavioural tests, and a package release

## User value

In order to receive consistently readable responses without repeating instructions, as a developer using an AI coding assistant, I want one project prose guide to shape every response and allow one bounded semantic self-review before the turn stops.

## Acceptance criteria

- [x] The feature is enabled only when `docs/ASSISTANT-VOICE-AND-TONE.md` exists; absence produces no hook output or extra model turn.
- [x] The complete prose guide is injected on the first prompt and only reinjected after substantive content changes.
- [x] The same main assistant may review and replace its response once; the Stop retry guard prevents a second continuation.
- [x] No profile, enforcement setting, deterministic response check, nested assistant, MCP evaluator, or certification claim is introduced.
- [x] `/wr-voice-tone:update-assistant-guide` creates or updates the guide, preserves unrelated prose, and deletes only on explicit opt-out.
- [x] Claude Code and Codex projected hooks pass equivalent behavioural fixtures, and the packed plugin contains every required file.
- [x] The published `@windyroad/voice-tone` package is read back from npm and smoke-tested from a fresh install.

## Driving problem trace

P540 records that ordinary assistant responses have no durable project voice guide or bounded self-review surface.

## JTBD trace

JTBD-013 requires each opted-in response to follow project prose guidance without the user restating it.

## Implementation notes

Implement ADR-126 in the existing voice-and-tone plugin. Reuse native command hooks and the current Codex projection path; keep the retry ceiling explicit and the absent-guide path silent.

## Dependencies

- **Blocks**: project-specific voice and tone for ordinary assistant responses
- **Blocked by**: (none)

## Related

- ADR-126: Opt-in prose-guided assistant-response self-review.
