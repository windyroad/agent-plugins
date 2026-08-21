# Problem 517: An iteration can burn its whole budget in the commit gate and lose everything, because the commit is the last step

**Status**: Open
**Reported**: 2026-08-21
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture. Impact 3: the work itself survives (staged files are durable, and the salvage path recovered all of it), but the iteration's budget, its metadata and the loop's throughput are lost, and recovery needs a human to notice and dispatch a salvage session. Nothing ships wrong and no adopter is affected, which is what holds it below 4. Likelihood 3: fires on slices that touch several prose surfaces at once; one witness so far, and the round count is not predictable in advance — honest field risk, not inflated to lift rank (ADR-076).
**Origin**: internal
**Effort**: M — the fix is not obvious. Candidate shapes range from bounding or batching the gate rounds, to committing earlier and amending, to checkpointing the iteration's work before the gate. Each touches `/wr-itil:work-problems` Step 5 dispatch and possibly the ADR-014 single-commit grain, so it needs a decision before it needs code. Sized level with P451, which reworks the same dispatch surface.
**WSJF**: 4.5 — (9 × 1.0) / 2
**JTBD**: JTBD-006
**Persona**: developer

## Description

An AFK iteration can spend its entire budget inside the ADR-014 commit gate and lose everything, because the commit is the last step and the gate rounds are unbounded and non-independent.

Witnessed 2026-08-21. The iteration working P508 finished all of its work — 23 files staged, 57/57 bats green, a well-written changeset — and was SIGTERMed at the 60-minute idle threshold with zero commits (exit 143, 0-byte JSON, no `ITERATION_SUMMARY`, no retro). The salvage session then paid the same gate from scratch and needed **4 architect rounds, 3 jtbd rounds and 3 risk-scorer rounds** to land the identical work.

The rounds are not independent, and that is the part that makes the cost unpredictable. Each remediation pass edits files, which re-fires the gates and surfaces drift the previous round could not see. Concretely: repointing one step of `capture-rfc`'s SKILL made a contradiction three lines away newly visible, and only the third architect round found it. So gate cost scales with how many prose surfaces a slice touches, is not knowable when the iteration is dispatched, and is paid entirely **after** the work is already done — at the point where an idle-timeout SIGTERM costs the most.

## Symptoms

- An iteration reaches `exit 143` + 0-byte JSON with a coherent, complete, staged working tree and zero commits.
- The gate rounds visibly compound: a fix applied to satisfy one reviewer round exposes a finding the same reviewer could not have raised on the prior round.
- The salvage session's gate cost approximates the dead iteration's — so the loop pays for the same gate twice and lands the work once.

## Workaround

Salvage it. `/wr-itil:work-problems` already routes exit-143 + 0-byte JSON to a main-turn salvage per the P307 / P261 precedent, and that worked here: verify via bats, then commit from a fresh session through a clean gate pass (never reusing the dead subprocess's markers, per ADR-009). The workaround recovers the code but not the iteration's retro, which is gone permanently.

## Impact Assessment

- **Who is affected**: the maintainer running `/wr-itil:work-problems` AFK, and any adopter running the same loop.
- **Frequency**: once observed (2026-08-21, P508). Expected on slices that repoint prose across several SKILL surfaces at once; rare on single-file fixes.
- **Severity**: one iteration's budget plus its metadata, and the loop stalls until someone notices. The staged work survives.
- **Analytics**: not instrumented. The gate-round count per iteration is not currently recorded anywhere — `ITERATION_SUMMARY` has no field for it, and the iteration that would have reported it is precisely the one that dies. Instrumenting it is likely a prerequisite for sizing the fix.

## Root Cause Analysis

Preliminary hypothesis, not yet confirmed: the ADR-014 commit gate sits at the end of the iteration, its round count is a function of how much prose the slice touches, and nothing bounds or forecasts it. The iteration therefore commits nothing until it has already spent whatever the gate demanded, and an idle-timeout SIGTERM at that moment discards the whole run.

The compounding property is what distinguishes this from ordinary gate latency. A reviewer's Nth round can only see the tree as the (N-1)th round left it, so a slice that repoints several interdependent prose surfaces generates findings serially rather than all at once. That makes the total unpredictable from the dispatch side, which is where the timeout is configured.

### Investigation Tasks

- [ ] Confirm the hypothesis against the dead iteration's cost/timing rather than the salvage session's. Note the obstacle: the iteration's own metadata is gone, so this may only be reconstructable from the Anthropic billing dashboard per the P147 metadata-loss handling shape.
- [ ] Instrument the gate-round count per iteration — likely an `ITERATION_SUMMARY` field — so the frequency estimate above rests on data rather than one witness.
- [ ] Decide the fix shape before building it. At least three are live and they are not equivalent: bound or batch the gate rounds; commit earlier and amend; or checkpoint the staged work before entering the gate. This is a genuine ≥2-option decision, so it wants a recorded decision before implementation (ADR-074).
- [ ] Check whether the compounding is reducible by front-loading — P424 found that pre-empting known blockers in the FIRST reviewer prompt converged the substance in far fewer rounds. If that generalises, the cheap fix is prompt discipline rather than dispatch rework.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P451, P147, P370 — see Related for how each differs.

## Related

Captured via `/wr-itil:capture-problem` during the P508 salvage retro. Hang-off arbitration was **not** dispatched: the mechanical pre-filter matched 51 candidates on the `ADR-014` signal, exceeding the 5-candidate cap, so per the sub-step 2b latency short-circuit the candidate set is recorded here for review-time re-evaluation at `/wr-itil:review-problems` rather than arbitrated at capture. The signal is low-value in this case — `ADR-014` appears in roughly every ticket that ends in a commit.

Deliberately distinguished from three near neighbours that share the exit-143 signature or the lost-work shape:

- **P451** (`docs/problems/open/451-work-problems-dispatch-exceeds-interactive-harness-10min-foreground-bash-ceiling.md`) — same `SIGTERM` + 0-byte JSON signature, **different mechanism**: the interactive harness's 10-minute foreground Bash ceiling, which fires regardless of what the iteration is doing. This ticket is about the 60-minute idle threshold being reached because the gate consumed the time. The two compose — an iteration slow in the gate is also a candidate for P451's ceiling — but the fixes are unrelated.
- **P370** (`docs/problems/verifying/370-iter-subprocess-ends-turn-waiting-on-background-task-no-auto-resume-lost-work.md`) — lost commit-bearing work, but via an unreaped background task at turn end. No background task was implicated here; the iteration appears to have been working, not waiting.
- **P147** (`docs/problems/closed/147-p121-sigterm-clean-flush-guarantee-conditional-needs-skill-md-caveat-for-stuck-before-emit-subclass.md`) — the **handling** shape for exactly this event, and it worked correctly: the orchestrator observed exit 143 + 0-byte JSON, did not silently continue, and routed the staged tree to a salvage session with git evidence. This is P147's first live exercise, ~3.5 months after it closed. P147 is not the defect; it is what made the recovery possible.

Duplicate-check matched five tickets carrying `commit-gate` in the filename — P036, P090, P415, P035, P408. None is this problem: they cover subagent instructions, marker TTL expiry, multi-`-m` message review, delegation fallback, and staleness cadence respectively. Listed here so the next `/wr-itil:review-problems` pass can confirm rather than re-derive.

- **ADR-014** — the single-commit-per-batch grain whose gate this ticket is about.
- **ADR-009** — never reuse a dead subprocess's gate markers; why the salvage ran the gate fresh rather than inheriting.
- **P508** (`docs/problems/known-error/508-fix-proposal-still-instantiates-a-standalone-rfc-doc-after-adr-103-made-it-a-release-row.md`) — the ticket the dead iteration was working. Its slice A landed via the salvage; the gate cost recorded above is that salvage's.
- **P424** — the front-loaded-reviewer-prompt witness that may make this cheap to mitigate.
