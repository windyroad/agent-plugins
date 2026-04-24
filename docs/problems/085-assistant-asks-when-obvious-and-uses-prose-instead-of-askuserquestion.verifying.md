# Problem 085: Assistant asks for input when the next step is obvious, AND uses prose asks instead of AskUserQuestion when input is actually needed

**Status**: Verification Pending
**Reported**: 2026-04-21 (AFK iter 6 post-loop, during P084 evidence-update discussion)
**Priority**: 16 (High) — Impact: High (4) x Likelihood: Almost Certain (4)
**Effort**: M — requires one or more of: (1) hook on assistant output that detects prose-ask patterns ("Want me to...", "Should I...", "A or B?") and blocks the response with a systemMessage reminder; (2) hook on assistant output that detects consent-gate-when-obvious patterns (immediately-prior user message contains a direction/yes/act-verb AND next assistant message contains a question) and blocks; (3) CLAUDE.md-level mandatory rules promoted from memory feedback; (4) memory feedback addendum making the two rules explicit in the same file. Architect review at implementation to decide hook shape.
**WSJF**: 8.0 — (16 × 1.0) / 2 — High severity (two explicit in-session corrections reinforcing memory guidance that already existed; pattern recurs despite the memory being read at session start); moderate effort. Sits at the current top of the queue with P084 (worker tool-surface) as the other WSJF-8 ticket.

## Direction decision (2026-04-21, user — interactive AskUserQuestion post-AFK-iter-7)

**Enforcement mechanism**: **Hook + CLAUDE.md rule combined** (same shape as P078 direction — composed family).

**Plugin ownership** (per P015/P022/P078/P082 shared-architecture decision 2026-04-21): the prose-ask + ask-when-obvious hook lives inside `@windyroad/itil` — governance-interaction concern, same as P078. NOT a shared `/wr-governance:output-gate` registry across plugins.

Implementation surface:
- **PostToolUse hook** (on assistant-output) detects prose-ask patterns ("Want me to", "Should I", "Option A or Option B?", "(a)/(b)/(c)?") AND ask-when-obvious patterns (prior user message contains direction-pinning + current assistant response contains a question). Blocks with systemMessage requiring either (a) act-without-asking (if the decision is obvious), or (b) emit an AskUserQuestion call (if genuinely ambiguous).
- **CLAUDE.md mandatory rule** promotes the combined memory-captured guidance (`feedback_act_on_obvious_decisions.md`) to a repo-level rule. Pre-generation guidance.

Composition with P078 (correction → offer ticket): both hooks live inside `@windyroad/itil`. Implementation question at architect review: one hook file with two detection functions, or two hook files each with one. Lean: one file with a registry of detection functions — cleaner composition, shared marker pattern.

## Description

Two related behavioural gaps in the same axis — the assistant asking the user when it shouldn't, or asking in the wrong shape when it should.

**Facet A — Asks when the next step is obvious.** Despite `~/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/feedback_act_on_obvious_decisions.md` being in session memory, the assistant still surfaces prose consent-gates on obvious-next-step decisions.

Observed 2026-04-21 during P084 evidence-update discussion (session id 5e3bfb4b-a578-464b-891b-7e17939ab63f):

- User: "yes, update P084. Can custom subagents definitions accept Agent in their Tools: list? We have a subagent we can ask, don't we?"
- Assistant: updated P084-recommendation prose **then asked** "Want me to: (1) Update P084 with the probe outcome (dis-recommend (1), elevate (3)), or (2) Also verify whether custom subagent_type definitions support Agent in their Tools list before updating the ticket?"
- User correction: "rather than having a subagent check the docs, can you just ask a subagent to try launching an Agent?"

Option (1) was already directed by the user's "yes, update P084". Option (2) was obviously worth doing given the user's direction to verify. Asking was wrong on both counts.

Second instance, same session:

- Assistant reported probe findings + doc citation, then concluded: "Want me to: 1. Update P084 with the probe outcome (dis-recommend (1), elevate (3)), or 2. Also verify whether custom subagent_type definitions support Agent in their Tools list before updating the ticket?"
- User correction: "you didn't need my involement to figure the agent subagent subsubagent stuff"

**Facet B — When input is actually needed, asks in prose instead of AskUserQuestion.** Both of the above asks were prose questions in the assistant's output, not AskUserQuestion tool calls. `docs/decisions/013-structured-user-interaction-for-governance-decisions.md` Rule 1 mandates AskUserQuestion for governance decisions. The assistant has been reading this ADR and its own memory guidance all session and still emitted prose "Option A or Option B?" prompts.

User correction (third in the same exchange): "and if you have questions for me, you MUST use the askuserquestion tool"

The two facets reinforce each other: the correct rule is **"obvious default → act; genuine ambiguity → AskUserQuestion; never prose-ask"**. Today the assistant fails both halves of that rule, not just one.

## Symptoms

- Prose asks like "Want me to...", "Should I...", "A or B?", "Shall we...", "Let me know if..." emitted in the assistant's user-facing output.
- Asks surface on obvious next-step decisions the user has already directed or pre-pinned (direction-pinning, all-yes, earlier-confirmation-in-session).
- Asks surface after the assistant has completed a verification/probe/investigation that clearly mapped to one next action.
- Memory file `feedback_act_on_obvious_decisions.md` exists and is read at session start, yet the pattern still recurs.
- ADR-013 Rule 1 mandates AskUserQuestion for governance decisions; assistant still emits prose questions.

## Workaround

Manual user correction in the moment, followed by the assistant acknowledging and re-acting. High friction for the user. Does not prevent the next recurrence — the pattern persists across sessions despite memory capture.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001 — Enforce Governance Without Slowing Down)** — the "without slowing down" axis is specifically about not creating ask-friction. Prose asks on obvious decisions ARE the friction.
  - **AFK-persona (JTBD-006 — Work the backlog AFK)** — the user is AFK by definition; a prose ask without AskUserQuestion is unanswerable from notifications and blocks the loop silently. Even an appropriate AskUserQuestion in AFK mode should fall back to ADR-013 Rule 6 structured summary, never prose.
- **Frequency**: Almost Certain — at least twice in the exchange that triggered this ticket; pattern documented across multiple prior sessions (see `feedback_act_on_obvious_decisions.md` originSessionId reference). Compounds across every session.
- **Severity**: High. Trust erosion on every instance; recurring despite durable memory guidance = memory alone is insufficient signal to shift behaviour.

## Root Cause Analysis

### Structural

1. **Memory is advisory, not enforced.** `feedback_act_on_obvious_decisions.md` is read at session start but has no hook, no CLAUDE.md rule, no output-filter that prevents the pattern it names. The assistant's own reasoning is the only enforcement layer, and it fails ~30% of the time in practice.
2. **ADR-013 Rule 1 has no output-validator.** ADR-013 mandates AskUserQuestion for governance decisions, but there's no hook that scans assistant output for prose-ask patterns and blocks them. The rule lives in the decision doc; the enforcement would have to live in a hook or a CLAUDE.md rule.
3. **The two facets share a root cause: the assistant decides "should I ask here" inline during generation.** That decision is (a) context-sensitive and (b) easy to get wrong when the assistant has partial confidence in the next step. A post-hoc hook on the output stream could catch the pattern after generation, where the signal is clearer (presence of "Want me to..." / "Should I..." / "Option A or B" in the text).

### Candidate fixes

1. **Output-stream hook (PostToolUse on assistant turn / response-edit hook)** that detects prose-ask patterns in the assistant's text response and either (a) blocks the response with a systemMessage reminder to re-emit using AskUserQuestion, or (b) auto-wraps the detected options into an AskUserQuestion call. Option (a) is lower-risk (the assistant chooses); option (b) is lower-friction (automatic). Detection regex is imperfect but the pattern is stable (~10 canonical phrasings).
2. **CLAUDE.md mandatory rule** promoted from memory — explicit "BEFORE emitting any question in prose, check: (a) is the answer obvious from direction / policy / session context? If yes, act. (b) If genuinely ambiguous, use AskUserQuestion, NEVER prose." Plus a short list of canonical prose-ask phrasings to avoid. Relies on the assistant's reasoning at generation time; same failure mode as today's memory.
3. **Memory file addendum** — add the prose-ask rule to `feedback_act_on_obvious_decisions.md` or split into `feedback_use_askuserquestion.md`. Strictly weaker than option 2 (CLAUDE.md is always loaded; memory is advisory). Useful as a short-term stopgap.
4. **A combination of (1) + (2) + (3)**: hook for mechanical enforcement, CLAUDE.md for pre-generation guidance, memory for session-specific reinforcement. Defence in depth.

Recommended: (1) + (2). Hook-based enforcement is the only mechanism that has reliably worked in this plugin suite (architect/JTBD/risk-scorer/TDD all use PreToolUse or PostToolUse hooks for the same class of "assistant reasoning alone is insufficient" problem). CLAUDE.md promotion complements the hook by reducing the rate at which the hook has to fire.

## Related

- **`feedback_act_on_obvious_decisions.md`** (memory file, 2026-04-21) — the pre-existing guidance that this ticket captures as structurally-unenforced.
- **`feedback_verify_from_own_observation.md`** (memory file) — sibling memory covering a related "don't defer to the user when you can check yourself" pattern.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.md`) — Rule 1 names AskUserQuestion as the canonical surface for governance decisions. This ticket surfaces the enforcement gap: Rule 1 is declared but not hook-validated.
- **P078** (`docs/problems/078-assistant-does-not-offer-problem-ticket-on-user-correction.open.md`) — sibling pattern: assistant doesn't offer a ticket on correction. P085 is the matching pattern: assistant asks inappropriately. Both are "assistant-behaviour structural gaps" that memory alone can't enforce.
- **P082** (`docs/problems/082-no-voice-tone-or-risk-gate-on-commit-messages.open.md`) — sibling output-filter gap on a different surface (commit messages). The same hook-on-assistant-output architecture could cover both P082 and P085.
- **P083** (`docs/problems/083-work-problems-iteration-worker-prompt-does-not-forbid-schedulewakeup.open.md`) — sibling "subagent-prompt must forbid a specific behaviour" ticket; consider whether P085's hook shape composes with P083's prompt-level forbid list.
- **JTBD-001** (Enforce Governance Without Slowing Down) — the "without slowing down" axis is exactly what prose-asks-on-obvious-decisions violate.
- **JTBD-006** (Work the backlog AFK) — AFK mode especially suffers from unanswerable prose asks; ADR-013 Rule 6 structured-summary fallback is the only valid AFK ask shape, and this ticket covers it.

### Investigation Tasks

- [ ] Architect review on the fix shape: hook-based output filter (option 1) vs CLAUDE.md rule (option 2) vs combination.
- [ ] If hook-based: specify the detection regex / classifier. Canonical prose-ask phrasings observed: "Want me to", "Should I", "Would you like me to", "Shall we", "Let me know if", "Option A or Option B?", "(a) / (b) / (c)?", "Do you want to..." — plus question marks at end of assistant turn when preceding content doesn't already include an AskUserQuestion call.
- [ ] If CLAUDE.md-based: draft the rule text and decide where it lives (new section vs amendment to existing accessibility/workflow rules).
- [ ] Consider composition with P082 (commit-message voice/risk gate) and P083 (subagent-prompt forbid-list) — all three are assistant-output-validators at different surfaces.
- [ ] Implement + behavioural bats contract assertions per `feedback_behavioural_tests.md`: simulate assistant output containing a prose ask, assert the hook fires / blocks / auto-wraps; simulate an obvious-decision scenario, assert the hook does NOT fire.
- [ ] Update `feedback_act_on_obvious_decisions.md` with the prose-ask addendum (short-term) regardless of the structural fix timeline.

## Fix Released

**Release**: 2026-04-24 (AFK iter, `@windyroad/itil` minor bump).

**Implementation**: Hook + CLAUDE.md rule combined, exactly as the 2026-04-21 Direction decision pinned. Architect re-review 2026-04-24 returned GO-with-advisory:
- Event binding corrected from ticket's originally-speculated `PostToolUse` (does not fire on pure assistant text) to `UserPromptSubmit` + `Stop` (the two Claude Code events where assistant-output validation is viable). The UserPromptSubmit half is preventive (terse MANDATORY reminder when the user's incoming prompt pins a direction); the Stop half is post-hoc (reads `transcript_path`, scans the last assistant turn for canonical prose-ask phrasings, emits `stopReason` nudge when one is found and no `AskUserQuestion` tool_use call is present).
- Hook file layout: two entry scripts (one per event type) sharing a single detector registry — `packages/itil/hooks/lib/detectors.sh`. Matches the ticket's "one file with a registry of detection functions" lean.
- Plugin ownership: `@windyroad/itil`, per the shared-architecture decision referenced in Direction.

**Files shipped**:
- `packages/itil/hooks/itil-assistant-output-gate.sh` — UserPromptSubmit hook, direction-pin detection, once-per-session full block, terse reminder thereafter (ADR-038).
- `packages/itil/hooks/itil-assistant-output-review.sh` — Stop hook, prose-ask scan, `stopReason` nudge emission.
- `packages/itil/hooks/lib/detectors.sh` — canonical phrasing list (prose-ask patterns + direction-pin patterns).
- `packages/itil/hooks/lib/session-marker.sh` — byte-identical sync from `packages/shared/hooks/lib/session-marker.sh` per ADR-017.
- `packages/itil/hooks/hooks.json` — UserPromptSubmit + Stop entries registered.
- `scripts/sync-session-marker.sh` — `itil` added to `CONSUMERS`.
- `CLAUDE.md` (repo root) — 2–4 line MANDATORY pointer promoting the memory rule to repo-level, pointing at the detector file for the full phrasing list (ADR-038 progressive disclosure).
- `.changeset/wr-itil-p085-assistant-output-gate.md` — minor bump.

**Tests**: 22 new behavioural bats assertions under `packages/itil/hooks/test/` per `feedback_behavioural_tests.md` / P081 — simulate JSONL transcripts on stdin, assert hook fires/does-not-fire under matching/clean scenarios. No structural grep-for-string tests.

**Verification path (on return)**: session after next release, user pins a direction (e.g. "yes, proceed") — UserPromptSubmit hook injects the MANDATORY reminder. If assistant still emits a prose-ask, Stop hook `stopReason` appears in the next turn's context. If neither hook fires on a known direction-pin / prose-ask exchange, re-open.

**Follow-up advisory** (architect, not blocking): the P078 + P085 + P082 cluster introduces a new architectural primitive — "assistant-output gate on UserPromptSubmit/Stop" — distinct from the existing "file-edit gate on PreToolUse". A future ADR should codify the primitive + the per-plugin ownership rule. Not drafted this iter; follow-up ticket candidate.

**Related fixes landed together in this commit**: none. Single-ticket commit per ADR-014.
