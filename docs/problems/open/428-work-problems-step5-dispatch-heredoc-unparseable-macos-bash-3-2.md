# Problem 428: work-problems Step 5 dispatch heredoc-in-command-substitution is unparseable under macOS /bin/bash 3.2

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#345)
**Effort**: S. WSJF = (9 × 1.0) / 1 = 9.0.
**WSJF**: 9 — (9 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

The `/wr-itil:work-problems` Step 5 iter-dispatch command embeds a heredoc inside a command substitution that macOS's stock `/bin/bash` 3.2 cannot parse. The launch fails silently (zero-byte prompt / no iter). `bash -n` on a 5.x bash gives false confidence because the construct parses there.

## Symptoms

- On macOS default bash 3.2, the Step 5 dispatch produces no iter (silent launch failure). Works on bash 5.x, masking the defect during development.

## Impact Assessment

- **Who is affected**: macOS adopters running AFK loops on the system bash.
- **Frequency**: every dispatch on bash 3.2.
- **Severity**: Medium — silent no-op; the loop appears to run but does nothing.

## Root Cause Analysis

### Investigation Tasks

- [ ] Write the iter prompt to a file and pass it via `$(cat "$FILE")` (or `--prompt-file`) rather than a heredoc in command substitution; add a bash-3.2 parse check to CI.

## Dependencies

- **Composes with**: P420 (bash-3.2 portability class — sibling, distinct script + fix; do not fold).

## Related

- Inbound issue #345.
