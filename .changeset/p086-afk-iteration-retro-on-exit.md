---
"@windyroad/itil": minor
---

P086: AFK iteration subprocess now runs `/wr-retrospective:run-retro` before emitting `ITERATION_SUMMARY`

The AFK `/wr-itil:work-problems` iteration subprocess previously emitted `ITERATION_SUMMARY` and exited without running retro, discarding every per-iteration friction observation — hook TTL expiries, marker-vs-file deadlocks, repeat-workaround patterns, subagent-delegation friction, release-path instability. Across a 5-iteration AFK loop that's 20–50 tool-level observations the backlog never sees, degrading JTBD-006's "clear summary on return" outcome and JTBD-101's "new friction patterns become ticketable" promise.

`packages/itil/skills/work-problems/SKILL.md` Step 5 iteration prompt body gains a closing step (step 4) naming `/wr-retrospective:run-retro` before the `ITERATION_SUMMARY` emission step. Retro runs INSIDE the subprocess so its Step 2b pipeline-instability scan has access to the iteration's full tool-call history; retro commits its own work per ADR-014 (run-retro delegates ticket creation to `/wr-itil:manage-problem`); orchestrator picks up retro-created tickets on the next Step 1 scan naturally — no cross-process marker sharing required. Retro is non-blocking: if retro fails or surfaces findings, the iteration still emits `ITERATION_SUMMARY` so the AFK loop does not halt on a flaky retro run.

`docs/decisions/032-governance-skill-invocation-patterns.proposed.md` subprocess-boundary variant gains a matching "Retro-on-exit (P086 amendment)" clause under the Pattern contract block, parallel to how P084 amended P077 — the retro contract is the subprocess-boundary variant's closing-step invariant alongside spawn command, stdout parse shape, exit-code semantics, hook session-id isolation, post-subprocess state re-read, and orchestration boundary.

`packages/itil/skills/work-problems/test/work-problems-step-5-delegation.bats` gains four doc-lint contract assertions (P086): iteration prompt names `/wr-retrospective:run-retro`; retro ordered BEFORE `ITERATION_SUMMARY` emission; retro named as non-blocking closing step; ADR-014 cited for retro commit ownership.

Architect review PASS (no ADR invariant violated; amendment shape parallels P084→P077). JTBD review PASS (JTBD-006 + JTBD-101 primary alignment; JTBD-001 no-regression — retro runs inside subprocess, orchestrator main turn unaffected).
