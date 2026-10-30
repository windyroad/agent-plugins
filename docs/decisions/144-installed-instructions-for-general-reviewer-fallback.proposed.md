---
status: proposed
date: 2026-10-30
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2027-01-30
---

# Installed instructions for general reviewer fallback

## Context and Problem Statement

A hosted agent can run independent general subagents while its delegation tool
cannot select an installed named reviewer. Requiring that selector prevents
reviews and delivery even though the reviewer instructions remain installed.
Tom directed the plugins to fall back to a general reviewer with the specific
reviewer's instructions when the named reviewer is unavailable.

## Decision Drivers

- Keep independent governance reviews available on the actual runtime.
- Preserve the complete installed reviewer contract, including runtime-specific instructions.
- Retain existing verdict, source, policy, action and completion checks.
- Avoid requiring a local delivery handoff or repeated environment setup.

## Considered Options

1. **Instruction-backed general reviewer fallback (chosen).** Prefer named
   reviewers; use an independent general reviewer with the full installed
   instructions and original request when named selection is unavailable.
2. **Named reviewers only.** Keep delivery blocked until the hosted runtime
   supports the selector, even when independent review remains possible.

## Decision Outcome

Choose instruction-backed fallback. The plugin identifies the requested role
from an explicit fallback prompt containing the complete installed instructions,
compares them with its own canonical source, and associates that dispatch with
the actual returned child and spawning parent. A label or self-description alone
does not establish reviewer identity. Runtime-specific reviewer additions are
part of the instructions, not optional caller knowledge.

General reviewers receive a fresh context, the original task and the same
read-only review scope. Fallback addresses unavailable dispatch, not a failed
assessment. A substantive failure still requires remediation and review.

Receipt-bearing plugins retain their existing source, checkout, policy, draft,
action, expiry and single-consumption checks. The fallback uses the existing
registered completion route and verifies that its installed instructions have
not changed before accepting or consuming completion. Named review paths remain
available. Missing instructions or completion evidence cannot become a pass.

## Consequences

### Good

- Independent review can continue without a named-agent selector.
- The installed reviewer contract remains the source of review instructions.
- Existing verdict and action checks remain applicable to both dispatch paths.

### Neutral

- Named and general dispatch can produce the same review verdict contract.
- The fallback prompt is larger because it includes the full instructions.

### Bad

- Instruction-backed identity requires prompt visibility at registration.
- A runtime exposing neither registration nor completion evidence still cannot
  satisfy receipt-bearing gates; prose claims are insufficient.

## Confirmation

Actual installed use completes an independent general review when named selection
is unavailable and its normal completion handling qualifies the assessed action.
Incorrect or missing instructions, unrelated child completion, changed source or
policy, stale evidence and duplicate completion remain unable to qualify actions.
Publication and synthetic tests alone do not establish actual hosted use.

## Pros and Cons of the Options

### Instruction-backed general reviewer fallback

- Good because it preserves review availability and the installed contract.
- Bad because registration must inspect the supplied instructions.

### Named reviewers only

- Good because identity comes directly from the native selector.
- Bad because it prevents available independent review on hosted runtimes.

## Reassessment Criteria

Reassess when runtimes provide a supported named-reviewer selector everywhere,
or when dispatch/completion visibility changes so instruction-backed registration
can no longer establish the reviewed contract.
