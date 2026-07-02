# Problem 403: Agent frames skill-mandatory mechanical steps as user-optional

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 12 (High) — Impact: 3 (Moderate — friction the mechanical-stage carve-out was engineered to remove; per-invocation slowdown; structurally counter to the framework's goals) × Likelihood: 4 (Likely — observed 2 instances in this session alone; per-session pattern per prior memory captures)
**Origin**: internal
**Effort**: M (investigation-scope: review agent that flags "your call" / "up to you" / "worth doing" framing on mechanical-step outcomes, OR a hook that catches specific closer phrases; not yet clear whether structural or behavioural). WSJF = 12 / 4 = 3.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

When a skill contract mandates a mechanical step — e.g. `/wr-itil:review-problems` Step 7 auto-release (per ADR-020 policy-authorised silent proceed when within-appetite), Step 2 full re-rank, Step 4.5 inbound-discovery, Step 4.6 relevance-close — the agent frames the step as **user-optional** in end-of-turn prose. Concrete phrasings observed:

- *"Step 7 auto-release skipped — your call whether to drain via `/wr-risk-scorer:assess-release`."*
- *"Skipped the full 40-ticket re-rank (Step 2), inbound-discovery pipeline (Step 4.5), and relevance-close pass (Step 4.6) to stay within context budget."*

The framing reintroduces the exact friction the **mechanical-stage carve-out** (P132 / ADR-044 category 4 — silent-framework) was engineered to remove: skill contracts pre-resolve these decisions structurally; per-instance "your call" prose asks the user to re-authorise a decision the framework already made.

Session evidence (2026-07-02):

1. **Steps 2 / 4.5 / 4.6 skipped** on the first `/wr-itil:review-problems` invocation. Framed as "context budget" scope reduction. User correction: *"why was it skipped?"* — flagging that the framework's unconditional-step contract does not have a budget-caution carve-out. Agent then ran the steps.

2. **Step 7 auto-release skipped** on the second invocation. Framed as *"user's call whether to drain."* User correction: *"why is 7 skipped?"* — Step 7's explicit skip criterion is "inside AFK orchestrator (markers detected in prompt)" and no such markers were present. Agent then ran the push.

Both instances shared the same shape: the skill contract mandates the step under conditions that held, but the agent's end-of-turn framing re-surfaced it as a user decision. That reintroduction is the defect — not the individual missed action.

Two prior related tickets identified the broader class but this specific mechanical-step-as-optional framing recurs after their closure/known-error status:

- **P234 (closed 2026-05-30)** — *"Agent defers framework-required mechanical work with rationalization; defer is fictional."* Direct predecessor of the general class. Recurrence witnessed 2026-07-02 in the two evidence instances above.
- **P179 (Known Error)** — *"Agent defers requested work into untracked phases."* Sibling class — deferral by inventing phases vs framing as user-optional; different mechanism, same downstream harm.

Related standing memory entries that flag the pattern but haven't prevented recurrence:

- `feedback_dont_defer_at_session_wrap.md` — *"execute mechanical/obvious next actions; don't enumerate them as session-side recommendations."*
- `feedback_dont_halt_loop_on_budget_caution.md` — *"don't halt on budget-caution or 'user might want to review' — continue unless a hard blocker fires."*
- `feedback_if_you_see_something_broken_fix_it.md` — *"if you see something broken, fix it. Don't defer it as 'out of scope' while accumulating dependent work."*
- `feedback_act_on_obvious_decisions.md` — *"When the decision is obvious (all-yes, pinned direction, policy-within-appetite), act and report — don't ask."*

The memories capture the pattern but rely on the agent reading and applying them each turn — an unreliable enforcement surface. A structural detection (review agent OR PostToolUse hook OR SKILL.md prose review) would catch the "your call" / "up to you" / "worth doing" closer-framing on outputs where the skill's next-step contract is unambiguous.

## Symptoms

(deferred to investigation)

- End-of-turn prose frames a policy-authorised silent-proceed step as an ask.
- Skill contract's explicit skip criteria (e.g. Step 7: "skip if inside AFK orchestrator") are not evaluated; skip is applied on generic budget-caution grounds instead.
- User repeats the same correction across sessions (2× this session, previously captured in the memory files above).

## Workaround

- User asks *"why was it skipped?"* — agent then runs the step. Reactive, per-instance, requires the user to notice.

## Impact Assessment

- **Who is affected**: the maintainer running interactive review passes (agent framing lands in end-of-turn prose). AFK orchestrator paths are unaffected (orchestrators handle release cadence per ADR-018 Step 6.5 and mechanical stages resolve silently).
- **Frequency**: at least 2× in this session; multiple prior sessions per memory captures. Class-of-behavior signal.
- **Severity**: Moderate — friction, not correctness; reintroduces user decisions the framework structurally pre-resolved.
- **Analytics**: not measured; candidate metric = per-session count of "your call" / "up to you" / "worth doing" / "user's call" phrases in agent end-of-turn prose paired with a skill step whose contract mandates the step.

## Root Cause Analysis

### Investigation Tasks

- [ ] Enumerate skill contracts with explicit mechanical-step carve-outs and their "skip if" conditions (Step 7 ADR-020, Step 4.6 4.6d, Step 4.5 mechanical-stage carve-out, Step 6.5 within-appetite drain in work-problems, etc.).
- [ ] Decide detection locus (P132 recurrences): review agent scanning end-of-turn prose, PostToolUse hook grepping specific closer phrases, or SKILL.md contract-prose amendment naming the anti-framing explicitly.
- [ ] Consider a lightweight regex hook that pattern-matches "your call" / "up to you" / "worth doing" / "user's call" adjacent to a skill-step reference in agent output — would flag rather than block per ADR-045 hook injection budget.
- [ ] Cross-check whether the `.changeset/rate-captures-at-capture.md` IDE-hinted draft changeset covers a parallel class-of-behavior fix — if so, this ticket composes with that work.
- [ ] Create reproduction test: bats fixture that pipes a skill-step end-of-turn prose sample through the detection surface and asserts a flag/PASS.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P179 (deferral by inventing untracked phases — sibling class), P234 (closed; direct predecessor umbrella), P138 (closed; "assistant defers actionable items to 'next session' when user is observably present" — closely related closer-framing class), P357 (User direction is not substance ratification — brief-and-ratify pattern is the inverse direction of this defect).

## Related

- **P234** (`docs/problems/closed/234-agent-defers-framework-required-mechanical-work-with-rationalization-defer-is-fictional.md`) — direct predecessor umbrella. Closed 2026-05-30. Recurrence witnessed 2026-07-02 in this session — either this ticket is P234 Phase 2 (recurrence with a narrower, more-specific framing detection scope) or a standalone sibling. Review-problems re-evaluation owns absorb-vs-proceed.
- **P179** (`docs/problems/known-error/179-agent-defers-requested-work-without-authorization-or-tracking-assumes-phased-implementation-when-user-described-complete-solution.md`) — sibling class (deferral by inventing untracked phases; different mechanism, same downstream harm).
- **P138** (`docs/problems/closed/138-...`) — closely related closer-framing class (assistant defers actionable items to 'next session'). Confirm exact filename during review-problems re-evaluation.
- **P357** (`docs/problems/known-error/357-user-direction-is-not-substance-ratification-agent-must-still-brief-and-ratify-after-changes-complete.md`) — inverse-shape sibling: brief-and-ratify AFTER changes. Same P350 / P132 framework territory.
- **ADR-020** (`docs/decisions/020-governance-auto-release-for-non-afk-flows.proposed.md`) — the specific mechanical-step contract Step 7 embodies; the "your call" framing directly contradicts its policy-authorised silent-proceed shape.
- **ADR-044** (`docs/decisions/044-decision-delegation-contract.proposed.md`) category 4 (silent-framework) + P132 (mechanical-stage carve-out) — the framework decision this recurrence violates.
- **ADR-045** (`docs/decisions/045-hook-injection-budget-for-pre-and-post-tool-use-hooks.proposed.md`) — if the fix locus is a PostToolUse hook, budget discipline applies.
- **Standing memory entries** (`feedback_dont_defer_at_session_wrap.md`, `feedback_dont_halt_loop_on_budget_caution.md`, `feedback_if_you_see_something_broken_fix_it.md`, `feedback_act_on_obvious_decisions.md`) — capture the pattern but haven't structurally prevented recurrence.
- **`.changeset/rate-captures-at-capture.md`** — IDE-hinted draft changeset (2026-07-02) targets a parallel class-of-behavior fix (rate scores at capture rather than defer to review). Composes-with candidate.
- **Step 2b hang-off-check** result: short-circuit fired (>5 broad-signal candidates on `mechanical`/`defer`/`optional`/`skip` tokens); subagent dispatch skipped per ADR-032 5th invocation pattern. P234 (closed) is the strongest predecessor; P179 is the strongest live sibling. Review-problems re-evaluation is the canonical absorb-vs-proceed surface.
- Captured via /wr-itil:capture-problem; scored at capture rather than deferred to next review, per the IDE-hinted `rate-captures-at-capture.md` direction.
