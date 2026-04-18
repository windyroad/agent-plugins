# Problem 028: Governance skills should auto-release and auto-install after completing fixes

**Status**: Known Error
**Reported**: 2026-04-16
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3)
**Effort**: M (auto-release portion); L overall if auto-install is in scope
**WSJF**: 4.5 — (9 × 2.0) / 4 once split; or 9 × 1.0 / 2 = 4.5 as currently scoped

## Description

When a governance skill (e.g., `manage-problem work`) completes a fix — commits, creates a changeset, and closes the problem — it stops there. The user must then manually trigger `npm run push:watch`, merge the release PR via `npm run release:watch`, pull the marketplace, and reinstall the affected plugins before the fix takes effect in their Claude Code session.

This contradicts the lean release principle (ADR-014) and the "governance must not interrupt flow" constraint (JTBD-001 / JTBD-005). The fix is functionally complete but not usable until the user discovers and completes a 4-step release+install sequence.

Observed: after P027 fix was committed and closed, user stated "this should have released by itself. Maybe even installed."

## Symptoms

- After a governance skill fix is committed, the user must manually run `npm run push:watch`, then `npm run release:watch`, then pull the marketplace cache, then `claude plugin install` to pick up the new code.
- The problem closure commit includes a changeset but the release pipeline is not triggered automatically.
- The installed plugin continues running the old code until the manual install step is completed.

## Workaround

Run manually: `npm run push:watch` → merge PR via `npm run release:watch` → `claude plugin install <package>@windyroad --scope project`.

## Impact Assessment

- **Who is affected**: Solo-developer persona (JTBD-001, JTBD-005) — every governance skill fix session
- **Frequency**: Every time a governance skill fix is completed and released
- **Severity**: Medium — fix is complete but unusable; the 4-step manual sequence is friction that directly contradicts the "fast governance" premise
- **Analytics**: Observed this session after P027 fix

## Root Cause Analysis

### Confirmed Root Cause (2026-04-18)

Source-code evidence from `packages/itil/skills/manage-problem/SKILL.md`
step 11 (line 395+) and `packages/architect/skills/create-adr/SKILL.md`
(equivalent terminal step):

- Step 11 explicitly lists three actions: `git add`, satisfy commit gate,
  `git commit`. There is no `npm run push:watch` or `npm run release:watch`
  call. The lean-release principle is referenced as prose at line 96
  (under "Working a Problem") but not codified as an automated step.
- ADR-014 (governance skills commit their own work) terminates the
  workflow at commit. The "natural extension" P028 calls out — pushing
  and releasing — is not in the ADR.
- `claude plugin install` is shell-only; calling it from a skill via
  Bash is possible but has session-restart side-effects (the running
  session does not pick up new code from a freshly-installed plugin
  without a restart).

### Partial Coverage from ADR-018 (2026-04-18)

ADR-018 (Inter-iteration release cadence for AFK loops) and the P041 fix
that implemented it (commit `87c2ecf`, `@windyroad/itil@0.4.1`) shipped
the auto-release behaviour for the **AFK orchestrator case only**:

- `work-problems` Step 6.5 now invokes `wr-risk-scorer:assess-release`
  after each iteration commit and runs `npm run push:watch` +
  `npm run release:watch` if push/release risk reaches appetite.
- This works — demonstrated live in the P040/P041 release cycles during
  this session.

What is still missing for P028:

1. **Non-AFK governance skill flows** — when the user invokes
   `/wr-itil:manage-problem` or `/wr-architect:create-adr` directly
   (outside the work-problems orchestrator), step 11 still ends at
   commit. The user must trigger release manually.
2. **Auto plugin install on the user's machine after release** — even
   when release lands on npm, the running Claude Code session does not
   pick up the new plugin code until the marketplace cache refreshes
   AND the plugin is re-installed AND the session is restarted.
3. **Plugin manifest sync (P042)** — every release without a matching
   `plugin.json` bump leaves the marketplace serving stale code, which
   makes auto-install moot.

### Architect Decision Needed

The remaining gap splits cleanly into two concerns:

- **Auto-release for non-AFK governance** (M effort): extend ADR-014
  to require step 11 = commit + `npm run push:watch` + `npm run
  release:watch` (when changesets queued). Mirror Step 6.5 in
  manage-problem and create-adr terminal steps. Reuse the fail-safe
  semantics from ADR-018 (stop on `release:watch` failure; no retry).
- **Auto plugin install after release** (L effort, riskier): a
  separate decision. Installing a new plugin version into the user's
  active session has surprising side-effects. May warrant deferring
  indefinitely unless Claude Code adds in-session plugin reload.

The auto-install concern is independent enough to split into its own
ticket. The auto-release concern blocks on an ADR-014 amendment (or new
ADR citing ADR-014 + ADR-018 as the lineage).

### Workaround

User manually runs `npm run push:watch` then `npm run release:watch`
after each governance commit. Already what the user does today; the
P040/P041 fixes during this session demonstrate the pattern works
non-interactively.

### Investigation Tasks

- [x] Determine whether `push:watch` + `release:watch` can be appended
      to step 11 as a standard post-commit sequence — confirmed yes
      (demonstrated by ADR-018 / Step 6.5 in work-problems)
- [x] Check whether `claude plugin install` can be called from within
      the skill — confirmed possible via Bash, but with session-restart
      side-effects that make it unsafe in interactive sessions
- [x] Consider whether this belongs in SKILL.md or as a shared hook
      — recommend per-SKILL.md step (mirrors Step 6.5 pattern); a
      shared helper script could come later if a third skill needs it
- [x] Evaluate risk: confirmed auto-release is reversible (the npm
      release is the action; `npm run release:watch` already requires
      passing CI which is the natural confirmation gate per ADR-013
      Rule 6)
- [ ] Architect decision: amend ADR-014 OR create a new ADR for "Step
      11 must include push and release" — blocking work
- [ ] Decide whether to split auto-install into a separate ticket
      (recommended by current investigation)
- [ ] Once decision lands: implement step 11 changes in
      manage-problem and create-adr (and any other governance skills
      with terminal commit step)

## Related

- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — lean release principle; this problem is the natural extension
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" target
- JTBD-005: `docs/jtbd/solo-developer/JTBD-005-assess-on-demand.proposed.md` — must not leave task context
- P027: `docs/problems/027-manage-problem-work-flow-is-expensive.known-error.md` — preceded this; P027 fix required manual release+install
