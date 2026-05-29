# Problem 327: ADR bodies dominate session token usage — design a summary surface for routine compliance loading

**Status**: Open
**Reported**: 2026-05-30
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems; user signaled "highest priority because of token burn" at capture)
**Origin**: inbound-reported (relayed from other projects)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; design + summary-surface ADR + 76-ADR migration likely XL once scoped)
**Type**: technical

## Description

In adopting projects using @windyroad/architect, `docs/decisions/` ADR content dominates session token usage — often over 50% of total context. The full ADR bodies (especially **Considered Options**, **Pros and Cons of the Options**, **Consequences**, and **Reassessment Criteria**) are valuable for understanding the thinking at the time and evolving decisions later, but in a typical compliance/review session we don't need all that information — only enough to follow each decision (the chosen option + the binding constraints).

**Design question.** How might we maintain decision **summaries** (e.g. a per-ADR distilled `summary:` frontmatter field, a `docs/decisions/README.md` compendium, or a separate short-form surface) that the architect / JTBD / risk-scorer agents load by default for routine compliance review, while preserving the full ADR body for explicit deep-dive review, human ratification, and decision evolution?

**Reporter framing.** Reported by external adopters during multi-project sessions — this is an inbound report per ADR-076 (Tier 1: customer-service / feedback-signal preservation). User signal during capture: *"that's probably the highest priority issue because of the amount of token burn."*

**Goal.** Drop the architect / JTBD / risk-scorer per-edit token cost without losing the deep-context-on-demand value that the full ADR body provides.

## Symptoms

- Token usage profile in adopting-project sessions shows >50% spend on `docs/decisions/` reads.
- Effect compounds in agents (architect, JTBD, risk-scorer) that fire on every project-file edit — each invocation re-loads the ADR set.
- Reported across multiple adopter sessions; not project-specific.

## Workaround

(deferred to investigation — informal candidate: agents could opportunistically read only the Decision Outcome section, but no enforced contract exists yet)

## Impact Assessment

- **Who is affected**: every adopter using `@windyroad/architect` (and indirectly `@windyroad/jtbd`, `@windyroad/risk-scorer`); developer persona JTBD-006 (AFK backlog work) and tech-lead persona JTBD-201 (restore service fast — context budget directly affects investigation depth).
- **Frequency**: every session that touches a project file — i.e. essentially every working session.
- **Severity**: High — direct degradation of usable context budget; reporter framed as "highest priority issue."
- **Analytics**: (deferred — would benefit from a token-spend profile across a representative session set)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (user signaled "highest priority" at capture — likely re-rates to Impact 4 × Likelihood 5 = Severity 20 / Very High → ADR-076 Tier 0)
- [ ] Design the summary surface — three candidate shapes: (a) per-ADR `summary:` frontmatter field; (b) `docs/decisions/README.md` compendium loaded in lieu of full bodies for routine reads; (c) separate short-form file per ADR (e.g. `<NNN>-<slug>.summary.md`). Architect decision needed.
- [ ] Decide which agents load the summary vs the full body — default-to-summary, fall back to full on explicit deep-dive surfaces (review-decisions drain, create-adr, capture-adr).
- [ ] Migration path for existing 76 ADRs — auto-generate first-cut summaries from existing `## Decision Outcome` sections; human-confirm + refine opportunistically.
- [ ] Update create-adr / capture-adr to author the summary at decision time so new ADRs are born compact.
- [ ] Confirm with adopters whether the proposed summary shape preserves the deep-context-on-demand value they actually use.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P194 (ADRs accumulate forward-chronology evidence inline — decisions bucket dominates context; same family — both target the ADR-content-load-cost class)

## Related

- **P194** — sibling, decisions bucket dominates context (forward-chronology evidence accumulation angle).
- **P097** — SKILL.md files mix runtime-necessary steps with maintainer-facing rationale, bloating every skill invocation (same family at the SKILL-prose surface; this ticket is the ADR-prose surface).
- **ADR-076** — reported-first ranking tier; this ticket exercises the Tier 1 inbound path.
- **ADR-038** — progressive-disclosure pattern (SKILL.md + REFERENCE.md split); the ADR-prose analogue would be ADR-summary + ADR-body split.
- Dup-check matches (non-blocking; SKILL Step 2 contract): P030, P103, P194, P216, P248, P310, P315, P316, P148.

(captured via /wr-itil:capture-problem; expand at next investigation)
