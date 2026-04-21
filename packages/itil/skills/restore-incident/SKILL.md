---
name: wr-itil:restore-incident
description: Mark an incident as service-restored — transitions a mitigating incident to restored, appends a Timeline entry, and hands off to /wr-itil:manage-problem for linked-problem creation or update per ADR-011.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

# Restore Incident

Mark an active incident as service-restored and hand off to problem management for root-cause tracking. This skill is the active-restoration path — the point where the "cool-headed, evidence-first" incident lifecycle crosses from mitigation to post-restoration (JTBD-201).

The first restore attempt moves the file from `.mitigating.md` to `.restored.md`, updates the `**Status**` field to "Restored", appends a verification-signal entry to the Timeline, and invokes `/wr-itil:manage-problem` via the Skill tool so a problem record captures the root-cause handoff. If the user declines problem creation with a justification, a `## No Problem` section is written on the incident instead — preserving the audit-trail invariant.

This skill is the P071 phased-landing split of `/wr-itil:manage-incident <I> restored` per ADR-010 amended Skill Granularity rule: one skill per distinct user intent. The argument `<I>` is a data parameter, permitted under the amendment — only word-verb-arguments must be split out. The original `/wr-itil:manage-incident <I> restored` subcommand route remains as a thin-router forwarder during the deprecation window but is scheduled for removal in `@windyroad/itil`'s next major version.

## Arguments

`/wr-itil:restore-incident <I###>` — one positional data parameter:

- `<I###>` — the incident ID (e.g. `I007` or bare `007`). Resolves to `docs/incidents/<I###>-*.mitigating.md` (primary path) or `docs/incidents/<I###>-*.restored.md` (idempotent re-invocation).

If `$ARGUMENTS` is empty or malformed, ask via `AskUserQuestion` for the incident ID.

## Pre-flight (ADR-011)

Restore requires two pre-flight conditions:

1. **Mitigation recorded**: at least one `[<timestamp> UTC] <action> → <outcome>` row in the `## Mitigation attempts` section. A restore with no mitigation recorded usually means the incident self-resolved — in that case the user should record the self-resolution as a mitigation entry first (e.g. `[<timestamp> UTC] (no action taken — issue self-resolved) → pending verification`).
2. **Verification signal captured**: the user must describe the signal that confirms service is restored (e.g. "error rate back to baseline per Datadog", "user reports normal", "synthetic probe passing"). This is the verification evidence that the restore is real, not wishful.

If either pre-flight fails, block the transition and ask via `AskUserQuestion` what to do: (a) record a mitigation + verification signal now and retry, (b) document why this incident is an exception (e.g. Sev 4-5 lightweight path) and proceed with an Audit-trail note, (c) cancel.

## Steps

### 1. Parse arguments

Extract `<I###>` from `$ARGUMENTS`. Normalise:

- Accept `I007`, `i007`, `007`, `7` → canonicalise to `I007` (uppercase I + zero-padded 3 digits).
- If missing, ask via `AskUserQuestion`.

### 2. Locate the incident file

```bash
ls docs/incidents/<I###>-*.mitigating.md docs/incidents/<I###>-*.restored.md 2>/dev/null
```

- If neither exists (the incident is `.investigating.md` or `.closed.md`), report "No active mitigation-or-restored incident `<I###>` found. If the incident is still investigating, record at least one mitigation attempt via `/wr-itil:mitigate-incident <I###> <action>` first." and exit.
- If a `.mitigating.md` file matches, this is the restore transition (Case A in Step 4).
- If a `.restored.md` file matches, this is an idempotent re-invocation (Case B in Step 4).
- If multiple files match (should not happen under the naming convention), report the ambiguity and exit.

### 3. Pre-flight: verification signal + mitigation-attempts check

For the Case A path (restore transition), perform the pre-flight checks:

1. Read the `## Mitigation attempts` section. If it is missing, empty, or contains only `*(none yet)*`, the first pre-flight fails. Ask via `AskUserQuestion`.
2. Ask via `AskUserQuestion` for the verification signal if not already provided in `$ARGUMENTS`. The signal is free-text and should name the metric, probe, or report that confirms restoration.

### 4. Record the restore and transition if needed

Compute a UTC timestamp (e.g. `2026-04-21T14:37Z`). Then:

**Case A — first restore (`.mitigating.md` → `.restored.md`)**:

1. `git mv docs/incidents/<I###>-<title>.mitigating.md docs/incidents/<I###>-<title>.restored.md`
2. Update the `**Status**:` field from `Mitigating` to `Restored` via `Edit`.
3. Append to the `## Timeline` section:

   ```markdown
   - [<timestamp> UTC] Service restored — <verification signal>
   ```

**Case B — idempotent re-invocation (`.restored.md` stays `.restored.md`)**:

1. No `git mv` needed.
2. Do not re-edit the `**Status**:` field.
3. If a verification signal was provided in `$ARGUMENTS` and differs from the existing Timeline, append an additional `[<timestamp> UTC] Service restored (re-verified) — <verification signal>` line to the `## Timeline`. Otherwise, skip the Timeline append and proceed to Step 5 (the user may be re-running the handoff).

### 5. Problem handoff

Ask via `AskUserQuestion`: "Service restored. Should I create or update a problem record for the root cause? (a) yes — recommended, (b) no — document why (trivial/one-off)".

**Branch (a) — Yes, create or update problem**:

1. Construct a handoff payload:
   - Incident ID and title
   - Timeline summary (most recent entries)
   - Top-ranked hypothesis + cited evidence from `## Hypotheses`
   - Mitigation applied + verification signal from `## Mitigation attempts` + the just-appended Timeline entry
2. Invoke `/wr-itil:manage-problem` via the **Skill tool** with the payload as arguments. The problem skill's existing dedupe flow handles new-vs-update — do not duplicate that logic here.
3. Capture the returned `P<NNN>` (or `P<NNN> (updated)` for a dedupe hit).
4. Write (or update) the incident's `## Linked Problem` section:

   ```markdown
   ## Linked Problem
   P<NNN> (<title>) — <status>
   ```

   If the section already exists, edit it in place; otherwise append at the end of the file.

**Branch (b) — No, document the no-problem justification**:

1. Ask via `AskUserQuestion` for the justification (free-text). Examples: "one-off cosmic-bit-flip; not reproducible", "transient upstream outage; no action on our side", "test incident (training exercise)".
2. Write a `## No Problem` section into the incident file:

   ```markdown
   ## No Problem
   <reason — e.g. "one-off cosmic-bit-flip; not reproducible">
   ```

   If a `## Linked Problem` section exists, replace it with the `## No Problem` section (one or the other — never both).

### 6. Quality checks

After the restore, verify:

- **Status consistency**: `**Status**:` field matches the filename suffix (`Restored` + `.restored.md`).
- **Timeline monotonicity**: the new "Service restored" entry's timestamp is ≥ the last existing timeline entry's timestamp.
- **Post-restore sections present**: exactly one of `## Linked Problem` or `## No Problem` exists; never both, never neither.

### 7. Report

Report:

- The file path created/modified.
- The incident ID and title.
- The transition (Mitigating → Restored, or Restored → Restored for re-invocations).
- The verification signal recorded.
- Whether a problem was created, updated, or skipped with a `## No Problem` justification.
- The linked problem ID (if any).
- A pointer: "Run `/wr-itil:close-incident <I###>` when the linked problem reaches Known Error, Verifying, or Closed (or if the incident carries a No Problem justification), or keep the incident in Restored while the root cause work progresses."

### 8. Commit the completed work (ADR-014)

Per ADR-014, governance skills commit their own work.

1. `git add` the renamed / modified incident file.
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes and create a bypass marker. If the subagent type is not available (spawned subagent surface), invoke `/wr-risk-scorer:assess-release` via the Skill tool instead — per ADR-015 it wraps the same pipeline subagent.
3. `git commit -m "docs(incidents): I<NNN> restored — <verification signal summary>"`.
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
3. Report the release: "Released <package>@<version>. Restoration record is now live on npm."

**Failure handling**: if `release:watch` fails (CI failure, publish failure), stop and report the failure clearly. Do not retry non-interactively — the user must intervene.

**Above-appetite branch**: if push/release risk is above appetite, skip the drain and report: "Release skipped — risk above appetite. Run `npm run push:watch` and `npm run release:watch` manually when ready."

## Ownership boundary

`restore-incident` writes the Timeline "Service restored" entry, the Status field, the file rename on the transition, and exactly one of `## Linked Problem` or `## No Problem`. It does NOT:

- Close the incident (that is `/wr-itil:close-incident <I###>` — slice 6c).
- Link the incident to an existing problem without performing the restore transition (that is `/wr-itil:link-incident <I###> P<MMM>` — slice 6d).
- Record a mitigation attempt (that is `/wr-itil:mitigate-incident <I###> <action>` — slice 6a).
- Rename or transition a `.investigating.md` file — the incident must already be `.mitigating.md` before restore.

If the user wants any of the above, the skill reports the appropriate sibling and exits.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md`) — originating ticket. This skill is slice 6b of the P071 phased-landing plan.
- **ADR-010 amended** (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — Skill Granularity section) — canonical skill-split naming + forwarder contract + `deprecated-arguments: true` frontmatter flag.
- **ADR-011** (`docs/decisions/011-manage-incident-skill.proposed.md`) — incident lifecycle file-suffix conventions (`.investigating.md` / `.mitigating.md` / `.restored.md` / `.closed.md`) + Decision Outcome point 4 (direct Skill-tool invocation of `/wr-itil:manage-problem` for problem handoff).
- **ADR-013** Rule 1 — structured user interaction (verification-signal and handoff prompts use AskUserQuestion; deprecation notice uses systemMessage).
- **ADR-013** Rule 6 — policy-within-appetite non-interactive actions (release drain).
- **ADR-014** — governance skills commit their own work.
- **ADR-015** — release scorer delegation pattern.
- **ADR-020** — auto-release when changesets are queued.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion bats pattern applied to this skill.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — discoverable surface via `/wr-itil:` autocomplete.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — one skill per distinct user intent.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — this skill IS the active-restoration path; audit trail invariants preserved post-split.
- `packages/itil/skills/manage-incident/SKILL.md` — hosts the thin-router forwarder for the deprecated `manage-incident <I###> restored` form.
- `packages/itil/skills/mitigate-incident/SKILL.md` — slice 6a precedent; restore-incident mirrors the split shape.
- `packages/itil/skills/manage-problem/SKILL.md` — cross-skill invocation target during problem handoff.

$ARGUMENTS
