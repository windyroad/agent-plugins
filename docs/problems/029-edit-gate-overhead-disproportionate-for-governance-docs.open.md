# Problem 029: Edit gate overhead disproportionate for governance documentation changes

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)

## Description

The architect and JTBD pre-edit hooks fire on every project file edit, including documentation-only governance operations such as:
- Closing a problem (`git mv` + one-line status field update)
- Transitioning a problem to Known Error
- Updating investigation task checkboxes

These edits carry no architectural risk and no JTBD alignment risk — they are the output of governance skills doing their job, not code changes. Yet the hooks trigger mandatory agent delegations before each edit is allowed. The user rejected both gates during this session, treating them as unnecessary overhead.

When the user denies the architect or JTBD delegation, the edit is blocked and the governance skill stalls mid-operation. This forces either: (a) the user to approve the delegation despite considering it pointless, or (b) the session to be restructured around the blocked edit.

Observed this session: architect review rejected for P023 closure (one-line status change) and for P027 investigation start.

## Symptoms

- Architect + JTBD agents prompted before every problem file edit, including trivial status updates and `git mv` renames
- User rejecting agent delegations for documentation-only governance operations
- Governance skills stalling mid-operation when delegation is denied
- Friction observed: "this should have released by itself" — user expects governance ops to be low-friction end-to-end

## Workaround

Approve the architect and JTBD delegations even for trivial edits (they typically find no issues). Accept the overhead.

## Impact Assessment

- **Who is affected**: Solo-developer persona (JTBD-001, JTBD-005) — every governance session
- **Frequency**: Every problem file edit, every session
- **Severity**: Medium — interrupts flow, creates decision fatigue, contradicts "governance must be fast enough to not interrupt work" premise
- **Analytics**: Two rejected delegations observed this session

## Root Cause Analysis

### Preliminary Hypothesis

1. **Hooks use a blanket pattern match** on file paths — `docs/decisions/` and all project files trigger the architect check regardless of whether the change is architectural or documentation-only.
2. **No change-type signal** — the hooks cannot distinguish "closing a problem ticket" from "adding a new dependency". Both look like file edits.
3. **No governance-mode exemption** — there is no concept of "this edit is the output of an approved governance skill" that would suppress the overhead gates.

Potential fix directions:
- Exempt `docs/problems/*.md` and `docs/decisions/*.md` from the architect/JTBD pre-edit hooks (governance files have their own skill-driven process)
- Add a marker/env var that active governance skills can set to suppress overhead gates for their own outputs
- Configure the hooks to skip delegation when the change is a documentation-only edit (no `.ts/.js/.sh` files touched)

### Investigation Tasks

- [ ] Audit which hook(s) fire on `docs/problems/` edits — identify whether it's the architect hook, JTBD hook, WIP hook, or all of them
- [ ] Check whether `docs/problems/*.md` actually needs architect or JTBD review — expected answer: No, problem files are the output of an approved governance skill and carry no architectural risk
- [ ] Prototype exemption: add `docs/problems/` and `docs/decisions/` to the architect/JTBD hook blocklist and test that governance skill operations complete without gates firing
- [ ] Check whether a governance-mode env var (set by manage-problem, cleared on exit) is a cleaner mechanism than a path-based exemption

## Related

- P027: `docs/problems/027-manage-problem-work-flow-is-expensive.known-error.md` — sibling problem; both reduce governance overhead
- P028: `docs/problems/028-governance-skills-should-auto-release-and-install.open.md` — sibling problem; all three are aspects of "governance is too slow"
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" outcome target
- ADR-007 / ADR-008: JTBD gate scope decisions — defines what the gate covers
