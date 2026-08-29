---
status: in-progress
story-id: a-failed-reviewer-blocks-the-guarded-edit
reported: 2026-08-30
decision-makers: [Tom Howard]
problems: [P469]
jtbd: [JTBD-101]
rfcs: [RFC-079]
story-maps: [STORY-MAP-008]
estimated-effort: S
---

# STORY-073: A failed reviewer blocks the guarded edit

**Reported**: 2026-08-30
**Problems**: P469
**JTBD**: JTBD-101
**RFCs**: RFC-079
**Story Maps**: STORY-MAP-008
**Estimated effort**: S

## User value

In order to trust a plugin's review gate, as a plugin developer, I want a failed style or voice review to block the guarded edit even when the read-only reviewer cannot write a verdict file.

## Acceptance criteria

- [x] The style-guide and voice-tone reviewers remain read-only and do not instruct agents to write verdict marker files.
- [x] Each PostToolUse hook creates review, hash, and plan markers only when the first canonical verdict heading is PASS.
- [x] Canonical FAIL output, unknown output, missing output, and stale legacy verdict files do not unlock edits.
- [x] One behavioural regression check drives both real hooks and proves FAIL and PASS marker effects.

## Driving problem trace

P469 records that the style-guide and voice-tone reviewers cannot write the verdict files their PostToolUse hooks read, so the hooks take a backward-compatibility branch that incorrectly unlocks edits after FAIL.

## JTBD trace

JTBD-101 requires plugin developers to extend and maintain the suite through understandable, tested hook conventions that do not break existing plugins.

## Implementation notes

Reuse the canonical output parser already shipped in each plugin's `gate-helpers.sh`; do not grant shell access or add another back-channel.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P353 established the hook-owned marker pattern.
- P468 covers generated Codex runtime capability parity separately.
