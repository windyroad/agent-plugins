---
name: wr-itil:close-incident
description: Close a restored incident — gated on the Linked Problem reaching Known Error, Verifying, or Closed (or a ## No Problem justification). Renames .restored.md to .closed.md.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Close Incident

Close a restored incident. Closing is the final lifecycle transition — once closed, the incident file is archival and does not appear in active incident views. The close operation is gated on the Linked Problem reaching an acceptable terminal state, or on the incident carrying a documented "No Problem" justification. The gate exists so the problem-handoff invariant (JTBD-201) is preserved: every incident either tracks to a root cause or carries an explicit note that none is required.

This skill is the P071 phased-landing split of `/wr-itil:manage-incident <I> close` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The argument `<I>` is a data parameter, permitted under the amendment. The original `/wr-itil:manage-incident <I> close` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Arguments

`/wr-itil:close-incident <I###>` — one positional data parameter:

- `<I###>` — the incident ID (e.g. `I007` or bare `007`). Resolves to `docs/incidents/<I###>-*.restored.md` (primary path) or `docs/incidents/<I###>-*.closed.md` (idempotent — already-closed short-circuits).

If `$ARGUMENTS` is empty or malformed, read the message from the arguments and report the expected shape. No AskUserQuestion — the gate itself is a hard check with a message, and an empty-arguments case is a user misinvocation, not a decisional branch.

## Close gate (ADR-011 + ADR-022)

The close operation checks the Linked Problem's file suffix:

| Linked problem state | File suffix | Close allowed? | Rationale |
|----------------------|-------------|----------------|-----------|
| Open | `.open.md` | **Blocked** | Root cause work not yet converged. The problem may still reclassify, re-scope, or need a fix before the incident can be safely archived. |
| Known Error | `.known-error.md` | Allowed | Root cause is identified and understood; a workaround exists or the risk is accepted. Incident may close. |
| Verifying | `.verifying.md` | Allowed (ADR-022) | Fix released, root cause confirmed, post-release verification pending. Per ADR-022, verifying satisfies the "Restored → Closed" handoff at least as well as Known Error did under the old contract. |
| Closed | `.closed.md` | Allowed | Problem fully resolved. Incident may close. |

If the incident carries a `## No Problem` section (instead of a Linked Problem), the gate is bypassed — the user has documented why no problem record is required.

## Steps

### 1. Parse arguments

Extract `<I###>` from `$ARGUMENTS`. Normalise:

- Accept `I007`, `i007`, `007`, `7` → canonicalise to `I007` (uppercase I + zero-padded 3 digits).
- If missing, report "Usage: `/wr-itil:close-incident <I###>`" and exit.

### 2. Locate the incident file

```bash
ls docs/incidents/<I###>-*.restored.md docs/incidents/<I###>-*.closed.md 2>/dev/null
```

- If no file matches, report "No restored incident `<I###>` found. If the incident is still mitigating, run `/wr-itil:restore-incident <I###>` first. If no incident with this ID exists, check `/wr-itil:list-incidents`." and exit.
- If a `.closed.md` file matches, this is an idempotent re-invocation — report "Incident `<I###>` is already closed." and exit without further action.
- If a `.restored.md` file matches, proceed to Step 3.
- If both suffixes somehow match (should not happen under the naming convention), report the ambiguity and exit.

### 3. Read the Linked Problem (or No Problem) section

Read the incident file and locate either:

- A `## Linked Problem` section with a line like `P<NNN> (<title>) — <status>`, OR
- A `## No Problem` section with a justification.

Branch on which section is present:

**Case A — `## Linked Problem` present**:

1. Extract the problem ID `P<NNN>` from the section.
2. Locate the problem file:

   ```bash
   ls docs/problems/<NNN>-*.md 2>/dev/null | head -1
   ```

   Accept both `P<NNN>-*.md` and `<NNN>-*.md` naming conventions for robustness.

3. Read the problem file's suffix:
   - `.open.md` → close is **blocked**. Report: "Linked problem `P<NNN>` is still Open. Transition it to Known Error (via `/wr-itil:transition-problem P<NNN> known-error`), or let the release verification pipeline take it to `.verifying.md` before closing this incident. If the problem is genuinely not required, update the Linked Problem section to a No Problem justification instead." and exit.
   - `.known-error.md`, `.verifying.md`, or `.closed.md` → close is **allowed**. Proceed to Step 4.

**Case B — `## No Problem` present**:

Close is **allowed**. Proceed to Step 4.

**Case C — neither section present**:

Report: "Incident `<I###>` has no Linked Problem or No Problem section. Run `/wr-itil:restore-incident <I###>` to complete the restore handoff first (which writes one of those sections), or run `/wr-itil:link-incident <I###> P<MMM>` to attach an existing problem, or edit the file manually to add a No Problem section." and exit.

### 4. Transition to closed

Compute a UTC timestamp (e.g. `2026-04-21T14:37Z`). Then:

1. `git mv docs/incidents/<I###>-<title>.restored.md docs/incidents/<I###>-<title>.closed.md`
2. Update the `**Status**:` field from `Restored` to `Closed` via `Edit`.
3. Append to the `## Timeline` section:

   ```markdown
   - [<timestamp> UTC] Incident closed
   ```

### 5. Quality checks

After the close, verify:

- **Status consistency**: `**Status**:` field matches the filename suffix (`Closed` + `.closed.md`).
- **Timeline monotonicity**: the "Incident closed" entry's timestamp is ≥ the last existing timeline entry's timestamp.
- **Post-close sections present**: either `## Linked Problem` with an acceptable terminal-state problem, or `## No Problem` with a justification.

### 6. Report

Report:

- The file path closed.
- The incident ID and title.
- The transition (Restored → Closed).
- The linked problem ID (if any) and its state at close-time, OR the No Problem justification.
- Any quality-check warnings.

### 7. Commit the completed work (ADR-014)

Per ADR-014, governance skills commit their own work.

1. `git add` the renamed incident file.
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes and create a bypass marker. If the subagent type is not available (spawned subagent surface), invoke `/wr-risk-scorer:assess-release` via the Skill tool instead — per ADR-015 it wraps the same pipeline subagent.
3. `git commit -m "docs(incidents): close I<NNN>"`.
4. If risk is above appetite: report the above-appetite state clearly and exit without committing (close-incident does not carry `AskUserQuestion` in its allowed-tools — the gate is a hard check). The user can re-run with `--force` semantics by invoking the commit manually if they choose.

### 8. Auto-release when changesets are queued (ADR-020)

**Skip this step if the skill is running inside an AFK orchestrator.** Orchestrators handle release cadence themselves per ADR-018 (Step 6.5). When in doubt, defer to the orchestrator by skipping this step.

Otherwise, after the commit in step 7 lands, drain the release queue so the close lands on npm without requiring manual user action.

**Mechanism — delegate, do not re-implement scoring (per ADR-015):**

1. Invoke the release scorer. Two paths are valid:
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line.
3. **Drain condition**: if `push` and `release` are both within appetite (≤ 4/25, "Low" band per `RISK-POLICY.md`), AND `.changeset/` is non-empty, proceed to the drain action. Otherwise, skip the drain and report the unreleased state.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` remains non-empty after push (i.e. a release PR is pending), run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Report the release: "Released <package>@<version>. Close record is now live on npm."

**Failure handling**: if `release:watch` fails (CI failure, publish failure), stop and report the failure clearly. Do not retry non-interactively — the user must intervene.

**Above-appetite branch**: if push/release risk is above appetite, skip the drain and report: "Release skipped — risk above appetite. Run `npm run push:watch` and `npm run release:watch` manually when ready."

## Ownership boundary

`close-incident` writes the `## Timeline` close entry, the Status field, and the `.restored.md → .closed.md` rename. It does NOT:

- Restore the incident (that is `/wr-itil:restore-incident <I###>` — slice 6b).
- Link a problem to the incident (that is `/wr-itil:link-incident <I###> P<MMM>` — slice 6d).
- Record a mitigation attempt (that is `/wr-itil:mitigate-incident <I###> <action>` — slice 6a).
- Transition the linked problem's status (that is `/wr-itil:transition-problem P<NNN> <status>`).
- Rename a `.investigating.md` or `.mitigating.md` file — the incident must already be `.restored.md`.
- Prompt the user for decisions — the gate is a hard check with a message, never a prompt. If a decisional branch is needed (e.g. "close anyway without a linked problem"), the user edits the incident file to add a No Problem section and re-runs.

If the user wants any of the above, the skill reports the appropriate sibling and exits.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is slice 6c of the P071 phased-landing plan.
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-011** (`docs/decisions/011-manage-incident-skill.proposed.md`) — incident lifecycle file-suffix conventions (`.investigating.md` / `.mitigating.md` / `.restored.md` / `.closed.md`) + close-gate-on-linked-problem rule.
- **ADR-022** (`docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md`) — `.verifying.md` status; extends the close gate to accept `.verifying.md` alongside `.known-error.md` and `.closed.md`.
- **ADR-013** Rule 1 — structured user interaction (forwarder emits systemMessage for deprecation notice; gate-blocks are hard-fail messages, not prompts).
- **ADR-013** Rule 6 — policy-within-appetite non-interactive actions (release drain).
- **ADR-014** — governance skills commit their own work.
- **ADR-015** — release scorer delegation pattern.
- **ADR-020** — auto-release when changesets are queued.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — close gate preserves the problem-handoff audit trail.
- `packages/itil/skills/manage-incident/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-incident <I###> close` form.
- `packages/itil/skills/restore-incident/SKILL.md` — slice 6b precedent; close-incident is the next transition after restore.
- `packages/itil/skills/transition-problem/SKILL.md` — the skill used to advance a linked problem from `.open.md` to `.known-error.md` so the incident close gate can pass.

$ARGUMENTS
