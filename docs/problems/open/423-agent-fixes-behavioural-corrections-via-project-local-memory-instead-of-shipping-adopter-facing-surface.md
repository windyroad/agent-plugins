# Problem 423: Agent "fixes" recurring behavioural corrections via project-local memory instead of shipping an adopter-facing plugin surface

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 16 (Critical) — Impact: 4 x Likelihood: 4
**Origin**: internal
**Effort**: M
**WSJF**: 8.0 — (16 × 1.0) / 2 (added 2026-07-15 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

**User correction (verbatim, 2026-07-06):** *"'Updating the durable memory' — that won't help plugin users."*

When the user corrects a recurring behaviour that the `@windyroad/*` plugins are supposed to govern, the agent's reflex is to write a note to its **project-local, agent-private memory** (`~/.claude/projects/<proj>/memory/feedback_*.md`). That memory:
- Is loaded only into THIS agent, in THIS project. It conditions the agent's own priors.
- Ships to **no one**. Plugin **adopters** who install `@windyroad/itil` (etc.) get **nothing** from it — the behaviour the correction targets is not enforced, detected, or documented in the shipped plugin.

So a correction about how the plugins/agent should behave gets "resolved" in a channel that reaches only the maintainer's own machine. The recurring behavioural defect persists for every adopter. This is a **lesser-fix** (same class as P422 X-prime hedging): the correction is honoured in form (something was written down) but not in substance (the fix does not reach the people it should).

**The rule:** a correction that should govern the plugins or their adopters MUST land as a **shipped plugin surface** — a hook (PreToolUse/PostToolUse/Stop/UserPromptSubmit), a SKILL/agent contract line, a CLAUDE.md-injected instruction, a test fixture, or a policy doc that ships in the package. Project-local memory is legitimate ONLY for **agent-private, session-local reinforcement of THIS maintainer's own habits** — never as the fix for adopter-facing behaviour.

## Symptoms

- Session 2026-07-06: the X-prime/hedging correction (P422) was initially "fixed" by updating `feedback_no_shortcuts_no_softening.md` — helps no adopter; the user flagged it immediately.
- P311 (closed 2026-06-10 as "class captured in session memory") RECURRED — the memory-only close was insufficient, exactly this failure mode.
- General: `feedback_*.md` memories accumulate as the default reach for behavioural corrections, while the shipped plugins carry no corresponding enforcement.

## Impact Assessment

- **Who is affected**: plugin adopters (the corrected behaviour never reaches them) + the maintainer (must re-correct the same class repeatedly because nothing shipped enforces it).
- **Frequency**: routine — memory is the low-friction default; multiple instances per session.
- **Severity**: High — the plugin suite's whole value proposition is shipping governance to adopters; fixing governance in private memory defeats it (JTBD-101 "Extend the Suite" / adopters get skills-not-ADRs).
- **Analytics**: P311 memory-only → recurred; P422 initial memory-fix caught same-session.

## Root Cause Analysis

### Investigation Tasks

- [ ] Codify the routing rule: behavioural correction that governs plugins/adopters → shipped surface (hook/SKILL/agent/CLAUDE.md/test/policy); agent-private habit → memory. Candidate homes: a CLAUDE.md contract line + a run-retro Step 4b codification-shape reminder ("memory is not an adopter-facing shape") + possibly a detector.
- [ ] Reconcile with the run-retro codification catalog (Step 2 shape list already lists Memory as a shape — tighten its "best fit" to agent-private habits only, never adopter-facing behaviour).
- [ ] Audit existing `feedback_*.md` memories for ones that SHOULD be shipped surfaces (e.g. the no-shortcuts/hedging class → P422's shipped fix) and migrate them.

## Dependencies

- **Blocks**: (none)
- **Composes with**: P422 (X-prime hedging — same lesser-fix class; P422's fix MUST be adopter-facing per this ticket); P311 (closed memory-only → recurred — the canonical evidence).

## Related

- **P422** — sibling; its fix is now mandated adopter-facing (shipped hook + SKILL/CLAUDE.md contract), not memory.
- **P311** (`docs/problems/closed/311-*.md`) — closed memory-only 2026-06-10, recurred → the load-bearing evidence that memory-only fixes fail.
- Session memory `feedback_no_shortcuts_no_softening.md` — the memory that "fixed" P422 initially; illustrative of the anti-pattern (kept as agent-private reinforcement, but is NOT the fix).
- **JTBD-101** (Extend the Suite) / adopter-gets-skills-not-ADRs boundary — the reason adopter-facing shipping matters.
