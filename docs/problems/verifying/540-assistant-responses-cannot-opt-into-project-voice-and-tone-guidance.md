# Problem 540: Assistant responses cannot opt into project voice-and-tone guidance

**Status**: Verification Pending
**Reported**: 2026-09-17
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from a missing capability affecting every ordinary response when a project needs a consistent voice
**Origin**: internal (user-requested capability)
**Effort**: M — one existing plugin, two bounded hooks, one guide-management skill, cross-runtime projection, tests, and release verification
**JTBD**: JTBD-013
**Persona**: developer

## Description

The voice-and-tone plugin can guide project-authored copy and review external communications, but it cannot govern the ordinary responses produced by Claude Code or Codex. A user must restate response guidance manually, and a completed response receives no bounded semantic self-review against project-specific prose.

The missing surface prevents projects from opting into plain-language or controlled-English guidance, a creative voice, or another prose-defined response style through one durable project file.

## Symptoms

- Ordinary assistant responses do not read a project response-voice guide.
- Users must repeat voice-and-tone instructions in prompts.
- A response that drifts has no single bounded correction opportunity before the turn stops.
- The existing `docs/VOICE-AND-TONE.md` contract cannot be reused without conflating authored project copy with assistant conversation.

## Workaround

Repeat the desired response voice in the current prompt or in existing project instructions. This can influence a response, but it does not provide the dedicated opt-in guide or bounded Stop-hook self-review.

## Impact Assessment

- **Who is affected**: developers who need assistant conversation to follow project-specific language or voice guidance
- **Frequency**: every ordinary response in an opted-in project
- **Severity**: High — repeated prompting and inconsistent responses undermine the durable project convention
- **Analytics**: capability gap identified directly by the user; adoption remains to be measured after release

## Root Cause Analysis

### Investigation Tasks

- [x] Confirm native Claude Code and Codex command hooks expose the latest assistant message and a retry guard.
- [x] Separate assistant-response guidance from the existing project-copy guide.
- [x] Decide whether guidance is prose or a deterministic standards registry.
- [x] Bound semantic self-review to one continuation.
- [x] Ratify the architecture before implementation.

### Confirmed root cause

The plugin has no assistant-response policy file, prompt-injection path, Stop-hook review path, or guide-management skill. Its current surfaces intentionally stop at authored copy and external communications.

## Fix Strategy

ADR-127 supersedes ADR-126 after installed-runtime experiments reproduced an empty final continuation. It retains the opt-in `docs/ASSISTANT-VOICE-AND-TONE.md` prose guide and native first-prompt injection, but requires the guarded Stop continuation to emit one complete replacement and make the requested voice unmistakable. RFC-094 and STORY-090 deliver that capability inside `@windyroad/voice-tone` without deterministic style checks, profiles, an external evaluator, or a certification claim.

**Release vehicle**: `.changeset/fix-voice-tone-final-response.md`

## Verification

- Absent-guide, injection, content-change, first-Stop, and retry-guard behaviour pass in both projected runtimes.
- The update skill creates and updates the guide while preserving unrelated prose and requiring explicit opt-out for deletion.
- The packed package contains the complete hooks and skill.
- A packed-plugin Codex journey proves that the final assistant output is non-empty and applies an observable guide instruction.
- The published package is read back from npm and smoke-tested from a fresh install.

## Fix Released

Released in `@windyroad/voice-tone@0.9.0` (version-packages commit `cbad761398cf243f097f98ba0aed60227cf6f3ac`, PR #482, merge commit `130b41475a723b020ea2f2db6b84ae4f68a81699`, released 2026-09-17).

The release adds the opt-in assistant-response guide, bounded same-assistant semantic self-review, and guided create/update skill across the Claude Code and Codex package surfaces.

Observed in the releasing session: npm `latest` resolved to `0.9.0`, and a fresh registry install passed package-content, projected-hook, guide-injection, and Stop-decision smoke checks. Awaiting adopter verification in an ordinary interactive session.

That adopter verification failed: the released conditional Stop instruction allowed silence when the assistant considered its first response acceptable. Codex displayed a generic first response, then recorded an empty continuation as the final output. Protocol checks had verified hook output, not the user-visible result. ADR-127 records the replacement contract selected by installed-runtime experiments; release verification now includes the actual final Codex response.

## Dependencies

- **Blocks**: durable project-specific voice and tone for ordinary assistant responses
- **Blocked by**: (none)

## Related

- ADR-127: Unmistakably guided complete replacement (supersedes ADR-126).
- P440 concerns the separate external-communications reviewer’s knowledge of project idiom and does not absorb this response-generation surface.
- Mandatory hang-off arbitration returned `PROCEED_NEW`: none of P440, P200, P038, P257, or P469 owns ordinary assistant response hooks or the assistant guide.

(captured via /wr-itil:capture-problem; expand at next investigation)


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-090 | STORY-090: Keep assistant responses in my chosen voice | accepted |
