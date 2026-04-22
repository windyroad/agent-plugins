---
name: wr-itil:manage-incident
description: Declare, triage, mitigate, and close an incident using an evidence-first workflow. Restores service first, then hands off to manage-problem for root-cause work.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
deprecated-arguments: true
---

# Incident Management Skill

Declare, triage, mitigate, and close an incident using an evidence-first, cool-headed workflow. This skill's primary goal is **restoring service**. Once service is restored, the skill hands off to `wr-itil:manage-problem` so the underlying cause is tracked.

Incidents are time-bound events. Problems are persistent root causes. One problem can cause many incidents; one incident may (or may not) link to a problem.

## Operations

- **Declare**: `incident <title or symptoms>` — creates a new investigating incident
- **Update**: `incident <NNN> <details>` — append observations, evidence, or actions
- **Mitigate**: `incident <NNN> mitigate <action>` — record a mitigation attempt and outcome
- **Restore**: `incident <NNN> restored` — transition to `.restored.md` and trigger problem handoff
- **Close**: `incident <NNN> close` — only allowed when the linked problem is Known Error or Closed (or an explicit "no problem required" justification is recorded)
- **List**: `incident list` — active incidents, severity-sorted
- **Link**: `incident <NNN> link P<MMM>` — link an incident to an existing problem

## Lifecycle

| Status | File suffix | Meaning | Entry criteria |
|--------|-------------|---------|----------------|
| **Investigating** | `.investigating.md` | Symptoms reported, scope being established | Incident declared |
| **Mitigating** | `.mitigating.md` | Mitigation(s) in flight | At least one ranked hypothesis with cited evidence |
| **Restored** | `.restored.md` | Service verified restored | Mitigation applied + verification signal recorded |
| **Closed** | `.closed.md` | Incident complete | Linked problem is Known Error or Closed (or "no problem required" justification documented) |

## Evidence-First Workflow (The Cool-Headed Commitment)

During an incident, the instinct to jump to conclusions is strong. This skill forces evidence-first discipline via a required template. **Do not act on a hypothesis without at least one cited evidence source.**

### Required sections in every incident file

```markdown
## Observations
- [timestamp] <what was seen, from where — e.g. "14:02 UTC, 500s on /api/orders in Datadog dashboard foo">

## Hypotheses
- [ranked] <hypothesis> — Evidence: <log/repro/diff/metric reference>. Confidence: <low|med|high>.

## Mitigation attempts
- [timestamp] <action> → <outcome / verification signal>
```

### Mitigation preference

Prefer **reversible** mitigations over forward fixes:

1. Rollback to a known-good version
2. Feature flag off
3. Restart / cycle the affected component
4. Route traffic away
5. Scale up
6. Only after reversibles are exhausted: forward fix

Record every attempt, successful or not.

## Severity, not WSJF

Incidents are severity-driven and time-boxed. **WSJF does not apply to incidents** — the "effort" divisor is meaningless during a live event. WSJF applies to the resulting problem created via handoff.

Severity uses the Impact × Likelihood matrix from `RISK-POLICY.md`, interpreted as "right now, what's the live business impact?" — not "in general, how bad could this be?".

## Steps

### 1. Parse the request

Determine the operation from `$ARGUMENTS`:

- If arguments start with "list" → **delegate to `/wr-itil:list-incidents`** via the Skill tool. See "Deprecated-argument forwarders" below.
- If arguments match `<I###> mitigate <action>` → **delegate to `/wr-itil:mitigate-incident <I###> <action>`** via the Skill tool. See "Deprecated-argument forwarders" below.
- If arguments match `<I###> restored` → **delegate to `/wr-itil:restore-incident <I###>`** via the Skill tool. See "Deprecated-argument forwarders" below.
- If arguments match `<I###> close` → **delegate to `/wr-itil:close-incident <I###>`** via the Skill tool. See "Deprecated-argument forwarders" below.
- If arguments match `<I###> link P<MMM>` → **delegate to `/wr-itil:link-incident <I###> P<MMM>`** via the Skill tool. See "Deprecated-argument forwarders" below.
- If arguments start with `I<NNN>` or a bare number → this is an update
- Otherwise → declare a new incident

#### Deprecated-argument forwarders (ADR-010 amended + P071)

Per ADR-010's amended Skill Granularity section, word-argument subcommands that name distinct user intents are being split into their own named skills. During the deprecation window, this skill's Step 1 parser retains the legacy argument routes as **thin-router forwarders** that re-invoke the new named skill via the Skill tool AND emit a one-line systemMessage with the canonical deprecation notice so the user learns the new invocation shape.

**Forwarder for `list`** (P071 split slice 5 — new skill `/wr-itil:list-incidents`):

When `$ARGUMENTS` contains the word `list` as a top-level argument (not inside an incident body edit), delegate to `/wr-itil:list-incidents` via the Skill tool and emit this systemMessage verbatim:

> `/wr-itil:manage-incident list is deprecated; use /wr-itil:list-incidents directly. This forwarder will be removed in @windyroad/itil's next major version.`

The forwarder does NOT re-implement the list logic locally — it invokes the Skill tool with `wr-itil:list-incidents` and returns the new skill's output verbatim. Duplicating the scan logic would harden the deprecation window into a permanent fork.

**Forwarder for `<I###> mitigate <action>`** (P071 split slice 6a — new skill `/wr-itil:mitigate-incident`):

When `$ARGUMENTS` matches the shape `<I###> mitigate <action>` (an incident ID followed by the literal word `mitigate` followed by a free-text action), delegate to `/wr-itil:mitigate-incident <I###> <action>` via the Skill tool and emit this systemMessage verbatim:

> `/wr-itil:manage-incident <I###> mitigate <action> is deprecated; use /wr-itil:mitigate-incident <I###> <action> directly. This forwarder will be removed in @windyroad/itil's next major version.`

The forwarder does NOT re-implement the mitigation logic locally — it invokes the Skill tool with `wr-itil:mitigate-incident`, passes `<I###> <action>` through as the data parameters, and returns the new skill's output verbatim. Duplicating the rename + evidence-gate + timeline-append logic would harden the deprecation window into a permanent fork. The data-parameter shape `<I###> <action>` is permitted under ADR-010 amended — only the verb word `mitigate` is being split out.

**Forwarder for `<I###> restored`** (P071 split slice 6b — new skill `/wr-itil:restore-incident`):

When `$ARGUMENTS` matches the shape `<I###> restored` (an incident ID followed by the literal word `restored`), delegate to `/wr-itil:restore-incident <I###>` via the Skill tool and emit this systemMessage verbatim:

> `/wr-itil:manage-incident <I###> restored is deprecated; use /wr-itil:restore-incident <I###> directly. This forwarder will be removed in @windyroad/itil's next major version.`

The forwarder does NOT re-implement the restore logic locally — it invokes the Skill tool with `wr-itil:restore-incident`, passes `<I###>` through as the data parameter, and returns the new skill's output verbatim. Duplicating the rename + verification-signal prompt + manage-problem handoff logic would harden the deprecation window into a permanent fork.

**Forwarder for `<I###> close`** (P071 split slice 6c — new skill `/wr-itil:close-incident`):

When `$ARGUMENTS` matches the shape `<I###> close` (an incident ID followed by the literal word `close`), delegate to `/wr-itil:close-incident <I###>` via the Skill tool and emit this systemMessage verbatim:

> `/wr-itil:manage-incident <I###> close is deprecated; use /wr-itil:close-incident <I###> directly. This forwarder will be removed in @windyroad/itil's next major version.`

The forwarder does NOT re-implement the close logic locally — it invokes the Skill tool with `wr-itil:close-incident`, passes `<I###>` through as the data parameter, and returns the new skill's output verbatim. Duplicating the linked-problem gate + rename logic would harden the deprecation window into a permanent fork.

**Forwarder for `<I###> link P<MMM>`** (P071 split slice 6d — new skill `/wr-itil:link-incident`):

When `$ARGUMENTS` matches the shape `<I###> link P<MMM>` (an incident ID followed by the literal word `link` followed by a problem ID), delegate to `/wr-itil:link-incident <I###> P<MMM>` via the Skill tool and emit this systemMessage verbatim:

> `/wr-itil:manage-incident <I###> link P<MMM> is deprecated; use /wr-itil:link-incident <I###> P<MMM> directly. This forwarder will be removed in @windyroad/itil's next major version.`

The forwarder does NOT re-implement the link logic locally — it invokes the Skill tool with `wr-itil:link-incident`, passes `<I###> P<MMM>` through as the data parameters, and returns the new skill's output verbatim. Duplicating the problem-file-lookup + Linked Problem section write logic would harden the deprecation window into a permanent fork. The data-parameter shape `<I###> P<MMM>` is permitted under ADR-010 amended — only the verb word `link` is being split out.

### 2. For new incidents: Check for duplicates FIRST

Before creating, search `docs/incidents/` for active (non-closed) incidents with overlapping symptoms or scope. The user may already have an incident open for this outage.

1. Extract keywords from the description (e.g., "500 errors", "checkout", "login")
2. `grep -l` the keywords across `docs/incidents/*.{investigating,mitigating,restored}.md`
3. If matches are found, present them via `AskUserQuestion`:
   - "I found active incidents that may be related: I003 (checkout 500s, mitigating), I007 (login slowness, investigating). Would you like to (a) update an existing incident, (b) declare a new incident anyway, or (c) cancel?"
4. If the user chooses to update, switch to the update flow for that incident ID
5. If no matches, proceed to create

### 3. For new incidents: Assign the next ID

Create `docs/incidents/` if it does not exist. Then scan for the highest existing `I<NNN>` and increment:

```bash
mkdir -p docs/incidents
last=$(ls docs/incidents/I*.md 2>/dev/null | sed 's/.*\///' | grep -oE '^I[0-9]+' | sed 's/^I//' | sort -n | tail -1)
next=$(printf 'I%03d' $((10#${last:-0} + 1)))
echo "$next"
```

### 4. For new incidents: Gather information

Use `AskUserQuestion` for anything not in `$ARGUMENTS`:

- **Title**: short kebab-case-friendly description
- **Symptoms**: what is observable (errors, latency, missing data)?
- **Scope**: who/what is affected (users, endpoints, regions)?
- **Start time**: when did symptoms begin? (UTC, as precise as known)
- **Severity**: Impact (1-5) × Likelihood (1-5) per `RISK-POLICY.md`, interpreted as live impact

Do not ask for fields that can be inferred:

- **Reported**: today's date (UTC)
- **Status**: always "Investigating" for new incidents

### 5. For new incidents: Write the incident file

**File path**: `docs/incidents/<I###>-<kebab-case-title>.investigating.md`

**Template**:

```markdown
# Incident <I###>: <Title>

**Status**: Investigating
**Reported**: <YYYY-MM-DD HH:MM UTC>
**Severity**: <score> (<label>) — Impact: <label> (<n>) x Likelihood: <label> (<n>)
**Scope**: <who/what is affected>

## Timeline

- [<start-time> UTC] Symptoms began
- [<reported-time> UTC] Incident declared

## Observations

- [<timestamp> UTC] <what was seen, from where>

## Hypotheses

- [ranked] <hypothesis> — Evidence: <log/repro/diff/metric reference>. Confidence: <low|med|high>.

## Mitigation attempts

*(none yet)*

## Linked Problem

*(none yet — added on restore transition)*
```

### 6. For updates: Edit the existing file

Find the file by ID:

```bash
ls docs/incidents/<I###>-*.md 2>/dev/null
```

Append new observations, hypotheses, or timeline entries. **Every hypothesis must cite evidence.** If the user proposes a hypothesis without evidence, ask via `AskUserQuestion` what evidence supports it before writing.

### 7. For mitigate: delegate to `/wr-itil:mitigate-incident` (P071 split slice 6a)

The `mitigate` subcommand is now hosted by the `/wr-itil:mitigate-incident` skill. This step exists as a thin-router forwarder — the Step 1 parser recognises the `<I###> mitigate <action>` shape and delegates via the Skill tool. This body is intentionally empty of implementation logic; the canonical documentation of the rename, Status update, evidence-gate pre-flight, and Mitigation attempts append lives in `/wr-itil:mitigate-incident`.

Do not re-implement the rename or the evidence gate here — delegate. See "Deprecated-argument forwarders" under Step 1 for the canonical systemMessage.

### 8. For restore: delegate to `/wr-itil:restore-incident` (P071 split slice 6b)

The `restored` subcommand is now hosted by the `/wr-itil:restore-incident` skill. This step exists as a thin-router forwarder — the Step 1 parser recognises the `<I###> restored` shape and delegates via the Skill tool. This body is intentionally empty of implementation logic; the canonical documentation of the pre-flight checks, rename, Status update, Timeline append, and manage-problem handoff lives in `/wr-itil:restore-incident`.

Do not re-implement the rename or the problem handoff here — delegate. See "Deprecated-argument forwarders" under Step 1 for the canonical systemMessage.

### 9. For close: delegate to `/wr-itil:close-incident` (P071 split slice 6c)

The `close` subcommand is now hosted by the `/wr-itil:close-incident` skill. This step exists as a thin-router forwarder — the Step 1 parser recognises the `<I###> close` shape and delegates via the Skill tool. This body is intentionally empty of implementation logic; the canonical documentation of the Linked-Problem gate (accepting `.known-error.md`, `.verifying.md`, and `.closed.md`), the No Problem bypass, and the rename lives in `/wr-itil:close-incident`.

Do not re-implement the close gate or the rename here — delegate. See "Deprecated-argument forwarders" under Step 1 for the canonical systemMessage.

### 10. For list: Show active incidents

Read all `.investigating.md`, `.mitigating.md`, and `.restored.md` files in `docs/incidents/`. Extract ID, title, severity, and status. Sort by severity (highest first). Display as a markdown table.

### 11. For link: delegate to `/wr-itil:link-incident` (P071 split slice 6d)

The `link` subcommand is now hosted by the `/wr-itil:link-incident` skill. This step exists as a thin-router forwarder — the Step 1 parser recognises the `<I###> link P<MMM>` shape and delegates via the Skill tool. This body is intentionally empty of implementation logic; the canonical documentation of the problem-file lookup and the `## Linked Problem` section write (including the retroactive-link-from-No-Problem case) lives in `/wr-itil:link-incident`.

Do not re-implement the link logic here — delegate. See "Deprecated-argument forwarders" under Step 1 for the canonical systemMessage.

### 12. Edge cases

- **No problem required** — record a **No Problem** section with justification; close immediately.
- **Multiple incidents → one problem** — each incident links to the same `P<NNN>`; the problem file accumulates "Reported by incident" entries via `manage-problem`'s update flow.
- **Problem re-opens after the incident closed** — the closed incident stays closed; a new incident is declared for the new occurrence, linked to the re-opened problem.
- **Low-severity / solo-developer lightweight path** — for Sev 4-5 incidents, the skill may skip the Hypotheses section if the user confirms no investigation is needed. Timeline, Observations, and at least one mitigation attempt remain mandatory.

### 13. Quality checks

After any operation, verify:

- **ID uniqueness**: no duplicate `I<NNN>` in `docs/incidents/`
- **Naming convention**: `I<NNN>-<kebab-case-title>.<status>.md`
- **Status consistency**: Status field matches filename suffix
- **Required sections**: Timeline, Observations, Hypotheses (or documented skip), Mitigation attempts
- **Evidence discipline**: every Hypothesis has a cited evidence reference
- **Linked Problem** section present and consistent (or **No Problem** with justification) once the incident reaches Restored

### 14. Report

After any operation, report:

- The file path created/modified
- The incident ID and title
- The current status
- For restore: the linked problem ID (or "No Problem" note)
- Any quality-check warnings

Commit the completed work per ADR-014 (governance skills commit their own work):
1. `git add` all created/modified files for this operation
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes and create a bypass marker. If the subagent type is not available in the current tool set (e.g. this skill is running inside a spawned subagent), invoke `/wr-risk-scorer:assess-release` via the Skill tool instead — per ADR-015 it wraps the same pipeline subagent.
3. `git commit -m "<message>"` using the convention for the operation type:
   - New incident: `docs(incidents): open I<NNN> <title>`
   - Incident mitigated: `docs(incidents): I<NNN> mitigated — <mitigation summary>`
   - Incident restored: `docs(incidents): I<NNN> restored — <action>`
   - Incident closed: `docs(incidents): close I<NNN>`
4. If risk is above appetite: use `AskUserQuestion` to ask whether to commit anyway, remediate first, or park the work. If `AskUserQuestion` is unavailable, skip the commit and report the uncommitted state clearly.

### 15. Auto-release when changesets are queued (ADR-020)

**Skip this step if the skill is running inside an AFK orchestrator.** Orchestrators handle release cadence themselves per ADR-018 (Step 6.5). When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in step 14 lands, drain the release queue so the fix actually lands on npm without requiring manual user action.

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

**Above-appetite branch (per ADR-041)**: If push or release risk is above appetite (≥ 5/25), the skill MUST auto-apply scorer remediations in rank order until residual risk converges within appetite, OR halt the skill per ADR-041 Rule 5 if the scorer cannot produce a convergent plan. **The skill MUST NOT release above appetite under any circumstance.** The skill MUST NOT call `AskUserQuestion` as a shortcut out of the auto-apply loop.

**Auto-apply mechanism (ADR-041 Rule 2):**

1. Parse the scorer's `RISK_REMEDIATIONS:` block.
2. Rank by largest absolute `risk_delta` → smaller effort (S < M < L) → lower remediation ID.
3. Classify each remediation's `description` against ADR-041 Rule 2a's closed action-class enumeration. **Today's orchestrator-supported class (ADR-041 v1)**: `move-to-holding` only. Other classes (`revert-commit`, `amend-commit`, `feature-flag`, `rollback-to-tag`) are deferred to P108 and route to Rule 5 halt.
4. **Verification Pending carve-out (ADR-041 Rule 2b)**: skip remediations that target a commit attached to a `.verifying.md` ticket.
5. Apply the top-ranked eligible remediation. Each auto-apply is its own commit (ADR-041 Rule 3 — non-AFK has no iteration wrapper to amend into); each commit goes through architect + JTBD + risk-scorer gates per ADR-014.
6. Re-score via the same delegation path as step 1 above.
7. **Loop**: within appetite → drain per the Drain action above. Still above → next remediation. Exhausted or unsupported class → Rule 5 halt.

**Rule 5 halt (non-AFK mode)**: halt the skill. Emit the terminal report naming the final `RISK_SCORES:`, the Auto-apply trail, any Verification Pending ticket IDs implicated, and a one-line scorer-gap note. The user resolves interactively.

`push:watch` and `release:watch` are policy-authorised actions when residual risk is within appetite per RISK-POLICY.md, so no `AskUserQuestion` is required for the drain itself (ADR-013 Rule 5). Auto-apply actions under Rules 2–7 are also policy-authorised per ADR-013 Rule 5.

$ARGUMENTS
