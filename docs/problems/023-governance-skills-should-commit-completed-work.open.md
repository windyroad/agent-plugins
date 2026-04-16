# Problem 023: Governance skills should commit completed work, not defer to user

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)

## Description

The manage-problem skill (step 11) says "Do not commit — the user will commit when ready." This instruction actively works against the lean release principle: completed work sits uncommitted, accumulating WIP risk. If the session ends, context compresses, or a conflicting change lands, the uncommitted work is at risk of being lost or requiring manual recovery.

The correct behaviour: after completing a discrete unit of work (problem file update, Known Error transition, fix implementation), the skill should commit the changes immediately with a descriptive commit message. This aligns with the lean principle of reducing WIP and keeping the pipeline flowing — the risk-scorer can then assess the committed work and the release pipeline can pick it up.

This is not limited to manage-problem. The pattern "Do not commit — the user will commit when ready" appears to be a default assumption across governance skills. Every skill that produces file changes should commit its completed work unless the user has explicitly asked it not to.

## Symptoms

- manage-problem `work` mode completes a fix, updates problem files, transitions status — then says "Ready to commit when you are" instead of committing.
- Uncommitted changes accumulate across multiple problem-work iterations in a single session.
- If the session ends unexpectedly, all uncommitted governance artefact changes are lost.
- The risk-scorer WIP mode cannot assess uncommitted changes (they aren't in git history yet), creating a blind spot.
- The "Do not commit" instruction contradicts the lean release principle documented in the project.

## Workaround

User manually commits after each skill operation. Friction, not harm.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — manual commit step is unnecessary friction that slows the governance-work-release cycle.
  - Solo-developer persona (JTBD-002 Ship with Confidence) — uncommitted work is invisible to the risk-scorer pipeline, creating an unscored gap.
  - Tech-lead persona — WIP accumulation makes it harder to audit what governance work has been done.
- **Frequency**: Every manage-problem operation that produces file changes (create, update, transition, work).
- **Severity**: Medium. No data loss if session completes normally, but risk of loss on unexpected session end. Compounding friction across multi-problem work sessions.
- **Analytics**: Observed this session — manage-problem `work P021` completed SKILL.md edits + problem file transition, then asked user to commit instead of committing.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit manage-problem SKILL.md for all "Do not commit" / "the user will commit" instructions. Replace with "commit the changes with a descriptive message referencing the problem ID".
- [ ] Audit manage-incident SKILL.md for the same pattern.
- [ ] Audit other governance skills (create-adr, update-guide, update-policy, run-retro) for the same pattern.
- [ ] Define the commit-message convention for governance-skill commits (e.g., `docs(problems): transition P021 to known-error` or `fix(itil): amend manage-problem SKILL.md for P021`).
- [ ] Ensure the skill's `allowed-tools` includes Bash (for `git commit`) or that the skill instructs the primary agent to commit.

## Related

- `packages/itil/skills/manage-problem/SKILL.md` line ~280 — "Do not commit" instruction
- Session evidence: Image #5 showing "Ready to commit when you are" after P021 work
- P024: risk-scorer WIP mode should flag uncommitted completed work
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
