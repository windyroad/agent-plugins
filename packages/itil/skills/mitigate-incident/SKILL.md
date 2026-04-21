---
name: wr-itil:mitigate-incident
description: Record a mitigation attempt against an incident — transitions an investigating incident to mitigating on the first attempt, appends subsequent attempts to the Mitigation attempts timeline. Evidence-first gate enforced per ADR-011.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

# Mitigate Incident

Record a mitigation attempt against an active incident and transition its lifecycle. The first mitigation attempt moves the file from `.investigating.md` to `.mitigating.md`; subsequent attempts append to the existing `.mitigating.md` without re-transitioning. Every attempt (successful or not) is recorded so the post-incident audit trail is complete (JTBD-201).

This skill is the P071 phased-landing split of `/wr-itil:manage-incident <I> mitigate <action>` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The arguments `<I>` (incident ID) and `<action>` (mitigation description) are data parameters, permitted under the amendment — only word-verb-arguments must be split out. The original `/wr-itil:manage-incident <I> mitigate <action>` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Arguments

`/wr-itil:mitigate-incident <I###> <action>` — both positional:

- `<I###>` — the incident ID (e.g. `I007` or bare `007`). Resolves to `docs/incidents/<I###>-*.{investigating,mitigating}.md`.
- `<action>` — free-text description of the mitigation being applied (e.g. `rollback checkout service to 1.2.4`, `feature flag checkout.fast-path off`, `restart ingest worker pool`). Prefer **reversible** actions — see "Reversible preference" below.

If `$ARGUMENTS` is empty or malformed, ask via `AskUserQuestion` for the incident ID and the action.

## Reversible preference (ADR-011)

Prefer **reversible** mitigations over forward fixes:

1. Rollback to a known-good version
2. Feature flag off
3. Restart / cycle the affected component
4. Route traffic away
5. Scale up
6. Only after reversibles are exhausted: forward fix

Record every attempt, successful or not. Failed mitigations are as important to the audit trail as successful ones — they narrow hypothesis space for future investigation.

## Evidence-first gate (ADR-011)

**Pre-flight check before the first mitigation attempt**: the incident file must contain at least one hypothesis with cited evidence in the `## Hypotheses` section. If not, block the transition and ask via `AskUserQuestion`:

> "Incident `<I###>` has no hypothesis with cited evidence. Per ADR-011, mitigation requires at least one ranked hypothesis backed by a log, repro, diff, or metric reference. (a) Add a hypothesis + evidence now and retry, (b) Record the mitigation anyway with an evidence-skipped justification (requires audit-trail note), (c) Cancel."

This gate is the **cool-headed commitment**: it blocks "try this and see" actions during the high-adrenaline phase of an incident unless evidence is cited. The gate runs only on the first mitigation (the `.investigating.md → .mitigating.md` transition); subsequent mitigations on an already-`.mitigating.md` file append directly without re-gating.

## Steps

### 1. Parse arguments

Extract `<I###>` and `<action>` from `$ARGUMENTS`. Normalise `<I###>`:

- Accept `I007`, `i007`, `007`, `7` → canonicalise to `I007` (uppercase I + zero-padded 3 digits).
- If missing, ask via `AskUserQuestion`.

Extract `<action>` as everything after the incident ID. If missing or trivially short (< 8 chars), ask via `AskUserQuestion` for a descriptive action.

### 2. Locate the incident file

```bash
ls docs/incidents/<I###>-*.investigating.md docs/incidents/<I###>-*.mitigating.md 2>/dev/null
```

- If neither exists, report "No active incident `<I###>` found. Check `/wr-itil:list-incidents` for the active backlog or `/wr-itil:manage-incident` to declare a new one." and exit.
- If exactly one file matches, record its current suffix (`investigating` or `mitigating`) — this drives the transition decision in Step 4.
- If multiple files match (should not happen under the `<ID>-<title>.<status>.md` naming convention), report the ambiguity and exit.

### 3. Pre-flight: evidence gate (first mitigation only)

If the file suffix is `.investigating.md` (i.e. this is the first mitigation), read the `## Hypotheses` section and check for at least one line containing `Evidence:` followed by a non-empty reference. The shape per ADR-011:

```
- [ranked] <hypothesis> — Evidence: <log/repro/diff/metric reference>. Confidence: <low|med|high>.
```

- If at least one hypothesis has a cited evidence reference, proceed to Step 4.
- If no hypothesis carries evidence, invoke `AskUserQuestion` with the three-option prompt from "Evidence-first gate" above. Branch:
  - (a) User adds a hypothesis + evidence now — re-read the file and re-check; if satisfied, proceed. If still missing, report the gate failure and exit.
  - (b) User records anyway — append an `## Audit trail` note to the file: `[<timestamp> UTC] Evidence-gate bypassed by user — reason: <justification>`. Then proceed to Step 4.
  - (c) User cancels — exit without change.

If the file suffix is already `.mitigating.md`, skip the gate (it only runs on the transition).

### 4. Record the mitigation and transition if needed

Compute a UTC timestamp (e.g. `2026-04-21T14:37Z`). Then:

**Case A — first mitigation (`.investigating.md` → `.mitigating.md`)**:

1. `git mv docs/incidents/<I###>-<title>.investigating.md docs/incidents/<I###>-<title>.mitigating.md`
2. Update the `**Status**:` field from `Investigating` to `Mitigating` via `Edit`.
3. Append to the `## Mitigation attempts` section:

   ```markdown
   - [<timestamp> UTC] <action> → pending verification
   ```

   If the `## Mitigation attempts` section contains `*(none yet)*`, replace that placeholder with the first attempt row. Otherwise append below the last attempt.

4. Append to the `## Timeline` section:

   ```markdown
   - [<timestamp> UTC] Mitigation attempt: <action>
   ```

**Case B — subsequent mitigation (`.mitigating.md` stays `.mitigating.md`)**:

1. No `git mv` needed.
2. Do not touch the `**Status**:` field.
3. Append to the `## Mitigation attempts` section:

   ```markdown
   - [<timestamp> UTC] <action> → pending verification
   ```

4. Append to the `## Timeline` section:

   ```markdown
   - [<timestamp> UTC] Mitigation attempt: <action>
   ```

The outcome text starts at `pending verification` because verification signals (error-rate recovery, synthetic-probe passing, user report) usually arrive after the mitigation. The `/wr-itil:manage-incident <I###> restored` flow updates the outcome to the final verification signal when service is restored. Failed mitigations should be updated in place (via a subsequent `/wr-itil:manage-incident <I###>` update call or a future `/wr-itil:mitigate-incident` re-record) with the observed outcome — do not delete the original row.

### 5. Low-severity lightweight path (ADR-011 Step 12 edge case)

For **Sev 4-5** incidents, the Hypotheses section may be skipped if the user confirmed no investigation was needed at declare time. In that case:

- The evidence-first gate in Step 3 does not apply (there are no hypotheses to check).
- The Mitigation attempts append in Step 4 remains mandatory — Timeline, Observations, and at least one mitigation attempt are always required per ADR-011.
- Do not upgrade a skipped-hypotheses incident's severity silently; if the user decides mid-incident that investigation IS needed, they should update the incident via `/wr-itil:manage-incident <I###>` and add the hypothesis explicitly.

Detect "lightweight path" by reading the Severity label from the incident frontmatter: if Impact × Likelihood resolves to Sev 4 or Sev 5, the gate defaults to bypass with an audit-trail note unless the user has populated Hypotheses explicitly.

### 6. Quality checks

After any mitigation record, verify:

- **Status consistency**: `**Status**:` field matches the filename suffix (Investigating + `.investigating.md` OR Mitigating + `.mitigating.md`).
- **Timeline monotonicity**: the new timeline entry's timestamp is ≥ the last existing timeline entry's timestamp.
- **Mitigation attempts section exists**: if somehow missing from an older incident file, create it before appending.
- **No evidence-gate silent bypass**: if the gate was bypassed in Step 3, the `## Audit trail` note must be present.

### 7. Report

Report:

- The file path created/modified.
- The incident ID and title.
- The transition (Investigating → Mitigating, or Mitigating → Mitigating).
- The recorded action and the `pending verification` outcome.
- Any quality-check warnings.
- A pointer: "Run `/wr-itil:manage-incident <I###> restored` when the verification signal confirms service is restored, or re-invoke `/wr-itil:mitigate-incident <I###> <next-action>` to record another mitigation attempt."

### 8. Commit the completed work (ADR-014)

Per ADR-014, governance skills commit their own work.

1. `git add` the renamed / modified incident file.
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes and create a bypass marker. If the subagent type is not available (spawned subagent surface), invoke `/wr-risk-scorer:assess-release` via the Skill tool instead — per ADR-015 it wraps the same pipeline subagent.
3. `git commit -m "docs(incidents): I<NNN> mitigated — <action summary>"`.
4. If risk is above appetite: use `AskUserQuestion` to ask whether to commit anyway, remediate first, or park the work. If `AskUserQuestion` is unavailable, skip the commit and report the uncommitted state clearly.

### 9. Auto-release when changesets are queued (ADR-020)

**Skip this step if the skill is running inside an AFK orchestrator.** Orchestrators handle release cadence themselves per ADR-018 (Step 6.5). When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in step 8 lands, drain the release queue so the fix actually lands on npm without requiring manual user action.

**Mechanism — delegate, do not re-implement scoring (per ADR-015):**

1. Invoke the release scorer. Two paths are valid:
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line.
3. **Drain condition**: if `push` and `release` are both within appetite (≤ 4/25, "Low" band per `RISK-POLICY.md`), AND `.changeset/` is non-empty, proceed to the drain action. Otherwise, skip the drain and report the unreleased state.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` remains non-empty after push (i.e. a release PR is pending), run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Report the release: "Released <package>@<version>. Mitigation record is now live on npm."

**Failure handling**: if `release:watch` fails (CI failure, publish failure), stop and report the failure clearly. Do not retry non-interactively — the user must intervene.

**Above-appetite branch**: if push/release risk is above appetite, skip the drain and report: "Release skipped — risk above appetite. Run `npm run push:watch` and `npm run release:watch` manually when ready."

## Ownership boundary

`mitigate-incident` writes the Mitigation attempts timeline, the Status field, and the file rename on the first-attempt transition. It does NOT:

- Restore the incident to `.restored.md` (that is `/wr-itil:manage-incident <I###> restored` — slice 6b of the P071 phased plan will split this out).
- Close the incident (that is `/wr-itil:manage-incident <I###> close` — slice 6c).
- Create or link problems (that is the restore handoff; mitigate-incident does not touch problem state).
- Add or edit Hypotheses or Observations. Those belong to `/wr-itil:manage-incident <I###>` update flow.

If the user wants any of the above, the skill reports the appropriate sibling and exits.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is slice 6a of the P071 phased-landing plan.
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-011** (`docs/decisions/011-manage-incident-skill-wrapping.proposed.md`) — incident lifecycle file-suffix conventions (`.investigating.md` / `.mitigating.md` / `.restored.md` / `.closed.md`) + evidence-first rule + reversible-mitigation preference + Sev 4-5 lightweight path.
- **ADR-013** Rule 1 — structured user interaction (evidence-gate prompt uses AskUserQuestion; deprecation notices use systemMessage).
- **ADR-013** Rule 6 — policy-within-appetite non-interactive actions (release drain).
- **ADR-014** — governance skills commit their own work.
- **ADR-015** — release scorer delegation pattern.
- **ADR-020** — auto-release when changesets are queued.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — evidence-first audit trail preserved post-split.
- `packages/itil/skills/manage-incident/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-incident <I###> mitigate <action>` form.
- `packages/itil/skills/list-incidents/SKILL.md` — slice 5 precedent; the split-skill shape this slice mirrors.

$ARGUMENTS
