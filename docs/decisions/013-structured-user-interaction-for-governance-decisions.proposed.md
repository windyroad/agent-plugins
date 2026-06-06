---
status: "proposed"
date: 2026-04-16
human-oversight: confirmed
oversight-date: 2026-05-25
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

1. **Every governance-skill branch point with two or more mutually exclusive options MUST use `AskUserQuestion` — but only when the framework has not already resolved the decision.** Per ADR-044 (Decision-Delegation Contract), the framework (ADRs / JTBDs / RISK-POLICY / WSJF / lifecycle / SKILL contracts) is a decision-delegation contract: the user invested in writing decisions down so the agent doesn't re-ask them per-action. `AskUserQuestion` is reserved for the six human-value categories ADR-044 enumerates (direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction). For framework-resolved decisions the agent acts and reports. Free-text prose option lists (e.g., "(a)/(b)/(c)", "Your call:", "which would you like?") remain a defect when an `AskUserQuestion` is warranted; use structured options with `header`, `description`, and `multiSelect: false`. See ADR-044 for the framework-resolution boundary and the deviation-approval surface.

2. **Scoring/analysis agents remain pure output-only.** Their `tools:` frontmatter stays `[Read, Glob]`. They emit machine-readable verdicts (`RISK_SCORES`, `RISK_VERDICT`, etc.). They do not prompt the user.

3. **The calling skill owns `AskUserQuestion`.** When a skill wraps an agent (e.g., a future `/wr-risk-scorer:assess-release` wrapping the pipeline scorer), the skill interprets the agent's structured output and presents options via `AskUserQuestion`. When no skill exists (agent invoked directly by hooks), the primary agent owns the interaction.

4. **Plan mode for multi-step remediations.** When a decision produces a multi-step remediation plan (e.g., above-appetite risk with concrete remediation items), the calling skill enters plan mode before presenting options.

5. **Policy-authorised decisions proceed silently.** When a decision outcome is pre-determined by policy (e.g., risk residual is below appetite per RISK-POLICY.md), the skill proceeds without prompting. No ceremonial "accept the risk?" for decisions the policy has already authorised.

6. **Non-interactive fail-safe — queue-and-continue is the universal default (2026-06-06 amendment).** In non-interactive contexts where `AskUserQuestion` is unavailable (AFK iter loops via `/wr-itil:work-problems` Step 5 iter dispatch, subagent invocations, CI pipelines, scheduled triggers, scripted invocations), the skill MUST **queue the question and continue** by default:

   - **Queue**: append the decision (artefact, surface, candidate options, recommendation if any, and any operational context the orchestrator needs to surface the question intelligibly) to an outstanding-questions surface that the orchestrator main turn reads at loop end (e.g. `/wr-itil:work-problems` Step 2.5 batched AskUserQuestion). Skills may maintain a per-skill queue; the orchestrator main turn reads the union.
   - **Continue**: proceed to the next step / iteration. Do NOT halt-with-stderr-directive. Do NOT silently fail-soft-skip. Do NOT auto-default to a guess.

   **Halt-with-directive and silent-skip are DEVIATIONS that require an explicit, inline-cited carve-out justification** (the SKILL prose must name the authorising ADR or user-pinned protection). Documented carve-outs at the time of this amendment:

   - `/wr-itil:capture-problem` Step 1.5b derive-then-ratify HALT — authorised by ADR-074 (Confirm decision substance before building dependent work). No-ticket-created is the user-pinned protection; auto-creating a ticket with derived-but-unratified substance would build dependent work on an unconfirmed decision.
   - `/wr-architect:create-adr` Step 5 substance-confirm HALT — authorised by ADR-074 for the same reason: no-ADR-with-unconfirmed-substance.
   - `/wr-itil:manage-problem` Step 0 / create-gate HALT — authorised by the create-gate's role as the substance-confirm boundary for new tickets (analogous to ADR-074).

   **AUTO-DEFAULT** (the agent picks an option on the user's behalf without recording the choice as a queued question) is permitted ONLY when the decision is framework-resolved per ADR-044 (Decision-Delegation Contract) — the framework (RISK-POLICY / ADRs / JTBDs / WSJF / lifecycle / SKILL contracts) has already pre-decided the outcome and the agent is mechanically applying it. If the decision is NOT framework-resolved, AUTO-DEFAULT is a defect; the SKILL must queue.

   **Rationale (anchored to JTBD-006 — Progress the Backlog While I'm Away):** the AFK persona expects routine decisions to be resolved with safe defaults AND judgment-call decisions to be queued for their return, never guessed at. Halt-with-directive prematurely truncates loop throughput; silent-skip silently under-delivers; auto-default makes calls the persona explicitly does not delegate. Queue-and-continue preserves both throughput AND audit trail: the AFK loop progresses, judgment calls accumulate as a typed batch the user returns to, and the carve-outs (capture-problem / create-adr / manage-problem create-gate) protect the narrow class of substance-confirm boundaries where building-on-unconfirmed-substance is the larger harm than the throughput cost.

   **Cross-references:**
   - **ADR-044** — Decision-Delegation Contract. AUTO-DEFAULT lives inside the framework-resolution boundary; queue-and-continue lives outside it.
   - **ADR-074** — Confirm decision substance before building dependent work. Authorises the capture-problem / create-adr / manage-problem create-gate carve-outs.
   - **JTBD-006** — Progress the Backlog While I'm Away. The Desired Outcome "queued for my return, not guessed at" is the persona-correct shape.
   - **JTBD-001** — Enforce Governance Without Slowing Down. Queue-and-continue keeps governance enforcement *on* during AFK rather than degrading to HALT (skip-governance) or auto-decide (bypass-governance).
   - **JTBD-002** — Ship AI-Assisted Code with Confidence. The queue artefact is the AFK audit surface (governance-was-followed evidence).
   - **P352** — the originating problem ticket (closed 2026-06-06 via this amendment).

   **Shared-helper extraction deferred (2026-06-06 follow-on).** Lifting the queue-file mechanism to `packages/itil/lib/outstanding-questions.sh` so any skill in any context can append to a single union surface is a follow-on (not in scope for the originating amendment). Per-skill queues + orchestrator-reads-union is the interim contract.

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
- **2026-06-06 amendment confirmation** — every `SKILL.md` AFK fallback prose either (a) names queue-and-continue as the shape, OR (b) cites the authorising ADR / user-pinned protection for a HALT / SKIP / AUTO-DEFAULT carve-out. Behavioural / structural assertions per ADR-052 verify both: the ADR-013 amendment prose is present and each documented carve-out is inline-justified.

## Reassessment Triggers

- A new governance skill ships without structured interaction (standard not followed despite review)
- `AskUserQuestion` proves insufficient for complex multi-step decisions requiring richer interaction (e.g., tree-structured choices, conditional follow-ups)
- CI/non-interactive execution encounters the fail-safe block and requires a policy-based bypass mechanism

## Related

- P021: `docs/problems/021-governance-skill-structured-prompts.known-error.md` — the problem this ADR resolves
- P352: `docs/problems/verifying/352-afk-iter-default-when-skill-needs-to-ask-and-askuserquestion-unavailable-queue-and-continue.md` — the originating ticket for the 2026-06-06 Rule 6 amendment (universal queue-and-continue default)
- ADR-011: `docs/decisions/011-manage-incident-skill.proposed.md` — positive exemplar, already compliant
- ADR-010: `docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md` — naming pattern for ITIL skills covered by this standard
- ADR-005: `docs/decisions/005-plugin-testing-strategy.proposed.md` — testing strategy for confirmation criteria
- ADR-044: `docs/decisions/044-decision-delegation-contract.proposed.md` — framework-resolution boundary; Rule 6 AUTO-DEFAULT operates inside it, queue-and-continue outside it
- ADR-052: ADR-052 (behavioural / structural assertions) — Rule 6 amendment is verified by bats checks per its norm
- ADR-074: `docs/decisions/074-confirm-decision-substance-before-building-dependent-work.proposed.md` — authorises the capture-problem / create-adr / manage-problem create-gate HALT carve-outs in Rule 6
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
- JTBD-006: Progress the Backlog While I'm Away — the AFK persona's "queued for my return, not guessed at" outcome is the persona-correct shape for Rule 6
- RISK-POLICY.md — appetite threshold referenced by Rule 5
