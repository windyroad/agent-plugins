---
name: wr-itil:transition-problem
description: Advance a problem ticket's lifecycle status — Open → Known Error, Known Error → Verification Pending (verifying), Verification Pending → Closed. Renames the ticket file, updates the Status field, and refreshes docs/problems/README.md in the same commit. Delegates the execution to /wr-itil:manage-problem so the pre-flight checks, P057 staging-trap handling, P063 external-root-cause detection, and P062 README refresh stay on a single authoritative workflow. Use when the user asks to "transition", "close", "mark known-error", or "release" a specific ticket.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

# Transition Problem — Lifecycle Advance

Advance a specific problem ticket along the ITIL lifecycle: Open → Known Error → Verification Pending → Closed. The skill is a **thin-router selection surface** — it identifies the ticket and the destination status, then delegates the actual transition execution to `/wr-itil:manage-problem <NNN>` (which hosts the authoritative Step 7 transition block). This preserves the single-workflow ownership of the pre-flight checks, external-root-cause detection (P063), staging-trap handling (P057), and README.md refresh (P062).

This skill is phase 4 of the P071 phased-landing split of `/wr-itil:manage-problem <NNN> <status>` per ADR-010's amended Skill Granularity rule (one skill per distinct user intent). The original `/wr-itil:manage-problem <NNN> known-error` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Arguments

- `<NNN>` — the ticket ID (data parameter, e.g. `042`). Required.
- `<status>` — the destination status. One of:
  - `known-error` — Open → Known Error (root cause confirmed, fix path clear, fix not yet released).
  - `verifying` — Known Error → Verification Pending (fix released, awaiting user verification per ADR-022).
  - `close` — Verification Pending → Closed (user has confirmed the fix works in production).

The `<NNN>` and `<status>` tokens are **data parameters**, not word-subcommands. Per the P071 split rule (ADR-010 amended), data parameters (IDs, paths, URLs, enum destinations) are permitted; word-subcommands that name distinct user intents are not. This skill's argument shape is `data + data`, which is the same shape as `/wr-itil:report-upstream <NNN>`.

## Scope

**In scope:**
- Validate that the ticket file exists and the destination status is reachable from the current status (e.g. an `.open.md` file cannot transition directly to Verification Pending — it must go through Known Error first).
- Delegate the transition execution to `/wr-itil:manage-problem <NNN> <status>` via the Skill tool so the full Step 7 block runs (pre-flight checks, external-root-cause detection, file rename, Status field edit, staging re-stage per P057, README.md refresh per P062, commit per ADR-014).
- Report the outcome (new filename, new Status, commit SHA).

**Out of scope:**
- Re-implementing the Step 7 transition logic inline. Delegation to `/wr-itil:manage-problem` is the anti-fork discipline.
- Backlog re-ranking — that's `/wr-itil:review-problems`.
- Ticket creation or bare-update flows — that's `/wr-itil:manage-problem` (no-args form for creation, `<NNN>` bare for update).
- Parking a ticket — that's a distinct lifecycle move handled by `/wr-itil:manage-problem` directly (the `.parked.md` suffix has its own pre-flight path including P063 external-root-cause detection for `upstream-blocked` reasons).

## Steps

### 1. Parse the arguments

From `$ARGUMENTS`, extract the ticket ID (`<NNN>`, three digits) and the destination status (one of `known-error`, `verifying`, `close`). If either is missing or malformed, emit a usage message and stop:

```
Usage: /wr-itil:transition-problem <NNN> <status>
  <NNN>    — three-digit ticket ID (e.g. 042)
  <status> — one of: known-error, verifying, close
```

### 2. Discover the ticket file

Locate the ticket file by ID:

```bash
ls docs/problems/<NNN>-*.md 2>/dev/null
```

If no file is found, emit: `No ticket found for ID <NNN>` and stop.

If multiple files are found (should not happen — suffix-exclusive lifecycle), emit a warning and list the matches; stop and let the user resolve.

### 3. Validate the transition path

Check the current filename suffix and verify the destination status is reachable in one step:

| Current suffix | Destination argument | Valid? |
|----------------|----------------------|--------|
| `.open.md` | `known-error` | yes |
| `.known-error.md` | `verifying` | yes |
| `.verifying.md` | `close` | yes |
| any other pairing | — | no — emit an error and stop |

If the pairing is invalid, emit a clear message naming the current status, the requested destination, and the valid next step. Do not silently skip or auto-correct — invalid transitions are almost always user typos and a clear error is the cheapest recovery.

### 4. Delegate the transition to `/wr-itil:manage-problem <NNN> <status>`

Invoke `/wr-itil:manage-problem` via the Skill tool with the `<NNN> <status>` argument shape. The delegated skill runs its Step 7 transition block, which owns:

- **Pre-flight checks** — root cause documented, investigation tasks checked off, reproduction test referenced, workaround documented, effort re-rated (P047). Any missing check halts the transition with a specific error.
- **P063 external-root-cause detection** — fires on Open → Known Error (and on the `upstream-blocked` park path). If a strict-token hit appears in the Root Cause Analysis section, the prompt routes the user to `/wr-itil:report-upstream` or defers with a stable marker. The AFK fallback (per ADR-013 Rule 6) appends the deferred-report marker automatically.
- **Staging trap handling (P057)** — after `git mv` renames the file, the Edit tool writes the Status field and (for the `verifying` destination) the `## Fix Released` section. The re-stage (`git add <new>`) is explicit — without it the content edit leaks into the next commit and the audit trail breaks.
- **README.md refresh (P062)** — regenerates `docs/problems/README.md` in-place on every transition so the dev-work table, Verification Queue, and Parked section never lag the on-disk ticket inventory. The refresh joins the same commit as the rename + content edit.
- **Commit per ADR-014** — governance skills commit their own work. Transition commits use the conventions named in the delegated skill's Step 11 block.

**Why delegate rather than re-implement:** the Step 7 block is a policy-governed, multi-concern flow (pre-flight + P063 + P057 + P062 + ADR-014 commit). Re-hosting it on a sibling skill would fork the ownership contract and compound maintenance cost. The split skill (this file) owns the *selection* of ticket + destination; `/wr-itil:manage-problem` owns the *execution*.

### 5. AFK / non-interactive branch (ADR-013 Rule 6)

When this skill is invoked inside an AFK orchestrator (detect via `/wr-itil:work-problems` markers in the invoking prompt — phrases like "AFK", "work-problems", "batch-work", "ALL_DONE"), do NOT emit `AskUserQuestion`. The orchestrator has already selected the transition (commonly Known Error → Verification Pending as part of a release commit) and this skill runs the execution only. The P063 external-root-cause detection's AFK fallback is owned by the delegated `/wr-itil:manage-problem` Step 7 block; this skill inherits that behaviour without re-implementing it.

Interactive mode (no orchestrator markers): the skill proceeds through Steps 1–4 directly. If any pre-flight check fails inside the delegated skill, the delegation returns that error and this skill surfaces it verbatim.

### 6. Report the outcome

After the delegated `/wr-itil:manage-problem <NNN> <status>` completes:

1. Report: ticket ID, previous Status, new Status, new filename, commit SHA.
2. If the destination was `verifying`, name the `## Fix Released` section's release marker in the output so the user can correlate with the shipped version.
3. **Do NOT re-commit or re-refresh** — the delegated skill already committed the change per ADR-014 and refreshed the README per P062. Re-emitting either would break the single-commit audit trail.

## Ownership boundary

`transition-problem` owns:
- Argument parsing (`<NNN> <status>`).
- Ticket-file discovery via `ls docs/problems/<NNN>-*.md`.
- Destination-reachability validation (Open → Known Error → Verification Pending → Closed, one step at a time).
- Delegating one transition execution to `/wr-itil:manage-problem <NNN> <status>`.

`transition-problem` does NOT:
- Run the Step 7 transition block inline — delegates to `/wr-itil:manage-problem`.
- Fire the P063 external-root-cause detection prompt directly — delegated skill owns it.
- Refresh `docs/problems/README.md` directly — delegated skill owns the refresh per P062.
- Commit — delegated skill commits per ADR-014.
- Park tickets — the `.parked.md` suffix has its own path on `/wr-itil:manage-problem` (P063 AFK fallback fires there too).

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is phase 4 of the P071 phased-landing plan (list-problems was phase 1; review-problems was phase 2; work-problem was phase 3).
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 for interactive prompts; Rule 6 for the AFK non-interactive branch.
- **ADR-014** — governance skills commit their own work. The delegated `/wr-itil:manage-problem <NNN> <status>` owns the per-transition commit; this skill does not re-commit.
- **ADR-022** — `.verifying.md` suffix on release; Verification Pending is a first-class status distinct from Known Error. Known Error → Verification Pending is the most common transition this skill forwards.
- **ADR-032** — governance skill invocation patterns. `/wr-itil:work-problems` may delegate transition iterations to this skill during AFK release orchestration.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **P057** — `git mv` + Edit staging trap rationale; the delegated Step 7 block implements the re-stage. Named here as a transitive contract so callers can reason about the dependency.
- **P062** — `/wr-itil:review-problems` is the canonical README.md cache writer, but Step 7 transitions also refresh README.md in-place per P062's mechanism. Named here as a transitive contract.
- **P063** — external-root-cause detection at Open → Known Error and at the `upstream-blocked` park path. The delegated Step 7 block owns the prompt; this skill inherits the AFK fallback without re-implementing.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete. Users type `/wr-itil:transition-problem 042 known-error` rather than remembering the `manage-problem <NNN> known-error` subcommand.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- `packages/itil/skills/manage-problem/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-problem <NNN> known-error` form; also the delegated execution target for each transition.
- `packages/itil/skills/review-problems/SKILL.md` — sibling refresh skill; this skill's transitions trigger the same README.md regeneration mechanism P062 codifies.
- `packages/itil/skills/list-problems/SKILL.md` — sibling read-only display skill; same cache contract.
- `packages/itil/skills/work-problem/SKILL.md` — sibling selection skill; delegates per-ticket execution (including transitions) through `/wr-itil:manage-problem`.

$ARGUMENTS
