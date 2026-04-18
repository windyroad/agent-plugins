# Problem 049: Known Error status is overloaded — "fix released, awaiting verification" deserves its own explicit status

**Status**: Open
**Reported**: 2026-04-19
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: 4.0 — (8 × 1.0) / 2

## Description

The current problem lifecycle treats "Known Error" as a single status covering two distinct sub-states:

1. **Root cause confirmed, fix NOT yet implemented.** Work is required on the dev side to implement, test, and release the fix.
2. **Fix released, awaiting user verification.** Work is required on the user side to observe the fix in production and explicitly confirm it.

The skill signals the second sub-state by appending a `## Fix Released` section inside the `.known-error.md` file. The status field and filename suffix do not change. This forces every tool, orchestrator, and reader (human or agent) to open each file's body to figure out which sub-state it is in.

Empirical evidence (2026-04-19 snapshot of this repo): **16 of 16** `.known-error.md` files in `docs/problems/` have a `## Fix Released` section. In practice the "Known Error = confirmed-but-not-fixed" sub-state is effectively never the resting state — tickets pass through it quickly and then linger indefinitely in the "fix released, awaiting verification" sub-state. The overload is not theoretical; it is universal in this project's backlog today.

Consequences:

- `docs/problems/README.md` ranking table shows `Status: Known Error` for both sub-states, so WSJF output doesn't distinguish "work on this next" from "user: please verify".
- `manage-problem review` step 9d has to open every `.known-error.md` file to check for a Fix Released section before it can prompt the user.
- AFK orchestrators (`work-problems`) that try to skip Fix Released tickets via the classifier table (`Known Error with ## Fix Released | Skip`) must also open each file, which defeats the point of the README fast-path.
- Related ticket P048 (detection of verification candidates) inherits this overload — its fix surface is complicated by having to re-derive the sub-state that could have been a first-class field.
- Ranking WSJF for a ticket with `## Fix Released` is ambiguous: its effort is already spent (dev-side), its remaining work is user-side verification, but the WSJF formula still scores it as a "Known Error × effort" item — distorting the backlog prioritisation.

Proposed: introduce a new **explicit status** between Known Error and Closed to capture the "fix released, awaiting verification" sub-state, with its own file suffix and its own ranking semantics.

## Symptoms

- Readers (humans and agents) cannot tell from the README ranking table which Known Error tickets are truly awaiting dev work vs awaiting user verification.
- `grep -L "^## Fix Released" docs/problems/*.known-error.md` returned zero files on 2026-04-19 — the "root cause confirmed, not yet fixed" sub-state is empirically vacant; all Known Error tickets in practice mean "Fix Released".
- Step 9d and the `work-problems` classifier table both have to scan file bodies to distinguish sub-states.
- WSJF scoring for Fix-Released-and-waiting items mis-weights backlog priority — their remaining work is user-side verification, not dev effort, so including them at a high Known Error multiplier (×2.0) inflates the top of the ranking and pushes real-dev-work items down.
- The `## Known Errors (Fix Released — pending verification)` separate table in `docs/problems/README.md` is a workaround for the overload — an implicit "shadow status" maintained by hand.

## Workaround

- The skill appends a `## Fix Released` section to the body of each Known Error file when the fix lands.
- The README has a separate `## Known Errors (Fix Released — pending verification)` table maintained by hand.
- Readers mentally apply the rule: "if the file body contains `## Fix Released`, treat it as Verification Pending". The rule is not encoded in the status or filename.

None of these are systemic. Every consumer of the problem data (skill code, README renderers, orchestrators, the human) repeats the same file-body check independently.

## Impact Assessment

- **Who is affected**: solo-developer persona (JTBD-001, JTBD-006) — ranking output ambiguity; plugin-developer persona (JTBD-101) — anyone building tooling against `docs/problems/` has to encode the file-body-scan rule to distinguish sub-states, and any drift between tools creates inconsistent reports.
- **Frequency**: every read of the problem backlog (review, work selection, README render). With 16 Known Error files today, essentially every interaction with the backlog hits the overload.
- **Severity**: Minor — no functional breakage. The cost is cognitive, structural, and prioritisation-accuracy; not operational.
- **Analytics**: 2026-04-19 snapshot — 16/16 `.known-error.md` files contain `## Fix Released`. Zero Known Error tickets were in the "awaiting-implementation" sub-state today.

## Root Cause Analysis

### Structural: one status, two meanings

`packages/itil/skills/manage-problem/SKILL.md` defines the lifecycle table as:

| Status | File suffix | Meaning |
|--------|-----------|---------|
| Open | `.open.md` | Reported, under investigation |
| Known Error | `.known-error.md` | Root cause confirmed, fix path clear |
| Parked | `.parked.md` | Blocked on upstream or suspended |
| Closed | `.closed.md` | Fix verified in production |

The step-by-step closure workflow is "when the fix is released, add a `## Fix Released` section but keep as `.known-error.md`". That sentence is the entire disambiguation mechanism — it lives in prose inside the SKILL.md documentation, not in the data model.

### Structural: the WSJF model has no distinct multiplier for awaiting-verification

`manage-problem` WSJF uses two status multipliers: Open (1.0) and Known Error (2.0). A ticket whose remaining work is user-side verification should arguably have a different multiplier (user-facing action queue ≠ dev-facing work queue). Today both sub-states of Known Error share ×2.0, so the ranking doesn't reflect where the work lives.

### Candidate fixes

1. **Introduce a new status "Verification Pending"** (or similarly-named) with file suffix `.verifying.md` (or `.fix-released.md` / `.pending-verification.md`). The transition is automatic when a fix is released: the skill renames the file from `.known-error.md` → `.verifying.md` and writes the `## Fix Released` section. The README and all tools can distinguish sub-states by glob alone. Addresses the core overload.
2. **Adjust the WSJF status multiplier** for the new status. Options: 0.0 (exclude from dev-work ranking, list in a separate "awaiting verification" queue), 0.5 (count but down-weight since the work isn't dev effort), or keep at 2.0 if the multiplier is intended to capture "how close to Closed" rather than "how much dev work remains".
3. **Parked-style exclusion**: treat `.verifying.md` files like `.parked.md` — exclude from the main WSJF ranking, list in a dedicated section of `docs/problems/README.md`. Keeps the dev-work ranking clean.
4. **Migrate existing files**: rename all 16 existing `.known-error.md` files that carry a `## Fix Released` section to the new suffix, in a single batch commit. Zero net information change — just making the data model match the structural state.
5. **Update downstream readers**: `work-problems` classifier table, `manage-problem review` step 9c/9d, README template, any bats tests that grep for specific suffixes. Small, mechanical set of edits.

Candidates 1 + 3 + 4 + 5 form a minimum viable fix. Candidate 2 is a standalone decision that pairs naturally with 1.

### Interaction with related tickets

- **P048** (manage-problem does not surface Fix Released tickets as verification candidates) — P049 simplifies P048's fix surface substantially. Instead of "grep each file body for Fix Released and then filter", the detection layer becomes "glob `*.verifying.md` and sort". Both tickets should land together or P049 first; P048's heuristics (exercise evidence, age, likely-verified flag) still apply on top of the cleaner status.
- **P047** (WSJF effort buckets coarse and not re-rated) — sibling "skill's static model doesn't track reality" ticket. P049 is the same theme at the status-dimension level: the data model is coarser than the actual lifecycle.
- **P030** (closed) — fixed the verification prompt content. P049 fixes the discovery surface P030's prompt fires from.

### Naming discussion (to be decided in the fix's ADR)

- "Verification Pending" — clear intent, slightly verbose.
- "Fix Released" — matches the current section header; user-recognisable; risk of confusion with the informal phrase.
- "Awaiting Verification" — clearer about who is blocked (the user).
- "Staged for Closure" — emphasises that closure is the next transition.

File suffix options: `.verifying.md`, `.pending-verification.md`, `.fix-released.md`, `.awaiting-verification.md`. Prefer concise suffix that still round-trips through `ls` output cleanly.

### Investigation Tasks

- [ ] Architect review: this change touches the problem-file data model — a core contract between `manage-problem`, `manage-incident`, `work-problems`, and any downstream renderer. Expect a new ADR to capture the status addition and migration plan. Likely path: `docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md`.
- [ ] Decide the status name and file suffix in the ADR.
- [ ] Decide WSJF status-multiplier semantics for the new status (candidate 2 above).
- [ ] Enumerate every SKILL.md / README / bats reference to `.known-error.md` or "Known Error" status that needs updating. Non-exhaustive list: `packages/itil/skills/manage-problem/SKILL.md` (lifecycle table, steps 7, 9b step 10 auto-transition, 9c, 9d, closing workflow), `packages/itil/skills/work-problems/SKILL.md` (classifier table, step 3 tie-break), `packages/itil/skills/manage-incident/SKILL.md` (linked-problem gating), `docs/problems/README.md` template + existing "Known Errors (Fix Released)" table.
- [ ] Draft migration script: `git mv` each `.known-error.md` with `## Fix Released` to the new suffix, preserving git history via rename detection. Verify on a branch first.
- [ ] Update bats tests to reference the new suffix where applicable; add new tests asserting the lifecycle-table and the WSJF multiplier for the new status.
- [ ] Coordinate with P048: after P049 ships, P048's fix can drop the file-body scan and use the suffix-based detection. Update P048's fix strategy accordingly.
- [ ] Consider whether `manage-incident` gains an analogous sub-state. Incidents have Investigating / Mitigating / Restored / Closed (ADR-011). "Restored" arguably has the same user-verification lag as Known Error here — but incident closure rules already force a linked-problem status check, which sidesteps the issue. Document the deliberate non-parallel.

## Related

- `packages/itil/skills/manage-problem/SKILL.md` — primary fix target (lifecycle table, transition rules, WSJF, step 9d).
- `packages/itil/skills/work-problems/SKILL.md` — classifier table "Known Error with `## Fix Released` | Skip" becomes a glob instead.
- `packages/itil/skills/manage-incident/SKILL.md` — linked-problem gating rule (step 9) references `.known-error.md` suffix; needs updating.
- `docs/problems/README.md` — ranking table + "Known Errors (Fix Released — pending verification)" shadow table; both simplify under the new status.
- P048: `docs/problems/048-manage-problem-does-not-detect-verification-candidates.open.md` — complementary; P049 simplifies P048's implementation surface.
- P047: `docs/problems/047-wsjf-effort-bucket-accuracy-gaps.open.md` — sibling theme (skill's static model doesn't track reality).
- P030: `docs/problems/030-manage-problem-verification-prompts-lack-fix-summary.closed.md` — predecessor; fixed the verification prompt content, not the discovery surface.
- ADR-011: `docs/decisions/011-manage-incident-skill.proposed.md` — incident lifecycle precedent; informs the non-parallel decision.
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — governance commit rules apply to the migration commits and ADR authoring.
- Anticipated: `docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md` — the ADR that would land with the fix.
