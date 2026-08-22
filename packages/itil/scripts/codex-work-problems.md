---
name: wr-itil:work-problems
description: Drain the ITIL problem backlog in WSJF order using native Codex subagents, governed commits, pushes, and releases.
---

# Work Problems in Codex

Continuously work the highest-priority actionable problem until the backlog is drained, the user stops, or a real governance dependency requires human direction. Use Codex's native subagent tools. Never invoke `codex exec`, start a nested Codex CLI, or implement process/PID polling.

## Preflight

1. If `docs/problems/` is absent, direct the user to `/wr-itil:scaffold-intake` and stop.
2. Run the installed ITIL maintenance commands required by the repository, including layout migration, README reconciliation, catch-up scanning, stale upstream-cache checks, and unresolved-response checks. Resolve them from the plugin's bundled `bin/`; do not use source-repository paths.
3. Preserve unrelated working-tree changes. Revert only changes created by a failed preflight.
4. If the task has a persistent Codex goal, keep it active until this drain reaches a genuine terminal state. A slow tool or subagent is not a blocker.

## Loop

1. Read the problem index and current ticket files. Select the highest WSJF problem in the highest non-empty actionable tier. Use the documented tie-break rules.
2. Skip tickets whose required JTBD, decision, risk, or story-map oversight is unconfirmed. Record one structured outstanding question for each genuinely user-answerable dependency; do not ask mid-loop.
3. Run the relevance and stop-condition checks. Before declaring `ALL_DONE`, run the repository's unconditional pre-completion gates and rescan the backlog.
4. Spawn one native Codex subagent for the selected ticket. Give it the exact checkout, ticket, applicable decisions, and this contract:
   - invoke `/wr-itil:manage-problem` for the ticket and follow its lifecycle rules;
   - make only in-scope changes and preserve unrelated work;
   - run focused tests and the required architecture/risk checks;
   - create the required changeset for shippable plugin behavior;
   - commit the completed iteration, but do not push or release;
   - return one `ITERATION_SUMMARY` JSON object containing ticket, action, commits, tests, risks, outstanding questions, and remaining work.
5. Wait for that same subagent. Do not cancel, replace, retry, or fan out merely because Cruise or normal model execution makes the call slow. When it completes, consume its summary and close it.
6. Validate the summary with `wr-itil-verify-iter-summary`. If the subagent failed after changing the checkout, inspect and safely complete or revert only its own partial work before continuing.
7. Run inter-iteration verification. If the iteration produced committed shippable work, complete the repository's governed push and release cadence when risk is within appetite. Above-appetite risk is a remediation instruction: reduce scope or split the change; never ask the user to approve risk above appetite.
8. Report only material progress, then rescan and repeat.

## Fix Proposal Rule

A fix proposal is a release row on an existing story map, never a new file under `docs/rfcs/`. The row has an identity from `wr-itil-next-rfc-id`, at least one story card, and a story whose `problems:` list names the driving problem. Creating a new map, activity column, job, or uncovered architectural choice requires a queued human decision rather than a silent edit.

## Questions and Stop Conditions

- Batch outstanding questions at loop end with `request_user_input`, no more than four per call. Brief substance before IDs.
- Continue past skipped tickets when another actionable ticket exists.
- Stop only for an explicit user stop, a fully drained backlog, a governance dependency that blocks every remaining ticket, or an unrecoverable tool/repository failure.
- Never describe a delayed native tool or subagent as unavailable, hung, or blocked without an actual error or terminal failure.

## Final Report

Report completed and skipped tickets, commits, tests, push/release outcomes, remaining backlog, and outstanding design questions. Preserve the distinction between committed, pushed, released, and production-verified states.
