# Problem 357: User direction is not substance ratification — agent must brief-and-ratify AFTER changes are complete (sibling-class to P340 on the user-direction code path)

**Status**: Open
**Reported**: 2026-06-10
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems; HIGH in practice — same downstream blast radius as P340: ratification claims may stamp ADRs whose substance was never user-authorised because the LLM may have misimplemented the direction)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Surfaced 2026-06-10 by direct user observation during a session where the agent wrote a `human-oversight: confirmed` marker for an ADR-060 amendment immediately after applying user-direction edits (screenshot evidence: agent comment line `# Write oversight marker for ADR-060 amendment (user direction = substance ratification)` followed by SID + marker hash; sibling compendium regenerated 61 ADRs total). The user surfaced (verbatim): *"hey, the agents consider user direction = ratification. That would be true IFF the LLM correctly understands the user direction. That is not always the case, so even when the LLM is following user direction (ADR create or edit), it MUST still ratify the changes AFTER they are complete, which includes properly briefing the user on those changes (without relying on cryptic IDs to do the explaining)."*

The current agent behaviour treats user direction (a user message like *"amend ADR-X to do Y"*) as if it implied substance ratification of the resulting edit. That implication is only valid IF the LLM correctly understood the direction AND implemented it without semantic drift. The LLM doesn't always do that — it may interpret the direction wrong, choose a different mechanism than the user intended, expand scope beyond what was asked, or miss a load-bearing constraint. When that happens, the oversight marker fires on a body the user never approved — the same failure shape P340 captured for the AskUserQuestion path, now manifesting on the user-direction path that bypasses the substance-confirm AskUserQuestion gate the P340 fix added.

The required behaviour is symmetric to the P340 fix on the AskUserQuestion path: even when the agent follows user direction, it MUST surface the changes AFTER applying them so the user can confirm the LLM interpreted the direction correctly. The post-change briefing MUST be self-contained prose (per P350 brief-before-ID discipline) — not a list of cryptic IDs the user has to chase to understand what was actually changed.

## Symptoms

- Agent receives user direction (e.g. *"amend ADR-060 to remove Phase 4 type-axis machinery"*).
- Agent applies the direction via Edit/Write to the ADR file.
- Agent immediately writes `human-oversight: confirmed` + `oversight-date: <today>` + invokes `wr-architect-mark-oversight-confirmed` shim.
- No post-change AskUserQuestion fires to verify the LLM's interpretation of the direction.
- The downstream architect-agent infrastructure reads the marker as proof of ratification per ADR-066.
- User notices later, may say *"that's not what I meant"* — but by then dependent ADRs / cross-references may already cite the misimplemented version as authoritative.

## Workaround

User must manually inspect every ADR amendment AFTER the agent applies it AND BEFORE accepting the marker write. Or: user must explicitly call out *"don't write the oversight marker yet — let me see the changes first"*. Both place the cost on the user.

## Impact Assessment

- **Who is affected**: developer (maintainer-side governance authoring); secondary impact on downstream personas reading the corpus.
- **Frequency**: every user-directed ADR amendment OR ADR create where the direction is given as prose (not via the create-adr Step 5 AskUserQuestion flow). Recurrent across all governance-direction interactions.
- **Severity**: HIGH-IN-PRACTICE — same blast radius as P340: ratification claims may stamp ADRs whose substance was never user-authorised because the LLM may have misimplemented the direction; the architect-agent infrastructure operates downstream as if oversight had happened.
- **Analytics**: deferred to investigation.

## Root Cause Analysis

The `/wr-architect:create-adr` Step 5 substance-confirm AskUserQuestion gate (added by the P340 fix shipped via @windyroad/architect@0.13.0 commit 4a36ae1) only fires when the agent is walking the create-adr flow itself. When the user gives prose direction outside that flow — e.g. *"amend ADR-060 Phase 4 to remove the type-axis machinery"* — the agent applies the Edit and writes the marker without going through the substance-confirm gate. The gate is path-specific; the new gap is path-bypass.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Audit all marker-write sites: identify every path where the agent writes `human-oversight: confirmed` or invokes `wr-architect-mark-oversight-confirmed` / `wr-jtbd-mark-oversight-confirmed`. The create-adr Step 5 path has the gate; the user-direction-amendment path apparently does not.
- [ ] Design the post-change ratification gate shape: AFTER applying user-directed edits to an ADR/JTBD/RFC, BEFORE writing the oversight marker, the agent MUST surface a self-contained post-change brief via AskUserQuestion (per P350) showing the actual diff substance + asking the user to confirm the LLM's interpretation. Options: Confirm (writes marker), Amend (apply correction + re-surface), Reject (reverts edit; no marker).
- [ ] Investigate symmetry: this same class likely applies to ADR creates triggered by user direction (vs by Step 5 flow). And to JTBD/RFC writes triggered by user direction. Sweep the marker-write surfaces.
- [ ] Behavioural test: a fixture that exercises user-direction → Edit → expects post-change AskUserQuestion BEFORE marker write.
- [ ] Decide whether the post-change brief is part of the marker shim (`wr-architect-mark-oversight-confirmed` becomes interactive when LIVE) or a separate step in the agent's workflow before the shim invocation.

## Dependencies

- **Blocks**: (none — observation-class ticket; the fix is additive)
- **Blocked by**: (none)
- **Composes with**: P340 (sibling — the AskUserQuestion-path substance-confirm gap; this ticket captures the user-direction-path equivalent), P339 (the substance-question-shape question of P340), P315 (substance-confirm-before-build at the BUILD-time interaction surface — this ticket is the AFTER-build equivalent), P350 (brief-before-ID discipline — the post-change brief MUST be self-contained prose without cryptic IDs)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P340** (`docs/problems/verifying/340-human-oversight-marker-can-be-written-on-draft-acceptance-substance-confirmation-pattern-needs-prose-briefing-and-selectable-options.md`) — the AskUserQuestion-path version of this class. Fix shipped 2026-06-01 via @windyroad/architect@0.13.0 commit 4a36ae1. This new ticket captures the parallel gap on the user-direction code path that the P340 fix did not cover.
- **P339** (`docs/problems/closed/339-...`) — the question-shape sibling of P340; substance-confirm bundled with draft-acceptance.
- **P315** (the substance-confirm-before-build class at the BUILD-time interaction surface — agent implementing dependent work before substance is confirmed; this ticket captures the AFTER-build symmetric surface — agent stamping ratification marker before substance has actually been confirmed by the user).
- **P350** (brief-before-ID empathy gap; the post-change brief proposed in this ticket MUST inline what each changed line MEANS, not just cite ADR-NNN / file-paths).
- **ADR-066** (the human-oversight marker contract; the architect-agent reads the marker as proof of ratification — bogus ratification flows downstream as if it were real).
- **ADR-074** (substance-confirm-before-build — the same principle this ticket extends to post-build verification).
- **`/wr-architect:create-adr`** Step 5 (currently the only path with the substance-confirm gate; this ticket is about the user-direction paths that bypass it).
- **`/wr-architect:review-decisions`** Step 4 (the drain surface — Confirm/Amend/Reject options exist there; the proposed fix for this ticket extends a similar Confirm/Amend/Reject surface to the user-direction edit path).
- Memory `feedback_run_decisions_by_user_before_drafting.md` (the BEFORE-drafting case; this ticket captures the AFTER-drafting case).
- Memory `feedback_brief_before_id.md` (P350; the post-change brief discipline this ticket requires).
