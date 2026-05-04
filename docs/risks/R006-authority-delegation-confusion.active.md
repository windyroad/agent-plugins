---
risk_id: R006
slug: authority-delegation-confusion
status: Active
category: brand
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [SKILL.md (per skill — AskUserQuestion call sites), agent.md (per agent), packages/itil/hooks/itil-assistant-output-gate.sh, packages/itil/hooks/itil-assistant-output-review.sh, packages/itil/hooks/itil-correction-detect.sh, CLAUDE.md MANDATORY rules, ADR-013, ADR-044]
cascade_scope: every agent decision point in every skill invocation; every AskUserQuestion call; every UserPromptSubmit pattern match for direction-pinning or correction signals
afk_class: both — interactive surfaces the issue immediately; AFK orchestrator iters can compound the wrong-decision pattern across many iterations before user sees output
afk_amplification: high — AFK loops expose the issue most acutely; the "asking-when-framework-resolved" failure mode produces unnecessary halts and the "deciding-when-user-should" failure mode commits errors invisibly
reversal_class: judgement-recoverable (correction in next turn surfaces the pattern); audit-trail-preserved (assistant-output-review hook scans transcript)
control_budget_class: free-hook (UserPromptSubmit + Stop hook scans) + per-decision-point cost (ADR-044 6-class taxonomy lookup)
dogfood_days: P085 assistant-output gate ~10 days; P132 inverse-P078 codification recent (~3 days); ADR-044 framework ~7 days
authority_class: framework-resolved (this risk class is itself ABOUT authority-class assignment); meta-control surfaces the misclassification
prompt_cache_window: ongoing
ci_a: integrity (decision-making under wrong authority delegation produces wrong actions); brand (visible mistakes consume trust-budget faster than technical impact alone)
agentic_category: judgement
---

# Risk R006: Authority-delegation confusion

## Description

Agentic systems must continually decide WHO decides — the agent (per skill contract or framework rule), the user (genuine ambiguity warranting AskUserQuestion), or a framework rule (mechanical resolution under documented policy). Misdirected authority takes two symmetric forms:

1. **Agent asks when framework had resolved** (lazy deferral / hoop-jumping): agent invokes AskUserQuestion for a decision the SKILL contract or framework rule already determined; user pays UX cost; AFK loops halt unnecessarily; trust-budget erodes through "you keep asking obvious things".
2. **Agent decides when user should** (over-reach): agent acts on a class-2 deviation-approval or class-1 direction-setting decision without user consent; user discovers the action after the fact; trust-budget erodes through "you didn't ask before doing X".

ADR-044 codifies a 6-class taxonomy (direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction) but adoption is per-skill and the corpus shows recurring instances of both failure modes. CLAUDE.md MANDATORY rules (P085 act-on-obvious, P078 capture-on-correction, P132 inverse-P078 don't-ask-mechanical) attempt to surface the issue in every prompt.

**Source → event → consequence chain**: source = decision point in skill / hook / agent invocation where authority class is ambiguous OR misclassified; event = agent invokes AskUserQuestion when class-4 silent-framework applies (failure mode 1) OR agent acts on class-2 deviation-approval without consent (failure mode 2); consequence = UX friction OR unauthorised action; cumulative consequence = trust-budget erosion + visible-mistake count.

## Inherent Risk

- **Impact**: 3/5 (Moderate) — failure-mode-1 produces friction; failure-mode-2 can produce unauthorised actions. Brand impact is the load-bearing dimension because trust is finite and slow to rebuild. Not Severe because individual instances are recoverable.
- **Likelihood**: 4/5 (Likely) — corpus evidence: ~30 ask-hygiene retros in `docs/retros/` (`*-ask-hygiene.md` pattern) over the past 2 weeks, each surfacing instances of failure-mode-1; P078 codified the failure-mode-2 capture surface; P132 codified the inverse pattern; multiple sessions have user corrections invoking strong-affect signals (FFS, DON'T) when failure-mode-1 fires repeatedly.
- **Inherent Score**: 12
- **Inherent Band**: High

## Controls

- **`packages/itil/hooks/itil-assistant-output-gate.sh`** (P085) — UserPromptSubmit hook injects MANDATORY reminder when prompt contains direction-pinning signals (yes / go / proceed / act / just do it). **Effectiveness**: medium — surfaces the rule per-prompt; doesn't enforce, only nudges. Reduces likelihood from 4 to 3 by raising salience.
- **`packages/itil/hooks/itil-assistant-output-review.sh`** (P085) — Stop hook scans last assistant turn for canonical prose-ask phrasings (Want me to / Should I / etc.) and emits stopReason nudge. **Effectiveness**: medium — Stop hooks bias the next turn; cumulative effect across iterations. Reduces likelihood from 3 to 2.
- **`packages/itil/hooks/itil-correction-detect.sh`** (P078) — UserPromptSubmit hook detects strong-affect correction signals (FFS / DO NOT / contradiction / !!! / "you always|never|keep") and instructs OFFER ticket capture FIRST. **Effectiveness**: medium-high — converts correction-signals into durable backlog (capture-problem ticket) so the class-of-behaviour persists across sessions. Pairs with ADR-032 capture-problem skill.
- **CLAUDE.md MANDATORY rules** (P085 + P078 + P132) — top-of-prompt reminders for direction-pinning, correction-on-capture, and inverse-P078 (don't ask in mechanical stages). **Effectiveness**: medium — load-bearing for setting expectations; effectiveness scales with rule clarity.
- **ADR-044 6-class taxonomy** — codifies the authority classes (direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction) so SKILL contracts can name the class for each decision point. **Effectiveness**: high when invoked — makes authority-class explicit per decision; lower when SKILL contracts haven't been audited against the taxonomy yet (P136 master tracker for the audit).
- **P136 ADR-044 alignment audit master** — open ticket tracking the per-skill audit against the 6-class taxonomy. **Effectiveness**: pending — once skills are audited, residual likelihood drops further.

## Residual Risk

- **Impact**: 3/5 (Moderate) — controls don't change consequence shape per-instance; trust-budget impact accumulates regardless of mitigation.
- **Likelihood**: 2/5 (Unlikely) — three hook-based controls + CLAUDE.md rules + ADR-044 taxonomy each contribute likelihood reduction; observed friction-event count has dropped meaningfully over past week (subjective from retro patterns).
- **Residual Score**: 6
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; P136 alignment audit is the next major mitigation milestone.

## Treatment

**Mitigate**. Land P136's per-skill audit; convert the 6-class taxonomy from advisory to load-bearing per skill.

**Active mitigations**:
1. P085 hook pair (UserPromptSubmit + Stop) keeps direction-pinning + prose-ask detection on every turn.
2. P078 correction-detect hook captures strong-affect-correction signals as durable problem tickets.
3. P132 inverse-P078 rule prevents over-asking in mechanical stages (where SKILL contract resolves).
4. P136 alignment audit (open) — per-skill audit against ADR-044 6-class taxonomy.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: ask-hygiene retro count exceeds 1/day for 5 consecutive days (signals controls regression). Or: strong-affect correction signal (FFS/DON'T/etc.) fires more than 1/session sustained over 1 week. Or: P136 alignment audit reveals uncovered failure modes that controls don't address.
- **Metrics**: ask-hygiene retro count / week (target trending toward 0); strong-affect correction count / session (target 0); P136 audit progress (% skills audited against taxonomy); UserPromptSubmit gate fire-count / week (signal of direction-pinning surfacing).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P078 (capture-on-correction driver), P085 (assistant-output gate), P132 (inverse-P078 don't-ask-mechanical), P136 (ADR-044 alignment audit master), P140-P157 (multiple ask-hygiene retros recording instances).
- **Treatment ADRs**: ADR-013 (structured user interaction for governance decisions; Rule 1 obviates prose-ask; Rule 5 silent-proceed; Rule 6 AFK fail-safe), ADR-044 (decision delegation contract; the 6-class taxonomy), ADR-032 (capture-problem skill — the durable backlog surface).
- **Personas affected**: plugin-user (every friction event is paid by the user); solo-developer (JTBD-001 60-second-flow promise); plugin-maintainer (cumulative trust-budget impact).

## Source Evidence

- `docs/retros/*-ask-hygiene.md` — 30+ retros over past 2 weeks documenting instances.
- `docs/problems/078-assistant-does-not-offer-problem-ticket-on-user-correction.*.md` — driver for failure-mode-2 capture surface.
- `docs/problems/085-...verifying.md` — P085 driver for the load-bearing assistant-output gate.
- `docs/problems/132-...md` (or current state) — inverse-P078 codification.
- `docs/problems/136-adr-044-alignment-audit-master.open.md` — alignment audit ticket.
- `docs/decisions/044-decision-delegation-contract.proposed.md` — 6-class taxonomy authority.
- `docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md` — interaction rules.
- `packages/itil/hooks/lib/detectors.sh` — pattern vocabulary for direction-pinning, prose-ask, correction signals.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe. NEW class — not covered by pre-wipe R001-R006 register. The pattern surfaced strongly enough across the corpus + retros to warrant its own register entry; the symmetric failure modes + the existing hook controls + ADR-044 taxonomy make this a tractable risk class to monitor and mitigate.
