# Problem 540: Assistant responses cannot opt into project voice-and-tone guidance

**Status**: Known Error
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

ADR-126 chooses an opt-in `docs/ASSISTANT-VOICE-AND-TONE.md` prose guide, native first-prompt injection, and one guarded same-assistant Stop continuation. RFC-094 and STORY-090 deliver that capability inside `@windyroad/voice-tone` without deterministic checks, profiles, an external evaluator, or a certification claim.

## Verification

- Absent-guide, injection, content-change, first-Stop, and retry-guard behaviour pass in both projected runtimes.
- The update skill creates and updates the guide while preserving unrelated prose and requiring explicit opt-out for deletion.
- The packed package contains the complete hooks and skill.
- The published package is read back from npm and smoke-tested from a fresh install.

## Dependencies

- **Blocks**: durable project-specific voice and tone for ordinary assistant responses
- **Blocked by**: (none)

## Related

- ADR-126: Opt-in prose-guided assistant-response self-review.
- P440 concerns the separate external-communications reviewer’s knowledge of project idiom and does not absorb this response-generation surface.
- Mandatory hang-off arbitration returned `PROCEED_NEW`: none of P440, P200, P038, P257, or P469 owns ordinary assistant response hooks or the assistant guide.

(captured via /wr-itil:capture-problem; expand at next investigation)


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-090 | STORY-090: Keep assistant responses in my chosen voice | accepted |
