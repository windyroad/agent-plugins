---
status: draft
story-id: outbound-lifecycle-comments-generated-from-real-issue-context
reported: 2026-07-15
decision-makers: [Tom Howard]
problems: [P376]
jtbd: [JTBD-301]
rfcs: [RFC-028]
story-maps: [STORY-MAP-004]
estimated-effort: M
human-oversight: confirmed
oversight-hash: 25afedba4f3e1cdff7f4742dce1635519871fae6e3b4f117b0fbc2ff6ba77b41
---

# STORY-045: Outbound lifecycle comments generated from real issue context

**Reported**: 2026-07-15
**Problems**: P376
**JTBD**: JTBD-301
**RFCs**: RFC-028
**Story Maps**: STORY-MAP-004
**Estimated effort**: M — SKILL.md Step 4 prose rework + paired promptfoo eval cases + contract bats extensions, single plugin (`packages/itil/`), few files. Confirmed/refined at the accepted transition per I10 INVEST Estimable.

## User value (required, INVEST Valuable)

In order to hear a fast, honest verdict on fixes I ship, as an upstream maintainer receiving reports from this project, I want the downstream reporter's lifecycle comments generated from my issue's real context — crediting whoever provided the fix or workaround, honest about whether the fix is verified in the wild or merely installed, and posted even when my issue has already been closed — instead of direction-inverted form-letters that thank me for a report I never filed.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The outbound O→KE / K→V / V→Closed comments in `packages/itil/skills/update-upstream/SKILL.md` Step 4 are LLM-generated from the local ticket's sections PLUS the upstream issue's body and comments; no canned template bodies remain on the outbound path (P363 Directive 1, applied symmetrically). The outbound purpose taxonomy is preserved: test-confirm / report-outcome-with-thanks / respond-to-info-request (user clarification 2026-06-23).
- [ ] When the upstream thread suggested a workaround we adopted, the generated comment acknowledges we are using it while awaiting the fix (Directive 2).
- [ ] Titled+linked artefact references appear only when BOTH the upstream repo AND our own repo are PUBLIC (conjunction — disclosure breadth AND link-target reachability); otherwise the strict ban holds; classification tokens / step IDs / agent-internal vocabulary are banned regardless of visibility (Directive 3, architect-hardened conjunction form).
- [ ] When the upstream maintainer or a commenter provided the fix or workaround we adopted, the comment credits them by @handle and confirms the exact adopted details — four provenance branches: maintainer-self / maintainer-provided / commenter-provided / both-source (Directive 4).
- [ ] A local transition driven by a verified upstream fix auto-dispatches the outbound confirmation comment through the gate chain (cog-a11y when-available → external-comms risk → voice-tone) with no user prompt (inbound #349 expansion leg i; framework-resolved per the already-ratified auto-post-within-appetite contract).
- [ ] The generated comment states honestly whether the upstream fix is verified-in-the-wild or installed-only, and posts the outcome confirmation on an already-closed upstream issue without attempting `gh issue close`, recording the `posted-on-closed-issue` disclosure path (inbound #349 expansion leg ii; P113 closed-for-inactivity witness).
- [ ] Paired promptfoo Tier-A/B eval cases + contract bats extensions covering the above ship in the same commit as the SKILL prose (R009 prose-floor discharge).

## Driving problem trace (required — I6 invariant)

P376 Gap 2 — the outbound update-upstream templates carry the same structural defect the P363 rework fixed on the inbound side, inverted in direction (reporter-credit prose addressed to the maintainer; upgrade-request prose addressed to the package author). Fix substance ratified at the 2026-07-04 interactive decision drain (ticket § Ratified Direction); scope expanded 2026-07-15 with absorbed inbound #349.

## JTBD trace (required — I9 invariant)

JTBD-301 (Report a Problem Without Pre-Classifying It) — the reporter feedback loop, here with this project as the reporter to upstream maintainers: predictable acknowledgement, eventually responded to with an honest verdict.

## Implementation notes (optional)

Symmetric to the inbound I3 generation-prompt section already shipped in the same SKILL (P363 rework, `@windyroad/itil@0.51.2`). Held pending ADR-090 ratification of this story + STORY-MAP-004 at the next interactive drain; RFC-028's `stories:` array is wired only after ratification (ADR-090 rule 3), then implementation lands with the `Refs: STORY-045` trailer (ADR-096).

## Dependencies

- **Blocks**: (none — populate at /wr-itil:manage-story if applicable)
- **Blocked by**: (none — populate at /wr-itil:manage-story; Phase 2 I-invariant prohibits Blocked-by references to unaccepted stories at acceptance time per INVEST Independent)

## Related

(captured via /wr-itil:capture-story during the 2026-07-15 AFK P376 iteration; expand at next /wr-itil:manage-story invocation)
