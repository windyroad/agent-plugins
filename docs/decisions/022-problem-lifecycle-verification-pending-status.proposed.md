---
status: "proposed"
date: 2026-04-19
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-19
---

# Problem lifecycle — add a Verification Pending status between Known Error and Closed

## Context and Problem Statement

The problem lifecycle today uses four statuses — Open, Known Error, Parked, Closed — mapped to file suffixes `.open.md`, `.known-error.md`, `.parked.md`, `.closed.md`. Known Error is defined as "root cause confirmed, fix path clear". The closure workflow appends a `## Fix Released` section to the same `.known-error.md` file when the fix ships, keeping the status and suffix unchanged until the user explicitly verifies.

This overloads Known Error with two distinct sub-states:

1. Root cause confirmed, fix NOT yet implemented — **dev work remaining**.
2. Fix released, awaiting user verification — **user work remaining**.

P049 (Known Error status overloaded with Fix Released sub-state) captured the gap with concrete evidence: **16 of 16** active `.known-error.md` files in this repo contain `## Fix Released` on 2026-04-19. Sub-state (1) is empirically vacant; tickets pass through it quickly and linger indefinitely in sub-state (2).

Consequences already observed:

- `docs/problems/README.md` WSJF ranking can't distinguish the two sub-states without opening each file's body. A hand-maintained "Known Errors (Fix Released — pending verification)" shadow table in the same README is the current workaround.
- `manage-problem review` step 9d has to file-body-scan every `.known-error.md` to find verification candidates. The `work-problems` classifier table has the same scan.
- WSJF multiplier (Known Error = 2.0) treats user-side verification work the same as dev-side implementation work, distorting rank order. A ticket whose remaining work is a user's one-paragraph "yes it's fixed" competes with a ticket whose remaining work is days of dev effort.
- P048 (manage-problem does not surface Fix Released tickets as verification candidates) requires a file-body scan to implement today; with an explicit status, the scan becomes a glob.

This ADR decides how to make the sub-state first-class.

## Decision Drivers

- **Data-model clarity** — every consumer of `docs/problems/` (skills, orchestrators, README renderers, human readers) today re-derives the sub-state by reading file bodies. A first-class status removes the scan.
- **Ranking accuracy** — the WSJF backlog should rank dev work in one list and user-verification work in another, not mix them.
- **Cross-tool consistency** — `manage-problem`, `manage-incident`, `work-problems` all depend on the problem-file status contract. A status change affects all three; better to decide it once.
- **Backward compatibility** — 16 existing files need migration. A clean one-commit rename preserves git history via rename-detection and avoids long-lived dual state.
- **JTBD-001** (Enforce Governance Without Slowing Down) — disambiguated ranking reduces cognitive load per review.
- **JTBD-006** (Progress the Backlog While I'm Away) — AFK orchestrators rank faster when the status carries meaning directly. The persona constraint "problems requiring my judgment (verification) are queued for my return, not guessed at" is honoured by the separate Verification Queue: AFK loops never touch those tickets without the user.
- **JTBD-101** (Extend the Suite with Clear Patterns) — a clean status contract is easier to extend and document.
- **P049, P048** — the problem tickets this ADR resolves (P049 directly, P048 simplified substantially).

## Considered Options

1. **Status quo** — keep Known Error overloaded; continue using `## Fix Released` sections + the hand-maintained shadow table in README.
2. **Introduce "Verification Pending" status with `.verifying.md` suffix, WSJF multiplier 0 (excluded from dev ranking)** (chosen).
3. Introduce the same status with WSJF multiplier 0.5 — include in ranking but down-weighted.
4. Introduce the same status with WSJF multiplier 2.0 — same as Known Error, treating multiplier as "closeness to Closed" rather than "dev work remaining".

Status-name candidates considered: Verification Pending (chosen), Fix Released, Awaiting Verification, Staged for Closure. File-suffix candidates: `.verifying.md` (chosen), `.fix-released.md`, `.awaiting-verification.md`, `.staged.md`.

## Decision Outcome

Chosen option: **"Verification Pending" status with `.verifying.md` suffix and WSJF multiplier 0 (excluded from dev ranking)**, because it names the blocked role clearly (the user must verify), produces a concise suffix that round-trips through `ls` output, and keeps the dev-work backlog uncontaminated by user-side items. A separate "Verification Queue" section in `docs/problems/README.md` surfaces items without ranking them against dev work — the same pattern already used for `.parked.md` files.

### Scope

**In scope (this ADR):**

- Add the new status to the lifecycle table in `packages/itil/skills/manage-problem/SKILL.md`.
- Update the Known Error → Verification Pending transition point: when a fix is released, the skill renames `<NNN>-<title>.known-error.md` → `<NNN>-<title>.verifying.md` AND writes the `## Fix Released` section. Both operations happen in the same commit.
- Update WSJF math: status multiplier table gains "Verification Pending = 0" (excluded). `manage-problem review` step 9b's WSJF calculation treats `.verifying.md` files as "skip ranking, list separately".
- Update `manage-problem review` step 9c: present a dedicated "Verification Queue" section (ranked by release age, not WSJF) in parallel to the main ranked table.
- Update `manage-problem review` step 9d: target `*.verifying.md` files directly via glob instead of scanning `.known-error.md` bodies.
- Update `manage-problem work` step 3 classifier rule (Known Error with `## Fix Released` → Skip) to Skip all `.verifying.md` files for dev-work selection — the match becomes suffix-based.
- Update the Open → Known Error pre-flight (step 7): clarify that Known Error is for "root cause confirmed AND fix not yet shipped". Releasing the fix is a second transition (Known Error → Verification Pending), not an edit in place.
- Update `packages/itil/skills/work-problems/SKILL.md` classifier table (`Known Error with ## Fix Released | Skip`) to use the suffix.
- Update `packages/itil/skills/manage-incident/SKILL.md` linked-problem close gating (step 9): `.known-error.md`, `.verifying.md`, and `.closed.md` all permit incident close; `.open.md` still blocks.
- Update `docs/problems/README.md` template: replace the hand-maintained "Known Errors (Fix Released — pending verification)" table with a "Verification Queue" section sourced from `.verifying.md` files.

**Migration (separate follow-up commit, cites this ADR):**

- Rename the 16 existing `.known-error.md` files that contain `## Fix Released` → `.verifying.md`. Single mechanical-migration commit per ADR-014 commit discipline. `git mv` preserves rename detection so history is intact. The migration commit is distinct from the ADR commit so reviewers can see the decision in isolation from the data movement.
- Update each renamed file's `**Status**:` field from "Known Error" to "Verification Pending".

**Out of scope (follow-up tickets):**

- P048's detection layer (exercise observations, age-based surfacing) — simplified by this ADR but implemented separately.
- `manage-incident` does NOT gain an analogous sub-state — its Restored → Closed transition is already gated on the linked problem's status per ADR-011, which now reads `.verifying.md` naturally.

### WSJF multiplier rationale

Multiplier 0 (exclude) was chosen over 0.5 and 2.0 because:

- The work remaining on a Verification Pending ticket is **user-side** (observe the fix, answer yes/no). Dev-work ranking should not include user action items.
- Keeping these tickets at multiplier 2.0 (same as Known Error) would swamp the top of the ranking — 16 of 16 current Known Errors would dominate the work queue.
- Multiplier 0.5 partially addresses that concern but still mixes user and dev work in one list. Users then have to mentally filter again.
- Multiplier 0 + a dedicated "Verification Queue" section in the README gives the user one glance-able view of "what dev work is next" and a separate glance at "what verifications are waiting for me".

This mirrors how `.parked.md` tickets are excluded and shown separately today.

## Consequences

### Good

- Status contract matches empirical usage — no more 16/16 sub-state overload.
- Glob-based distinction simplifies every consumer's code path: `ls docs/problems/*.verifying.md` is the whole query.
- WSJF backlog shows only dev work; user-verification work has its own queue.
- P048's fix surface becomes a glob-and-sort, not a file-body-scan. The detection-layer ticket simplifies substantially.
- Symmetry with `.parked.md` excluded-from-ranking pattern reduces cognitive surface area.
- Migration is one batch commit, preserves git history via rename detection.
- Honours JTBD-006 constraint: problems awaiting user verification are queued for the user's return, not guessed at by an AFK orchestrator.

### Neutral

- Two transitions (Open → Known Error → Verification Pending → Closed) instead of one (Open → Known Error → Closed with an embedded flag). The transition count is what the lifecycle actually is; the ADR makes it visible.
- SKILL.md step-wise documentation grows by one status row. The step for "when the fix is released" moves from "append ## Fix Released to the Known Error file" to "rename to .verifying.md + append ## Fix Released".
- Third-party tooling that enumerates `docs/problems/*.known-error.md` will no longer see Fix-Released items. This is the expected behaviour — they weren't Known Errors in the old sense — but downstream tooling maintainers (if any exist) need to update their globs.

### Bad

- Introduces one more file-suffix, slightly increasing the surface to memorise. Mitigated by the dedicated status staying close to the existing naming scheme (`.open`, `.known-error`, `.verifying`, `.parked`, `.closed`).
- Migration touches 16 files; rename conflicts are possible if a parallel branch was renaming the same files. Mitigated by doing the migration in a single commit on `main` with no other parallel ticket work.
- If the project ever decides to re-collapse the two sub-states (e.g. because some consumer relies on the old contract), the reversal is another migration. The reassessment criteria below cover this.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/itil/skills/manage-problem/SKILL.md` lifecycle table has a `Verification Pending | .verifying.md` row.
   - SKILL.md WSJF multiplier table has a "Verification Pending = 0" row (or equivalent "excluded" wording).
   - Step 7 (Open → Known Error transition) explicitly states Known Error is pre-release.
   - A Known Error → Verification Pending transition is documented with explicit steps: `git mv`, update Status field, add `## Fix Released` section.
   - Step 9b WSJF loop explicitly skips `.verifying.md` files.
   - Step 9c presents a dedicated "Verification Queue" section.
   - Step 9d targets `*.verifying.md` via glob.
   - `packages/itil/skills/work-problems/SKILL.md` classifier rule uses the `.verifying.md` suffix, not a content scan.
   - `packages/itil/skills/manage-incident/SKILL.md` linked-problem close gating accepts `.verifying.md` alongside `.known-error.md` and `.closed.md`.
   - `docs/problems/README.md` template has a "Verification Queue" section.
2. **Test:** bats test in `packages/itil/skills/manage-problem/test/` asserts:
   - The SKILL.md lifecycle table contains the new status + suffix.
   - The WSJF multiplier table contains the new row.
   - Renaming a `.known-error.md` with `## Fix Released` → `.verifying.md` preserves the Status field as "Verification Pending".
   - `grep -l '^## Fix Released' docs/problems/*.verifying.md` returns all such files (sanity check on the migration result).
3. **Behavioural / migration:** after the migration follow-up commit, `ls docs/problems/*.known-error.md` returns only files WITHOUT a `## Fix Released` section. `ls docs/problems/*.verifying.md` returns the 16 migrated files plus any future Verification Pending tickets. The README "Known Errors (Fix Released)" shadow table has been replaced by the "Verification Queue" section driven off the glob.
4. **Commit discipline:** the migration commit's message references this ADR (e.g. `chore(problems): migrate Fix Released Known Errors to Verification Pending (ADR-022)`) per ADR-014.

## Pros and Cons of the Options

### Option 1: Status quo

- Good: zero migration cost.
- Bad: 16/16 Known Errors are Fix Released; the overload is universal in practice.
- Bad: every consumer re-derives the sub-state by file-body scan. Every new ticket that touches this area (P048, P049, and any future detection/ranking tooling) repeats the pattern.

### Option 2: Verification Pending + `.verifying.md` + multiplier 0 (chosen)

- Good: data model matches empirical usage.
- Good: dev-work ranking uncontaminated by user-verification work.
- Good: suffix-based detection simplifies P048 and every downstream tool.
- Good: symmetric with `.parked.md` excluded-from-ranking pattern.
- Bad: one-time migration of 16 files.
- Bad: a new suffix to remember.

### Option 3: Multiplier 0.5

- Good: preserves a single ranked list.
- Bad: still mixes user-side and dev-side work; ranking still distorted.
- Bad: no fundamental improvement over status quo on the ranking-accuracy driver.

### Option 4: Multiplier 2.0 (same as Known Error)

- Good: no math change.
- Bad: treats verification work as equivalent-priority-per-effort to dev work, which is not what ranking should do.
- Bad: 16 current tickets swamp the top of the backlog, degrading the value of WSJF for selection.

## Reassessment Criteria

Revisit this decision if:

- Third-party consumers of `docs/problems/` emerge and can't easily adopt the new suffix (would be a migration-cost concern).
- The "dev work remaining" sub-state of Known Error reappears as a common resting state (if tickets start parking in Known Error before release for substantive durations, a richer status contract may be warranted).
- `manage-incident` gains its own analogous sub-state — parallel status could be inherited from this ADR or go its own way.
- The WSJF framework moves toward a two-queue model explicitly (e.g. grounded estimates from P022), at which point multiplier 0 may become redundant with an explicit queue field.

## Related

- P049: `docs/problems/049-known-error-status-overloaded-with-fix-released-substate.open.md` — the problem ticket this ADR resolves.
- P048: `docs/problems/048-manage-problem-does-not-detect-verification-candidates.open.md` — follow-up; this ADR simplifies its fix surface from file-body scan to glob.
- P047: `docs/problems/047-wsjf-effort-bucket-accuracy-gaps.open.md` — sibling theme (skill's static model doesn't track reality at the effort dimension; this ADR addresses the status dimension).
- P030: `docs/problems/030-manage-problem-verification-prompts-lack-fix-summary.closed.md` — predecessor fix for the verification prompt content.
- ADR-011: `docs/decisions/011-manage-incident-skill.proposed.md` — incident lifecycle precedent; informs the non-parallel decision for `manage-incident`.
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — commit discipline for the migration commit + any follow-on skill edits.
- ADR-020: `docs/decisions/020-governance-auto-release-for-non-afk-flows.proposed.md` — sibling lifecycle ADR; commit → score → release flow interacts with the new Verification Pending transition.
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-006: `docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
