# Problem 232: bash until-loop with `pgrep -f 'bats --recursive'` self-references the polling loop's own command line — new variant of P146 stuck-before-emit deadlock; SKILL.md prompt warning insufficient

**Status**: Open
**Reported**: 2026-05-16
**Priority**: 9 (Med) — Impact: 3 (Moderate — iter wastes 30–60 min wall-clock + $20–30 in subscription cost; ITERATION_SUMMARY metadata lost per P147 stuck-before-emit; retro commit lost; requires manual SIGTERM) × Likelihood: 3 (Likely — recurred during P132 Phase 2a-iii-B iter despite explicit SKILL.md prompt warning against the antipattern class)
**Effort**: M (deferred — re-rate at next `/wr-itil:review-problems`)
**WSJF**: (9 × 1.0) / 2 = **4.5** (deferred — provisional)
**Type**: technical

> Sibling to [[P146]] (parent class — bash until-loop polls bats output with bats-console-summary regex against TAP-format output). P146 fix shipped as SKILL.md prompt warning at `/wr-itil:work-problems` Step 5 iteration prompt body. THIS variant proves the warning is insufficient under agent autonomy. Captured 2026-05-16 from observed deadlock in `/wr-itil:work-problems` AFK loop iter 4 P132 Phase 2a-iii-B.

## Description

Iter 4 (P132 Phase 2a-iii-B) committed main work cleanly at 58 min wall-clock (`da1a3fe` — create-adr Step 2 retrofitted as 4th derive-first dispatch adopter), then deadlocked in retro phase. Diagnosis at SIGTERM revealed 4 zsh polling loops, each of shape:

```bash
until ! pgrep -f 'bats --recursive' > /dev/null 2>&1; do sleep 5; done; echo "done"
```

(Plus variants with `tail -30 <output_file>` after the polling loop and `wc -l` after.)

**Self-referential pgrep deadlock**: `pgrep -f` matches against the FULL command line of every running process. The polling loop's own zsh `-c` command-line ARGUMENT contains the literal string `pgrep -f 'bats --recursive'`. So when 4 such polling loops are running concurrently, each loop's `pgrep -f 'bats --recursive'` matches the OTHER 3 loops (and itself). Each loop concludes "bats --recursive is still running" and sleeps + repeats. Infinite spin.

Confirmed empirically at SIGTERM (2026-05-16):

```
$ pgrep -f 'bats --recursive'
4324    <- polling loop 1
15867   <- polling loop 2  
19465   <- polling loop 3
67939   <- polling loop 4
```

No actual `bats --recursive` process running. All 4 matches were the polling loops themselves.

P146 captured "bash until-loop polls bats output with bats-console-summary regex against TAP-format output" — the symptom-shape was "stuck after backgrounded bats completes because the regex doesn't match TAP output". P232 captures a DIFFERENT symptom-shape: stuck because the pgrep pattern matches the polling loop itself, regardless of whether any bats actually ran. Same broader class (bash until-loop deadlock for backgrounded subprocess completion detection) but different mechanism.

## Symptoms

- Iter 4 (2026-05-16) committed at 58 min, then idle until manual SIGTERM at 103 min (45 min stuck).
- `pgrep -f 'bats --recursive'` returns the polling loop PIDs themselves; no actual bats running.
- Exit 143 + 0-byte JSON per P147 stuck-before-emit subclass.
- ITERATION_SUMMARY lost (retro never completed).

## Workaround

Manual SIGTERM. Wall-clock + cost already spent; metadata reconstructed from `git log` + `git status --porcelain` per P147 contract.

## Impact Assessment

- **Who is affected**: any AFK iter that uses `pgrep -f '<pattern>'` to poll for completion of a backgrounded subprocess where the pattern contains a string that appears in the polling loop's own command line.
- **Frequency**: 1 recurrence in 4 iters this session despite explicit SKILL.md prompt warning. Likelihood will not drop without structural enforcement.
- **Severity**: 30–60 min wall-clock + $20–30 wasted cost per recurrence; retro metadata loss.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm the self-referential `pgrep -f` deadlock pattern in a behavioural bats fixture
- [ ] Audit the SKILL.md prompt warnings — do they explicitly cite the self-reference failure mode, or only the TAP-vs-console-summary failure mode? (Empirically the prompt warns about TAP-vs-console but not self-reference.)
- [ ] Decide structural enforcement shape (see Fix Strategy)

## Fix Strategy

Three options enumerated:

**Option A — prompt-discipline extension (low-effort)**: extend `/wr-itil:work-problems` SKILL.md Step 5 iteration prompt body to explicitly cite both failure modes (TAP-vs-console-summary AND self-referential pgrep) with worked-example commands. Lowest-friction; closes the immediate prompt-blindness gap.

**Option B — Bash-tool PreToolUse hook (medium-effort)**: detect bash command lines matching `until ! pgrep -f` (or `while pgrep -f` / `pkill -0` polling patterns) and refuse them at the PreToolUse layer, advising `wait $bg_pid` or `BashOutput` polling instead. Structural enforcement; closes the antipattern class regardless of agent autonomy. Composes with the existing hook surface.

**Option C — Stop-hook scanner (highest-effort)**: on iter Stop event, scan the session's tool-call history for `until ! pgrep` / `while pgrep` patterns and emit a deviation-candidate at session-wrap so the user reviews the recurrence. Detection without prevention; useful for visibility but doesn't stop the wall-clock waste in-iter.

**Preferred**: Option B (PreToolUse hook). Highest structural value; SKILL.md prompt warnings have empirically failed.

## Dependencies

- **Composes with**: [[P146]] (parent class — bash until-loop deadlock on bats completion polling)
- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- [[P146]] — parent class; TAP-vs-console-summary variant. P146 may need re-opening if this fix supersedes its scope.
- [[P147]] — stuck-before-emit subclass. P232 is a new recurrence at the stuck-before-emit boundary.
- [[P083]] — iteration worker prompt forbids ScheduleWakeup. Same prompt-discipline class; demonstrates prompt-level enforcement has precedent.

## Change Log

- **2026-05-16** — Captured by `/wr-itil:work-problems` orchestrator main-turn post-SIGTERM wrap, per user direction "Yes — capture as new ticket" to AskUserQuestion batch after iter 4 deadlock recovery. Iter 4 (P132 Phase 2a-iii-B) was the recurrence — main commit `da1a3fe` landed intact; retro lost; SIGTERM at 103 min.
