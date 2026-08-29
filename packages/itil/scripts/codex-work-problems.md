---
name: wr-itil:work-problems
description: Drain the ITIL problem backlog in WSJF order using isolated Codex CLI iterations, governed commits, pushes, and releases.
---

# Work Problems in Codex

Continuously work the highest-priority actionable problem until the backlog is drained, the user stops, or a real governance dependency requires human direction. Run each selected problem in one fresh `codex exec` process and consume its structured result before continuing.

## Preflight

1. If `docs/problems/` is absent, direct the user to `/wr-itil:scaffold-intake` and stop.
2. Run the installed ITIL maintenance commands required by the repository, including layout migration, README reconciliation, catch-up scanning, stale upstream-cache checks, and unresolved-response checks. Resolve them from the plugin's bundled `bin/`; do not use source-repository paths.
3. Resolve the exact checkout with `git rev-parse --show-toplevel`. Preserve unrelated working-tree changes and record the pre-iteration status. Revert only paths proven to have been created by a failed iteration.
4. If the task has a persistent Codex goal, keep it active until this drain reaches a genuine terminal state. A slow process is not a blocker.

## Loop

1. Read the problem index and current ticket files. Select the highest WSJF problem in the highest non-empty actionable tier. Use the documented tie-break rules.
2. Skip tickets whose required JTBD, decision, risk, or story-map oversight is unconfirmed. Record one structured outstanding question for each genuinely user-answerable dependency; do not ask mid-loop.
3. Run the relevance and stop-condition checks. Before declaring `ALL_DONE`, run the repository's unconditional pre-completion gates and rescan the backlog.
4. Dispatch exactly the selected ticket through the isolated Codex command below. Do not select or work a second ticket inside that process.
5. Wait for that same process. Do not cancel, replace, retry, or fan out merely because normal model execution is slow.
6. Classify the exit and JSONL metadata before reading the final-output file. On success, validate the summary with `wr-itil-verify-iter-summary` and consume it. On failure, apply the recovery contract below and halt.
7. Run inter-iteration verification. If the iteration produced committed shippable work, complete the repository's governed push and release cadence when risk is within appetite. Above-appetite risk is a remediation instruction: reduce scope or split the change; never ask the user to approve risk above appetite.
8. Report only material progress, then rescan and repeat.

## Isolated Codex iteration

Build a self-contained prompt containing the selected ticket ID and title, the exact checkout, applicable confirmed decisions, and these requirements:

- invoke `/wr-itil:manage-problem <number>` and work only that problem;
- preserve unrelated work and use path-scoped staging;
- load and obey the installed governance skills, agents, and hooks;
- run focused tests and required architecture, JTBD, voice, accessibility, and risk checks when their gates apply;
- add a changeset for shippable package behavior;
- commit completed iteration work, but do not push or release;
- invoke `/wr-retrospective:run-retro` before the final response, commit any retro-owned briefing refresh through its governed path, and continue to the summary even if retro reports a non-blocking failure;
- end with one `ITERATION_SUMMARY` containing ticket, action, outcome, commit state, tests, risks, outstanding questions, remaining work, and notes.

Run the nested process in the outer session's installed Codex environment. Do not replace `CODEX_HOME` or ignore user configuration: the inherited plugin registry and hooks are the governance surface. Export the three AFK guards so pending interactive questions, oversight nudges, and machine-authored correction text do not leak into the isolated turn.

```bash
ITERATION_CHECKOUT="$(git rev-parse --show-toplevel)"
ITERATION_JSONL="$(mktemp)"
ITERATION_FINAL="$(mktemp)"

export WR_SUPPRESS_PENDING_QUESTIONS=1
export WR_SUPPRESS_OVERSIGHT_NUDGE=1
export WR_SUPPRESS_CORRECTION_DETECT=1

codex exec \
  --ephemeral \
  --dangerously-bypass-approvals-and-sandbox \
  --dangerously-bypass-hook-trust \
  --cd "$ITERATION_CHECKOUT" \
  --json \
  --output-last-message "$ITERATION_FINAL" \
  "$ITERATION_PROMPT" \
  >"$ITERATION_JSONL" 2>&1
ITERATION_EXIT=$?
```

The two output channels are load-bearing and must stay separate:

- `ITERATION_JSONL` carries progress and error metadata only. Parse it as JSONL; never scrape the final agent message from this stream.
- `ITERATION_FINAL` carries the final agent message. Read `ITERATION_SUMMARY` only from this file after the exit and metadata checks pass.

Always remove both temporary files after their contents have been classified and consumed.

## Error classification and recovery

Classify in this order:

1. A non-zero process exit halts the loop. Use the exit code plus JSONL error messages to report `quota exhausted`, `rate limited`, `authentication failed`, `service overloaded`, or `execution failed`; do not call a quota failure merely unavailable.
2. Exit zero with a JSONL `error` or `turn.failed` event also halts before summary parsing. Apply the same message classification. A final-output file does not override an error event.
3. Exit zero without an error event permits final-output parsing. The file must contain exactly one valid `ITERATION_SUMMARY` for the selected ticket; otherwise halt as `invalid iteration summary`.

After every exit, record the checkout delta against the pre-iteration status for diagnosis, without mutation. Recovery may begin only after exit zero, error-free JSONL, and exactly one valid `ITERATION_SUMMARY` for the selected ticket. Missing, multiple, or wrong-ticket summaries halt without recovery. Then compare the checkout with the recorded pre-iteration status:

- A clean checkout proceeds normally.
- A coherent commit named by the valid summary proceeds to inter-iteration verification.
- Coherent staged work attributable only to the selected ticket may be recovered only after its focused tests and governance gates pass again in the outer session.
- Ambiguous, unstaged, or unrelated changes hard-block recovery. Report their paths and halt without mutation.
- When a failed iteration created known disposable paths, restore only the explicit verified path list with path-scoped Git commands. Never use a broad reset, clean, checkout, restore, or stash operation.

## Fix Proposal Rule

A fix proposal is a release row on an existing story map, never a new file under `docs/rfcs/`. The row has an identity from `wr-itil-next-rfc-id`, at least one story card, and a story whose `problems:` list names the driving problem. Creating a new map, activity column, job, or uncovered architectural choice requires a queued human decision rather than a silent edit.

## Questions and Stop Conditions

- Batch outstanding questions at loop end with `request_user_input`, no more than four per call. Brief substance before IDs.
- Continue past skipped tickets when another actionable ticket exists.
- Stop only for an explicit user stop, a fully drained backlog, a governance dependency that blocks every remaining ticket, confirmed quota exhaustion, or an unrecoverable process or repository failure.
- Never describe a delayed process as unavailable, hung, or blocked without an actual error or terminal failure.

## Final Report

Report completed and skipped tickets, commits, tests, push and release outcomes, remaining backlog, and outstanding design questions. Preserve the distinction between committed, pushed, released, and production-verified states.
