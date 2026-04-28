# Problem 141: AFK iter `packages/<plugin>/` commits without changesets — orchestrator-main-turn back-fill is fragile recovery, hook-level enforcement preferable

**Status**: Open
**Reported**: 2026-04-29
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3) — observed twice in single session (40% miss rate across 5 publishable iters)
**Effort**: M — new PreToolUse:Bash hook matching `git commit`; deny when staged diff includes `packages/<plugin>/` files but `.changeset/<plugin>-*.md` is not staged. Plus matching behavioural bats per ADR-037 + P081.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-28 / 2026-04-29 across the long `/wr-itil:work-problems` AFK loop session: iter 2 (P130 commit `b9da37e`) shipped `packages/itil/skills/work-problems/SKILL.md` + new bats without authoring `.changeset/wr-itil-p130-*.md`. Orchestrator main-turn back-filled at `dcc65b4`. Iter 7 (P134 commit `a8b6f18`) shipped 5-SKILL changes + new advisory script + 13 new bats without changeset. Orchestrator back-filled at `ac2425e`. Pattern: 2/5 publishable iters omitted changesets. Recovery cost: ~2× orchestrator main-turn commits + ~$2 risk-scorer round-trips per recovery.

## Description

`/wr-itil:work-problems` iteration subprocesses (per ADR-032 subprocess-boundary variant) are dispatched with explicit `manage-problem` SKILL.md guidance to author changesets. The iter prompt template even includes a "CHANGESET DISCIPLINE" reminder. Despite this, ~40% of publishable iters in the 2026-04-28 session omitted changesets — the prompt-time reminder is insufficient.

The recovery pattern (orchestrator main-turn back-fill) is:
1. Step 6.5 risk-scorer detects the missing changeset (or it goes undetected until release-time)
2. Orchestrator main turn writes a `.changeset/wr-<plugin>-<ticket>-*.md` file from session evidence
3. Risk-scorer rescore + commit gate
4. Commit "docs(orchestrator-repair): add missing P<NNN> changeset for <SHA>"
5. Continue loop

This works but:
- Adds ~5 min per recovery
- Splits one logical fix across 2 commits (the original iter commit + the back-fill)
- Relies on the orchestrator noticing — silent omissions could ship to npm without the changelog entry

A PreToolUse:Bash hook on `git commit` that detects the pattern and denies with a clear directive would prevent the omission at the source.

## Symptoms

- Iter commit lands `packages/<plugin>/` files without `.changeset/<plugin>-*.md` in the same commit
- Orchestrator's Step 6.5 risk scorer or main-turn observation catches it (sometimes)
- Recovery requires 1-2 additional orchestrator main-turn commits
- Cumulative session cost: 2 back-fills × ~5min = 10min wall-clock + ~$4 across this session
- Pattern recurs across multiple sessions

## Workaround

Orchestrator main-turn back-fill (described above). Manual; relies on noticing the omission.

## Impact Assessment

- **Who is affected**: every `/wr-itil:work-problems` AFK loop session that ships `packages/<plugin>/` fixes. Higher-frequency than per-incident: every long session is a candidate for one or more iter omissions.
- **Frequency**: ~40% of publishable iters in the 2026-04-28 evidence session.
- **Severity**: Moderate. Each omission costs ~5min recovery + risk of silent npm-publish-without-changelog if undetected.
- **Likelihood**: Likely. Iter prompt-time reminder is insufficient signal; subprocess agents under context pressure systematically miss the requirement.
- **Analytics**: 2026-04-28 session: 2 back-fills (`ac2425e` for P130, orchestrator-main-turn for P134). 5 publishable iters total. 40% miss rate.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm hook-level enforcement is the right shape vs. iter-prompt strengthening (architect-design call). Lean: hook — prompt-level guidance has demonstrably failed.
- [ ] Define the detection logic:
  - **PreToolUse:Bash matching `git commit`**: parse `git diff --cached --stat`; if any `packages/<plugin>/*` file is staged, check that `.changeset/<plugin>-*.md` is also staged. If not, deny with directive: "Staged `packages/<plugin>/` files require `.changeset/<plugin>-*.md`. Author one before committing."
  - **Bypass mechanism**: env var `BYPASS_CHANGESET_GATE=1` for legitimate non-publishable commits (e.g. CI workflow edits, .github/* changes).
  - **Allow-list paths**: `packages/<plugin>/test/`, `packages/<plugin>/scripts/test/` are testable-only changes; some test additions may not need changesets. Architect verdict on whether to allow-list test paths or require changesets for them too.
- [ ] Decide deny shape:
  - Hard deny (commit blocked, agent must author changeset)
  - Advisory deny with `BYPASS_CHANGESET_GATE` env var override (agent decides)
- [ ] Behavioural bats per ADR-037 + P081 covering: detection on staged packages/* without changeset (deny); detection with changeset (allow); test-only paths (allow or deny per architect verdict); BYPASS env var (allow); non-publishable paths like .github/* (allow).
- [ ] Plugin manifest registration in `packages/itil/.claude-plugin/plugin.json`.

### Preliminary hypothesis

Iter subprocesses operate under context pressure (heavy SKILL.md + ticket body + architect/JTBD prompt content). The "author a changeset" reminder competes with N other reminders and is sometimes dropped. Hook-level enforcement makes the requirement unmissable without adding to the iter's context budget.

## Fix Strategy

**Kind**: create

**Shape**: hook (PreToolUse:Bash matching `git commit`)

**Suggested name**: `packages/itil/hooks/itil-changeset-discipline.sh`

**Scope**: deny `git commit` when staged diff includes `packages/<plugin>/*` files but no matching `.changeset/<plugin>-*.md` is staged. Allow when changeset is present, or when `BYPASS_CHANGESET_GATE=1` is set.

**Triggers**: every `git commit` Bash invocation.

**Prior uses (this session)**:
- 2026-04-28 iter 2 P130 (`b9da37e`) — packages/itil/skills/work-problems/SKILL.md + bats; no changeset; back-fill at `dcc65b4`
- 2026-04-28 iter 7 P134 (`a8b6f18`) — 5 SKILL.md + scripts/check-problems-readme-budget.sh + 13 bats; no changeset; back-fill at `ac2425e`

**Composes-with**: P073 (changeset author-time gate — same surface, different layer; P073 fires at `.changeset/*.md` Write/Edit, P141 at `git commit`), P140 (Step 6.5 fix-and-continue — orchestrator main-turn changeset back-fill IS one of the fix-and-continue patterns; if the hook prevents the omission, fewer Step 6.5 recoveries needed).

**Out of scope**: detecting omissions on already-pushed commits (that's release-cycle territory); auto-authoring the changeset (requires LLM judgment about scope/severity).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P073, P140, P135 (decision-delegation contract — hook IS framework-resolved enforcement)

## Related

- **P073** (`docs/problems/073-...open.md`) — changeset author-time gate; same family of friction at a different surface.
- **P140** (`docs/problems/140-...verifying.md`) — fix-and-continue on CI failure; orchestrator main-turn back-fill is one fix-and-continue pattern P141 could prevent.
- **P135** (`docs/problems/135-...verifying.md`) — decision-delegation contract.
- **ADR-014** — governance skills commit their own work.
- **ADR-018** — release cadence.
- **ADR-009** — gate marker conventions.
- 2026-04-28 session evidence: iter 2 + iter 7 omissions documented in commits `dcc65b4` and `ac2425e` (orchestrator main-turn back-fills).
