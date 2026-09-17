---
status: proposed
date: 2026-09-17
human-oversight: confirmed
oversight-date: 2026-09-17
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-12-17
supersedes: [ADR-126]
jtbd: [JTBD-013, JTBD-101]
persona: developer
---

# Unmistakably guided complete replacement

## Context and Problem Statement

The released hook loaded the project guide, then asked the same assistant to review its response. Its instruction allowed silence when the assistant judged that no correction was needed.

A real Codex conversation exposed the failure: Codex displayed a generic first response, ran the Stop hook, and recorded an empty continuation as the final assistant output. Protocol-level tests passed while the user-visible outcome failed.

The replacement contract was tested before this decision was finalised. An isolated Codex home installed the packed `@windyroad/voice-tone@0.9.0` package and ran fresh, non-interactive Codex conversations against two guides.

- The released conditional-review prompt produced an empty final output.
- A prompt that always required a complete replacement passed three of three trials that required a visible marker. It also passed three of three trials that asked for a creative voice. The creative responses were still mostly generic.
- A prompt that also required the requested voice to be unmistakable initially exposed a shell-quoting error caused by an apostrophe in the candidate text.
- After that wording was corrected, it produced non-empty, visibly guided output in three of three conversational trials and three of three technical trials.

These trials show that a complete replacement prevents the observed empty result, while the stronger instruction makes expressive prose guidance materially visible. They do not prove that a language model will comply on every response.

## Decision Drivers

- An opted-in response must not end with an empty review continuation.
- Guidance remains prose-only, with no deterministic style checks.
- Review remains bounded to one extra model turn.
- File existence remains the only activation switch.
- Release evidence must inspect a real Codex conversation's final output.
- The chosen prompt must have passed the installed-runtime experiment before ratification.

## Considered Options

1. **Emit one unmistakably guided complete replacement (chosen).** The continuation preserves the response's meaning, rewrites it in full, and makes the voice requested by the guide unmistakable rather than merely acceptable.
2. **Keep conditional replacement.** Preserve the released instruction that permits silence when the assistant accepts its original response.
3. **Remove the Stop review.** Inject the guide only and remove the correction opportunity.

## Decision Outcome

Chosen option: **"Emit one unmistakably guided complete replacement"**, because it was the only tested wording that both prevented an empty final output and made the creative guide visibly affect the response.

The prompt-start hook still only tells the assistant that the guide exists. The response-review hook still does nothing when there is no guide, no assistant response to review, or a review is already running. In all other cases, it blocks once. It then tells the same assistant to preserve the previous response's meaning and write one complete replacement. The replacement must make the voice requested by the guide unmistakable rather than merely acceptable. It must not be empty, include a verdict or review commentary, or claim certification.

The continuation remains the second and final model turn. It is semantic self-review, not independent assurance. A runtime may display the first response before the replacement.

## Consequences

### Good

- The review continuation has a clear user-visible output contract.
- The selected wording has installed-runtime evidence across conversational and technical prompts.
- The fix preserves prose-only guidance, file-existence opt-in, and the one-turn ceiling.
- A real Codex journey detects the failure that protocol-only tests missed.

### Neutral

- Every opted-in response uses one replacement continuation.
- The first response may still appear briefly before the replacement.
- The same assistant still judges and rewrites its own work.

### Bad

- The extra continuation always consumes latency and tokens.
- Model compliance remains probabilistic.
- Subjective guidance can still be applied inconsistently.
- More forceful creative guidance can become exaggerated; the guide must still describe the desired limits.

## Confirmation

- A hook test fails if the Stop reason permits silence or does not require one complete replacement.
- Existing tests continue to prove absent-guide silence and the one-turn guard.
- A packed-plugin Codex journey uses a guide requiring an observable marker.
- The journey asserts that the final assistant output is non-empty and contains that marker.
- A second journey uses expressive prose guidance and confirms that the final response visibly applies it without losing the original meaning.
- Hook projection or shell output alone is insufficient release evidence.
- Documentation states the replacement and first-response visibility behaviour.

## Pros and Cons of the Options

### Emit one unmistakably guided complete replacement

- Good: closes the empty-final-response failure and visibly applies the guide without another evaluator or retry loop.
- Bad: always pays for the second response, can overstate creative traits, and still depends on model compliance.

### Keep conditional replacement

- Good: permits a silent pass when the original response appears acceptable.
- Bad: repeats the observed failure and cannot distinguish a valid pass from an empty result.

### Remove the Stop review

- Good: removes the second-turn cost and empty-continuation path.
- Bad: removes the same-turn correction opportunity.

## Reassessment Criteria

Reassess by 2026-12-17, or sooner if runtimes can replace responses before display, journeys show repeated failures, continuation cost outweighs quality, or users require independent assurance.

## Related

- Supersedes architecture decision record `ADR-126` in full.
- Problem `P540` records the realised failure.
- Risk `R098` records protocol-success with user-visible response failure.
- Jobs To Be Done `JTBD-013` and `JTBD-101` cover response alignment and installed-plugin verification.
