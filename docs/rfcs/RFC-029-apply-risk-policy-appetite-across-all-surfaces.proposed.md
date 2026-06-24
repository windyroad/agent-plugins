---
status: proposed
rfc-id: apply-risk-policy-appetite-across-all-surfaces
reported: 2026-06-24
human-oversight: confirmed
oversight-date: 2026-06-25
decision-makers: [Tom Howard]
problems: [P377]
adrs: []
jtbd: []
stories: []
---

# RFC-029: Apply RISK-POLICY appetite faithfully across all surfaces

**Status**: proposed
**Reported**: 2026-06-24
**Problems**: P377
**ADRs**: (none yet — ADR-013/042/044 amendments land in Slice 1)
**JTBD**: (none)

## Summary

P377 found that skills, agents, and hooks **override** RISK-POLICY appetite instead of applying it. RISK-POLICY § Risk Appetite says above appetite → block/halt; it sanctions no "ask the user to commit anyway" path. This RFC closes the gap so the framework, not a consent gate, governs risk.

**Slice decomposition** (detail in `docs/plans/` P377 plan; each slice is its own ADR-014 commit carrying `Refs: RFC-029`):

1. **Governance (ADRs)** — extend ADR-042 Rule 1 from "push or release" to "commit, push, or release" (never above appetite, auto-remediate, never ask) + write the incident-as-risk-reducing scoring framing (live realised-risk baseline; no incident carve-out) into the ADR-042 body; narrow ADR-044 category-3 so above-appetite commit is framework-mediated; note ADR-013 Rule 5 already authorises silent-proceed. P357 substance-confirm before `confirmed`.
2. **Remove above-appetite-commit AskUserQuestion from skills** — manage-problem, transition-problem(s), the three incident skills, assess-release; replace with the ADR-042 auto-remediate language already in the same files' release branch.
3. **Scoring agents read appetite from the policy** — pipeline.md + wip.md read appetite from RISK-POLICY.md (reuse the canonical parser in `lib/risk-gate.sh`; do NOT add a second); propagate the no-incident-bypass framing into agent prose + the gate deny message; fix `plan-risk-guidance.sh` default 5→4.
4. **Remove unauthorised bypasses** — `BYPASS_RISK_GATE` env var + `ci-bypass` marker (P208 fail-closed, no escape). KEEP the sanctioned `reducing-*` / `incident-release` markers.
5. **update-policy skill anchors the bypass clause** — write a § Authorized Bypass Scenarios clause on policy create/review (default-permitted when silent) so the reducing/incident bypass is policy-anchored for this repo + adopters.
6. **Tests** — behavioural bats + promptfoo for the corrected gate/skill/agent behaviour.

## Driving problem trace

- **P377** — skills/agents/hooks override RISK-POLICY appetite (above-appetite commit-ask, hardcoded appetite in scoring agents, unauthorised BYPASS_RISK_GATE + ci-bypass). This RFC is the coordinated multi-ADR + multi-skill + hook fix that closes it.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

- `ce149bd7` docs(problems): RFC-029 Slice 6 — record enforcement-floor coverage + close P377 implementation — 2026-06-24
- `7f10bd17` feat(risk-scorer): RFC-029 Slice 5 — update-policy writes an Authorized Bypass Scenarios clause (P377) — 2026-06-24
- `70862540` feat(risk-scorer): RFC-029 Slice 4 — remove unauthorised BYPASS_RISK_GATE + ci-bypass (P377) — 2026-06-24
- `6cd909b2` feat(risk-scorer): RFC-029 Slice 3 — agents read appetite from policy; propagate incident framing (P377) — 2026-06-24
- `1268747c` feat(itil,risk-scorer): RFC-029 Slice 2 — remove above-appetite-commit AskUserQuestion from skills (P377) — 2026-06-24
- `f91aad4d` docs(decisions): RFC-029 Slice 1 — extend never-above-appetite to commit; no incident carve-out (P377) — 2026-06-24
- `61eadd30` docs(rfcs): capture RFC-029 apply RISK-POLICY appetite across all surfaces — 2026-06-24

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
