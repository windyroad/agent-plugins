---
name: wr-itil:work-problem
description: Pick the highest-WSJF open or known-error problem ticket and work it — investigate, implement, commit, and release per the standard manage-problem workflow. Selection is framework-mediated (WSJF + documented tie-break ladder per ADR-044); singular variant; distinct from /wr-itil:work-problems (plural AFK orchestrator). Use this when the user asks to "work the next problem", "work the top of the queue", or "grind through one ticket".
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent
---

# Work Problem — Pick-and-Run

Pick the highest-WSJF ticket from the current backlog and work it end-to-end. This is the **singular** entry point — one ticket per invocation. Selection is **framework-mediated** per ADR-044's Framework-Mediated Surface (Prioritisation row): the agent applies the WSJF formula + documented tie-break ladder mechanically and reports the chosen ticket + the rung that decided. The user retains direct override via `/wr-itil:work-problem <NNN>` invocation and via mid-flow correction (ADR-044 category 6).

This skill is the P071 phased-landing split of `/wr-itil:manage-problem work` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The original `/wr-itil:manage-problem work` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Name distinction (work-problem vs work-problems)

- **`/wr-itil:work-problem`** (singular, this skill) — one ticket per invocation. Framework-mediated selection (WSJF + tie-break ladder). Intended for a user who wants to dispatch the next-highest ticket and then stop. User-override path: `/wr-itil:work-problem <NNN>` to pin a specific ticket.
- **`/wr-itil:work-problems`** (plural, AFK orchestrator) — loops through the backlog by WSJF, delegating each iteration to this skill (via the Agent tool, per ADR-032 + P077). Intended for AFK batch runs; non-interactive selection; stops only when nothing actionable remains.

Both names coexist intentionally per P071's out-of-scope note on the naming coexistence. The plural orchestrator uses this skill as its per-iteration unit.

## Scope

**In scope:**
- Read `docs/problems/README.md` when fresh; otherwise delegate the refresh to `/wr-itil:review-problems` first (never re-implement the re-scoring logic locally — same anti-fork discipline as the list-problems cache path).
- Pick the highest-WSJF ticket via the framework-mediated tie-break ladder (Known Error > Open; smaller effort first; older reported date; ticket number ascending) per ADR-044 Framework-Mediated Surface. Report the chosen ticket + the rung that decided. No `AskUserQuestion` fires for selection.
- Honour the user-override path `/wr-itil:work-problem <NNN>` — when the user names a ticket directly, skip the ladder and proceed to Step 3 with the named ticket.
- Delegate the actual work to `/wr-itil:manage-problem <NNN>` via the Skill tool so the investigation / known-error transition / fix / closure flow stays hosted on a single authoritative workflow (ADR-010 thin-router discipline applied to the work path).
- Scope-expansion prompt (ADR-013 Rule 1; ADR-044 category-2 deviation-approval surface) when the selected ticket's effort grows during work — same three-option structure as `/wr-itil:manage-problem`'s Working a Problem section.

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

### 2. Select the ticket (framework-mediated)

Read the WSJF Rankings table from the now-fresh `docs/problems/README.md`. Apply the framework's tie-break ladder mechanically to pick the next ticket — selection is **framework-mediated** per ADR-044's Framework-Mediated Surface (Prioritisation row). The agent picks, reports the choice + the tie-break rung that decided, and proceeds. **No `AskUserQuestion` fires for selection** — the WSJF formula + tie-break ladder already resolve the decision.

**User-override path** — when the user invokes `/wr-itil:work-problem <NNN>` (ticket ID supplied as an argument, e.g. `/wr-itil:work-problem 042`), skip the ladder entirely and proceed to Step 3 with the named ticket. This is the documented escape hatch for the user to bypass the framework-mediated selection. Mid-flow correction (ADR-044 category 6 / P078 surface) is the long-tail catcher when the agent's pick was wrong in a way the framework couldn't anticipate.

**Tie-break ladder** (applied in order; same logic the plural orchestrator's Step 3 uses, per P077 + ADR-044):

1. **WSJF score** (descending) — highest WSJF wins.
2. **Status** — Known Error before Open. Verification Pending tickets are not in this queue (handled by `/wr-itil:review-problems` Step 4 verification prompt).
3. **Effort** — smaller effort first (S < M < L < XL).
4. **Reported date** — older reported date wins (FIFO discipline for tied tickets at this rung).
5. **Ticket number** — ascending (final deterministic break).

When a single ticket is the strict top, rungs 2-5 are not consulted. When multiple tickets are tied at the top, walk down the ladder until a rung decides.

**Report shape (JTBD-201 audit-trail)** — after picking, the agent reports the chosen ticket + the rung that decided, with citations to the WSJF inputs. Example: *"Selected P042: <title> (WSJF 12.0; tied with P057 at WSJF; tie-break rung: 'Known Error > Open' — P042 is Known Error, P057 is Open)"*. This citation makes the selection reproducible from the README state at the time of the report and is the audit surface JTBD-201 requires.

**No prose-ask fallback** — never present the selection as prose "(a)/(b)/(c)" or "which would you like?" (regression guard for ADR-013 Confirmation grep). Selection is mechanical; the agent picks and reports.

**No AFK / interactive split** — selection is mechanical in both interactive and AFK modes. The prior asymmetry between AFK (mechanical) and interactive (`AskUserQuestion`-driven) was the lazy-deferral surface ADR-044 was written to close; converging both modes to the same algorithm is the alignment. The plural orchestrator (`/wr-itil:work-problems`) Step 3 also uses this ladder, so all entry surfaces resolve to one selection algorithm (no AFK-vs-interactive divergence to maintain).

### 3. Delegate the work to `/wr-itil:manage-problem <NNN>`

Invoke `/wr-itil:manage-problem <NNN>` via the Skill tool with the selected ticket's ID as the argument. The delegated skill runs the full Working a Problem flow appropriate to the ticket's status:

- **Open ticket**: investigate root cause; document findings; create reproduction test; identify workaround; auto-transition to Known Error when root cause + workaround are documented; if the fix is small, proceed straight into implementation.
- **Known Error**: read the root cause analysis; implement the fix following the project's standard workflow (plan if needed, architect review, tests, changeset); include the Known Error → Verification Pending `git mv` in the fix commit per ADR-022.

**Why delegate rather than re-implement:** the full investigation / transition / fix / release pipeline is a long-lived, policy-governed flow that must stay on a single authoritative workflow. Re-hosting it on a sibling skill would fork the ownership contract and compound maintenance cost. The split skill (this file) owns the *selection* of the next ticket; `/wr-itil:manage-problem <NNN>` owns the *execution*.

### 4. Scope-expansion check (ADR-013 Rule 1; ADR-044 category-2 deviation-approval)

If the delegated `/wr-itil:manage-problem <NNN>` reports that the ticket's effort expanded during investigation or architect review (e.g. S → L, or L → XL), fire the standard scope-change `AskUserQuestion` prompt. **Effort growth IS the contradicting evidence** against the WSJF score that ranked this ticket at the top — this is the ADR-044 **category-2 (deviation-approval)** surface. The 3-option vocabulary below is the work-item-tactical analog of the framework-tactical 5-option vocabulary (Approve+amend / Approve+supersede / Approve+one-time / Reject / Defer); the user is the right authority for the shape, so the `AskUserQuestion` is genuine, not lazy.

- Option 1: `Continue with expanded scope` — keep working this ticket at its new size.
- Option 2: `Update problem and re-rank` — save findings to the problem file, re-score WSJF, and re-run the framework-mediated selection to surface the new top of queue.
- Option 3: `Pick a different problem` — park this one and work something else.

Use `header: "Scope change"` and `multiSelect: false`. This is the same structure `/wr-itil:manage-problem`'s Working a Problem section documents; the split lifts it without modification.

**AFK / non-interactive branch (ADR-013 Rule 6)**: same fallback as `/wr-itil:work-problems` — save findings + the new Effort/WSJF lines to the ticket file and skip to the next iteration. The orchestrator owns the re-selection loop.

### 5. Post-work housekeeping

After the delegated `/wr-itil:manage-problem <NNN>` completes:

1. If the ticket status changed (Open → Known Error, Known Error → Verification Pending), the delegated skill already committed the change per ADR-014 + ADR-022 and updated `docs/problems/README.md` per P062. This skill does NOT re-commit or re-refresh; it reports what happened.
2. Report the outcome: ticket ID, action taken (investigated / transitioned / fix-released), commit SHA(s), and next-recommended action (typically "run `/wr-itil:work-problem` again for the next ticket" or "stop — all actionable tickets worked").
3. **Do NOT loop automatically.** This is the singular skill. If the user wants to continue, they invoke `/wr-itil:work-problem` again, or switch to `/wr-itil:work-problems` (plural) for the AFK orchestrator loop.

## Ownership boundary

`work-problem` (singular) owns:
- Reading the WSJF Rankings from `docs/problems/README.md`.
- Applying the framework-mediated tie-break ladder for selection (ADR-044 Prioritisation row).
- Reporting the chosen ticket + the tie-break rung that decided (JTBD-201 audit-trail).
- Honouring the user-override path `/wr-itil:work-problem <NNN>` (skip the ladder; proceed with the named ticket).
- Delegating one execution iteration to `/wr-itil:manage-problem <NNN>`.
- Firing the scope-expansion `AskUserQuestion` on effort drift (ADR-044 category-2 deviation-approval surface).

`work-problem` does NOT:
- Fire `AskUserQuestion` for the ticket selection itself — selection is framework-mediated per ADR-044.
- Refresh the README.md cache directly — defers to `/wr-itil:review-problems`.
- Loop over multiple tickets — that's `/wr-itil:work-problems` (plural).
- Commit the ranking refresh or the per-ticket work — delegated skills commit per ADR-014.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is phase 3 of the P071 phased-landing plan (list-problems was phase 1; review-problems was phase 2).
- **P136** (`docs/problems/136-adr-044-alignment-audit-master.open.md`) — ADR-044 alignment audit master; this skill is the Phase 2 first audit target (work-problem singular).
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-013 amended** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 amended in P135 to defer to ADR-044 for framework-resolution boundary. Step 4 scope-expansion is the only Rule-1 surface this skill retains; Rule 6 covers Step 4's AFK fallback.
- **ADR-044** (`docs/decisions/044-decision-delegation-contract.proposed.md`) — Decision-Delegation Contract; this skill's Step 2 selection is framework-mediated per the ADR's Prioritisation row. Step 4 scope-expansion is a category-2 (deviation-approval) surface per the ADR's 6-class taxonomy.
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
