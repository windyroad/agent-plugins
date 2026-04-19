---
name: wr-itil:manage-problem
description: Create, update, or transition a problem ticket using an ITIL-aligned problem management workflow with WSJF prioritisation. Supports creating new problems, updating root cause analysis, transitioning status, and closing problems.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Problem Management Skill

Create, update, or transition problem tickets following an ITIL-aligned problem management process. This skill is the authoritative definition of the problem management workflow — no separate process document is needed.

## Output Formatting

When referencing problem IDs, ADR IDs, or JTBD IDs in prose output, always include the human-readable title on first mention. Use the format `P029 (Edit gate overhead for governance docs)`, not bare `P029`. Tables with separate ID and Title columns are fine as-is.

## Operations

- **Create**: `problem <title or description>` — creates a new open problem
- **Update**: `problem <NNN> <update details>` — updates an existing problem (add root cause, evidence, fix strategy)
- **Transition**: `problem <NNN> known-error` — moves to known-error when root cause is confirmed
- **List**: `problem list` — shows all open problems sorted by priority
- **Work**: `problem work` — runs a review first, then begins working the highest-WSJF problem
- **Review**: `problem review` — re-assess all open problems: update priorities per RISK-POLICY.md, estimate effort, calculate WSJF, and update files

**Closing problems:** Problems are closed ONLY after the user verifies the fix in production — not when the fix is committed or released. The workflow (per ADR-022):
1. When the fix is released: `git mv` the file from `.known-error.md` to `.verifying.md`, update the Status field to "Verification Pending", AND add a `## Fix Released` section (e.g., `Deployed in v0.26.X. Awaiting user verification.`). All three edits land in the same commit per ADR-014.
2. When the user explicitly confirms ("it's fixed", "verified", "working"): `git mv` from `.verifying.md` to `.closed.md`, update the Status field to "Closed", and reference the problem in the commit message (e.g., "Closes P008").
3. Never assume the fix works — always wait for explicit user confirmation before closing.

The `.verifying.md` suffix distinguishes "fix released, awaiting user verification" from "root cause confirmed, fix not yet implemented" (the Known Error meaning pre-release). See ADR-022 for rationale.

## Problem Lifecycle

| Status | File suffix | Meaning | Entry criteria |
|--------|-----------|---------|----------------|
| **Open** | `.open.md` | Reported, under investigation | New problem identified |
| **Known Error** | `.known-error.md` | Root cause confirmed, fix path clear, **fix NOT yet released** | Root cause documented, reproduction test exists, workaround in place |
| **Verification Pending** | `.verifying.md` | Fix released, awaiting user verification (ADR-022) | Fix shipped; `## Fix Released` section written; user action remaining |
| **Parked** | `.parked.md` | Blocked on upstream or suspended by user decision | Upstream blocker identified, or user explicitly suspends; reason and un-park trigger documented |
| **Closed** | `.closed.md` | Fix verified in production | User explicitly confirms the released fix works |

**Parked problems** are excluded from WSJF ranking and work selection. They are listed separately in review output so users can see them without them polluting the backlog. To park a problem:
1. `git mv docs/problems/<NNN>-<title>.<current>.md docs/problems/<NNN>-<title>.parked.md`
2. Update the Status field to "Parked"
3. Add a `## Parked` section with: reason for parking, expected trigger to un-park, date parked

To un-park: `git mv` back to `.open.md` (or `.known-error.md` if root cause is confirmed), update Status, remove `## Parked` section.

**Verification Pending problems** are also excluded from WSJF ranking — their remaining work is user-side verification, not dev effort. They appear in a dedicated "Verification Queue" section in review output so the user can see what's waiting on them without mixing with dev-work ranking. See step 9c for the queue layout.

**Test-driven resolution:** When root cause is identified, create a failing test that reproduces the problem. Skip/disable the test if a feature-disabling workaround is applied. Re-enable the test when the permanent fix is implemented — the test passing confirms resolution.

## WSJF Prioritisation

Problems are ranked using Weighted Shortest Job First (WSJF):

**WSJF = (Severity × Status Multiplier) / Effort**

**Severity** = Impact × Likelihood (1-25) from `RISK-POLICY.md`. Read the impact levels, likelihood levels, and risk matrix from the policy — do not hardcode them here.

**Status Multiplier** (known-errors have confirmed root cause and clear fix path — higher value per unit of work):

| Status | Multiplier |
|--------|-----------|
| Known Error | 2.0 |
| Open | 1.0 |
| Verification Pending | 0 (excluded) |
| Parked | 0 (excluded) |

`Verification Pending` and `Parked` tickets are excluded from the main dev-work ranking per ADR-022 (verification) and the Parked policy above. `Verification Pending` remaining work is user-side confirmation, not dev effort, so mixing it into the dev-work queue would distort WSJF. Both are surfaced in dedicated sections (see step 9c) — not in the ranked table.

**Effort** (estimated fix size — smaller effort = higher priority):

| Effort | Divisor | Description |
|--------|---------|-------------|
| S | 1 | < 1 hour, single file, quick fix |
| M | 2 | 1-4 hours, few files, moderate change |
| L | 4 | 4 hours – 1 day, multiple files, significant change within a single plugin |
| XL | 8 | > 1 day, multi-day or cross-package work (multiple plugins, migration, new ADR required) |

**Example**: A Known Error with severity 8 (Impact 4 × Likelihood 2) and Small effort:
WSJF = (8 × 2.0) / 1 = **16.0** — do this first.

An Open problem with severity 6 (Impact 3 × Likelihood 2) and Large effort:
WSJF = (6 × 1.0) / 4 = **1.5** — lower priority despite medium severity.

An Open problem with severity 8 (Impact 2 × Likelihood 4) and Extra-Large effort (multi-day, cross-package):
WSJF = (8 × 1.0) / 8 = **1.0** — defer until severity climbs or scope shrinks.

When estimating effort, read the problem's root cause analysis and fix strategy. If effort is unknown, default to M (2). Effort is a **live estimate**, not a set-once label: re-rate it when root cause is confirmed, when architect review narrows or expands scope, and during each `manage-problem review`. A note capturing the reason for any bucket change makes the ranking audit-able (see steps 7 and 9b).

## Working a Problem

What "work" means depends on the problem's status:

**Open problem (no confirmed root cause):**
1. Read the problem description and any preliminary hypotheses
2. Investigate the root cause — read relevant source code, run experiments, query prod data. Do NOT guess.
3. Document findings in the Root Cause Analysis section with evidence
4. Create a failing reproduction test (can be skipped/disabled)
5. Identify a workaround (even "delete and re-enter" counts)
6. Update the problem file with all findings
7. **Transition to Known Error immediately** — once root cause and workaround are documented, `git mv` the file to `.known-error.md` and update the Status field. Do not wait for a separate review.
8. If the fix is small enough, continue straight to implementing it (becoming a Known Error → Closed flow in one session)

**Known Error (root cause confirmed, fix path clear):**
1. Read the root cause analysis and fix strategy
2. Implement the fix following the project's development workflow (plan if needed, architect review, tests, etc.)
3. Include the problem doc closure in the fix commit (`git mv` to `.closed.md`, update Status)
4. Push, create changeset, release per the lean release principle

**Scope expansion during work:** If investigation or architect review reveals that the problem's scope has grown significantly (e.g., effort re-sized from S to L, additional files discovered), use `AskUserQuestion` before continuing:
- Option 1: `Continue with expanded scope` — keep working this problem at its new size
- Option 2: `Update problem and re-rank` — save findings to the problem file, re-score WSJF, and re-run the work selection to let the user pick from the updated queue
- Option 3: `Pick a different problem` — park this one and work something else
- Use `header: "Scope change"` and `multiSelect: false`

**In both cases:** After completing work on one problem, run `problem work` again to pick up the next highest-WSJF problem. Keep going until the user says stop or no more problems are actionable.

## Steps

### 1. Parse the request

Determine the operation from `$ARGUMENTS`:
- If arguments start with a number (e.g., "011"), this is an update or transition
- If arguments contain "list", show a summary of all open problems
- If arguments contain "work", run a **review** first (step 9), then begin working the highest-WSJF problem
- If arguments contain "review", run the review (step 9) only
- Otherwise, this is a new problem creation

### 2. For new problems: Check for duplicates FIRST

Before creating, search existing problems for similar issues. The user may not know a problem already exists.

1. Extract keywords from the description/title (e.g., "foul drawn", "checkpoint", "delete", "stuck saving")
2. Search all files in `docs/problems/` for those keywords using Grep
3. Read the title and status of each match
4. If matches are found, present them to the user via `AskUserQuestion`:
   - "I found existing problems that may be related: P011 (stuck saving, CLOSED), P023 (foul drawn garbled, OPEN). Would you like to: (a) Update an existing problem, (b) Create a new problem anyway, (c) Cancel?"
5. If the user chooses to update, switch to the update flow for that problem ID
6. If no matches found, proceed to create

**Search strategy**: Search problem filenames AND file content. A match on the filename (kebab-case title) or the Description/Symptoms sections counts. Cast a wide net — false positives are cheap (user chooses), but false negatives mean duplicate problems.

### 3. For new problems: Assign the next ID

Compute the next ID as the **max of the local and origin highest IDs**, plus one, zero-padded to 3 digits. Comparing against `origin/<base>` is required by ADR-019 (confirmation criterion 2): without it, parallel sessions can mint the same ID for different problems and force a destructive surgical rebase on push (P040 incident).

```bash
# Local-max ID
local_max=$(ls docs/problems/*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^[0-9]+' | sort -n | tail -1)

# Origin-max ID — `git ls-tree origin/<base>` reads remote-tracking ref
# without requiring a fetch in this step (Step 0 preflight is the place
# where the fetch happens). Default base is `main`; if the user is on
# another branch, swap accordingly.
origin_max=$(git ls-tree origin/main docs/problems/ 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1)

# Take the max of the two and increment.
next=$(printf '%03d' $(( $(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

If the local choice would have collided with an origin ticket created since the last fetch, the `git ls-tree origin/<base>` lookup catches it here and the renumber is automatic. Log the renumber decision in the operation report (e.g. "Bumped next ID from 042 → 043 to avoid collision with origin").

### 4. For new problems: Gather information

If the arguments contain a description, extract what you can. For anything missing, use `AskUserQuestion` to gather:

- **Title**: Short kebab-case-friendly description
- **Description**: What is happening? What should happen instead?
- **Priority**: Impact (1-5) × Likelihood (1-5) per RISK-POLICY.md

Do NOT ask for fields that can be inferred:
- **Reported date**: Use today's date
- **Status**: Always "Open" for new problems
- **Symptoms**: Infer from description if possible
- **Workaround**: Default to "None identified yet." unless obvious from context

### 4b. For new problems: Concern-boundary analysis (multi-concern check)

Before writing the problem file, perform a concern-boundary analysis on the gathered description to prevent conflated tickets that make WSJF scoring meaningless (P016).

**Self-check**: Read the description and root cause information gathered in step 4. Answer: "How many distinct root causes are present? If fixed independently, how many separate fix paths exist?"

- **Single concern** (one root cause, one fix path): proceed directly to step 5.
- **Multiple concerns** (two or more distinct root causes, different components, or if the architect review flagged this needs its own ADR): present a split prompt.

**Split prompt** — use `AskUserQuestion`:
- `header: "Multi-concern problem"`
- `multiSelect: false`
- Options:
  1. `Split into separate problems (Recommended)` — description: "Create one problem ticket per distinct concern, with consecutive IDs. Each ticket gets its own priority, WSJF score, and fix path."
  2. `Keep as a single problem` — description: "Create one ticket covering all concerns. Use this only if the concerns are so tightly coupled that they cannot be fixed independently."

**Non-interactive fallback**: When `AskUserQuestion` is unavailable (e.g., non-interactive/AFK mode), automatically split into separate problems and note the auto-split in output. Do not block creation.

**Split implementation**: When splitting, assign consecutive IDs (e.g., if next ID is 035, create P035 and P036). Create each problem file independently. Cross-reference each ticket in the other's "Related" section.

**Scope**: This step applies only to **new problem creation** (steps 2–5). It does NOT apply to updates, status transitions, or reviews of existing tickets.

### 5. For new problems: Write the problem file

**File path**: `docs/problems/<NNN>-<kebab-case-title>.open.md`

**Template**:

```markdown
# Problem <NNN>: <Title>

**Status**: Open
**Reported**: <YYYY-MM-DD>
**Priority**: <score> (<label>) — Impact: <label> (<n>) x Likelihood: <label> (<n>)

## Description

<description>

## Symptoms

<bullet list of observable symptoms>

## Workaround

<workaround or "None identified yet.">

## Impact Assessment

- **Who is affected**: <personas>
- **Frequency**: <when/how often>
- **Severity**: <High/Medium/Low — reason>
- **Analytics**: <data source or N/A>

## Root Cause Analysis

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test
- [ ] Create INVEST story for permanent fix

## Related

<links to related files, problems, ADRs>
```

### 6. For updates: Edit the existing file

Find the file matching the problem ID:
```bash
ls docs/problems/<NNN>-*.md 2>/dev/null
```

Apply the update — this could be:
- Adding root cause evidence to the "Root Cause Analysis" section
- Checking off investigation tasks
- Adding a "Fix Strategy" section
- Adding "Related" links
- Updating priority based on new information

### 7. For status transitions

**Open → Known Error** (rename file, update content):

Known Error means "root cause confirmed, fix path clear, fix NOT yet released" (per ADR-022). Releasing the fix is a separate Known Error → Verification Pending transition — do NOT stay on `.known-error.md` after the fix ships.

Pre-flight checks before allowing transition:
- [ ] Root cause is documented (not just "Preliminary Hypothesis")
- [ ] At least one investigation task is checked off
- [ ] A reproduction test exists or is referenced
- [ ] A workaround is documented (even if "feature disabled")
- [ ] Effort bucket re-rated against the now-documented fix strategy; if the bucket changed since creation, update the Effort / WSJF lines and note the reason (P047 — creation-time estimates drift as scope clarifies)

If any check fails, report which checks failed and ask the user to address them before transitioning.

```bash
git mv docs/problems/<NNN>-<title>.open.md docs/problems/<NNN>-<title>.known-error.md
```

Update the "Status" field in the file to "Known Error".

**Known Error → Verification Pending** (fix released, per ADR-022):

When the fix for a Known Error ships, transition the ticket in a single commit:

```bash
git mv docs/problems/<NNN>-<title>.known-error.md docs/problems/<NNN>-<title>.verifying.md
```

Then edit the file:
- Update the "Status" field to "Verification Pending"
- Add a `## Fix Released` section with: release marker (version, commit SHA, or date), one-sentence fix summary, "Awaiting user verification" line, and any exercise evidence from the releasing session.

Both the `git mv` and the file edits belong in the same commit as the fix implementation per ADR-014 (governance skills commit their own work). The `.verifying.md` suffix signals to every downstream consumer (work-problems classifier, review step 9d, README rendering) that the remaining work is user-side verification — no file-body scan needed.

**Verification Pending → Closed** (user confirms):

Only the user can make this call. When they explicitly confirm the fix works in production:

```bash
git mv docs/problems/<NNN>-<title>.verifying.md docs/problems/<NNN>-<title>.closed.md
```

Update the "Status" field to "Closed". Reference the problem ID in the closure commit message (e.g., "Closes P008"). Step 9d's verification prompt is the structured path that fires this transition during `manage-problem review`.

### 8. For list: Show summary

Read all `.open.md` and `.known-error.md` files in `docs/problems/`. Extract ID, title, priority, and status. Sort by priority (highest first). Display as a markdown table.

### 9. For review: Re-assess all open problems

This is a batch operation that reviews every open/known-error problem and updates it.

**Fast-path for `work` (skip full re-scan when cache is fresh):**

Before running the full review, check whether `docs/problems/README.md` exists and is up to date using **git history** (not filesystem mtime, which is unreliable in worktrees and fresh checkouts — see P031):

```bash
readme_commit=$(git log -1 --format=%H -- docs/problems/README.md 2>/dev/null)
# Cache is stale if: no README commit, OR problem files committed since README, OR uncommitted problem file changes
if [ -z "$readme_commit" ] || \
   git log --oneline "${readme_commit}..HEAD" -- 'docs/problems/*.md' ':!docs/problems/README.md' 2>/dev/null | grep -q .; then
  echo "stale"
fi
```

If the command produces **no output** (no problem files have been committed or modified since the last README.md update), the cache is fresh:
- Read `docs/problems/README.md` only — it contains the ranked table from the last review
- Skip steps 9a–9b entirely
- Proceed to step 9c (work selection) using the cached table
- **Step 9d always fires even on the fast-path cache hit** (P048 Candidate 1): the verification prompt surface must not depend on whether the cache is fresh — pending verifications accumulate across sessions and the user expects the prompts to appear on every `review`. Skipping 9d alongside 9a–9b would suppress verification prompts whenever the cache is fresh, which is exactly when the user is most likely to verify.
- Note in the output: "Using cached ranking from [timestamp in README.md]"

If the command prints "stale", or `README.md` does not exist in git, run the full review (steps 9a–9e) and refresh the cache.

**Step 9a: Read the risk framework**

Read `RISK-POLICY.md` to get the current impact levels (1-5), likelihood levels (1-5), risk matrix, and label bands. These are the authoritative definitions — do not use outdated scales.

**Step 9b: For each open/known-error problem (skip `.parked.md` and `.verifying.md` files entirely):**

Parked problems and Verification Pending problems are excluded from WSJF ranking — do not read, score, or update them in this step. Parked tickets are shown in a dedicated Parked section in step 9c; Verification Pending tickets are shown in a dedicated Verification Queue section in step 9c (ranked by release age, not WSJF — per ADR-022).

1. Read the problem file
2. Read the codebase context — check if the problem's root cause has been investigated, if there are related fixes in git history, or if the problem is stale
3. **Re-assess Impact** (1-5) using the product-specific impact levels from RISK-POLICY.md. Ask: "If this problem occurs during a live game, what is the worst business consequence?"
4. **Re-assess Likelihood** (1-5) using the likelihood levels from RISK-POLICY.md. Ask: "Given the current codebase, how likely is this to affect the user?"
5. **Calculate Severity** = Impact × Likelihood
6. **Look up Label** from the risk matrix label bands
7. **Re-estimate Effort** (S / M / L / XL) by reading the root cause analysis and fix strategy. Consider: how many files, how complex, does it need planning, is it cross-package or migration-heavy (XL territory)? If the bucket has changed since last review, update the Effort line in the problem file and note the reason in a short parenthetical (e.g. "L → XL — architect review added ADR + migration script"). P047.
8. **Calculate WSJF** = (Severity × Status Multiplier) / Effort Divisor
9. **Update the Priority line** in the problem file if the score changed
10. **Auto-transition to Known Error**: If an open problem has confirmed root cause AND a workaround documented (even "feature disabled"), automatically transition it to known-error:
    - `git mv docs/problems/<NNN>-<title>.open.md docs/problems/<NNN>-<title>.known-error.md`
    - Update the Status field to "Known Error"
    - This happens automatically — do not ask the user

**Step 9c: Present summary and select problem to work**

After reviewing all problems, present a WSJF-ranked table for open/known-error problems (the main dev-work queue):

| WSJF | ID | Title | Severity | Status | Effort | Notes |
|------|-----|-------|----------|--------|--------|-------|

Then present a separate **Verification Queue** section for `.verifying.md` files (per ADR-022 — ranked by release age, oldest first; no WSJF because the multiplier is 0). Highlight each ticket whose release age is **≥ 14 days** (the within-skill default per P048 Candidate 4 — tunable; if it needs cross-skill consistency later, promote to policy) with a `likely verified` marker in the final column. This makes the Verification Queue not just a list but a ranked view of which verifications are most likely ready to close:

| ID | Title | Released | Fix summary | Likely verified? |
|----|-------|----------|-------------|------------------|

The `Likely verified?` column takes values:
- `yes (N days)` — release age ≥ 14 days; the user is unlikely to revert a landed fix after this long. Surface these first in step 9d's verification prompt so the user can batch-close them.
- `no (N days)` — release age < 14 days; may still be in validation. Fire step 9d for these too, but without the highlight.

Then present a separate **Parked** section listing `.parked.md` files (no ranking):

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|

Highlight:
- Problems whose priority changed (↑ or ↓)
- Problems that were auto-transitioned to known-error
- Problems that may be stale (reported > 2 weeks ago with no investigation progress)
- Problems that have been fixed but not closed (check git history for fix commits)
- Verification Pending tickets whose fix has been exercised repeatedly without regression (P048 detection layer — candidate for closure verification)

**When the operation is `work` (not just `review`), select the problem to work using `AskUserQuestion`:**

- If one problem has a strictly higher WSJF than all others, present it as the recommended option:
  - Option 1: `Work P<NNN>: <title> (Recommended)` — with description showing WSJF score and status
  - Option 2: `Pick a different problem` — let the user name a specific ID
- If two or more problems tie for the highest WSJF, present the tied problems as options:
  - One option per tied problem: `Work P<NNN>: <title>` — with description showing WSJF and a one-line rationale for why this one
  - Final option: `Pick a different problem`
- Use `header: "Next problem"` and `multiSelect: false`

**Never present the selection as prose "(a)/(b)/(c)" or "which would you like?"** — always use `AskUserQuestion` so the decision is structured and auditable.

**Step 9d: Check for pending verifications**

Target `docs/problems/*.verifying.md` via glob — do NOT scan `.known-error.md` bodies for a `## Fix Released` section (per ADR-022, Verification Pending is a first-class status, not a substring marker). For each `.verifying.md` file, use `AskUserQuestion` to ask the user if the fix has been verified in production. The question MUST include a fix summary extracted from the `## Fix Released` section — include the first sentence (or first bullet list) of that section in the question body or as the option description, so the user can answer without reading the full problem file. Do not ask with only the problem ID + title + version. If the user confirms, close the problem (`git mv` from `.verifying.md` to `.closed.md`, update Status). If the user says no or is unsure, leave it as Verification Pending.

**Step 9e: Update files and refresh README.md cache**

Edit each problem file where the priority changed. Then write/overwrite `docs/problems/README.md` with the current ranked table so future `work` invocations can skip the full re-scan:

```markdown
# Problem Backlog

> Last reviewed: <ISO timestamp>
> Run `/wr-itil:manage-problem review` to refresh.

## WSJF Rankings

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| <score> | P<NNN> | <title> | <severity> | <status> | <effort> |
...

## Verification Queue

Fix released, awaiting user verification (driven off `docs/problems/*.verifying.md` via glob — per ADR-022). Ranked by release age, oldest first:

| ID | Title | Released | Fix summary |
|----|-------|----------|-------------|
| P<NNN> | <title> | <release marker> | <one-sentence fix summary> |
...

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P<NNN> | <title> | <reason> | <date> |
...
```

Then commit all changed files per ADR-014:
1. `git add` the changed problem files and `docs/problems/README.md`
2. Satisfy the commit gate — two paths are valid (either produces a bypass marker):
   - **Primary**: delegate to the `wr-risk-scorer:pipeline` subagent-type via the Agent tool
   - **Fallback**: if the `wr-risk-scorer:pipeline` subagent-type is not available in the current tool set (e.g., this skill is itself running inside a spawned subagent), invoke the `/wr-risk-scorer:assess-release` skill via the Skill tool. Per ADR-015 it wraps the same pipeline subagent and produces an equivalent bypass marker via the `PostToolUse:Agent` hook. Do not silently skip the gate because the primary path is unavailable — the fallback exists specifically to close this gap (see P035).
3. `git commit -m "docs(problems): review — re-rank priorities"`

If `AskUserQuestion` is unavailable and risk is above appetite, skip the commit and report the uncommitted state (ADR-013 Rule 6 fail-safe). This applies only to the risk-above-appetite branch, not to the delegation-unavailable case above.

### 10. Quality checks

After creating or updating a problem file, verify:

- **ID uniqueness**: No duplicate IDs in `docs/problems/`
- **Naming convention**: File matches `<NNN>-<kebab-case>.<status>.md`
- **Required sections**: Description, Impact Assessment, and Investigation Tasks exist
- **Priority calculation**: Score = Impact × Likelihood, label matches score
- **No orphaned references**: If the problem references other problems by number, verify those files exist
- **Status consistency**: The Status field in the frontmatter matches the filename suffix

**Priority label mapping**: Read the label bands from `RISK-POLICY.md` — do not hardcode them here.

### 11. Report

After any operation, report:
- The file path created/modified
- The problem ID and title
- The current status
- Any quality check warnings

Commit the completed work per ADR-014 (governance skills commit their own work):
1. `git add` all created/modified files for this operation
2. Satisfy the commit gate — two paths are valid (either produces a bypass marker):
   - **Primary**: delegate to the `wr-risk-scorer:pipeline` subagent-type via the Agent tool (subagent_type: `wr-risk-scorer:pipeline`)
   - **Fallback**: if the `wr-risk-scorer:pipeline` subagent-type is not available in the current tool set (e.g., this skill is itself running inside a spawned subagent), invoke the `/wr-risk-scorer:assess-release` skill via the Skill tool. Per ADR-015 it wraps the same pipeline subagent and the `PostToolUse:Agent` hook writes an equivalent bypass marker. Do not silently skip the gate because the primary path is unavailable — the fallback exists specifically to close this gap (see P035).
3. `git commit -m "<message>"` using the convention for the operation type:
   - New problem: `docs(problems): open P<NNN> <title>`
   - Known Error transition: `docs(problems): P<NNN> known error — <root cause summary>`
   - Verification Pending transition: usually folded into the `fix(<scope>): ... (closes P<NNN>)` commit that ships the fix — the `git mv` to `.verifying.md` and the `## Fix Released` section land together. If transitioning without a fix commit, use `docs(problems): P<NNN> verification pending — <release marker>`.
   - Problem closed: `docs(problems): close P<NNN> <title>`
   - Review/re-rank: `docs(problems): review — re-rank priorities`
   - Fix implemented: `fix(<scope>): <description> (closes P<NNN>)` — include problem file changes (rename to `.verifying.md` + `## Fix Released` section) in the same commit per ADR-022
4. If risk is above appetite: use `AskUserQuestion` to ask whether to commit anyway, remediate first, or park the work. If `AskUserQuestion` is unavailable, skip the commit and report the uncommitted state clearly (ADR-013 Rule 6 fail-safe). This applies only to the risk-above-appetite branch, not to the delegation-unavailable case above.

### 12. Auto-release when changesets are queued (ADR-020)

**Skip this step if the skill is running inside an AFK orchestrator** (e.g. `/wr-itil:work-problems`). Orchestrators handle release cadence themselves per ADR-018 (Step 6.5). Detect via the presence of an orchestrator marker in the invoking prompt — look for phrases like "AFK", "work-problems", "batch-work", or the sentinel `ALL_DONE` convention. When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in step 11 lands, drain the release queue so the fix actually lands on npm without requiring manual user action.

**Mechanism — delegate, do not re-implement scoring (per ADR-015):**

1. Invoke the release scorer. Two paths are valid:
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool. The skill wraps the same pipeline subagent.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line.
3. **Drain condition**: if `push` and `release` are both within appetite (≤ 4/25, "Low" band per `RISK-POLICY.md`), AND `.changeset/` is non-empty, proceed to the drain action. Otherwise, skip the drain and report the unreleased state.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` remains non-empty after push (i.e. a release PR is pending), run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Report the release: "Released <package>@<version>. Fix is now live on npm."

**Failure handling**: If `release:watch` fails (CI failure, publish failure), stop and report the failure clearly. Do not retry non-interactively — the user must intervene.

**Above-appetite branch**: If push/release risk is above appetite, skip the drain and report: "Release skipped — risk above appetite. Run `npm run push:watch` and `npm run release:watch` manually when ready."

`push:watch` and `release:watch` are policy-authorised actions when residual risk is within appetite per RISK-POLICY.md, so no `AskUserQuestion` is required for the drain itself (ADR-013 Rule 6).

$ARGUMENTS
