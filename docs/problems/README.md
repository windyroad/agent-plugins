# Problem Backlog

> Last reviewed: 2026-04-17 (full re-rank; P031 known error + fix released; P029 fix released; label corrections)
> Run `/wr-itil:manage-problem review` to refresh.

## WSJF Rankings

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 24.0 | P031 | Stale cache detection in manage-problem work | 12 High | Known Error | S |
| 18.0 | P029 | Edit gate overhead for governance docs | 9 Med | Known Error | S |
| 12.0 | P021 | Governance skill structured prompts | 12 High | Known Error | M |
| 8.0 | P020 | No on-demand assessment skills | 16 High | Known Error | L |
| 4.5 | P016 | manage-problem should split multi-concern tickets | 9 Med | Open | M |
| 4.5 | P017 | create-adr should split multi-decision records | 9 Med | Open | M |
| 4.5 | P028 | Governance skills should auto-release and auto-install | 9 Med | Open | M |
| 4.0 | P018 | TDD enforce BDD + Example Mapping principles | 16 High | Open | L |
| 4.0 | P022 | Agents must not fabricate time estimates | 16 High | Open | L |
| 4.0 | P024 | Risk-scorer WIP flag uncommitted completed work | 8 Med | Open | M |
| 4.0 | P026 | install-utils duplicated across packages | 16 High | Open | L |
| 3.0 | P014 | No lightweight aside invocation for governance skills | 12 High | Open | L |
| 2.25 | P015 | TDD vague Gherkin outcome steps | 9 Med | Open | L |
| 1.5 | P012 | Skill testing harness scope undefined | 6 Med | Open | L |
| 1.5 | P019 | Deprecate single-file JTBD fallback | 6 Med | Open | L |

## Known Errors (Fix Released — pending verification)

| ID | Title | Released in |
|----|-------|-------------|
| P020 | No on-demand assessment skills | v0.3.2 |
| P021 | Governance skill structured prompts | v0.3.2 |
| P029 | Edit gate overhead for governance docs | commit ac9d453 |
| P031 | Stale cache detection in manage-problem work | this session |

## Parked

| ID | Title | Reason | Parked since |
|----|-------|--------|-------------|
| P005 | Connect setup skill doesn't match Discord plugin | Upstream: same --channels bug as P007/P008 — all connect work suspended | 2026-04-16 |
| P007 | Discord inbound reactions not delivered | Upstream: Discord channel plugin doesn't forward reaction events | 2026-04-16 |
| P008 | AskUserQuestion unavailable with --channels | Upstream: Anthropic `--channels` flag removes AskUserQuestion | 2026-04-16 |
