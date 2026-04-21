---
name: wr-itil:link-incident
description: Link an incident to an existing problem — writes or updates the ## Linked Problem section on the incident file with the problem's ID, title, and current status.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Link Incident

Attach an existing problem record to an incident. This is the standalone link operation — the `/wr-itil:restore-incident` skill already handles the link-at-restore flow (writing the `## Linked Problem` section as part of problem-handoff). The `link-incident` skill is for after-the-fact links: when an incident was closed with a `## No Problem` note that later turned out to be wrong, when multiple incidents share a newly-created problem and need to be linked, or when a problem existed in parallel but was not attached during restore.

This skill is the P071 phased-landing split of `/wr-itil:manage-incident <I> link P<M>` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The arguments `<I>` (incident ID) and `<P>` (problem ID) are data parameters, permitted under the amendment. The original `/wr-itil:manage-incident <I> link P<M>` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Arguments

`/wr-itil:link-incident <I###> P<MMM>` — two positional data parameters:

- `<I###>` — the incident ID (e.g. `I007` or bare `007`). Resolves to `docs/incidents/<I###>-*.{investigating,mitigating,restored,closed}.md`.
- `P<MMM>` — the problem ID (e.g. `P071` or bare `071`). Resolves to `docs/problems/<MMM>-*.md` (any lifecycle suffix).

If either argument is missing or malformed, report the expected shape and exit. No AskUserQuestion — both are data parameters, not decisional branches.

## Steps

### 1. Parse arguments

Extract `<I###>` and `P<MMM>` from `$ARGUMENTS`. Normalise:

- Accept `I007`, `i007`, `007`, `7` → canonicalise the incident ID to `I007`.
- Accept `P071`, `p071`, `071`, `71` → canonicalise the problem ID to `P071`.
- If either is missing, report "Usage: `/wr-itil:link-incident <I###> P<MMM>`" and exit.

### 2. Locate the incident file

```bash
ls docs/incidents/<I###>-*.md 2>/dev/null | head -1
```

The link operation works on any incident status — investigating, mitigating, restored, or closed. (Closed incidents are rare to link retroactively but not impossible — the audit-trail requirement is preserved either way.)

- If no file matches, report "No incident `<I###>` found. Check `/wr-itil:list-incidents` for active incidents or search `docs/incidents/` for closed incidents." and exit.
- If multiple files match (should not happen under the naming convention), report the ambiguity and exit.

### 3. Locate the problem file

```bash
ls docs/problems/<MMM>-*.md 2>/dev/null | head -1
```

Accept any lifecycle suffix: `.open.md`, `.known-error.md`, `.verifying.md`, `.closed.md`.

- If no file matches, report "No problem `P<MMM>` found. Check `/wr-itil:list-problems` for the current backlog." and exit.
- Read the problem file's title from the `# Problem <MMM>: <Title>` header line.
- Read the problem file's status from the filename suffix (Open / Known Error / Verifying / Closed).

### 4. Write or update the Linked Problem section

Construct the link entry:

```markdown
## Linked Problem
P<MMM> (<title>) — <status>
```

where `<status>` is the human-readable label derived from the file suffix (`Open`, `Known Error`, `Verifying`, `Closed`).

Branch on whether the incident already has a link:

**Case A — no `## Linked Problem` or `## No Problem` section present**:

Append the `## Linked Problem` section at the end of the incident file.

**Case B — `## Linked Problem` section already present**:

Replace the existing section's body with the new link entry. Keep the `## Linked Problem` heading. If the existing link matches exactly (same `P<MMM>`, same title, same status), report "Incident `<I###>` is already linked to `P<MMM>` with the same status — no change." and exit without modifying the file.

**Case C — `## No Problem` section present**:

This is a retroactive-link-after-no-problem case. Replace the `## No Problem` section with a `## Linked Problem` section carrying the new link entry. Also append a `[<timestamp> UTC] Retroactive link to P<MMM>` entry to the `## Timeline` section so the audit trail records the revision.

### 5. Quality checks

After the link, verify:

- Exactly one of `## Linked Problem` or `## No Problem` exists on the incident file (never both, never neither).
- The `## Linked Problem` body matches the canonical shape `P<MMM> (<title>) — <status>`.
- The problem file referenced actually exists in `docs/problems/`.

### 6. Report

Report:

- The incident ID and file path modified.
- The problem ID, title, and status linked.
- Whether the link was a new attach (Case A), an update (Case B), or a retroactive conversion from No Problem (Case C).
- Any quality-check warnings.

### 7. Commit the completed work (ADR-014)

Per ADR-014, governance skills commit their own work.

1. `git add` the modified incident file.
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes and create a bypass marker. If the subagent type is not available (spawned subagent surface), invoke `/wr-risk-scorer:assess-release` via the Skill tool instead — per ADR-015 it wraps the same pipeline subagent.
3. `git commit -m "docs(incidents): link I<NNN> to P<MMM>"`.
4. If risk is above appetite: report the above-appetite state clearly and exit without committing. The user can re-run the commit manually if they choose.

### 8. Auto-release when changesets are queued (ADR-020)

**Skip this step if the skill is running inside an AFK orchestrator.** Orchestrators handle release cadence themselves per ADR-018 (Step 6.5). When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in step 7 lands, drain the release queue so the link lands on npm without requiring manual user action.

**Mechanism — delegate, do not re-implement scoring (per ADR-015):**

1. Invoke the release scorer. Two paths are valid:
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line.
3. **Drain condition**: if `push` and `release` are both within appetite (≤ 4/25, "Low" band per `RISK-POLICY.md`), AND `.changeset/` is non-empty, proceed to the drain action. Otherwise, skip the drain and report the unreleased state.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` remains non-empty after push (i.e. a release PR is pending), run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Report the release: "Released <package>@<version>. Link record is now live on npm."

**Failure handling**: if `release:watch` fails (CI failure, publish failure), stop and report the failure clearly. Do not retry non-interactively — the user must intervene.

**Above-appetite branch**: if push/release risk is above appetite, skip the drain and report: "Release skipped — risk above appetite. Run `npm run push:watch` and `npm run release:watch` manually when ready."

## Ownership boundary

`link-incident` writes (or updates) the `## Linked Problem` section on an incident file and, in Case C only, appends a retroactive-link Timeline entry. It does NOT:

- Create a new problem (that is `/wr-itil:manage-problem` with no args).
- Update the problem's body (that is `/wr-itil:manage-problem P<MMM>`).
- Transition the problem's status (that is `/wr-itil:transition-problem P<MMM> <status>`).
- Transition the incident's status (that is `/wr-itil:restore-incident` or `/wr-itil:close-incident`).
- Record a mitigation (that is `/wr-itil:mitigate-incident`).
- Prompt the user for decisions — both arguments are data parameters; any missing-argument case is a hard-fail message, not a decisional branch.

If the user wants any of the above, the skill reports the appropriate sibling and exits.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is slice 6d of the P071 phased-landing plan.
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-011** (`docs/decisions/011-manage-incident-skill.proposed.md`) — incident lifecycle file-suffix conventions + Linked Problem section convention.
- **ADR-013** Rule 1 — structured user interaction (forwarder emits systemMessage for deprecation; missing-argument is a hard-fail message, not a prompt).
- **ADR-014** — governance skills commit their own work.
- **ADR-015** — release scorer delegation pattern.
- **ADR-020** — auto-release when changesets are queued.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — Linked Problem traceability preserved post-split.
- `packages/itil/skills/manage-incident/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-incident <I###> link P<MMM>` form.
- `packages/itil/skills/restore-incident/SKILL.md` — slice 6b precedent; writes the `## Linked Problem` section as part of problem-handoff. `link-incident` is the standalone-after-the-fact equivalent.
- `packages/itil/skills/manage-problem/SKILL.md` — the source of truth for problem titles / statuses read during link.

$ARGUMENTS
