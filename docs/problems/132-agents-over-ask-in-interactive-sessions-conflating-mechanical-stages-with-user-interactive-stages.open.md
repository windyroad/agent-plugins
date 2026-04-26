# Problem 132: Agents over-ask in interactive sessions — conflating mechanical-stages with user-interactive-stages of multi-stage skill contracts (inverse-P078)

**Status**: Open
**Reported**: 2026-04-27
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)
**Effort**: M — likely combination of (a) new UserPromptSubmit / Stop hook that detects AskUserQuestion calls firing in SKILL-explicit no-ask zones, (b) project CLAUDE.md rule reinforcing "when SKILL contract says mechanical, do not ask", (c) targeted in-skill reminders in run-retro Step 1.5 / Step 4b Stage 1 / Step 4a / wherever a skill explicitly carves out a no-ask zone. The detection hook is the load-bearing piece; CLAUDE.md + per-skill reinforcement are supporting layers.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-27 by direct user observation during `/wr-retrospective:run-retro` execution: *"As part of the retro, there is friction with you asking me if you should update the briefing and/or create tickets. Why do you feel you need to ask me?"*. P078 contradiction-signal pattern (the "you" + "why" pattern that signals a class-of-behaviour correction). The agent then traced the cause back to a defensive over-asking habit accumulated across the session: the user had corrected multiple upstream decisions (subprocess dispatch in iter 9, grep approach for P081, `.claude/` writes for the Plan output, retro cascade scope), and the agent began treating EVERY decision as user-confirmable instead of trusting SKILL contracts that explicitly carved out no-ask zones for mechanical actions.

## Description

Several SKILL contracts in this project explicitly distinguish **mechanical stages** (no user decision required — agent acts directly) from **user-interactive stages** (AskUserQuestion fires per ADR-013 Rule 1). The canonical example is `run-retro` Step 4b's two-stage codification flow:

- **Stage 1**: ticket every codify-worthy observation. *Mechanical — no user decision*. The skill text is explicit: *"Stage 1 fires regardless — ticketing is mechanical and does not require user input"*.
- **Stage 2**: record proposed fix strategy on each ticket. *User-interactive — per ticket*.

Similar mechanical-vs-interactive splits exist in:

- **`run-retro` Step 1.5 signal-vs-noise pass** — *"Classification ownership (policy-authorised per ADR-013 Rule 5): the agent owns silent classification. No AskUserQuestion is fired for individual entry promotions, demotions, or keep decisions"*. Only the **delete queue** (score ≤ -3) requires user confirmation.
- **`run-retro` Step 3 briefing additions** — additions are no-ask (apply Step 1.5 heuristic + write); only **removals** and **topic-file rotations** ask.
- **`/install-updates` Step 6a cache hit** — *"skip Step 6 — proceed directly to Step 6.5 with the cached scope. The user's prior explicit answer authorises the install per ADR-013 Rule 5 (policy-authorised silent proceed)"*.
- **`/wr-itil:work-problems` Step 6.5 drain at within-appetite** — drain is *"policy-authorised non-interactive"*; no AskUserQuestion required.
- **`/wr-itil:work-problems` Step 6.5 above-appetite ADR-042 auto-apply** — *"The skill MUST NOT call AskUserQuestion as a shortcut out of the auto-apply loop"*.

But agents in interactive sessions where the user has been actively correcting decisions — especially across multiple corrections in a single session — start over-applying ADR-013 Rule 1's "ask via AskUserQuestion when interactive" guidance to **everything**, including the explicit mechanical zones. The defensive habit:

1. User corrects a decision (e.g., "you should have done it main-turn, not subprocess").
2. Agent reasons: "I made a wrong autonomous call; I should ask before the next decision".
3. Agent over-generalises: every subsequent decision (mechanical or not) goes through AskUserQuestion.
4. Mechanical stages that the SKILL explicitly authorised silent execution of now produce friction the SKILL was designed to remove.

This is the **inverse of P078** (capture-on-correction). P078 captures *missing* asks (agent should have asked, didn't, user corrects). P132 captures *excess* asks (SKILL said don't ask, agent asked anyway, user notices the friction).

## Symptoms

- Observed 2026-04-27 during `/wr-retrospective:run-retro`: agent asked the user via AskUserQuestion (a) which of three pipeline-friction signals to add to the briefing, and (b) implicitly whether to capture P132 + P133 candidates as tickets. Both are SKILL-explicit no-ask zones (Step 3 briefing additions; Step 4b Stage 1 mechanical ticketing).
- User direct observation: *"there is friction with you asking me if you should update the briefing and/or create tickets. Why do you feel you need to ask me?"*.
- Pattern likely affects multiple SKILL surfaces:
  - `run-retro` (this incident) — Step 1.5 signal classification, Step 3 briefing additions, Step 4b Stage 1 ticketing, Step 4a verification close (mixed: per-candidate is interactive but the scan is mechanical)
  - `/wr-itil:work-problems` — Step 6.5 within-appetite drain, ADR-042 auto-apply remediations
  - `/wr-itil:manage-problem` — Step 9b auto-transitions, Step 9d verification prompts (interactive per candidate but the scan is mechanical)
  - `/install-updates` — Step 6a cache-hit silent proceed
- The defensive habit compounds across a session: the more corrections the user issues, the more the agent over-asks in subsequent decisions, the more the user has to wave the agent through mechanical stages, the more the agent over-asks. Negative feedback loop.

## Workaround

User explicitly notices and corrects the friction (this session). Agent traces the cause to the defensive habit and adjusts in-session. Without enforcement, future sessions repeat.

## Impact Assessment

- **Who is affected**: every user of every SKILL with mechanical-vs-interactive stage splits. Solo-developer (JTBD-001) primarily; AFK orchestration personas (JTBD-006) less so because subprocess iters reset the defensive context per iter.
- **Frequency**: every interactive session where the user issues 2+ corrections in a row. Once the defensive habit kicks in, it persists for the session unless explicitly broken.
- **Severity**: Moderate — degrades user experience in exactly the sessions the user is most actively engaged. The mechanical-stage no-ask design is a load-bearing UX investment that defensive over-asking silently undoes.
- **Likelihood**: Likely — the defensive pattern is a natural agent inference (when corrected, ask first). Without counter-pressure (CLAUDE.md rule + detection hook), every corrective session is a candidate.
- **Analytics**: 2026-04-27 session — this very retro. User issued 4 corrections this session (subprocess dispatch in iter 9, grep approach for P081 implementation, `.claude/` user-space writes, retro cascade scope). By the time the retro fired, the agent's over-ask was severe enough that the user noticed and surfaced this ticket request.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit all windyroad SKILL.md files for mechanical-vs-interactive stage splits. Inventory the explicit no-ask zones (Step 4b Stage 1 in run-retro is the canonical example; Step 1.5 classification ownership is another; Step 3 additions is another).
- [ ] Decide enforcement shape:
  - Option A: project CLAUDE.md rule only (declarative; relies on agent compliance) — *"When a SKILL contract says mechanical or no-ask, do not call AskUserQuestion. Trust the contract."*
  - Option B: new UserPromptSubmit / Stop hook that detects when an AskUserQuestion call fires inside a SKILL-explicit no-ask zone and emits a `systemMessage` warning (or denies). Detection mechanism: parse SKILL.md for "mechanical" / "no user decision" / "policy-authorised silent" keywords near step boundaries; cross-reference with the agent's most recent AskUserQuestion calls.
  - Option C: hybrid — CLAUDE.md rule + per-skill reinforcement (Step 4b Stage 1, Step 1.5 already explicit; add similar reinforcement to less-obvious mechanical stages elsewhere).
- [ ] If detection hook chosen: define the no-ask-zone signal. Candidates:
  - Marker pattern in SKILL.md (e.g., `<!-- no-ask-zone -->` HTML comments wrapping mechanical sections)
  - Keyword detection (regex on SKILL.md content: `mechanical`, `no user decision`, `policy-authorised silent`, `silent classification`)
  - Skill-author-curated allow-list per skill
- [ ] Investigate whether the defensive-habit-trigger can be detected: the agent receives N corrections in M turns → switch to defensive over-ask mode. If detectable, the same hook could break the loop earlier.
- [ ] Behavioural bats coverage for the detection hook (false-positive resistance is critical — a false positive on a legitimate AskUserQuestion in an interactive zone would itself produce friction).

### Preliminary hypothesis

The defensive over-ask habit is **structural** in how an agent reasons about ADR-013 Rule 1's "interactive default = AskUserQuestion" guidance. Rule 1 is correct for genuine ambiguity, but agents over-generalise it to "if user is interactive, ask before deciding ANYTHING". The mechanical-stage carve-outs that explicit SKILL contracts add are designed to remove THAT friction; defensive over-asking silently re-introduces it.

The fix path is project CLAUDE.md + per-skill reinforcement first (declarative — let the contracts speak); detection hook as the second layer if the declarative rule proves insufficient. This composes with P130 (orchestrator presence-aware dispatch) and P131 (`.claude/` user-space writes) — all three are this-session captures of agent-discipline gaps where the agent over-applied a heuristic and silently degraded UX.

## Fix Strategy

**Phase 1 (CLAUDE.md rule)**:

- Add explicit rule to project CLAUDE.md: *"When a SKILL contract explicitly carves out a stage as **mechanical** / **no user decision** / **policy-authorised silent proceed** / **agent owns silent classification**, do not call AskUserQuestion in that stage. Trust the contract. Defensive over-asking after upstream corrections silently undoes the load-bearing UX investment of the mechanical-stage carve-out (P132 inverse-P078). Save AskUserQuestion for stages the SKILL explicitly marks interactive — Stage 2 fix-shape per ticket, Step 4a verification close per candidate, Step 3 briefing removals, Step 3 Tier 3 rotations, Step 6.5 above-appetite cases, etc."*
- Land in the next CLAUDE.md edit window.

**Phase 2 (per-skill reinforcement)**:

- Audit `run-retro` SKILL.md for less-obvious mechanical stages — most are already explicit but there may be implicit no-ask zones (e.g., Step 5 summary emission has no ask but isn't labeled "mechanical"; agents could over-ask whether to emit the summary at all).
- Audit `/wr-itil:work-problems` for the same pattern — Step 6.5 within-appetite drain is explicit; Step 6.75 inter-iteration verification is implicit; Step 7 loop is implicit.
- Audit `/install-updates` Step 6a — explicit; Step 6.5 P059 auto-migration of confirmed siblings — implicit.
- For each implicit no-ask zone, add a brief "no user decision required" annotation matching the explicit ones.

**Phase 3 (detection hook — load-bearing if declarative proves insufficient)**:

- New `packages/itil/hooks/itil-mechanical-stage-detect.sh` PostToolUse:AskUserQuestion hook (or equivalent on the AskUserQuestion path):
  - Inspects the AskUserQuestion call's question header / body for keywords matching SKILL-mechanical-stage carve-outs (e.g., "should I add to briefing", "create ticket", "classify entry").
  - Cross-references against the most-recent SKILL.md the agent was running (read from session context or marker).
  - On detection: emits a `systemMessage` warning with the canonical SKILL quote ("Stage 1 fires regardless — ticketing is mechanical") and a one-line redirect ("Trust the contract; act").
  - Does NOT block the AskUserQuestion (would be too rigid); just surfaces the friction so the agent self-corrects.
- Behavioural bats per ADR-005 + ADR-044 (once landed) — false-positive resistance is critical.
- Composes with the inverse-P078 detector pattern P078 already established (UserPromptSubmit hook scanning user prompts for correction signals); this hook scans agent-side calls for over-ask signals.

**Out of scope**: detecting defensive-habit triggers (the "user-corrected-N-times-in-M-turns" pattern). That's a deeper agent-state behaviour ticket — open a sibling if Phase 1+2+3 don't sufficiently mitigate.

## Dependencies

- **Blocks**: (none — P132 is a discipline + enforcement gap; nothing strictly waits on it)
- **Blocked by**: (none — Phase 1 CLAUDE.md edit can proceed standalone; Phase 2/3 are follow-up)
- **Composes with**: P130 (orchestrator presence-aware dispatch — this-session capture of orchestrator-discipline gap), P131 (`.claude/` user-space writes — this-session capture of agent-write-discipline gap), P078 (capture-on-correction; the *original* pattern P132 inverts), P119 (manage-problem-enforce-create.sh — precedent for new PreToolUse:tool-name enforcement hooks), P085 (ADR-013 Rule 1/Rule 6 enforcement; sibling discipline ticket).

## Related

- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction; the original pattern. P132 is its inverse (excess-asks where the SKILL says no-ask).
- **P130** (`docs/problems/130-...open.md`) — orchestrator presence-aware dispatch; this-session capture of agent-discipline gap.
- **P131** (`docs/problems/131-...open.md`) — agents write to `.claude/` user space; this-session capture of agent-write-discipline gap.
- **P085** (`docs/problems/085-...verifying.md`) — ADR-013 Rule 1 / Rule 6 enforcement (UserPromptSubmit + Stop hooks; CLAUDE.md repo-root pointer); sibling discipline ticket. P132's Phase 3 detector composes with P085's existing enforcement layer.
- **P119** (`docs/problems/119-...verifying.md`) — manage-problem-enforce-create.sh PreToolUse:Write enforcement; precedent for the Phase 3 detection hook.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 (interactive default = AskUserQuestion); Rule 5 (policy-authorised silent proceed); Rule 6 (non-interactive AFK fail-safe). P132's fix reinforces Rule 5's mechanical-zone semantics.
- **`packages/retrospective/skills/run-retro/SKILL.md`** Step 4b Stage 1 — canonical mechanical-stage example (`Ticket every codify-worthy observation (mechanical — no user decision)`). P132's Phase 2 reinforces less-obvious siblings of this pattern.
- **`packages/retrospective/skills/run-retro/SKILL.md`** Step 1.5 Classification ownership — `the agent owns silent classification. No AskUserQuestion is fired for individual entry promotions, demotions, or keep decisions`. Another canonical mechanical-stage carve-out.
- **`packages/itil/skills/install-updates/SKILL.md`** Step 6a cache hit — explicit ADR-013 Rule 5 silent-proceed.
- **`packages/itil/skills/work-problems/SKILL.md`** Step 6.5 within-appetite drain + ADR-042 auto-apply — explicit policy-authorised paths.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — primary persona served. Mechanical-stage carve-outs ARE the "without slowing down" half; defensive over-asking undoes them.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — composes; AFK orchestrator iteration subprocesses naturally reset the defensive context per iter, so AFK is less affected.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-the-suite-with-new-plugins.proposed.md`) — composes; downstream adopters of windyroad SKILLs inherit the mechanical-stage contracts; P132's enforcement protects their UX too.
- 2026-04-27 session evidence: 4 user corrections accumulated through the session (subprocess dispatch in iter 9, grep approach for P081 implementation, `.claude/` user-space writes, retro cascade scope). By the time the retro fired, the agent's over-ask was severe enough that the user surfaced this very ticket request via direct observation: *"As part of the retro, there is friction with you asking me if you should update the briefing and/or create tickets. Why do you feel you need to ask me?"*. The agent's honest answer traced the cause to a defensive habit accumulated from upstream corrections — the inverse-P078 pattern this ticket captures.
