# Problem Backlog

> Last reviewed: 2026-04-17 (P026 Fix Released; P033/P016/P017 rankings refreshed)
> Added 2026-04-18 without full re-review: P040 (from session retrospective). Run `/wr-itil:manage-problem review` to refresh rankings.
> Updated 2026-04-18: P041 → Known Error after architect review (ADR-018 prerequisite identified; effort re-sized M → L; WSJF unchanged at 8.0).
> Updated 2026-04-18: P040 → Known Error after architect review (ADR-019 prerequisite identified — distinct from ADR-018; effort re-sized M → L; WSJF unchanged at 6.0).
> Added 2026-04-18 without full re-review: P042 (changesets does not sync plugin manifest version), P043 (next-ID collision guard split from P040). Run `/wr-itil:manage-problem review` to refresh rankings.
> Updated 2026-04-18: P041 fix released (@windyroad/itil@0.4.1, commit 87c2ecf); P040 fix released (@windyroad/itil@0.4.2, commit 9c6019e). Both awaiting user verification.
> Updated 2026-04-18: P028 → Known Error after investigation (ADR-018 partially covers via Step 6.5 for AFK orchestrator; non-AFK governance flows still need ADR-014 amendment or new ADR; auto-install split recommended).
> Updated 2026-04-18: P043 fix released (@windyroad/itil@0.4.3 + @windyroad/architect@0.3.2, commit 359ec7c). Manage-problem and create-adr now compute next ID as max(local, origin) + 1.
> Added 2026-04-18 without full re-review: P044 (run-retro does not recommend new skills when it should). Run `/wr-itil:manage-problem review` to refresh rankings.
> Updated 2026-04-19: P028 split on architect review — auto-install concern moved to P045 (deferred, blocked on Claude Code in-session plugin reload). Narrowed P028 (non-AFK auto-release) fix implemented under ADR-020 and awaiting release.
> Updated 2026-04-19: P044 → Known Error after review; fix implemented (run-retro Step 2/4b/5 extended for skill candidates + bats test); awaiting release.

## WSJF Rankings

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 24.0 | P031 | Stale cache detection in manage-problem work | 12 High | Known Error | S |
| 18.0 | P029 | Edit gate overhead for governance docs | 9 Med | Known Error | S |
| 12.0 | P021 | Governance skill structured prompts | 12 High | Known Error | M |
| 8.0 | P020 | No on-demand assessment skills | 16 High | Known Error | L |
| 4.5 | P016 | manage-problem should split multi-concern tickets | 9 Med | Known Error | M |
| 4.5 | P017 | create-adr should split multi-decision records | 9 Med | Known Error | M |
| 9.0 | P028 | Governance skills should auto-release (non-AFK) | 9 Med | Known Error | M |
| 8.0 | P044 | run-retro does not recommend new skills when it should | 8 Med | Known Error | M |
| 4.5 | P033 | No persistent risk register for ISO 31000 / ISO 27001 | 9 Med | Known Error | L |
| 8.0 | P041 | work-problems does not enforce release cadence | 16 High | Known Error | L |
| 6.0 | P040 | work-problems does not fetch origin before starting | 12 High | Known Error | L |
| 4.0 | P042 | changesets does not sync plugin manifest version | 16 High | Open | L |
| 9.0 | P043 | Next-ID collision guard in ticket-creator skills | 9 Med | Known Error | M |
| 4.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | L |
| 4.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | L |
| 4.0 | P024 | Risk-scorer WIP flag uncommitted completed work | 8 Med | Known Error | L |
| 3.0 | P014 | No lightweight aside invocation for governance skills | 12 High | Open | L |
| 2.25 | P015 | TDD vague Gherkin outcome steps | 9 Med | Open | L |
| 1.5 | P012 | Skill testing harness scope undefined | 6 Med | Open | L |
| 1.5 | P019 | Deprecate single-file JTBD fallback | 6 Med | Open | L |
| 1.5 | P034 | Centralise risk reports for cross-project skill improvement | 6 Med | Open | L |
| 1.5 | P045 | Auto plugin install after governance release (deferred) | 6 Med | Open | L |

## Known Errors (Fix Released — pending verification)

| ID | Title | Released in |
|----|-------|-------------|
| P016 | manage-problem should split multi-concern tickets | 2026-04-17 |
| P017 | create-adr should split multi-decision records | 2026-04-17 |
| P020 | No on-demand assessment skills | v0.3.2 |
| P021 | Governance skill structured prompts | v0.3.2 |
| P024 | Risk-scorer WIP flag uncommitted completed work | 2026-04-17 |
| P026 | install-utils duplicated across packages | 2026-04-17 |
| P029 | Edit gate overhead for governance docs | commit ac9d453 |
| P031 | Stale cache detection in manage-problem work | commit 824cb2c |
| P033 | No persistent risk register for ISO 31000 / ISO 27001 | 2026-04-17 |
| P041 | work-problems does not enforce release cadence | @windyroad/itil@0.4.1 (commit 87c2ecf) |
| P040 | work-problems does not fetch origin before starting | @windyroad/itil@0.4.2 (commit 9c6019e) |
| P043 | Next-ID collision guard in ticket-creator skills | @windyroad/itil@0.4.3 + @windyroad/architect@0.3.2 (commit 359ec7c) |
| P028 | Governance skills should auto-release (non-AFK) | pending — ADR-020 |
| P044 | run-retro does not recommend new skills when it should | pending — @windyroad/retrospective |

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P005 | Connect setup skill doesn't match Discord plugin | Upstream: same --channels bug as P007/P008 — all connect work suspended | 2026-04-16 |
| P007 | Discord inbound reactions not delivered | Upstream: Discord channel plugin doesn't forward reaction events | 2026-04-16 |
| P008 | AskUserQuestion unavailable with --channels | Upstream: Anthropic `--channels` flag removes AskUserQuestion | 2026-04-16 |
