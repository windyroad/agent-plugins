# Problem 465: The story `accepted` gate names ADR-090 ratification but no surface enforces it

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 8 (Medium) — Impact: 2 (Minor — governance/dev-tooling; an unratified story can be built on, defeating a human-oversight gate, but nothing adopter-facing breaks) × Likelihood: 4 (Likely — the hole is open in code today and the ambiguous prose actively invites the reading; an agent proposed exactly this bypass during the P430 iteration) — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — SKILL prose disambiguation + a ratification check at one or two enforcement loci + behavioural bats — cf. P456 (M)
**JTBD**: JTBD-006
**Persona**: developer

## Description

ADR-095 (line 45) and ADR-096 (lines 19, 25, 44) both state that human ratification per ADR-090 fires at the story's `draft → accepted` gate. ADR-096 goes further, closing its Decision Outcome with the claim that once the gates are in place "no malformed or unratified story can ever be implemented".

No surface implements that. `packages/itil/skills/manage-story/SKILL.md` gates `accepted` on I7 + I8 + I10 only (lines 18 and 102 — RFC trace, story-map trace, INVEST shape). `packages/itil/hooks/itil-no-implement-draft-gate.sh` resolves the story's `status:` and blocks only when it is not `accepted` / `in-progress`; it carries no ratification check at all (grep for `ratif` or `oversight` returns nothing). ADR-096's own Confirmation item (b) specifies the hook blocks on status only — so the ADR under-specifies its own Decision Driver and cannot deliver its Decision Outcome claim.

The result is that a story can be transitioned to `accepted` and then implemented while `human-oversight: unconfirmed` is still in its frontmatter, and every gate will pass.

Compounding the hole, `manage-story` SKILL.md line 179 describes `ratify` as "orthogonal to the `status:` lifecycle". That phrase is ambiguous between "ratification is not itself a status" (what it means) and "ratification is not a precondition of any status" (what it reads like). An agent acting on the second reading would accept and implement an unratified story believing it was fully compliant — which is exactly what was proposed during the P430 iteration on 2026-07-26 before `wr-architect:agent` refuted it (findings N1/N2). The architect asked explicitly for this to land as a ticket rather than a retro recommendation.

## Symptoms

- 2026-07-26 (P430 iter): the agent read SKILL.md line 179 plus the I7/I8/I10-only accepted gate and concluded that `manage-story 047 accepted` was reachable under AFK without ratification, which would have unblocked implementation. The architect refuted the reading on ADR-095/096 grounds and confirmed the mechanical path would indeed have succeeded — "your reading is accurate about the implementation and wrong about the decisions". The gate is held closed by decision alone, not by code.

## Workaround

Rely on the architect gate to catch the bypass. That works only when an architect review happens to run against a plan that names the transition, and it costs a full review round-trip to discover.

## Impact Assessment

- **Who is affected**: maintainers and AFK iterations working the story tier; anything downstream that trusts `accepted` to mean "a human has seen this".
- **Frequency**: latent on every story transition; realised whenever an agent reasons from the code rather than from ADR-095/096.
- **Severity**: Medium — the failure is silent (the story looks compliant) and it defeats the specific gate ADR-096 was written to close.

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide the enforcement locus: the `manage-story accepted` transition check, `itil-no-implement-draft-gate.sh`, or both. ADR-096 names the commit-trailer gate as the primary locus precisely because it catches hand-written commits, which argues for the hook.
- [ ] Disambiguate SKILL.md line 179 — "orthogonal" should say "not itself a lifecycle state, but a precondition of `accepted`".
- [ ] Amend ADR-096's Confirmation item (b) so it specifies the ratification check its Decision Driver depends on.
- [ ] Behavioural bats: a commit referencing an accepted-but-unratified story is blocked; an accepted-and-ratified story is allowed.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P456 — the inverse pair. P456 is the same gate being impassable under AFK (too strict); this ticket is the same gate being unenforced in code (too loose). P456's ratified fix direction is a selector-skip in the work-problems Step 3 selector; this one lands in `manage-story` and/or the draft gate. A fix to either MUST reference the other so the selector-skip direction and the enforcement check do not contradict.

## Related

- Surfaced by `wr-architect:agent` findings N1 + N2 during the P430 iteration, 2026-07-26.
- ADR-090 (drift-invalidated story/map oversight marker), ADR-095 line 45, ADR-096 lines 19/25/44 + Confirmation (b).
- Hang-off check (`wr-itil:hang-off-check`, 2026-07-26) returned PROCEED_NEW against P456, P457, P409, P412: all four share the ADR-089/090/095/096 citation cluster, which is ubiquitous across the story-tier backlog, but none shares this fix locus or root cause. P457 is ratification firing too early on an unauthored story-map (different tier, different stage); P409 is legacy-data conformance and explicitly disclaims codification work; P412 is adopter-facing discoverability and excludes enforcement extensions at its scope boundary.
- Captured via `/wr-itil:capture-problem`; expand at next investigation.
