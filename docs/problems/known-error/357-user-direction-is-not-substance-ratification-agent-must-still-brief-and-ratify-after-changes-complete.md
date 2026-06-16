# Problem 357: User direction is not substance ratification — agent must brief-and-ratify AFTER changes are complete (sibling-class to P340 on the user-direction code path)

**Status**: Known Error
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

### Marker-write-site audit (iter-31, 2026-06-16)

Swept every `human-oversight: confirmed` / `wr-*-mark-oversight-confirmed` write surface across `packages/architect` + `packages/jtbd`:

| Surface | Gate present? | Notes |
|---|---|---|
| `/wr-architect:create-adr` Step 5 § 5a | **Yes** (P340) | Briefing-in-prose + option-shaped `AskUserQuestion` BEFORE marker write; born-confirmed only on substantive-option match. |
| `/wr-architect:review-decisions` Step 3/4 | **Yes** (drain) | `AskUserQuestion` Confirm/Amend/Reject + brief-before-ID (P350/P302). **Latent P357-class sub-gap**: the **Amend** sub-path "applies the directed change first" then writes the marker with NO post-amend re-confirm — the LLM could misimplement the directed amend and the marker still lands. Lower-risk (user present, same turn) but same class. |
| `/wr-jtbd:confirm-jobs-and-personas` Step 3/4 | **Yes** (drain) | Same shape as review-decisions; same latent Amend sub-gap. |
| **Freeform "amend ADR-X / JTBD-X" user-direction path** | **NO** | Ungoverned by any SKILL. Agent applies Edit + calls `wr-architect-mark-oversight-confirmed` directly, rationalising "user direction = ratification." **This is the P357 gap** — and it is a *subclass of the P348 hollow-marker bug* (the shim's own doc comment: "every legitimate marker write traces back to an `AskUserQuestion` answer in the same turn"). |

**"P340/P350 may have already addressed this" hypothesis → FALSE (confirmed by audit).** P340 closed the create-adr + drain (AskUserQuestion-flow) paths. The freeform-prose user-direction-amendment path has no governing SKILL and bypasses all three gates.

### Fix shipped this iter (project-local behavioural backstop)

Codified the user's pinned behavioural direction as a new **MANDATORY rule (P357)** in the project root `CLAUDE.md`, mirroring the P085/P078/P131/P132 shape: *user direction ≠ substance ratification; after a freeform user-directed governance-artefact edit, brief-and-ratify AFTER (self-contained prose per P350) before the marker write; under AFK write `human-oversight: unconfirmed` and queue for the next interactive drain (ADR-066 P348 fallback).* Architect + JTBD pre-edit gates both PASS; no new ADR required (the rule restates already-ratified ADR-066 P348 + ADR-074). This is the mechanism-independent backstop; the structural enforcement layer is the deferred design decision below.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Audit all marker-write sites (iter-31 — see table above). 3 governed surfaces + 1 ungoverned freeform path; freeform path is the P357 gap, a P348-hollow-marker subclass.
- [ ] **DESIGN DECISION (queued for user — born-proposed, do NOT build on unconfirmed substance per ADR-074):** the structural enforcement mechanism for the freeform path. Genuine ≥2-option choice: **(a)** make `wr-architect-mark-oversight-confirmed` interactive when LIVE (shim owns the post-change confirm) vs **(b)** a PreToolUse-hook enforcement extending `architect-oversight-marker-discipline.sh` to require a post-change-confirm evidence marker on freeform edits vs **(c)** a separate agent-workflow step before the shim invocation. Plus a sub-decision: does the latent **Amend** sub-gap on the drains warrant a post-amend re-confirm? The CLAUDE.md backstop (shipped iter-31) is the behavioural spec the chosen mechanism enforces.
- [x] Investigate symmetry (iter-31): the freeform-direction class applies to ADR creates, JTBD writes, AND the drain **Amend** sub-paths (recorded above). Swept architect + jtbd marker surfaces.
- [ ] Behavioural test: a fixture that exercises user-direction → Edit → expects post-change AskUserQuestion BEFORE marker write (deferred with the mechanism decision — the test asserts the chosen mechanism).

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
