# Problem 395: external-comms agent silently goes dormant on the credibility axis — no nudge to author the missing RISK-POLICY section

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: corrective-feedback (user, 2026-06-28)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-302 (re-anchored from JTBD-101 per the wr-jtbd:agent gate, 2026-06-28 — JTBD-101 is a plugin-author authoring/CI job; this serves adopter discoverability of a shipped-but-dormant capability, which is JTBD-302 "Trust That the README Describes the Plugin I Just Installed")
**Persona**: plugin-user (re-anchored from plugin-developer to match JTBD-302)

## Description

The `wr-risk-scorer:external-comms` agent silently goes **dormant** on its Outbound Credibility / Self-Own axis when `RISK-POLICY.md` has no `## Outbound Credibility / Self-Own` section — it reviews the leak axis only and says nothing about the dormant axis. Per its own contract (`packages/risk-scorer/agents/external-comms.md`): *"When `RISK-POLICY.md` has no `## Outbound Credibility / Self-Own` section, the credibility axis is dormant (there is no class to cite per ADR-026 grounding) and you review the leak axis only."* The dormancy is framed as benign graceful degradation.

The user's correction (2026-06-28) inverts that framing: *"why isn't it nudging the creation of that section if it doesn't exist?"* The silent dormancy is itself the defect — a shipped capability (the credibility/self-own review axis, P384/RFC-032) is **invisible** to the adopter because nothing surfaces "this axis exists; author the policy section to activate it." This is the "capability exists but nothing surfaces it" class (the on-demand-only-rot pattern P375 rolls up; the scaffold-nudge precedent P297/ADR-047 already solves for a different shape).

The fix should NUDGE the adopter to author the section — e.g. extend the existing `risk-scorer-scaffold-nudge.sh` (P297 Phase 1 SessionStart hook) to also detect `POLICY_FILE_EXISTS AND !CREDIBILITY_SECTION_PRESENT` and advise authoring the section, OR a one-time advisory the first time the external-comms gate fires against a policy lacking the section. This is the **third predicate** in the policy-file × section matrix (P297 covers `POLICY × REGISTER-DIR`, P379 covers `!POLICY` entirely, this covers `POLICY × MISSING-SECTION`).

## Symptoms

- Run the external-comms gate (or read the agent contract) against a repo whose `RISK-POLICY.md` has no `## Outbound Credibility / Self-Own` section → the agent reviews leak-only and emits no signal that the credibility axis is available-but-dormant.
- Adopters who would benefit from the self-own axis never learn it exists.

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: plugin-developer / adopters running risk-scorer external-comms who would benefit from the credibility axis but never see it. JTBD-101 deliver-installed-features signal.
- **Frequency**: every repo whose RISK-POLICY.md lacks the section (i.e. every adopter until they author it — including this home repo, where the section is still deferred).
- **Severity**: no functional break — leak axis still works — but a shipped capability stays silently invisible (the exact rot-class the user flags).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Confirmed (2026-06-28 work-problems iter):** two compounding causes —

1. The agent contract (`packages/risk-scorer/agents/external-comms.md` lines 45, 88) frames the credibility axis as **dormant** when `RISK-POLICY.md` lacks the `## Outbound Credibility / Self-Own` section ("no class to cite per ADR-026 grounding … dormant, not lenient"). The framing is technically correct but carries **no surfacing obligation** — nothing tells the adopter the axis exists.
2. No SessionStart/gate-fire advisory detects the `POLICY_FILE_EXISTS AND !CREDIBILITY_SECTION_PRESENT` predicate. The existing `risk-scorer-scaffold-nudge.sh` covers only `POLICY × MISSING-DIR` (`docs/risks/`) and `Curation: pending review` content-state — neither the missing-section shape.

**Intended fix (mechanically validated, AFK-safe):** add the third predicate to `risk-scorer-scaffold-nudge.sh` — a read-only, every-session, class-B self-surfacing nudge advising the adopter to author the section, reusing the `WR_SUPPRESS_OVERSIGHT_NUDGE` AFK guard, with a bats four-state matrix test. The architect confirmed the *mechanics* are compliant (ADR-040 read-mostly PASS, ADR-068 guard PASS, ADR-052 test PASS) and the external-comms contract framing is consistent (the nudge surfaces dormancy, does not assert the axis is active).

**BLOCKED on a direction decision (queued to the iter's outstanding_questions — do not build on it unconfirmed, per ADR-074):** the architect flagged that the missing-**section** shape diverges from every predicate ADR-047 ratified (all `policy-file × missing-DIRECTORY`). ADR-047's 2026-06-08 amendment explicitly reserved this generalisation for a **confirmed Phase 2** ("the policy/artefact-pair semantics … likely a sibling ADR generalising the pattern") and flagged the shape as not-yet-confirmed-to-generalise. This is a genuine ≥2-option home/ADR decision not pinned by any accepted ADR:

- **Option A** — Extend ADR-047's predicate matrix in-place to add the `policy-file × missing-SECTION` shape; amend ADR-047 + re-confirm its oversight marker. (Cheapest; stretches a register-scaffold ADR to cover a different-plugin axis-activation concern.)
- **Option B** — Record a sibling generalisation ADR for "policy-file → governance-surface-activation nudges" (the Phase-2 vehicle ADR-047 itself anticipated); implement the section predicate under it. Cleaner separation; matches ADR-047's stated reassessment path. *(Architect's advisory lean.)*
- **Option C** — Home the nudge on the external-comms / ADR-028 surface (the axis it actually activates) rather than the risk-scorer scaffold hook. Co-locates nudge with the contract it serves; spreads SessionStart nudges across two hooks.

**Voice-tone phrasing (gate-approved, for whichever home wins):**
> `[wr-risk-scorer] RISK-POLICY.md present but has no '## Outbound Credibility / Self-Own' section — author it in RISK-POLICY.md to activate the external-comms credibility/self-own review axis.`

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — confirmed (agent-contract no-surfacing-obligation + no missing-section predicate detector)
- [ ] **User decision required:** pick the nudge home/ADR — Option A (extend ADR-047) / B (sibling ADR, architect lean) / C (external-comms surface). Blocks implementation per ADR-074.
- [ ] Implement the chosen predicate in `risk-scorer-scaffold-nudge.sh` + four-state bats test (mechanics pre-validated by architect)
- [ ] Create reproduction test

## Dependencies

- **Blocks**: P384 eval-floor — the held `p384` changeset's reinstate eval can't prove the active-axis self-own→FAIL without the section present; the missing nudge is upstream of P384's graduation.
- **Blocked by**: (none)
- **Composes with**: P384 (the credibility axis itself), P297/ADR-047 (scaffold-nudge precedent — the mirror to extend), P379 (sibling: nudge for missing-whole-policy-file), P375 (nothing-triggers-the-work meta — this is a rollup-candidate instance)

## Related

Captured via /wr-itil:capture-problem; PROCEED_NEW per the fresh-context `wr-itil:hang-off-check` arbiter (2026-06-28). Arbiter rationale (verbatim summary):

- **P379** (no SessionStart nudge when RISK-POLICY.md is *missing entirely*) — different trigger predicate: P379 fires on `!POLICY_FILE_EXISTS`; this fires on `POLICY_FILE_EXISTS AND !CREDIBILITY_SECTION_PRESENT`. Same SessionStart-nudge *family*, third distinct predicate in the policy-file × section matrix. Folding in would dilute P379's single-purpose `!POLICY` anchor.
- **P384** (external-comms credibility/self-own axis) — same axis, *opposite stance* on dormancy: P384 ships the agent-prose axis + a deferred author-the-section dogfood task that treats absent-section as benign; this capture asserts that benign framing IS the bug (nothing surfaces the dormant capability). The nudge is a blocker-*sibling* upstream of P384's eval-floor, not internal P384 scope. P384 is in Known Error / held-changeset lifecycle, not absorbing fresh mechanisms.
- **P297** (ADR-047 scaffold-nudge → SessionStart) — the *pattern source* to extend, not the absorber: its Phase-2 architect verdict concluded the `POLICY × ARTEFACT-DIR` pair shape is risk-scorer-specific and doesn't generalise; this rides a different shape (missing *section*) + a different surface (the external-comms gate). "Use the same template," not "Phase N of P297."
- **P375** (named-re-entry vs self-firing cadence meta) — this is a textbook *instance* of P375's "capability exists but nothing surfaces it" class; P375 tracks instances as rollup children in its `## Related` cluster, not absorbed into its body. PROCEED_NEW is how P375's other instances were handled.
