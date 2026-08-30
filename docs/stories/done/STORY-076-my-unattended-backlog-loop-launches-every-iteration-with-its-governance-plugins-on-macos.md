---
status: done
story-id: my-unattended-backlog-loop-launches-every-iteration-with-its-governance-plugins-on-macos
reported: 2026-08-30
decision-makers: [Tom Howard]
problems: [P428]
jtbd: [JTBD-006]
rfcs: [RFC-082]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-076: My unattended backlog loop launches every iteration with its governance plugins on macOS

**Reported**: 2026-08-30
**Problems**: P428
**JTBD**: JTBD-006
**RFCs**: RFC-082
**Story Maps**: STORY-MAP-011
**Estimated effort**: S

## User value

In order to keep unattended backlog work moving safely on a Mac, as a plugin developer running the AFK loop, I want every iteration to launch with its full prompt and governance plugins using macOS's system Bash.

## Acceptance criteria

- [x] The shipped Step 5 dispatch snippet parses and runs under macOS `/bin/bash` 3.2.57.
- [x] The iteration subprocess receives the complete prompt text without a heredoc nested in command substitution.
- [x] Every resolver-emitted `--plugin-dir` pair reaches the iteration subprocess without `mapfile` or `readarray`.

## Driving problem trace

P428 records that the shipped `/wr-itil:work-problems` Step 5 dispatch cannot be parsed by macOS Bash 3.2 and depends on the Bash 4-only `mapfile` builtin, so the unattended loop cannot launch an iteration with its governance plugins.

## JTBD trace

JTBD-006 asks a plugin developer to keep backlog maintenance running while they are away. A portable iteration dispatch lets the loop start each governed unit of work on the supported macOS shell without supervision.

## Implementation notes

Keep the change inside the shipped Step 5 command shape and cover the extracted command behaviour under `/bin/bash` 3.2.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- [P428](../../problems/verifying/428-work-problems-step5-dispatch-heredoc-unparseable-macos-bash-3-2.md)
- [JTBD-006: Work Backlog AFK](../../jtbd/developer/JTBD-006-work-backlog-afk.proposed.md)
