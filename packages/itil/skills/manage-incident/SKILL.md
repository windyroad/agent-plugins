---
name: wr-itil:manage-incident
description: Declare, triage, mitigate, and close an incident using an evidence-first workflow. Restores service first, then hands off to manage-problem for root-cause work.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
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

- If arguments start with "list" → show active incidents summary
- If arguments start with `I<NNN>` or a bare number → this is an update, mitigate, restore, close, or link
- Otherwise → declare a new incident

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

### 7. For mitigate: Record and transition to mitigating

When the first mitigation attempt is made:

1. `git mv docs/incidents/<I###>-<title>.investigating.md docs/incidents/<I###>-<title>.mitigating.md`
2. Update the **Status** field to "Mitigating"
3. Append to **Mitigation attempts**: `[<timestamp> UTC] <action> → <outcome>` (outcome may be "pending verification" initially; update once the verification signal is known)

Pre-flight check before first mitigation: the file must contain at least one hypothesis with cited evidence. If not, block the transition and ask the user what evidence supports the chosen action.

### 8. For restore: Transition and hand off to manage-problem

Pre-flight checks before restore:

- [ ] At least one mitigation attempt is recorded with outcome
- [ ] A verification signal is captured (e.g., "error rate back to baseline per Datadog", "user reports normal", "synthetic probe passing")

If checks pass:

1. `git mv docs/incidents/<I###>-<title>.mitigating.md docs/incidents/<I###>-<title>.restored.md`
2. Update the **Status** field to "Restored"
3. Append to **Timeline**: `[<timestamp> UTC] Service restored — <verification signal>`

Then perform the **handoff to problem management**:

1. Ask via `AskUserQuestion`: "Service restored. Should I create or update a problem record for the root cause? (a) yes — recommended, (b) no — document why (trivial/one-off)"
2. If yes, construct a handoff payload:
   - Incident ID and title
   - Timeline summary
   - Top-ranked hypothesis + cited evidence
   - Mitigation applied + verification signal
3. Invoke `wr-itil:manage-problem` via the `Skill` tool with the payload as arguments. The problem skill's existing dedupe flow handles new-vs-update.
4. Capture the returned `P<NNN>` and write a **Linked Problem** section into the incident file:
   ```markdown
   ## Linked Problem
   P<NNN> (<title>) — <status>
   ```
5. If the user chose "no", write a **No Problem** section with the justification and skip the handoff:
   ```markdown
   ## No Problem
   <reason — e.g. "one-off cosmic-bit-flip; not reproducible">
   ```

### 9. For close: Gate on linked problem status

The close operation checks the linked problem's file suffix:

```bash
linked_id=<extracted from Linked Problem section>
linked_file=$(ls docs/problems/${linked_id}-*.md 2>/dev/null | head -1)
```

- If `linked_file` ends with `.known-error.md` or `.closed.md` → close is allowed
- If `linked_file` ends with `.open.md` → close is blocked; report "Linked problem ${linked_id} is still Open. Transition it to Known Error first, or update the Linked Problem reference."
- If no linked problem and the file has a **No Problem** section → close is allowed

On close:

1. `git mv docs/incidents/<I###>-<title>.restored.md docs/incidents/<I###>-<title>.closed.md`
2. Update the **Status** field to "Closed"
3. Append to **Timeline**: `[<timestamp> UTC] Incident closed`

### 10. For list: Show active incidents

Read all `.investigating.md`, `.mitigating.md`, and `.restored.md` files in `docs/incidents/`. Extract ID, title, severity, and status. Sort by severity (highest first). Display as a markdown table.

### 11. For link: Attach a problem

When the user runs `incident <I###> link P<MMM>`:

1. Verify `docs/problems/P<MMM>-*.md` exists
2. Read or add the **Linked Problem** section with `P<MMM> (<title>) — <status>`
3. Report the link

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

Do not commit. The user will commit when ready.

$ARGUMENTS
