---
status: "proposed"
date: 2026-04-16
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-10-16
---

# Structured User Interaction for Governance-Skill Decisions

## Context and Problem Statement

Governance skills in this suite (risk-scorer, manage-problem, manage-incident, create-adr, run-retro) have branch points where the user must choose between mutually exclusive options. Today, some skills use `AskUserQuestion` (manage-incident does this well per ADR-011) while others fall back to prose "(a)/(b)/(c)" prompts (manage-problem work mode, risk-scorer above-appetite output). P021 documented three instances of this failure mode in a single session.

Prose decision prompts are:
- **Unstructured** — no typed header, no option chips, no machine-readable answer
- **Unauditable** — no record of what was offered vs what was chosen
- **Not composable** — cannot be consumed by non-interactive contexts (CI, scheduled triggers, scripted invocations)
- **Friction-inducing** — users parse English paragraphs instead of clicking a choice

The scoring/analysis agents (risk-scorer pipeline/wip/plan modes) are intentionally tool-restricted to `Read + Glob` and emit machine-readable verdicts (`RISK_SCORES`, `RISK_VERDICT`, `RISK_BYPASS`). They are correctly pure scorers. The problem is that no standard tells the calling skill or primary agent how to present scorer output to the user — so the primary falls back to conversational prose.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — prompt friction directly violates the "under 60 seconds" and "no manual step needed" desired outcomes
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — "audit trail exists showing governance was followed" requires structured, machine-readable decision records
- **P021** root cause analysis — confirmed that the prose-prompt failure mode recurs in every governance skill that lacks explicit `AskUserQuestion` instructions
- **ADR-011** (manage-incident) — positive exemplar; already uses `AskUserQuestion` at every decision branch

## Considered Options

### Option A: Expand tool grants on all agents

Add `AskUserQuestion` to every governance agent's `tools:` frontmatter so agents themselves can prompt the user.

**Pros:**
- Single point of ownership — the agent handles both scoring and interaction
- No coordination needed between agent output and skill/primary interpretation

**Cons:**
- Breaks the pure scorer pattern that risk-scorer agents rely on (they emit structured verdicts consumed by PostToolUse hooks; interactive prompts would break that pipeline)
- Agents invoked via Task tool cannot enter plan mode on the parent's behalf — plan mode is a primary-agent affordance
- Increases coupling between agent prompts and UI interaction patterns

### Option B: Keep agents pure, skills/primary own interaction (chosen)

Scoring/analysis agents remain output-only. The calling skill (or primary agent when no skill wraps the agent) owns `AskUserQuestion` and plan-mode entry.

**Pros:**
- Preserves the clean scorer contract (machine-readable output, hook-consumed verdicts)
- Aligns with ADR-011's manage-incident pattern (skill owns interaction, calls other skills via `Skill` tool)
- Skills already have `AskUserQuestion` in their `allowed-tools`; no new grants needed
- Plan mode is naturally available to the primary agent / skill layer

**Cons:**
- Requires every skill to explicitly document its `AskUserQuestion` branch points — the standard must be enforced via review, not by architecture alone
- When no skill wraps an agent (e.g., risk-scorer invoked by hooks), the primary agent must handle interaction, which is less deterministic than a skill document

### Option C: Do nothing

Accept prose prompts as a cosmetic issue.

**Pros:**
- No work

**Cons:**
- P021 will recur in every new governance skill
- Audit trail gap persists
- JTBD-001 friction compounds as the suite grows

## Decision Outcome

**Chosen option: Option B** — Keep agents pure, skills/primary own interaction.

### Rules

1. **Every governance-skill branch point with two or more mutually exclusive options MUST use `AskUserQuestion`.** Free-text prose option lists (e.g., "(a)/(b)/(c)", "Your call:", "which would you like?") are a defect. Use structured options with `header`, `description`, and `multiSelect: false`.

2. **Scoring/analysis agents remain pure output-only.** Their `tools:` frontmatter stays `[Read, Glob]`. They emit machine-readable verdicts (`RISK_SCORES`, `RISK_VERDICT`, etc.). They do not prompt the user.

3. **The calling skill owns `AskUserQuestion`.** When a skill wraps an agent (e.g., a future `/wr-risk-scorer:assess-release` wrapping the pipeline scorer), the skill interprets the agent's structured output and presents options via `AskUserQuestion`. When no skill exists (agent invoked directly by hooks), the primary agent owns the interaction.

4. **Plan mode for multi-step remediations.** When a decision produces a multi-step remediation plan (e.g., above-appetite risk with concrete remediation items), the calling skill enters plan mode before presenting options.

5. **Policy-authorised decisions proceed silently.** When a decision outcome is pre-determined by policy (e.g., risk residual is below appetite per RISK-POLICY.md), the skill proceeds without prompting. No ceremonial "accept the risk?" for decisions the policy has already authorised.

6. **Non-interactive fail-safe.** In non-interactive contexts (CI pipelines, scheduled triggers, scripted invocations where `AskUserQuestion` is unavailable), the skill MUST fail-safe — block or defer the decision rather than silently choosing an option on behalf of the user.

## Consequences

### Good

- Auditable decision trail: every governance decision is captured as a structured `AskUserQuestion` exchange with typed options and a recorded selection
- Machine-readable: downstream tooling (CI, analytics, retrospectives) can parse decision records without NLP
- Consistent UX: users learn one interaction pattern across all governance skills
- Reduced friction: clicking a choice is faster than parsing and responding to a prose paragraph

### Neutral

- ADR-011 (manage-incident) is already compliant — no retrofit needed there
- Existing manage-problem `AskUserQuestion` usage at duplicate-check, data-gathering, and verification steps is already compliant

### Bad

- Retrofitting manage-problem's work/review flows requires explicit `AskUserQuestion` instructions at each branch point (partially done in the P021 fix commit)
- Risk-scorer above-appetite flow needs a wrapping skill (P020) or explicit primary-agent instructions to present structured options — this is not yet implemented
- Every future governance skill author must learn and follow this standard; architect review is the enforcement gate
- Non-interactive fail-safe may block CI pipelines that encounter above-appetite decisions; a bypass mechanism may be needed (tracked as a reassessment trigger)

## Confirmation

- `grep -rn "Options:.*\(a\)\|Your call:\|which would you like\|which way?" packages/*/skills/` returns zero matches outside test fixtures
- Every `SKILL.md` with `AskUserQuestion` in `allowed-tools` uses it at all documented branch points (no prose fallback for decision prompts)
- Scoring agents (`pipeline.md`, `wip.md`, `plan.md`) have `tools: [Read, Glob]` only — no `AskUserQuestion` grant
- Below-appetite / policy-authorised paths produce no user prompt (silent proceed)

## Reassessment Triggers

- A new governance skill ships without structured interaction (standard not followed despite review)
- `AskUserQuestion` proves insufficient for complex multi-step decisions requiring richer interaction (e.g., tree-structured choices, conditional follow-ups)
- CI/non-interactive execution encounters the fail-safe block and requires a policy-based bypass mechanism

## Related

- P021: `docs/problems/021-governance-skill-structured-prompts.known-error.md` — the problem this ADR resolves
- ADR-011: `docs/decisions/011-manage-incident-skill.proposed.md` — positive exemplar, already compliant
- ADR-010: `docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — naming pattern for ITIL skills covered by this standard
- ADR-005: `docs/decisions/005-plugin-testing-strategy.proposed.md` — testing strategy for confirmation criteria
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
- RISK-POLICY.md — appetite threshold referenced by Rule 5
