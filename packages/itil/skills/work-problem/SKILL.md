---
name: wr-itil:work-problem
description: Pick the highest-WSJF open or known-error problem ticket and work it — investigate, implement, commit, and release per the standard manage-problem workflow. Interactive singular variant; distinct from /wr-itil:work-problems (plural AFK orchestrator). Use this when the user asks to "work the next problem", "work the top of the queue", or "grind through one ticket".
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent
---

# Work Problem — Pick-and-Run

Pick the highest-WSJF ticket from the current backlog and work it end-to-end. This is the **singular, interactive** entry point — one ticket per invocation, driven by an `AskUserQuestion` selection when the WSJF ranking is tied.

This skill is the P071 phased-landing split of `/wr-itil:manage-problem work` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The original `/wr-itil:manage-problem work` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Name distinction (work-problem vs work-problems)

- **`/wr-itil:work-problem`** (singular, this skill) — one ticket per invocation. Interactive `AskUserQuestion` selection. Intended for a user who wants to dispatch the next-highest ticket and then stop.
- **`/wr-itil:work-problems`** (plural, AFK orchestrator) — loops through the backlog by WSJF, delegating each iteration to this skill (via the Agent tool, per ADR-032 + P077). Intended for AFK batch runs; non-interactive selection; stops only when nothing actionable remains.

Both names coexist intentionally per P071's out-of-scope note on the naming coexistence. The plural orchestrator uses this skill as its per-iteration unit.

## Scope

**In scope:**
- Read `docs/problems/README.md` when fresh; otherwise delegate the refresh to `/wr-itil:review-problems` first (never re-implement the re-scoring logic locally — same anti-fork discipline as the list-problems cache path).
- Select the highest-WSJF ticket via `AskUserQuestion` (structured-interaction path per ADR-013 Rule 1). Present ties as peer options with per-option rationale.
- Delegate the actual work to `/wr-itil:manage-problem <NNN>` via the Skill tool so the investigation / known-error transition / fix / closure flow stays hosted on a single authoritative workflow (ADR-010 thin-router discipline applied to the work path).
- Scope-expansion prompt (ADR-013 Rule 1) when the selected ticket's effort grows during work — same three-option structure as `/wr-itil:manage-problem`'s Working a Problem section.

**Out of scope:**
- Batch looping over multiple tickets — that's `/wr-itil:work-problems` (plural). This skill runs exactly one ticket per invocation.
- Backlog re-ranking / Verification Queue prompt / README.md refresh — that's `/wr-itil:review-problems`. This skill reads the ranking; it does not rewrite it.
- Ticket creation — that's `/wr-itil:manage-problem` (no-args form).
- Status transitions other than those driven by the delegated `/wr-itil:manage-problem <NNN>` flow.

## Steps

### 1. Ensure the ranking is fresh

Check the `docs/problems/README.md` cache with the same git-history-based freshness test as `/wr-itil:list-problems` and `/wr-itil:review-problems` (per P031 — filesystem mtime is unreliable in worktrees and fresh checkouts, so git history is the authoritative staleness signal):

```bash
readme_commit=$(git log -1 --format=%H -- docs/problems/README.md 2>/dev/null)
if [ -z "$readme_commit" ] || \
   git log --oneline "${readme_commit}..HEAD" -- 'docs/problems/*.md' ':!docs/problems/README.md' 2>/dev/null | grep -q .; then
  echo "stale"
fi
```

- **Cache fresh** (no output): read `docs/problems/README.md` and use the cached WSJF Rankings table for Step 2.
- **Cache stale** (prints "stale") or `README.md` missing: **delegate to `/wr-itil:review-problems`** via the Skill tool to refresh the ranking before proceeding. Do NOT re-implement the re-scoring logic here — that would fork the review path and break P062's canonical-cache-writer contract. The review skill's Step 4 verification prompt runs on this refresh path (P048 Candidate 1: Verification Queue prompts always fire so pending verifications don't accumulate off-ledger).

### 2. Select the ticket

Read the WSJF Rankings table from the now-fresh `docs/problems/README.md`. Parse the top rows to find the highest-WSJF ticket(s).

**Selection via `AskUserQuestion`** (ADR-013 Rule 1 structured-interaction path):

- **Single top-WSJF ticket** (strictly higher than all others): present as the recommended option:
  - Option 1: `Work P<NNN>: <title> (Recommended)` — description shows WSJF score, Severity, and Status.
  - Option 2: `Pick a different problem` — user names a specific ID in the free-form response.
- **Tied top-WSJF tickets** (two or more tied for the highest WSJF): present each tied ticket as a peer option. Per-option description carries a one-line rationale naming the Status / Effort / concrete next action so the user can pick with context:
  - One option per tied ticket: `Work P<NNN>: <title>` — description: `WSJF <score> · <status> · <effort> · <one-line rationale>`.
  - Final option: `Pick a different problem`.
- Use `header: "Next problem"` and `multiSelect: false`.

**Never present the selection as prose "(a)/(b)/(c)" or "which would you like?"** — always use `AskUserQuestion` so the decision is structured and auditable. This is the same discipline `/wr-itil:manage-problem` Step 9c carries; the split lifts it verbatim.

**AFK / non-interactive branch (ADR-013 Rule 6)**: when this skill is invoked inside an AFK orchestrator (detect via `/wr-itil:work-problems` markers in the invoking prompt — phrases like "AFK", "work-problems", "batch-work", "ALL_DONE"), apply the within-day tiebreak per `/wr-itil:work-problems` Step 1c: Known Error > Open; smaller Effort; older reported date; ticket number ascending. Do NOT emit `AskUserQuestion` in AFK mode — the orchestrator has already selected the iteration and this skill runs the execution only.

### 3. Delegate the work to `/wr-itil:manage-problem <NNN>`

Invoke `/wr-itil:manage-problem <NNN>` via the Skill tool with the selected ticket's ID as the argument. The delegated skill runs the full Working a Problem flow appropriate to the ticket's status:

- **Open ticket**: investigate root cause; document findings; create reproduction test; identify workaround; auto-transition to Known Error when root cause + workaround are documented; if the fix is small, proceed straight into implementation.
- **Known Error**: read the root cause analysis; implement the fix following the project's standard workflow (plan if needed, architect review, tests, changeset); include the Known Error → Verification Pending `git mv` in the fix commit per ADR-022.

**Why delegate rather than re-implement:** the full investigation / transition / fix / release pipeline is a long-lived, policy-governed flow that must stay on a single authoritative workflow. Re-hosting it on a sibling skill would fork the ownership contract and compound maintenance cost. The split skill (this file) owns the *selection* of the next ticket; `/wr-itil:manage-problem <NNN>` owns the *execution*.

### 4. Scope-expansion check (ADR-013 Rule 1)

If the delegated `/wr-itil:manage-problem <NNN>` reports that the ticket's effort expanded during investigation or architect review (e.g. S → L, or L → XL), fire the standard scope-change `AskUserQuestion` prompt:

- Option 1: `Continue with expanded scope` — keep working this ticket at its new size.
- Option 2: `Update problem and re-rank` — save findings to the problem file, re-score WSJF, and re-run the work selection to let the user pick from the updated queue.
- Option 3: `Pick a different problem` — park this one and work something else.

Use `header: "Scope change"` and `multiSelect: false`. This is the same structure `/wr-itil:manage-problem`'s Working a Problem section documents; the split lifts it without modification.

**AFK / non-interactive branch**: same ADR-013 Rule 6 fallback as `/wr-itil:work-problems` — save findings + the new Effort/WSJF lines to the ticket file and skip to the next iteration. The orchestrator owns the re-selection loop.

### 5. Post-work housekeeping

After the delegated `/wr-itil:manage-problem <NNN>` completes:

1. If the ticket status changed (Open → Known Error, Known Error → Verification Pending), the delegated skill already committed the change per ADR-014 + ADR-022 and updated `docs/problems/README.md` per P062. This skill does NOT re-commit or re-refresh; it reports what happened.
2. Report the outcome: ticket ID, action taken (investigated / transitioned / fix-released), commit SHA(s), and next-recommended action (typically "run `/wr-itil:work-problem` again for the next ticket" or "stop — all actionable tickets worked").
3. **Do NOT loop automatically.** This is the singular skill. If the user wants to continue, they invoke `/wr-itil:work-problem` again, or switch to `/wr-itil:work-problems` (plural) for the AFK orchestrator loop.

## Ownership boundary

`work-problem` (singular) owns:
- Reading the WSJF Rankings from `docs/problems/README.md`.
- Firing the `AskUserQuestion` selection prompt (interactive mode).
- Delegating one execution iteration to `/wr-itil:manage-problem <NNN>`.
- Firing the scope-expansion `AskUserQuestion` on effort drift.

`work-problem` does NOT:
- Refresh the README.md cache directly — defers to `/wr-itil:review-problems`.
- Loop over multiple tickets — that's `/wr-itil:work-problems` (plural).
- Commit the ranking refresh or the per-ticket work — delegated skills commit per ADR-014.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is phase 3 of the P071 phased-landing plan (list-problems was phase 1; review-problems was phase 2).
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 for the interactive `AskUserQuestion` selection; Rule 6 for the AFK-orchestrator non-interactive branch.
- **ADR-014** — governance skills commit their own work. The delegated `/wr-itil:manage-problem <NNN>` owns the per-ticket commit; this skill does not re-commit.
- **ADR-018** — release cadence. AFK orchestrator owns release cadence; this skill does NOT auto-release.
- **ADR-032** — governance skill invocation patterns. `/wr-itil:work-problems` delegates iterations via the Agent tool; this singular skill is the canonical execution unit.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **P031** — git-history freshness check rationale (mtime unreliable in worktrees). Applies to the README cache this skill reads.
- **P062** — `/wr-itil:review-problems` is the canonical README.md cache writer. This skill defers to it for refreshes.
- **P077** — `/wr-itil:work-problems` Step 5 delegates iterations via the Agent tool. The delegated subagent invokes this skill's execution unit per iteration.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete. Users type `/wr-itil:work-problem` rather than remembering the `manage-problem work` subcommand.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- `packages/itil/skills/manage-problem/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-problem work` form; also the delegated execution target for each ticket.
- `packages/itil/skills/review-problems/SKILL.md` — sibling refresh skill; this skill defers to it when the cache is stale.
- `packages/itil/skills/list-problems/SKILL.md` — sibling read-only display skill; same cache read contract.
- `packages/itil/skills/work-problems/SKILL.md` — plural AFK orchestrator; uses this skill as its per-iteration execution unit.

$ARGUMENTS
