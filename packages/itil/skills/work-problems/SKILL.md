---
name: wr-itil:work-problems
description: Batch-work ITIL problem tickets while the user is AFK. Loops through the problem backlog by WSJF priority, delegating each problem to wr-itil:manage-problem, and stops when nothing is left to progress. Use this skill whenever the user says things like "work through my problems", "grind problems", "work the backlog", "work problems while I'm away", "process problems AFK", or any request to autonomously work through multiple problem tickets without interactive input. Also trigger when the user asks to "loop" or "batch" problem work, or says they'll be away and wants problems handled.
allowed-tools: Skill, Bash, Glob, Grep, Read
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
| Known Error with `## Fix Released` | **Skip** — needs user verification | user-answerable (verification) |
| Known Error with fix strategy documented | **Work it** — implement the fix | — |
| Known Error without fix strategy | **Work it** — produce a fix strategy, then implement | — |
| Open problem with preliminary hypothesis or investigation notes | **Work it** — continue the investigation | — |
| Open problem with no leads (empty Root Cause Analysis) | **Work it** — read the relevant code, form a hypothesis, document findings | — |
| Problem previously attempted twice without progress in this session | **Skip** — mark as stuck, needs interactive attention | user-answerable (direction) |
| Open problem with outstanding user-answerable design question (naming, direction, pacing, scope) | **Skip** — surface the question at stop (Step 2.5) | user-answerable (design) |
| Open problem needing architect design judgment (new-ADR-level question) | **Skip** — note the architect-design blocker; Step 2.5 may elevate via a pre-triggered architect call in `--deep-stop` mode | architect-design |
| Open problem blocked on upstream dependency or Claude Code capability gap | **Skip** — record the upstream-blocked reason | upstream-blocked |

The default is to work the problem. Only skip when the rule explicitly says so. This is an AFK loop — forward progress matters more than avoiding dead ends, because dead ends are cheap (findings are saved) and interactive input is expensive (user is absent).

**Skip-reason taxonomy.** Every skipped ticket is tagged with one of three categories so Step 2.5 can select which ones to surface as questions:

- **user-answerable** — the user can answer directly (verification, naming, direction, pacing, scope). Step 2.5 surfaces these as questions (interactive) or in the Outstanding Design Questions table (non-interactive / AFK).
- **architect-design** — requires architect judgment first; may escalate to a new ADR. Step 2.5 can optionally pre-trigger the architect agent in `--deep-stop` mode to produce a concrete user-answerable question. Otherwise noted as "pending architect review".
- **upstream-blocked** — external dependency, Claude Code capability gap, or waiting on third-party fix. Truly terminal for this loop — no user question would change anything. Report the blocker and move on.

Record the category alongside the skip reason in the iteration report so Step 2.5 can read the categories deterministically.

**Time-box each problem** to avoid runaway investigation: the delegated `manage-problem` skill's internal logic decides scope. If investigation reveals the scope has grown (e.g., effort was estimated S but turns out to be L or XL), save findings to the problem file, update the WSJF score, and move to the next problem. Never sink unbounded effort into one problem during AFK mode.

If a problem is skipped by this step, add it to a "skipped" list with the reason and loop back to step 3 for the next one.

### Step 5: Work the problem

Invoke the manage-problem skill:

```
/wr-itil:manage-problem work highest WSJF problem that can be progressed non-interactively as the user is AFK
```

The manage-problem skill will:
- Run a review if the cache is stale
- Select and work the highest-WSJF problem
- Use its built-in non-interactive fallbacks (auto-split multi-concern problems, auto-commit when risk is within appetite)
- Commit completed work per ADR-014

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

### Step 7: Loop

Go back to step 1. The backlog may have changed — new problems may have been created during fixes, priorities may have shifted, and the README.md cache will be stale.

## Non-Interactive Decision Making

When `AskUserQuestion` is unavailable or the user is AFK, the skill (and the delegated manage-problem skill) should resolve decisions automatically:

| Decision Point | Non-Interactive Default |
|---|---|
| Which problem to work | Highest WSJF, no prompt needed |
| Multi-concern split | Auto-split (manage-problem step 4b fallback) |
| Scope expansion during work | Update problem file, re-score WSJF, move to next problem instead of continuing |
| Commit when risk within appetite | Auto-commit (manage-problem step 9e fallback) |
| Commit when risk above appetite | Skip commit, report uncommitted state |
| Pipeline risk at appetite (push or release >= 4/25) | Drain release queue (`push:watch` then `release:watch`) before next iteration — per ADR-018 (Step 6.5) |
| Origin diverged before start | Pull `--ff-only` if trivial; stop with report (`git log HEAD..origin/<base>` and reverse) if non-fast-forward — per ADR-019 (Step 0) |
| Fix verification needed | Skip problem, add to "needs verification" list |
| Stop-condition #2 with user-answerable skip-reasons | Emit Outstanding Design Questions table in summary (do NOT call AskUserQuestion). The persona is AFK by definition — per JTBD-006 and ADR-013 Rule 6 — so the table is the default. Interactive invocations may batch up to 4 questions through AskUserQuestion instead — per ADR-013 Rule 1 (Step 2.5). |

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
