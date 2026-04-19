# Problem 039: Autonomous loops conflate diagnose with implement

**Status**: Open
**Reported**: 2026-04-17
**Priority**: 16 (High) — Impact: Significant (4) x Likelihood: Likely (4)
**Effort**: XL — diagnose-before-implement subagent template + hypothesis-verification gate + ADR extending 013/014/016 + cross-skill rollout (work-problems, manage-incident, others)
**WSJF**: 2.0 — (16 × 1.0) / 8

## Description

Autonomous multi-step loops (WSJF problem work, incident response, feature implementation) frequently race from a prompt directly into code changes without first producing a verified root-cause hypothesis with evidence. The result: fixes that are logically coherent against the *wrong* model of the problem ship through the TDD+ADR+release pipeline before the diagnosis error is caught — forcing revert-and-retry cycles.

The pattern surfaces as "Wrong Approach" (54 instances) and "Buggy Code" (41 instances) — the two dominant friction types across 30 days of sessions (`/Users/tomhoward/.claude/usage-data/report.html`, 2026-03-17 to 2026-04-16, 1,464 messages across 86 sessions). Specific examples in the report:

- **RapidAPI outage misdiagnosis**: Claude diagnosed a live production outage as a frontend/worker/API-key issue and proposed a RapidAPI-vendor-locked fix before user screenshots forced recognition of the real gateway bug affecting all consumers.
- **P140 shipped without P141**: Claude removed capture buttons without the conditional resume-recording path the user had explicitly required, introducing stale-links bugs requiring multiple follow-up fixes.
- **P011 "literal replay" requirement**: First green test didn't prove the fix — the test had to be rewritten to replay the actual bug literally.

The insights report's recommended pattern is "Split 'investigate' from 'implement'": before any fix, (1) state the hypothesis, (2) show evidence, (3) write a failing test that reproduces the *actual* bug (verify it fails for the right reason), (4) wait for acknowledgement, then (5) implement.

The `wr-itil:work-problems` skill (JTBD-006) partially addresses this for AFK batch mode by forcing investigation-first on Open problems with no leads. But the pattern is broader — incident response (JTBD-201), feature implementation, and refactors all exhibit it.

## Symptoms

- Fixes land, tests go green, but the fix addresses the wrong root cause — revert-and-retry required
- Re-work cycles visible in session replays: file written → reverted → rewritten, often within the same session
- High "Wrong Approach" friction count (54 over 30 days) relative to "Misunderstood Request" (17) — i.e., Claude understood the request but attacked it wrong
- Incident response starts with mitigation/fix attempts before reproduction is established
- Dependent tickets (e.g., P141 depends on P140) are closed without the dependency being honoured

## Workaround

Explicitly prompt "Before writing any fix: (1) state the hypothesis, (2) show evidence, (3) write a failing test that reproduces the actual bug (verify it fails for the right reason), (4) wait for my ack before implementing." This is the insights report's recommended copy-paste prompt and consistently produces higher fully_achieved rates.

## Impact Assessment

- **Who is affected**: Solo-developer persona using autonomous loops (JTBD-006), tech-lead/consultant during incident response (JTBD-201)
- **Frequency**: 95 instances of Wrong Approach + Buggy Code in 30 days ≈ 3+ per session average
- **Severity**: Significant — the revert-and-retry cycles compound into lost hours and risk shipping real regressions when a partial fix masks the real bug
- **Analytics**: `/Users/tomhoward/.claude/usage-data/report.html` — top two primary friction types combined account for ~61% of all flagged friction instances

## Root Cause Analysis

### Investigation Tasks

- [ ] Determine whether the fix belongs (a) in individual skills (manage-problem, manage-incident, auto-release) or (b) in a shared "diagnose-before-implement" subagent template that orchestrator skills delegate to
- [ ] Design a structured hypothesis+evidence output format that subsequent TDD steps can verify (hypothesis cites file:line or log line; failing test must exercise the cited path)
- [ ] Build a "hypothesis verification" gate: after the test goes RED, confirm it fails *for the reason in the hypothesis*, not for a trivial reason (file not found, typo)
- [ ] Consider an ADR if this introduces a new subagent pattern or extends ADR-013/014/016 (per wr-architect advisory)
- [ ] Create a reproduction test: seed a known misdiagnosis pattern, assert the gate blocks implementation until hypothesis+evidence are produced
- [ ] Create INVEST story for permanent fix

## Related

- [JTBD-006](../jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md) — AFK backlog progression; scope-expansion outcome requires conservative handling which implies diagnose-first
- [JTBD-201](../jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md) — incident response; "hypotheses cite evidence (logs, repro, diff, metric) before any mitigation is attempted" is the exact principle being violated
- [ADR-013](../decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — structured interaction at branch points; diagnose/implement is a branch point
- [ADR-014](../decisions/014-governance-skills-commit-their-own-work.proposed.md) — commit-gate behaviour that would interact with the hypothesis-verification step
- [ADR-016](../decisions/016-wip-verdict-commit-for-completed-governance-work.proposed.md) — WIP verdict contract; diagnose-first would extend the verdict surface
- `packages/itil/skills/work-problems/SKILL.md` — AFK orchestrator that partially enforces this for Open problems
- `packages/itil/skills/manage-incident/SKILL.md` — incident workflow that should most strictly enforce this
- `/Users/tomhoward/.claude/usage-data/report.html` — insights report evidence (2026-03-17 to 2026-04-16)
- P022 — agents must not fabricate time estimates (shares "evidence-before-claims" pattern)
- P011 (closed) — literal replay requirement; same class of bug
