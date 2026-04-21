---
name: wr-itil:review-problems
description: Re-assess every open and known-error problem ticket in docs/problems/ — re-read RISK-POLICY.md, re-rate Impact × Likelihood, re-estimate Effort, recalculate WSJF, surface pending verifications, auto-transition Open → Known Error where warranted, and rewrite docs/problems/README.md with the refreshed ranking. Writes to problem files and the README cache; commits the refresh per ADR-014.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

# Review Problems

Re-assess the problem backlog. This skill is a **batch operation** that reads every `.open.md` and `.known-error.md` ticket in `docs/problems/`, re-scores each against the current `RISK-POLICY.md`, re-estimates Effort against the current fix-strategy documentation, recalculates WSJF, auto-transitions Open tickets to Known Error when root cause + workaround are documented, fires the Verification Queue prompt for `.verifying.md` tickets, and rewrites `docs/problems/README.md` so downstream fast-paths (`list-problems` cache-hit, `work-problem` fast-path) see a fresh ranked view.

This skill is the P071 phased-landing split of `/wr-itil:manage-problem review` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The original `/wr-itil:manage-problem review` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Scope

**In scope:**
- `docs/problems/*.open.md` and `docs/problems/*.known-error.md` — re-scored (Impact × Likelihood × Effort → WSJF); Priority + Effort + WSJF lines updated when they change.
- `docs/problems/*.verifying.md` — surfaced in the Verification Queue and fed to Step 4's verification prompt (Known Error → Closed path when the user confirms).
- `docs/problems/*.parked.md` — listed in the Parked section; NOT re-scored (WSJF multiplier is 0).
- `docs/problems/README.md` — rewritten with the refreshed WSJF Rankings + Verification Queue + Parked tables; staged and committed with the review.

**Out of scope:**
- Work selection — the review produces the ranking, but does NOT pick the next ticket to work. That's `/wr-itil:work-problem` (slice 3 of P071, singular interactive variant; distinct from `/wr-itil:work-problems` plural AFK orchestrator).
- Ticket creation — use `/wr-itil:manage-problem`.
- Status transitions other than the Open → Known Error auto-transition and the Verification Pending → Closed prompt — use `/wr-itil:manage-problem <NNN>` (or the future `/wr-itil:transition-problem` split once it lands in a later slice).
- `docs/problems/*.closed.md` — omitted from the ranking entirely (the review addresses the active backlog).

## Steps

### 1. Read the risk framework

Read `RISK-POLICY.md` to get the current Impact levels (1-5), Likelihood levels (1-5), risk matrix, and label bands. These are the authoritative definitions — do not hardcode a scale.

### 2. Re-score every open / known-error ticket

For each `docs/problems/*.open.md` and `docs/problems/*.known-error.md` file (skip `.parked.md` and `.verifying.md` files entirely — their WSJF multiplier is 0 and they have dedicated sections in Step 3):

1. Read the problem file.
2. Read the codebase context — check if the root cause has been investigated since the last review, whether there are related fixes in git history, or whether the problem is stale.
3. **Re-assess Impact (1-5)** using the product-specific impact levels from `RISK-POLICY.md`. Ask: "If this problem occurs in production, what is the worst business consequence?"
4. **Re-assess Likelihood (1-5)** using the likelihood levels from `RISK-POLICY.md`. Ask: "Given the current codebase, how likely is this to affect the user?"
5. **Calculate Severity** = Impact × Likelihood.
6. **Look up Label** from the risk matrix label bands.
7. **Re-estimate Effort** (S / M / L / XL) by reading the Root Cause Analysis and Candidate Fix sections. Consider: how many files, how complex, does it need planning, is it cross-package or migration-heavy (XL territory)? If the bucket has changed since the last review, update the Effort line in the problem file and note the reason in a short parenthetical (e.g. "L → XL — architect review added ADR + migration script"). P047.
8. **Calculate WSJF** = (Severity × Status Multiplier) / Effort Divisor. Status Multiplier is 1.0 for Open, 2.0 for Known Error (per `/wr-itil:manage-problem`'s WSJF table — re-read if unsure).
9. **Update the Priority and WSJF lines** in the problem file if the scores changed.
10. **Auto-transition to Known Error** — if an open problem has confirmed root cause AND a workaround documented (even "feature disabled"), automatically transition it:
    - `git mv docs/problems/<NNN>-<title>.open.md docs/problems/<NNN>-<title>.known-error.md`
    - Update the Status field to "Known Error".
    - Re-stage explicitly per the P057 staging trap: `git add <new-path>` after the Edit.
    - This happens automatically — do not ask the user. The transition's fix-strategy is documented; only the shipping is outstanding.

### 3. Present the refreshed ranking

After re-scoring, present three sections matching the README.md format (same rendering used by `/wr-itil:list-problems` and by the README cache — Step 5 writes the same layout):

**WSJF Rankings** — dev-work queue (open + known-error), sorted by WSJF descending:

```
| WSJF | ID | Title | Severity | Status | Effort | Notes |
|------|-----|-------|----------|--------|--------|-------|
```

**Verification Queue** — `.verifying.md` tickets, sorted by release age (oldest first). Highlight any ticket whose release age is **≥ 14 days** with a `yes (N days)` marker in the `Likely verified?` column (within-skill default per P048 Candidate 4 — tunable; promote to cross-skill policy if needed):

```
| ID | Title | Released | Fix summary | Likely verified? |
|----|-------|----------|-------------|------------------|
```

**Parked** — `.parked.md` tickets (no ranking):

```
| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
```

Highlight:
- Problems whose priority changed (↑ or ↓ since the last review).
- Problems that were auto-transitioned to known-error in Step 2.
- Problems that may be stale (reported > 2 weeks ago with no investigation progress).
- Problems that have been fixed but not closed (check git history for fix commits referencing the problem ID).
- Verification Pending tickets whose fix has been exercised repeatedly without regression (P048 detection layer — candidate for closure verification; surface these first in Step 4).

Omit an empty section rather than rendering an empty header.

### 4. Verification prompt (Verification Pending → Closed)

Target `docs/problems/*.verifying.md` via glob — do NOT scan `.known-error.md` bodies for a `## Fix Released` section (per ADR-022, Verification Pending is a first-class status, not a substring marker). For each `.verifying.md` file, use `AskUserQuestion` to ask whether the fix has been verified in production.

The question MUST include a fix summary extracted from the `## Fix Released` section — include the first sentence (or first bullet list) of that section in the question body or as the option description, so the user can answer without reading the full problem file. Do NOT ask with only the problem ID + title + version.

- Surface the Step 3 `yes (N days)` tickets first so the user can batch-close them.
- If the user confirms: close the problem (`git mv` from `.verifying.md` to `.closed.md`, update Status to "Closed", re-stage per the P057 staging trap).
- If the user says no or is unsure: leave the ticket as Verification Pending.

**AFK / non-interactive branch (ADR-013 Rule 6):** when `AskUserQuestion` is unavailable, record the Verification Queue in the review output and skip the prompt. Do NOT auto-close verifying tickets — only the user can make that call. The user sees the queue on next interactive invocation.

### 5. Rewrite `docs/problems/README.md`

Write / overwrite `docs/problems/README.md` with the refreshed ranking so future `work-problem` / `list-problems` fast-paths can skip the full re-scan. Rendering rules match the SKILL.md `Present the refreshed ranking` section above — driven off globs, not file-body scans:

```markdown
# Problem Backlog

> Last reviewed: <ISO timestamp> — <one-line context about what changed>
> Run `/wr-itil:review-problems` to refresh WSJF rankings.

## WSJF Rankings

Dev-work queue only. Verification Pending (`.verifying.md`, WSJF multiplier 0) and Parked (`.parked.md`, multiplier 0) tickets are excluded per ADR-022 — surfaced in their own sections below.

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| <score> | P<NNN> | <title> | <severity> | <status> | <effort> |
...

## Verification Queue

Fix released, awaiting user verification (driven off `docs/problems/*.verifying.md` via glob per ADR-022). Ranked by release age, oldest first. `Likely verified?` column marks tickets ≥14 days old (P048 Candidate 4 default).

| ID | Title | Released | Likely verified? |
|----|-------|----------|------------------|
| P<NNN> | <title> | <release marker> | <yes (N days) / no (N days)> |
...

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P<NNN> | <title> | <reason> | <date> |
...
```

The "Last reviewed" parenthetical should name any meaningful state change in this refresh (auto-transitions fired, priority flips, newly-stale tickets) so the next session's fast-path has a human-readable audit marker alongside the git-history staleness test.

### 6. Commit the refresh

Commit all changed files per ADR-014 (governance skills commit their own work):

1. `git add` the changed problem files AND `docs/problems/README.md` AND any files renamed via `git mv` in Step 2's auto-transition branch (per the P057 staging trap — `git mv` alone stages only the rename, not the subsequent content edit; re-stage explicitly after each Edit).
2. Satisfy the commit gate — two paths are valid (either produces a bypass marker):
   - **Primary**: delegate to the `wr-risk-scorer:pipeline` subagent-type via the Agent tool.
   - **Fallback**: if the `wr-risk-scorer:pipeline` subagent-type is not available in the current tool set (e.g., this skill is itself running inside a spawned subagent), invoke the `/wr-risk-scorer:assess-release` skill via the Skill tool. Per ADR-015 it wraps the same pipeline subagent and produces an equivalent bypass marker via the `PostToolUse:Agent` hook. Do not silently skip the gate because the primary path is unavailable — the fallback exists specifically to close this gap (see P035).
3. `git commit -m "docs(problems): review — re-rank priorities"`

If `AskUserQuestion` is unavailable AND risk is above appetite, skip the commit and report the uncommitted state clearly (ADR-013 Rule 6 fail-safe). This applies only to the risk-above-appetite branch, not to the delegation-unavailable case above.

### 7. Auto-release when changesets are queued (ADR-020)

Skip this step if the skill is running inside an AFK orchestrator (e.g. `/wr-itil:work-problems`) — orchestrators handle release cadence themselves per ADR-018 (Step 6.5). Detect via orchestrator markers in the invoking prompt ("AFK", "work-problems", "batch-work", `ALL_DONE`). When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in Step 6 lands, drain the release queue per the mechanism documented in `/wr-itil:manage-problem` Step 12. Review commits typically score Very Low risk (doc-only), so the drain condition (push + release within appetite) is almost always satisfied.

## Ownership boundary

`review-problems` owns:
- Re-scoring the open / known-error backlog (writes Priority + Effort + WSJF lines on problem files).
- Auto-transitioning Open → Known Error when root cause + workaround are documented.
- Firing the Verification Queue prompt (Known Error → Closed via Verification Pending).
- Rewriting `docs/problems/README.md` — this is THE ownership point for the README cache. `list-problems` explicitly defers to this skill for the refresh.

`review-problems` does NOT:
- Pick the next ticket to work (that's `/wr-itil:work-problem`, singular).
- Create new tickets (that's `/wr-itil:manage-problem`).
- Transition tickets to Parked or implement fixes (those are dedicated transitions / fix commits — use `/wr-itil:manage-problem <NNN>` until `/wr-itil:transition-problem` lands).

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is phase 2 of the P071 phased-landing plan (list-problems was phase 1; work-problem singular is phase 3).
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-022** (`docs/decisions/022-verification-pending-status.proposed.md`) — Verification Pending status conventions; `.verifying.md` exclusion from WSJF ranking; Verification Queue rendering.
- **ADR-014** — governance skills commit their own work.
- **ADR-015** — governance skills delegate release scoring to the pipeline subagent / `assess-release` fallback.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **P031** — git-history freshness check rationale (mtime unreliable in worktrees). Applies to the README cache this skill owns.
- **P047** — live-estimate effort buckets; the Step 2 re-estimate is the lifecycle transition this ticket closes.
- **P048** Candidate 4 — the 14-day `Likely verified?` heuristic in Step 3.
- **P057** — staging trap. Step 2's auto-transition MUST re-stage after Edit.
- **P062** — README.md refresh on transitions. Step 5 is the review-path of the same refresh; `/wr-itil:manage-problem` Step 7 carries the transition-path.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- `packages/itil/skills/manage-problem/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-problem review` form.
- `packages/itil/skills/list-problems/SKILL.md` — sibling read-only display skill; defers the README refresh to this skill.

$ARGUMENTS
