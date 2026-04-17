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

When stopping, output a summary table of what was worked and what remains, then output exactly:

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

| Problem state | Action |
|---|---|
| Known Error with `## Fix Released` | **Skip** — needs user verification |
| Known Error with fix strategy documented | **Work it** — implement the fix |
| Known Error without fix strategy | **Work it** — produce a fix strategy, then implement |
| Open problem with preliminary hypothesis or investigation notes | **Work it** — continue the investigation |
| Open problem with no leads (empty Root Cause Analysis) | **Work it** — read the relevant code, form a hypothesis, document findings |
| Problem previously attempted twice without progress in this session | **Skip** — mark as stuck, needs interactive attention |

The default is to work the problem. Only skip when the rule explicitly says so. This is an AFK loop — forward progress matters more than avoiding dead ends, because dead ends are cheap (findings are saved) and interactive input is expensive (user is absent).

**Time-box each problem** to avoid runaway investigation: the delegated `manage-problem` skill's internal logic decides scope. If investigation reveals the scope has grown (e.g., effort was estimated S but turns out to be L), save findings to the problem file, update the WSJF score, and move to the next problem. Never sink unbounded effort into one problem during AFK mode.

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
| Fix verification needed | Skip problem, add to "needs verification" list |

## Edge Cases

**Review needed first**: If no problems have WSJF scores, run `/wr-itil:manage-problem review` as the first iteration to score everything, then proceed to the work loop.

**Scope creep during investigation**: If investigating an open problem reveals the scope is larger than expected (effort re-sized from S to L), save findings to the problem file, update the WSJF score, and move to the next problem. Don't sink unlimited effort into one problem during AFK mode — the user can decide when they return.

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
| Problem | Reason |
|---------|--------|
| P016 (Multi-concern splitting) | Awaiting user verification |

### Remaining Backlog
| WSJF | Problem | Status |
|------|---------|--------|
| 9.0 | P012 (Skill testing harness) | Open |

ALL_DONE
```
