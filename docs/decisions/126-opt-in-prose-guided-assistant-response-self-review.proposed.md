---
status: proposed
date: 2026-09-17
human-oversight: confirmed
oversight-date: 2026-09-17
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-12-17
jtbd: [JTBD-013, JTBD-003, JTBD-101]
persona: developer
---

# Opt-in prose-guided assistant-response self-review

## Context and Problem Statement

The voice-and-tone plugin currently governs authored project copy and external communications. It does not govern the ordinary responses produced by an AI coding assistant.

Projects need an optional way to describe how assistant responses should sound and read. The guidance may refer to a writing standard, such as ISO 24495-1:2023 for plain language or ASD-STE100 for Simplified Technical English, or it may describe a creative voice in prose. A named standard is not enough by itself, and model review cannot certify compliance with a standard.

Claude Code and Codex command hooks can inspect the latest assistant message when a turn is about to stop. A Stop hook can ask the same assistant to continue once with a corrected complete response. The first response may already be visible before the correction appears.

## Decision Drivers

- File existence must be the only opt-in switch.
- Guidance must remain expressive prose rather than a fixed profile or rules registry.
- The language model must assess meaning and style; deterministic checks are out of scope.
- Review must add no more than one model continuation per response.
- Projects without the guide must receive no hook output or extra model turn.
- Runtime limitations and first-response visibility must be stated honestly.
- The capability belongs in the existing voice-and-tone plugin.
- One guided skill must create and update the response guide.

## Considered Options

1. **Inject prose guidance and allow one semantic self-review continuation (chosen).** The same assistant receives the guide, reviews its completed response, and may replace it once.
2. **Inject prose guidance without a Stop review.** This is cheaper and simpler, but cannot correct a response that drifts after receiving the guidance.
3. **Use an independent external evaluator.** This separates author and reviewer, but adds another runtime, more configuration, and an avoidable dependency.

## Decision Outcome

Chosen option: **"Inject prose guidance and allow one semantic self-review continuation"**.

### Guide contract

`docs/ASSISTANT-VOICE-AND-TONE.md` is both the sole activation signal and the source of guidance. When the file is absent, the feature is silent and does not request another model turn.

The first version defines no profiles, enablement keys, enforcement levels, standards registry, or required frontmatter. The body is prose. A future setting needs a separate demonstrated use case and decision.

Projects may describe the relevant standard requirements in prose. If they only name a standard, the model may use information about that standard already present in its context or training, but the feature does not fetch, verify, or certify the standard text. The feature may claim alignment with that guidance, not certification. This guide remains separate from `docs/VOICE-AND-TONE.md`, which governs project-authored copy and external communications.

### Runtime behaviour

On the first user prompt in a session, a `UserPromptSubmit` hook injects the complete assistant guide. It injects the guide again only when its substantive content changes.

At the end of a response, a command-based `Stop` hook behaves as follows:

- If the guide is absent, it exits silently.
- If `stop_hook_active` is false, it blocks the stop once and tells the same main assistant to read the guide, assess its latest response semantically, and emit a complete corrected final response only when correction is needed.
- If `stop_hook_active` is true, it exits silently. There is no second retry.

The continuation is the second and final model turn. The hook does not start a nested assistant, call a Model Context Protocol (MCP) service, or require a custom reviewer. Supported Claude Code and Codex command-hook runtimes use the same contract. This decision makes no claim about ordinary web ChatGPT conversations, which do not expose these project hooks. A runtime may display the first response before the corrected response.

### Guide-management skill

`/wr-voice-tone:update-assistant-guide` creates or updates `docs/ASSISTANT-VOICE-AND-TONE.md`. It preserves unrelated prose, confirms replacement or removal of conflicting guidance, and never deletes the file unless the user explicitly opts out.

## Consequences

### Good

- One prose file supports both standards-based and creative guidance.
- The same language model can assess nuanced language without a deterministic rule engine.
- The retry guard places a hard ceiling on extra work.
- Existing projects remain unaffected until they add the file.

### Neutral

- Opted-in responses use one additional model continuation, with corresponding latency and token cost.
- The authoring model also performs the review; this is useful self-correction, not independent assurance.
- The first response can remain visible in runtimes that render it before the Stop hook completes.

### Bad

- Semantic self-review can miss or inconsistently apply guidance.
- Long guides consume context when injected.
- A corrected response may appear after an already-visible first response.

## Confirmation

- Behavioural tests prove that an absent guide produces no injection, Stop output, or continuation.
- Behavioural tests prove first-prompt injection, no unchanged repeat injection, and reinjection after a substantive guide change.
- Behavioural tests prove the first Stop may request one self-review and `stop_hook_active: true` cannot request another.
- Tests prove the implementation contains no deterministic response parser, nested assistant invocation, MCP evaluator, or independent reviewer.
- Skill tests cover create, update, unrelated-prose preservation, conflict confirmation, and explicit-only deletion.
- Claude Code and Codex hook fixtures exercise the same behaviour planned by this decision.
- The packed plugin contains the guide-management skill, hook commands, and supporting files.
- User documentation states opt-in behaviour, token and latency cost, first-response visibility, supported runtimes, and the alignment-not-certification boundary.
- The governed release is pushed, published, read back from the package registry, and smoke-tested from a fresh install.

Requested action: ratify Option 1 as written, choose another option, propose amendments, or reject the decision.

## Pros and Cons of the Options

### Prose guidance with one semantic self-review continuation

- Good, because it combines expressive guidance with one bounded correction opportunity.
- Bad, because it costs an extra model turn and is not independent assurance.

### Guidance injection only

- Good, because it has no review continuation cost.
- Bad, because drift cannot be corrected within the same response cycle.

### Independent external evaluator

- Good, because review is separate from authorship.
- Bad, because it introduces another runtime and configuration surface for a capability the main assistant can perform.

## Reassessment Criteria

Reassess no later than 2026-12-17, or sooner if:

- supported hook runtimes no longer expose the latest assistant message or a retry guard;
- measured self-review quality does not justify its latency and token cost;
- users need independently assured or certified conformance; or
- one guide becomes too large to inject safely.

## Related

- Architecture decision record `ADR-028` — plugin hook registration.
- Architecture decision record `ADR-038` — voice-and-tone guide injection.
- Architecture decision record `ADR-045` — bounded hook behaviour.
- Architecture decision record `ADR-083` — Codex-compatible plugin surfaces.
- Architecture decision record `ADR-094` — shared runtime-neutral governance.
- Jobs To Be Done record `JTBD-013` — keep assistant responses in my chosen voice.
- Jobs To Be Done record `JTBD-003` — maintain consistent voice and tone.
- Jobs To Be Done record `JTBD-101` — extend the suite with new plugins.
