---
status: proposed
rfc-id: p270-external-comms-gated-upstream-report-afk-auto-fire
reported: 2026-06-04
decision-makers: [Tom Howard]
problems: [P270]
adrs: [ADR-024, ADR-028, ADR-042, ADR-013, ADR-014, ADR-074, ADR-071, ADR-044, ADR-076, ADR-077]
jtbd: [JTBD-006, JTBD-001, JTBD-004, JTBD-201]
stories: []
---

# RFC-018: P270 — external-comms-risk-gated AFK auto-fire for ALL upstream reports including security-classified tickets

**Status**: proposed
**Reported**: 2026-06-04
**Problems**: P270
**ADRs**: ADR-024 (cross-project problem-reporting contract — amended in-place; new orchestrator-layer Decision Outcome step authorising external-comms-gated auto-fire including security), ADR-028 (voice-tone gate / `wr-risk-scorer:external-comms` agent — the load-bearing gate this RFC wires the orchestrator to), ADR-042 (auto-apply scorer remediations open-vocabulary — within-axis precedent), ADR-013 (structured user interaction Rule 6 fail-safe — queue-rather-than-silently-choose is the "defer the decision" branch), ADR-014 (governance skills commit their own work — back-write + commit ordering preserved), ADR-074 (Confirm decision substance before building dependent work — 3 leaf-substance gaps queued as outstanding_questions against P270), ADR-071 (every fix goes through an RFC — why this RFC exists), ADR-044 (Decision-delegation contract — queue category: direction-setting), ADR-076 (tier-first selection — queued-question surface at Step 2.5b end-of-loop unchanged), ADR-077 (decisions compendium regeneration — compendium refresh rides the same commit)
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away — primary driver), JTBD-001 (Enforce Governance Without Slowing Down — blanket-defer was the slowdown), JTBD-004 (Connect Agents Across Repos to Collaborate — faster cross-repo handoff), JTBD-201 (Restore Service Fast with an Audit Trail — audit trail now tracks actual filing, not deferred intent)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P270 fix under the RFC-first framework per ADR-071. It carries **no independent architectural decisions** — the substantive choice is user-direction-pinned at principle level 2026-06-02 (cited verbatim in the ADR-024 amendment + below); per-leaf substance is deferred as `outstanding_questions` against P270 per ADR-074 substance-confirm-before-build. Pattern modelled on RFC-015 (P333 retro-fit) and RFC-016 (P344 retro-fit). Status transitions `proposed → in-progress → verifying` alongside the P270 ticket per ADR-022 fold-fix.

## Summary

P270: on external-root-cause detection (`/wr-itil:manage-problem` Step 6 / `/wr-itil:work-problems` Step 4 `upstream-blocked` classifier row), the AFK orchestrator currently appends a `- **Upstream report pending** —` marker to the ticket and defers the actual filing to a human turn that often never comes. ADR-024 Consequences line 137 + line 129 authorise this conservative blanket-defer ("AFK orchestrators should never auto-report a security-classified ticket"; "the skill must fall through to ... halt the orchestrator"). The blanket-defer over-clamps the non-security path that the report-upstream skill's own AFK behaviour table (`packages/itil/skills/report-upstream/SKILL.md` lines 505–515) says proceeds.

The fix reverses the blanket-defer for ALL classifications including security, gated instead by an external-comms risk assessment (the `wr-risk-scorer:external-comms` agent shipped per ADR-028; the dependency the 2026-04-25 (P070) amendment named as "interim static heuristic until that evaluator lands" is met). Below-appetite → send. Above-appetite → risk-reduce → re-score → send-or-queue. Queue does NOT halt (P352 queue-and-continue); the outstanding_question surfaces at the existing batched-`AskUserQuestion` end-of-loop gate.

## Driving problem trace

- **P270** (`docs/problems/open/270-agent-waits-for-human-to-initiate-upstream-report-instead-of-filing-on-detect.md`) — agent waits for human to initiate upstream report instead of filing on detect; feedback-delay class. Status: Open → Known Error in the same commit as this RFC's fold-fix per ADR-022 P143.

## User-ratified principle (verbatim, 2026-06-02)

> "I wanted to order file all upstream reports including security but it should be doing an external communication risk assessment. If the risk is below appetite then send. If it's above appetite then take risk reducing measures if that brings it into appetite great send otherwise queue it for my review."

## Scope

Single fold-fix commit (post the capture-rfc skeleton commit per ADR-014 capture-grain):

- `docs/decisions/024-cross-project-problem-reporting-contract.proposed.md` — append 2026-06-04 (P270) entry to `## Amendments` block; rewrite Confirmation §1 line 146 + §2 line 152 + §2 line 155 to cite external-comms gate result.
- `docs/decisions/README.md` — regenerate via `packages/architect/scripts/generate-decisions-compendium.sh` per ADR-077.
- `packages/itil/skills/work-problems/SKILL.md` Step 4 classifier table `upstream-blocked` row + decision-table row — re-cast "do NOT auto-invoke" prose as external-comms-gated branching.
- `packages/itil/skills/manage-problem/SKILL.md` Step 6 external-root-cause-detection AFK fallback (~line 669) — same re-cast.
- `packages/itil/skills/report-upstream/SKILL.md` AFK behaviour summary table (lines 505–515) — security-path-halt row and dedup-halt row both re-cast as external-comms-gated; public-issue path row gains the explicit external-comms gate reference.
- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — extend with behavioural assertions covering the new branching.
- `docs/problems/known-error/270-*.md` — fold-fix ticket transition (Open → Known Error); body extended with the 3 outstanding_questions queued against P270 per ADR-074.
- `.changeset/wr-itil-p270-external-comms-gated-upstream-report-afk-auto-fire.md` — `@windyroad/itil` patch changeset; may move to holding per ADR-061 if commit-gate scorer flags push above appetite.

## Decisions carried (none — all choices pinned)

1. **Per-classification AFK branching axis** — user-direction-pinned at principle level 2026-06-02 (cited verbatim above).
2. **Risk-gate authority** — `wr-risk-scorer:external-comms` agent (ADR-028 line 117 third-evaluator extension point; ADR-028 already declares the agent which is now shipped at `packages/risk-scorer/agents/external-comms.md` + `packages/risk-scorer/skills/assess-external-comms/`).
3. **Above-appetite branching shape** — within-axis re-use of ADR-042's risk-reduce-then-halt pattern, generalised from commit/push/release risk to the external-comms risk axis (per ADR-042 open-vocabulary clause).
4. **Queue-not-halt** — P352 queue-and-continue precedent + ADR-013 Rule 6 "defer the decision" branch (the queue IS the defer; not silent-choose).

## Deferred substance (per ADR-074 — queue as outstanding_questions against P270)

1. **Risk-reducing measures vocabulary** — what constitutes a "risk-reducing measure" for an above-appetite upstream report? Alternative disclosure channel? Content redaction? Defer-to-security-advisory path? Bounded vocabulary (analogous to ADR-042's `move-to-holding` enumeration) or open-ended LLM judgement (analogous to the `wr-risk-scorer:external-comms` agent's own scoring)?
2. **Security-disclosure-channel routing in AFK** — when auto-filing security AND below-appetite, route per existing Step 6: GitHub Security Advisories default if upstream has `SECURITY.md` declaring them; halt on missing-`SECURITY.md`; always-queue-for-review when classification is security regardless of risk band?
3. **`## Drafted Upstream Report` section retention vs rename** — the section currently means "halt-and-save"; post-amendment it means "queued-report save". Same name + repurposed semantics, or rename to `## Queued Upstream Report` to reflect changed meaning?

These three queue as `outstanding_questions` against P270 itself (recorded in the P270 ticket body) — return-presentation surfaces them as direction-setting decisions per ADR-044 category 1.

## Tasks

- [x] User-ratified principle captured 2026-06-02 (verbatim above).
- [ ] ADR-024 `## Amendments` block append the 2026-06-04 (P270) entry.
- [ ] ADR-024 Confirmation §1 line 146 + §2 line 152 + §2 line 155 rewritten.
- [ ] Compendium regenerated via `packages/architect/scripts/generate-decisions-compendium.sh` per ADR-077.
- [ ] `packages/itil/skills/work-problems/SKILL.md` Step 4 classifier table + decision-table row re-cast.
- [ ] `packages/itil/skills/manage-problem/SKILL.md` Step 6 external-root-cause-detection AFK fallback re-cast.
- [ ] `packages/itil/skills/report-upstream/SKILL.md` AFK behaviour summary table re-cast.
- [ ] `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` extended with behavioural assertions.
- [ ] P270 ticket transitioned Open → Known Error; 3 outstanding_questions queued in body.
- [ ] `.changeset/wr-itil-p270-external-comms-gated-upstream-report-afk-auto-fire.md` patch changeset created.

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- [ADR-024](../decisions/024-cross-project-problem-reporting-contract.proposed.md)
- [ADR-028](../decisions/028-voice-tone-gate-external-comms.proposed.md)
- [ADR-042](../decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md)
- [ADR-013](../decisions/013-structured-user-interaction-for-governance-decisions.proposed.md)
- [ADR-014](../decisions/014-governance-skills-commit-their-own-work.proposed.md)
- [ADR-074](../decisions/074-confirm-decision-substance-before-building-dependent-work.proposed.md)
- [ADR-071](../decisions/071-every-fix-goes-through-an-rfc.proposed.md)
- [ADR-044](../decisions/044-decision-delegation-contract.proposed.md)
- [ADR-076](../decisions/076-inbound-reported-problems-rank-ahead-via-sort-tier.proposed.md)
- [ADR-077](../decisions/077-decisions-compendium.proposed.md)
- [P270](../problems/open/270-agent-waits-for-human-to-initiate-upstream-report-instead-of-filing-on-detect.md) (transitions to `known-error/` in the same commit per ADR-022 fold-fix)
- [P352](../problems/) (queue-and-continue precedent)
- [JTBD-006](../jtbd/developer/JTBD-006-work-backlog-afk.proposed.md)
