---
name: wr-itil:work-problems
description: Batch-work ITIL problem tickets while the user is AFK. Loops through the problem backlog by WSJF priority, delegating each problem to wr-itil:manage-problem, and stops when nothing is left to progress. Use this skill whenever the user says things like "work through my problems", "grind problems", "work the backlog", "work problems while I'm away", "process problems AFK", or any request to autonomously work through multiple problem tickets without interactive input. Also trigger when the user asks to "loop" or "batch" problem work, or says they'll be away and wants problems handled.
allowed-tools: Agent, Skill, Bash, Glob, Grep, Read
---

# Work Problems — AFK Batch Orchestrator

Autonomously loop through ITIL problem tickets by WSJF priority, working each one via `wr-itil:manage-problem`, until nothing actionable remains.

The user is AFK during this process, so every decision point that would normally require interactive input should be resolved automatically using safe defaults. The skill reports progress between iterations so the user can review what happened when they return.

## How It Works

Each iteration is one cycle of: scan backlog, pick highest-WSJF problem, work it, report result. The loop continues until a stop condition is met.

### Step 0: Preflight (per ADR-019)

Before opening the work loop, reconcile local state with origin so the orchestrator does not iterate against a stale backlog or create tickets with IDs that collide with parallel sessions (P040).

**Mechanism:**

1. Run `git fetch origin`.
2. Compare local `HEAD` with `origin/<base>` (default `main`; otherwise the branch the user is on).
3. Branch on the divergence shape:

| Local vs origin | Action |
|---|---|
| HEAD at or ahead of origin/<base> | Proceed to Step 1 |
| origin/<base> ahead, local has no unpushed commits (pure fast-forward) | Run `git pull --ff-only` non-interactively. Log the count of pulled commits in the AFK iteration log. Proceed to Step 1. |
| origin/<base> ahead, local has unpushed commits (non-fast-forward) | STOP the loop. Report the divergence with `git log --oneline HEAD..origin/<base>` and `git log --oneline origin/<base>..HEAD`. Do NOT attempt to rebase or merge non-interactively — that is a judgment call the persona forbids in AFK mode. |

**Network failure**: if `git fetch origin` returns a network error, stop and report. Default behaviour is fail-closed — the user can retry when network is restored.

**Non-interactive authorisation**: per ADR-013 Rule 6, `git fetch origin` and `git pull --ff-only` are policy-authorised actions (no semantic merge, no destructive overwrite). `git pull --rebase`, `git merge`, and any operation that resolves conflicts are NOT policy-authorised — they require user input.

**Cross-cutting**: this rule applies to every AFK orchestrator skill. The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in the ticket-creator skills (`manage-problem` and `wr-architect:create-adr`), not here — see the related problem ticket for that work.

### Step 1: Scan the backlog

Read `docs/problems/README.md` if it exists and is fresh (check via git history — see manage-problem step 9 for the cache freshness check). If stale or missing, scan all `.open.md` and `.known-error.md` files in `docs/problems/`, extract their WSJF scores, and rank them.

Exclude:
- `.closed.md` files (done)
- `.parked.md` files (blocked on upstream)
- `.verifying.md` files (Verification Pending — fix released, awaiting user verification per ADR-022; surfaced in the Verification Queue section, never in dev-work ranking)
- Problems with no WSJF score (need a review first — run `/wr-itil:manage-problem review` as the first iteration if scores are missing)

### Step 2: Check stop conditions

Stop the loop and report a summary if any of these are true:

1. **No actionable problems** — zero open or known-error problems remain
2. **All remaining problems require interactive input** — e.g., they all need user verification (known-errors with `## Fix Released`), or their scope expanded beyond what's safe to auto-resolve
3. **All remaining problems are blocked** — investigation hit a dead end, or the fix requires changes outside the project

When stop-condition #2 fires, do not jump straight to `ALL_DONE` — run Step 2.5 first to surface the outstanding questions.

For stop-conditions #1 and #3 (no questions to ask), skip Step 2.5 and emit the summary + `ALL_DONE` directly.

### Step 2.5: Surface outstanding design questions (P053, fires only for stop-condition #2)

The skipped tickets that triggered stop-condition #2 frequently carry **user-answerable design questions** (naming, direction, pacing, scope) whose answers would unblock the next AFK loop. The information the user needs to answer is fully known at stop time, so there is no cost to surfacing the questions before the terminal `ALL_DONE` emit.

**1. Extract the question set.** For every skipped ticket whose classifier skip-reason is `user-answerable` (see Step 4's taxonomy), extract its outstanding question(s) from the ticket body — typically from a "Pacing decision", "Naming decision", or outstanding "Investigation Tasks" section. Cap at 4 questions per `AskUserQuestion` call per Anthropic's tool documentation.

**2. Branch on interactivity per ADR-013 Rule 1 / Rule 6.**

- **Interactive invocation** (AskUserQuestion is available AND the loop was not started in AFK mode): batch the questions into one `AskUserQuestion` call (or more, if >4 questions, issued sequentially). Header: `"Outstanding design questions"`. For each question, set the prompt from the extracted text and the options from the ticket's candidate fixes or option list. Write each answer back to the corresponding ticket file so the next AFK loop does not re-ask.
- **Non-interactive / AFK invocation** (default for this skill per JTBD-006 — the persona is AFK): do NOT call `AskUserQuestion`. Instead emit an `### Outstanding Design Questions` section in the post-stop summary listing each question with its Ticket ID, the question text, and one-line context. The user answers on return.

This branch is the Rule 6 fail-safe applied to stop-condition #2: Rule 1 says route governance decisions through `AskUserQuestion`; Rule 6 says fall back to a structured summary when the tool is unavailable or the user is away. JTBD-006's persona constraint ("autonomously work without needing interactive input") makes the non-interactive path the default for this skill — AskUserQuestion is the exception, not the rule.

**3. Emit the final summary + `ALL_DONE`.** The summary includes the Outstanding Design Questions table when any user-answerable questions were surfaced (see Output Format).

```
ALL_DONE
```

This sentinel line allows external scripts to detect completion.

### Step 3: Pick the highest-WSJF problem

Select the problem with the highest WSJF score. If there's a tie, prefer:
1. Known Errors over Open problems (they have a confirmed fix path — less risk of wasted effort)
2. Smaller effort over larger (faster throughput)
3. Older reported date (longer wait = higher urgency)

### Step 4: Classify each problem

Read the problem file and apply these deterministic rules:

| Problem state | Action | Skip-reason category |
|---|---|---|
| `.verifying.md` (Verification Pending, per ADR-022) | **Skip** — fix released, awaiting user verification | user-answerable (verification) |
| Known Error with fix strategy documented | **Work it** — implement the fix (on release, transition to `.verifying.md` per ADR-022) | — |
| Known Error without fix strategy | **Work it** — produce a fix strategy, then implement | — |
| Open problem with preliminary hypothesis or investigation notes | **Work it** — continue the investigation | — |
| Open problem with no leads (empty Root Cause Analysis) | **Work it** — read the relevant code, form a hypothesis, document findings | — |
| Problem previously attempted twice without progress in this session | **Skip** — mark as stuck, needs interactive attention | user-answerable (direction) |
| Open problem with outstanding user-answerable design question (naming, direction, pacing, scope) | **Skip** — surface the question at stop (Step 2.5) | user-answerable (design) |
| Open problem needing architect design judgment (new-ADR-level question) | **Skip** — note the architect-design blocker; Step 2.5 may elevate via a pre-triggered architect call in `--deep-stop` mode | architect-design |
| Open problem blocked on upstream dependency or Claude Code capability gap | **Skip** — but first append the pending-upstream-report marker to the ticket's `## Related` section (see P063 — run the manage-problem SKILL.md external-root-cause detection AFK fallback before skipping). The marker wording is fixed: `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready`. Use the already-noted check to avoid duplicates. | upstream-blocked |

The default is to work the problem. Only skip when the rule explicitly says so. This is an AFK loop — forward progress matters more than avoiding dead ends, because dead ends are cheap (findings are saved) and interactive input is expensive (user is absent).

**Skip-reason taxonomy.** Every skipped ticket is tagged with one of three categories so Step 2.5 can select which ones to surface as questions:

- **user-answerable** — the user can answer directly (verification, naming, direction, pacing, scope). Step 2.5 surfaces these as questions (interactive) or in the Outstanding Design Questions table (non-interactive / AFK).
- **architect-design** — requires architect judgment first; may escalate to a new ADR. Step 2.5 can optionally pre-trigger the architect agent in `--deep-stop` mode to produce a concrete user-answerable question. Otherwise noted as "pending architect review".
- **upstream-blocked** — external dependency, Claude Code capability gap, or waiting on third-party fix. Truly terminal for this loop — no user question would change anything. Report the blocker and move on. **Before skipping, run the manage-problem external-root-cause detection AFK fallback** (per P063): grep the ticket for the stable marker `- **Upstream report pending** —` or `- **Reported Upstream:**` / a `## Reported Upstream` section; if none is present, append `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` to the ticket's `## Related` section. This preserves the outbound audit trail across AFK iterations so the user can see the deferred action on return.

Record the category alongside the skip reason in the iteration report so Step 2.5 can read the categories deterministically.

**Time-box each problem** to avoid runaway investigation: the delegated `manage-problem` skill's internal logic decides scope. If investigation reveals the scope has grown (e.g., effort was estimated S but turns out to be L or XL), save findings to the problem file, update the WSJF score, and move to the next problem. Never sink unbounded effort into one problem during AFK mode.

If a problem is skipped by this step, add it to a "skipped" list with the reason and loop back to step 3 for the next one.

### Step 5: Work the problem (delegate via Agent tool, per P077)

**Delegate each iteration to a subagent via the Agent tool** — do NOT invoke `/wr-itil:manage-problem` inline via the Skill tool. Inline Skill-tool invocation expands manage-problem's SKILL.md (500+ lines) into the main orchestrator's context every iteration, accumulates across the AFK loop, and causes silent early-stop (`ALL_DONE` without a documented stop condition firing). This delegation is the AFK iteration-isolation wrapper sub-pattern under ADR-032.

**Agent call shape:**

- `subagent_type`: `general-purpose` — Option B pinned in P077. Iteration work is general engineering, not specialised domain expertise, and `general-purpose` has `Tools: *` so the subagent can recursively invoke architect / jtbd / risk-scorer subagents for its own gate reviews. Promotion to a typed `wr-itil:work-problems-iteration-worker` subagent remains available if a specialised constraint ever emerges; until then, typing it would just duplicate manage-problem's "always do X" preamble.
- `description`: `Work P<NNN> (<title>)` — one iteration, identified by the highest-WSJF ticket selected in Steps 3–4.
- `prompt` (self-contained — the subagent has no prior conversation context):
  1. **Context**: this is one iteration of the AFK work-problems loop. The user is AFK. The orchestrator selected `P<NNN> (<title>)` as the highest-WSJF actionable ticket.
  2. **Task**: apply the `/wr-itil:manage-problem` workflow for `work highest WSJF problem that can be progressed non-interactively as the user is AFK`. Follow manage-problem SKILL.md verbatim, including architect / jtbd / style-guide / voice-tone gate reviews and the commit gate (manage-problem Step 11).
  3. **Constraints**: commit the completed work per ADR-014. Do NOT push, do NOT run `push:watch`, do NOT run `release:watch` — the orchestrator's Step 6.5 owns release cadence. Do NOT invoke `capture-*` background skills (AFK carve-out — ADR-032). Non-interactive defaults apply per ADR-013 Rule 6.
  4. **Return the iteration summary** (see contract below).

**Return-summary contract.** The subagent's final message MUST end with a structured summary block the orchestrator parses without re-reading tool calls. Required fields:

```
ITERATION_SUMMARY
ticket_id: P<NNN>
ticket_title: <title>
action: worked | skipped
outcome: closed | verifying | known-error | investigated | scope-expanded | partial-progress | skipped
committed: true | false | skipped
commit_sha: <sha>                                  # required when committed=true
reason: <one-line>                                 # required when committed=false or action=skipped
skip_reason_category: user-answerable | architect-design | upstream-blocked  # required when action=skipped
outstanding_questions: [<one-line each>]           # optional; drives Step 2.5 when skip_reason_category=user-answerable
remaining_backlog_count: <N>
notes: <one-line>
```

Architect review (R2) requires the commit state fields (`committed` / `commit_sha` / `reason`) so **Step 6.75's Dirty-for-known-reason branch stays evaluable** from the summary alone. JTBD review requires `ticket_id` / `action` / `skip_reason_category` / `outstanding_questions` so Step 2.5 and the Output Format's Completed / Skipped / Outstanding Design Questions tables can be populated deterministically without the orchestrator having to re-parse ticket files.

**Inter-iteration continuity.** Step 6.5 (release-cadence check) and Step 6.75 (inter-iteration verification) stay in the **main orchestrator's turn**, NOT the iteration subagent. Rationale: release-cadence and `git status --porcelain` are orchestration-level concerns; `push:watch`/`release:watch` are long-running waits that would waste iteration-subagent context; the orchestrator needs to see the summary from one iteration before deciding whether to drain before the next.

The manage-problem skill (running inside the iteration subagent) will:

- Run a review if the cache is stale.
- Select and work the highest-WSJF problem.
- Use its built-in non-interactive fallbacks (auto-split multi-concern problems, auto-commit when risk is within appetite).
- Commit completed work per ADR-014 (the iteration subagent's commit — the orchestrator does NOT commit from its main turn).

### Step 6: Report progress

After each iteration, report:
- Which problem was worked (ID + title)
- What was done (investigated, transitioned to known-error, fix implemented, etc.)
- The outcome (success, partially progressed, skipped, scope expanded)
- How many problems remain in the backlog

Format as a brief status line, not a wall of text. The user will read these when they return.

**Example:**
```
[Iteration 1] Worked P029 (Edit gate overhead for governance docs) — implemented fix, closed. 8 problems remain.
[Iteration 2] Worked P021 (Governance skill structured prompts) — investigated root cause, transitioned to known-error. 7 problems remain.
[Iteration 3] Skipped P016 (Multi-concern ticket splitting) — fix released, awaiting user verification. Worked P024 (Risk scorer WIP flag) — implemented fix, closed. 6 problems remain.
```

### Step 6.5: Release-cadence check (per ADR-018)

After the iteration's commit lands but before starting the next iteration, check whether the unreleased queue would push pipeline risk to or above appetite. If so, drain the queue before continuing. This prevents silent accumulation of unreleased changesets across AFK iterations (P041).

**Mechanism — delegate, do not re-implement scoring:**

1. Invoke the risk scorer to score cumulative pipeline state. Two paths are valid (per ADR-015):
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool. The skill wraps the same pipeline subagent.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line.
3. **Threshold**: if `push` or `release` is at or above appetite (4/25, "Low" band per `RISK-POLICY.md`), drain the queue.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` is non-empty after push, run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Resume the loop only after the release lands on npm.

**Failure handling**: If `release:watch` fails (CI failure, publish failure), stop the loop and report the failure in the AFK summary. Do not retry non-interactively — the user must intervene.

`push:watch` and `release:watch` are policy-authorised actions when residual risk is within appetite per RISK-POLICY.md, so no `AskUserQuestion` is required for the drain itself (ADR-013 Rule 6).

### Step 6.75: Inter-iteration verification (P036)

Before spawning the next iteration's subagent, verify the working tree state against the expected outcome of the iteration that just completed. This is defence-in-depth: P035 closed the most-likely commit-gate failure path, but a subagent could still fail to commit for reasons the fallback does not cover (a failure inside `/wr-risk-scorer:assess-release`, a git conflict, a malformed commit message). Without this check, silent failures accumulate across iterations and the final summary reports commits that did not land.

**Mechanism:**

1. Run `git status --porcelain`.
2. Classify the output into one of three cases:

| Status | Expected when | Action |
|---|---|---|
| Clean (empty output) | The subagent committed successfully (the default happy path) | Proceed to Step 7 |
| Dirty for a known reason | A deliberate hand-off to the next iteration (e.g. the subagent chose to skip the commit and report "uncommitted state" because risk was above appetite — per the Non-Interactive Decision Making table above). Reason MUST be stated in the iteration report. | Include the dirty state in the next iteration's subagent context and proceed to Step 7 |
| Dirty for an unknown reason | Neither of the above — the subagent reported success but the tree is not clean, or the tree is dirty without a documented reason in the iteration report | **Halt the loop.** Report the `git status --porcelain` output, the last subagent's reported outcome, and the divergence. Do NOT spawn the next iteration. |

**Rationale**: the orchestrator previously treated the subagent's reported outcome as truth. Any lie, partial write, or silent failure in the subagent propagated into the summary. The `git status --porcelain` check is the cheapest possible independent verification — policy-authorised, no network, no judgement required — and it catches exactly the class of failure the subagent cannot self-report.

**Out of scope for this step**: attempting recovery from an unknown-reason dirty state. Per ADR-013 Rule 6, conflict resolution and ambiguous state require user input; non-interactive recovery would mask the bug this check is meant to surface.

### Step 7: Loop

Go back to step 1. The backlog may have changed — new problems may have been created during fixes, priorities may have shifted, and the README.md cache will be stale.

## Non-Interactive Decision Making

When `AskUserQuestion` is unavailable or the user is AFK, the skill (and the delegated manage-problem skill) should resolve decisions automatically:

| Decision Point | Non-Interactive Default |
|---|---|
| How each iteration runs (iteration delegation) | Delegate to `subagent_type: general-purpose` via the Agent tool per Step 5 — NOT inline Skill-tool invocation. This is the AFK iteration-isolation wrapper sub-pattern under ADR-032; the main orchestrator consumes the iteration subagent's return-summary contract and does not re-read the subagent's tool calls. Per P077 + ADR-032. |
| Which problem to work | Highest WSJF, no prompt needed |
| Multi-concern split | Auto-split (manage-problem step 4b fallback) |
| Scope expansion during work | Update problem file, re-score WSJF, move to next problem instead of continuing |
| Commit when risk within appetite | Auto-commit (manage-problem step 9e fallback) |
| Commit when risk above appetite | Skip commit, report uncommitted state |
| Pipeline risk at appetite (push or release >= 4/25) | Drain release queue (`push:watch` then `release:watch`) before next iteration — per ADR-018 (Step 6.5) |
| Origin diverged before start | Pull `--ff-only` if trivial; stop with report (`git log HEAD..origin/<base>` and reverse) if non-fast-forward — per ADR-019 (Step 0) |
| Fix verification needed | Skip problem, add to "needs verification" list |
| Stop-condition #2 with user-answerable skip-reasons | Emit Outstanding Design Questions table in summary (do NOT call AskUserQuestion). The persona is AFK by definition — per JTBD-006 and ADR-013 Rule 6 — so the table is the default. Interactive invocations may batch up to 4 questions through AskUserQuestion instead — per ADR-013 Rule 1 (Step 2.5). |
| Unexpected dirty state between iterations | Halt the loop. Report the `git status --porcelain` output, the last iteration's reported outcome, and the divergence — per P036 (Step 6.75). Do NOT attempt non-interactive recovery. |
| External root cause detected at Open → Known Error, or at park with `upstream-blocked` reason | Append the stable `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` marker to the ticket's `## Related` section; do NOT auto-invoke `/wr-itil:report-upstream` (Step 6 security-path branch is interactive — per ADR-024 Consequences). Use the already-noted grep check to avoid duplicate lines. Per P063 + ADR-013 Rule 6. |

## Edge Cases

**Review needed first**: If no problems have WSJF scores, run `/wr-itil:manage-problem review` as the first iteration to score everything, then proceed to the work loop.

**Scope creep during investigation**: If investigating an open problem reveals the scope is larger than expected (effort re-sized from S to L, or L to XL), save findings to the problem file, update the WSJF score, and move to the next problem. Don't sink unlimited effort into one problem during AFK mode — the user can decide when they return.

**Circular work**: If the same problem keeps appearing as highest-WSJF across iterations without making progress, skip it after the second attempt and note it as "stuck — needs interactive attention".

**Git conflicts**: If a commit fails due to conflicts, stop the loop and report the conflict. Don't try to resolve conflicts non-interactively.

## Output Format

The skill should produce a final summary when the loop ends:

```
## Work Problems Summary

### Completed
| # | Problem | Action | Result |
|---|---------|--------|--------|
| 1 | P029 (Edit gate overhead) | Implemented fix | Closed |
| 2 | P021 (Structured prompts) | Investigated root cause | Transitioned to Known Error |

### Skipped
| Problem | Skip-reason category | Reason |
|---------|---------------------|--------|
| P016 (Multi-concern splitting) | user-answerable (verification) | Awaiting user verification |

### Outstanding Design Questions

(Emitted only when stop-condition #2 fires AND at least one skipped ticket has a `user-answerable (design/direction/pacing/scope)` skip-reason. Populated by Step 2.5 in non-interactive / AFK mode per ADR-013 Rule 6.)

| Ticket | Question | Context |
|--------|----------|---------|
| P049 (Known Error overloaded) | What should the new status be called, and what file suffix? | Decide so the rename/migration commit can land unambiguously. |
| P051 (run-retro improvement axis) | Ship in this AFK loop or next? | P050 is still fresh; rewriting Step 2/4b/5 twice in one session may churn. |

### Remaining Backlog
| WSJF | Problem | Status |
|------|---------|--------|
| 9.0 | P012 (Skill testing harness) | Open |

ALL_DONE
```

When every skipped ticket is in the `upstream-blocked` category (stop-condition #3) or there are no skipped tickets (stop-condition #1), omit the Outstanding Design Questions section entirely rather than rendering an empty heading.

## Related

- **P077** (`docs/problems/077-work-problems-step-5-does-not-delegate-to-subagent.verifying.md`) — driver for Step 5's Agent-tool delegation and the return-summary contract.
- **P036** — inter-iteration verification (Step 6.75); remains in the orchestrator's main turn.
- **P040** — origin-fetch preflight (Step 0); unchanged.
- **P041** — release-cadence drain (Step 6.5); remains in the orchestrator's main turn.
- **P053** — Outstanding Design Questions surfacing at stop-condition #2 (Step 2.5); fed by the iteration subagent's `outstanding_questions` field.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 6 non-interactive fail-safe applies to every iteration-subagent decision surface.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — preserved under the iteration subagent; the subagent commits its own work.
- **ADR-015** (`docs/decisions/015-on-demand-assessment-skills.proposed.md`) — Agent-tool-vs-Skill-tool delegation precedent (Step 6.5's wording mirror).
- **ADR-018** (`docs/decisions/018-release-cadence.proposed.md`) — release cadence stays in the orchestrator's main turn, not the iteration subagent.
- **ADR-019** (`docs/decisions/019-afk-orchestrator-preflight.proposed.md`) — preflight stays in the orchestrator's main turn.
- **ADR-022** (`docs/decisions/022-problem-verification-pending.proposed.md`) — iteration outcomes map into the return-summary's `outcome` field (`verifying` for a released fix, `known-error` for a root-cause-confirmed ticket awaiting release, etc.).
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — pattern taxonomy parent; Step 5 is the canonical AFK iteration-isolation wrapper sub-pattern per the ADR-032 amendment that lands with P077.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — doc-lint bats contract-assertion pattern used by `test/work-problems-step-5-delegation.bats`.
- **JTBD-001**, **JTBD-006**, **JTBD-101**, **JTBD-201** — personas whose reliability expectations the iteration-isolation wrapper restores.
