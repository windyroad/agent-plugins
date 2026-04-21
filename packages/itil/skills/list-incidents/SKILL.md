---
name: wr-itil:list-incidents
description: List active incidents from docs/incidents/ sorted by severity. Read-only display of the incident backlog — no edits, no interaction. Shown as a markdown table with ID, title, severity, and status columns.
allowed-tools: Read, Bash, Grep, Glob
---

# List Incidents

Display the active incident backlog — investigating, mitigating, and restored incidents — sorted by severity (highest first). This skill is a pure read-only view of `docs/incidents/`; it does not edit, transition, close, or create incidents. For those operations, use the dedicated skills (`/wr-itil:manage-incident` to declare / update / mitigate / restore / close / link).

This skill is the P071 phased-landing split of `/wr-itil:manage-incident list` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The original `/wr-itil:manage-incident list` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Scope

Included in the ranking table:
- `docs/incidents/*.investigating.md` — symptoms reported, scope being established
- `docs/incidents/*.mitigating.md` — mitigation(s) in flight
- `docs/incidents/*.restored.md` — service verified restored, awaiting close gate

`docs/incidents/*.closed.md` is omitted entirely (the view is of active incidents, not the closed archive). Closed incidents remain readable by filename convention; this skill does not index them.

**Severity, not WSJF** — per ADR-011: incidents are time-bound events where the WSJF "effort" divisor is meaningless during a live event. Severity uses Impact × Likelihood from `RISK-POLICY.md`, interpreted as "right now, what's the live business impact?". The skill surfaces the severity score from each incident file's frontmatter directly — no re-scoring, no auto-transitioning.

## Steps

### 1. Live scan

Enumerate the active incident files via glob:

```bash
ls docs/incidents/*.investigating.md docs/incidents/*.mitigating.md docs/incidents/*.restored.md 2>/dev/null
```

If the `docs/incidents/` directory does not exist or no active incidents are present, report "No active incidents." and exit.

For each matched file, read the `**Status**`, `**Severity**`, and the first-line `# Incident <I###>: <Title>` header. The severity line shape is:

```
**Severity**: <score> (<label>) — Impact: <label> (<n>) x Likelihood: <label> (<n>)
```

Extract the numeric `<score>` for sorting. If severity is missing, treat the incident as severity 0 and flag it so the user knows the incident file is incomplete.

### 2. Display

Render one section:

**Active Incidents** — sorted by severity descending:

```
| Severity | ID | Title | Status |
|----------|------|-------|--------|
| <score> | I<NNN> | <title> | <status> |
```

If the section is empty (no active incidents), omit the table and print "No active incidents." instead.

### 3. Trailing suggestions

After the table, print one short pointer depending on what the output showed:

- When the table is non-empty: `Run /wr-itil:manage-incident <I###> to update a specific incident, or /wr-itil:manage-incident <I###> mitigate / restored / close to advance its lifecycle.`
- When the table is empty: (no pointer needed).

## Ownership boundary

`list-incidents` is read-only — it does not modify, rename, or commit any files. There is no README cache for incidents (unlike `docs/problems/README.md` which the `review-problems` skill maintains). Every invocation runs a live scan. If the output seems wrong, check the incident file frontmatter directly; there is no cache to refresh.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is slice 5 of the P071 phased-landing plan.
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-011** (`docs/decisions/011-manage-incident-skill-wrapping.proposed.md`) — incident lifecycle file-suffix conventions (`.investigating.md` / `.mitigating.md` / `.restored.md` / `.closed.md`) + "Severity, not WSJF" rule.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — incident status visibility for audit trail.
- `packages/itil/skills/manage-incident/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-incident list` form.
- `packages/itil/skills/list-problems/SKILL.md` — slice 1 precedent; this skill mirrors its read-only display shape.

$ARGUMENTS
