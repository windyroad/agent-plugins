# Problem 021: Risk-scorer decision prompt shape — silent below appetite, structured remediation above

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 9 (Medium) — Impact: Moderate (3) x Likelihood: Likely (3)

## Description

The risk-scorer pipeline assessment asks the user "do you want to accept the risk?" even when the residual risk is at or below the appetite threshold. RISK-POLICY.md is explicit (lines 30-36): "Pipeline gates block when cumulative residual risk exceeds 4. Very Low (1-2) and Low (3-4) risk changes proceed without intervention."

Accepting risk is only semantically meaningful when residual **exceeds** appetite. Below appetite, the release is pre-authorised by policy. Controls (the pipeline gate itself) prevent releasing above appetite, so an accept-risk prompt below appetite is:
- Redundant (nothing to authorise — policy already authorised it)
- Misleading (implies a choice the user doesn't actually have — they can't meaningfully "reject")
- Friction (breaks flow for an empty ceremonial step)

Observed this session: release risk assessed at residual 3 (Low, within appetite 4), agent still prompted "accept the risk?" before proceeding.

**Above-appetite shape also needs improvement.** When residual exceeds appetite, today's output is a free-text "Your call: accept X/25 explicitly and merge, or take the N hour for the remediations" — unstructured, hard to automate against, forces the user to parse prose and decide between accept-or-remediate in their head. The correct shape is: automatically enter planning mode to draft concrete remediations, and use the `AskUserQuestion` tool to collect any clarifications needed. This turns a free-text decision into a structured, auditable exchange.

## Symptoms

- Risk-scorer (pipeline mode) emits an accept-risk prompt on every assessment, regardless of residual vs appetite.
- Users habituate to dismissing the prompt → when a real above-appetite case arrives, the dismissal reflex may misfire.
- Assessments that should take < 60s (per JTBD-001 outcome) are padded with an empty decision step.
- The screenshot from this session shows residuals at 3, 3, 3 with verdict "accept appetite threshold of 4" — immediately followed by "Your call: accept 3/25 explicitly and merge, or take the 1 hour for the two remediations to bring it into appetite" — but it's already IN appetite.
- Above-appetite outputs use free-text "Your call:" prose instead of structured tooling. No planning mode entry, no `AskUserQuestion` for clarifications, no machine-readable remediation list. Auditing above-appetite decisions requires parsing English.

## Workaround

User manually dismisses the prompt. Friction, not harm.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — prompt friction directly violates "speed without sacrificing quality" and the under-60-second outcome target.
  - Tech-lead persona — repeated empty prompts erode trust in the governance surface.
  - Any user of `wr-risk-scorer` on a low-risk release path — most releases should be Very Low / Low and should therefore pass silently.
- **Frequency**: Every pipeline assessment where residual is within appetite — which per policy framing should be the common case. Expected to fire most of the time.
- **Severity**: Medium. Friction, not correctness. The gate still works. But compounding friction erodes adoption.
- **Analytics**: Observed this session — addressr v0.23.4 release risk assessment, residual 3/25 (Low), verdict "Below appetite threshold of 4", still asked "Your call: accept 3/25 explicitly and merge…" See Image #3.

## Root Cause Analysis

The risk-scorer agent's output template appears to always include an "accept-or-remediate" section, regardless of whether the residual is above or below appetite. The agent does not branch on the residual-vs-appetite comparison before formatting the decision prompt.

Contributing factors:
1. **Agent prompt/template does not condition on appetite.** The decision prompt is unconditional; should be conditional on `residual > appetite`.
2. **Acceptance is conflated with acknowledgement.** Below appetite, the user needs no acceptance (policy-authorised); at most a brief "proceeding silently" signal. The agent treats both cases identically.
3. **No self-check against RISK-POLICY.md framing.** The policy is authoritative and explicit about "proceed without intervention" below 4, but the agent doesn't enforce that in its own output shape.

### Investigation Tasks

- [ ] Inspect the risk-scorer pipeline-mode agent prompt (`packages/risk-scorer/agents/pipeline.md` or equivalent) — find the output template that contains the accept-or-remediate block.
- [ ] Add a conditional: when cumulative residual ≤ appetite, emit only the score + verdict (`RISK_VERDICT: below-appetite`) and a terse proceed line. Omit the "Your call:" decision prompt.
- [ ] Distinguish three output states explicitly: (a) below appetite → proceed silently; (b) above appetite → structured remediation (see below); (c) at appetite exactly → surface a note but do not prompt (per policy framing "proceed without intervention" covers 3-4).

**Above-appetite behaviour — architectural decision required.** The risk-scorer agents are currently tool-restricted to `Read + Glob` (no `AskUserQuestion`, no ability to enter plan mode). Sub-agents invoked via Task also cannot enter plan mode on the parent's behalf — plan mode is a primary-agent affordance. This means "auto-enter plan mode + use AskUserQuestion" cannot be delivered by the scorer agent alone. Architect flagged two options:

  - **Option A — Expand tool grants.** Add `AskUserQuestion` to the risk-scorer agents' `tools:` frontmatter. Reframe "planning mode" as structured remediation output the primary agent can act on.
  - **Option B — Split the contract (architect's preferred).** Keep the scorer as a pure scorer. When above appetite, it emits a machine-readable verdict with a structured remediation list (e.g. `RISK_REMEDIATIONS:` marker, one per line, each with effort + risk delta). The *calling skill* (or primary agent) reads that output, enters plan mode via the standard primary-agent mechanism, and uses `AskUserQuestion` to collect clarifications. This aligns with existing hook-driven architecture and keeps scoring and orchestration separate concerns.

- [ ] **Draft companion ADR: "Structured user interaction — AskUserQuestion + plan-mode for remediations."** Architect flagged this is cross-cutting beyond risk-scorer (affects P020 on-demand assessment skills, ADR-011 manage-incident, future remediation flows). Deciding the pattern once prevents each skill re-inventing it. Cross-reference from P020 and ADR-011.
- [ ] Define the machine-readable remediation marker format if Option B chosen. Candidate: `RISK_REMEDIATIONS:` block with `id | description | effort (S/M/L) | risk_delta (-N) | files_touched` columns.
- [ ] Decide where plan-mode entry and `AskUserQuestion` prompting live. If in a skill: `/wr-risk-scorer:assess-release` (P020) would own the orchestration. If in a hook: the commit-gate/push-gate hooks would need to branch on above/below appetite.
- [ ] Check other assessment modes (wip, plan) for the same pattern — they likely share the template and tool grants.
- [ ] Update `RISK_SCORES:` / `RISK_VERDICT:` / `RISK_BYPASS:` marker contract (if needed) so the commit-gate hook distinguishes silent-pass from bypass-reducing from above-appetite-needs-remediation.
- [ ] Create reproduction tests:
  - Residual 3 → assert output contains no "Your call:" prompt.
  - Residual 6 → assert output contains structured `RISK_REMEDIATIONS:` (Option B) or the scorer invokes `AskUserQuestion` (Option A), not free-text.

## Related

- `RISK-POLICY.md` lines 28-36 — authoritative appetite framing ("proceed without intervention")
- `packages/risk-scorer/agents/pipeline.md`, `plan.md`, `wip.md`, `agent.md`, `policy.md` — agent prompt templates (primary fix location); currently tool-restricted to `Read + Glob`
- `packages/risk-scorer/skills/update-policy/SKILL.md` — only existing risk-scorer surface with `AskUserQuestion` grant; pattern reference if Option A is chosen
- `packages/risk-scorer/hooks/plan-risk-guidance.sh` — reacts to EnterPlanMode but does not trigger it
- Related: `docs/problems/020-on-demand-assessment-skills.open.md` — any on-demand assessment skill wrapping risk-scorer must inherit the corrected prompt shape AND may be the natural home for above-appetite orchestration (Option B)
- Related: ADR-011 `docs/decisions/011-manage-incident-skill.proposed.md` — nearest neighbour for the structured-interaction ADR; should adopt the same convention
- Candidate new ADR: `docs/decisions/013-structured-user-interaction-for-remediation.proposed.md` (architect flagged — cross-cutting pattern)
- `docs/BRIEFING.md` — notes that risk-scorer agents have no Bash tool and output structured markers
- Session evidence: Image #3 showing residual 3 with accept-risk prompt
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "governance without slowing down"; under-60-second outcome target
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md` — "the agent cannot bypass governance"; structured remediation strengthens this
