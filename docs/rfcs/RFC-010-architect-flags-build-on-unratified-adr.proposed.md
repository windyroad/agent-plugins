---
status: proposed
rfc-id: architect-flags-build-on-unratified-adr
reported: 2026-05-27
decision-makers: [Tom Howard]
problems: [P318, P425]
adrs: [ADR-074, ADR-066, ADR-064]
jtbd: [JTBD-006, JTBD-001]
stories: []
---

# RFC-010: Architect flags changes built on an unratified ADR

**Status**: proposed
**Reported**: 2026-05-27
**Problems**: P318 (Phase 1 driver), P425 (Phase 2 driver — trace edge wired 2026-07-26 per P371 existing-vehicle-untraced sub-case: P425 is a defect in Phase 1's delivered scope, so this RFC is its fix vehicle rather than a new one)
**ADRs**: ADR-074 (build-upon contract — generalises enforcement surface 1), ADR-066 (oversight marker + orthogonal-axis design), ADR-064 (verdict types)

## Summary

Close the residual P315 foreground gap: the architect agent (and `/wr-architect:review-design`) review every project file edit + plan but do NOT flag a change that builds on an **unratified** ADR (one lacking `human-oversight: confirmed`). Wire that check into the architect's review at the broadest, always-on surface.

Key framing (user correction 2026-05-27): the trigger is the **oversight marker**, NOT `proposed` status. Building on a ratified ADR (even `status: proposed`) is fine; only marker-less (unratified, non-superseded) dependencies flag. Census 2026-05-27: 61/65 ratified, 4 unratified — near-silent in steady state.

## Driving problem trace

- **P318** — architect review doesn't flag build-on-unratified-ADR; only the ITIL propose-fix surface (RFC-008) does, leaving ad-hoc foreground edits/plans uncovered.

## Scope

- **`agent.md`**: add issue type **[Unratified Dependency]** + the review instruction — when a change/plan explicitly **cites or implements** an ADR, the architect Greps that ADR's frontmatter for `human-oversight: confirmed` (the agent has Grep, not Bash — it cannot run `wr-architect-is-decision-unconfirmed`, so it performs the equivalent marker-grep). If absent AND the ADR is not `*.superseded.md` → emit **ISSUES FOUND / [Unratified Dependency]** with action "ratify ADR-NNN via `/wr-architect:review-decisions` before this lands." Status-agnostic; never key on `proposed`.
- **`review-design/SKILL.md`**: note the [Unratified Dependency] check applies to plan review.
- **Bound** to explicit cite/implement (not transitive dependence). Near-zero unratified set keeps noise negligible regardless.
- **Test**: structural doc-lint that `agent.md` carries the [Unratified Dependency] type + the marker-grep instruction (structural-permitted per ADR-052 Surface 2, P176 — the agent verdict is prompt-driven, not behaviourally testable until the skill-invocation harness lands; mirrors the existing `architect-needs-direction-verdict.bats` precedent). **HISTORICAL — Phase 1 record only.** ADR-052's 2026-06-09 amendment repealed the Surface-2 `structural-permitted` carve-out this bullet relies on; T3's test is now a known state of violation tracked by P290, not a permitted shape. The behavioural harness that replaced it exists at `packages/architect/agents/eval/`. Do not cite this bullet as precedent — see Phase 2 T7.

Out of scope: the ITIL propose-fix guard (RFC-008, already shipped — this generalises it to the architect surface); re-deciding the marker-vs-status framing (settled by the user).

## Tasks

- [x] **T0 DONE** — recorded **enforcement surface 3** as a thin Amendment 2026-05-27 to ADR-074's Decision Outcome (architect verdict ISSUES FOUND on [Undocumented Decision] — surface 3 is a genuinely new surface; substance user-pinned same-session so born-confirmed, not Needs-Direction).
- [x] **T1 DONE** — `agent.md`: added `[Unratified Dependency]` issue type + the "When to flag" instruction. Grep-based (agent has Read/Glob/Grep, no Bash) read-only equivalent of `is-decision-unconfirmed.sh`: frontmatter-scoped, case-insensitive + trailing-ws-tolerant marker match, `*.superseded.md` skip, keyed on the marker NOT `status:`, explicit-cite-only (inverse-P078 over-fire guard).
- [x] **T2 DONE** — `review-design/SKILL.md`: noted the [Unratified Dependency] check is in-scope for plan review (the agent owns it; no extra prompt wiring).
- [x] **T3 DONE** — `architect-unratified-dependency-verdict.bats` (5 structural assertions, `tdd-review: structural-permitted (justification: P176)` header per ADR-052 Surface 2). 12 architect-verdict bats GREEN.

**Phase 1 implementation status (2026-05-27): COMPLETE** — this describes T0–T3 only; **Phase 2 below is open**. Architect PASS on the resolved plan (ADR-074 surface-3 amendment + frontmatter-scoped/superseded-skip grep fidelity + structural-permitted test header). JTBD PASS.

## Phase 2 — over-fire carve-out (P425) — APPROACH UNDECIDED, BLOCKED

Phase 1 (T0–T3, 2026-05-27) shipped the guard. Phase 2 addresses a defect in that delivered scope: the guard over-fires on ADRs the architect itself prescribed.

**Falsified premise.** The Scope section above bounds the guard's noise on a stated premise — "the near-zero unratified set keeps noise negligible" (census 2026-05-27: 61/65 ratified). That holds in interactive steady state, where `create-adr` births ADRs confirmed and the `/wr-architect:review-decisions` drain clears the tail. It is **false inside an AFK loop**: every ADR the loop captures is mandated born `human-oversight: unconfirmed` (ADR-066 / P348), and the drain is an `AskUserQuestion` surface the ADR-044 AFK carve-out forbids mid-loop. So the unratified set is never near-zero while the loop runs, and the guard fires on the loop's own prescribed output with no reachable clearing action.

**Approach undecided.** The fix must add a fourth non-flagging case without weakening the three cases Phase 1 legitimately closes. That is a choice among ≥2 viable options with no pinned direction, so per ADR-070 it is not recorded here: the candidate options and their trade-offs live in **P425**, and the pick is queued as ADR-044 category-1 direction-setting against the governing decisions already in `adrs:` — ADR-074 (enforcement surface 3) and ADR-066 (definition of "unconfirmed"). Phase 2 is **not a proposed fix** — it is reopened scope awaiting that pick.

**Blocked prerequisite chain** (in order; nothing below step 1 can start):

1. Ratify the option pick — an amendment to ADR-074 (enforcement surface 3) and ADR-066 (definition of "unconfirmed"). No AFK path.
2. Capture the story on a story map (ADR-095 membership at capture; ADR-089 ≥1 story per RFC). Deliberately blocked, not merely deferred: ADR-095 requires a real user-value statement and ≥1 acceptance criterion at capture, and those differ materially across the candidate options — authoring the story now would force the pick, which is the P315 build-on-unconfirmed failure ADR-074 exists to prevent.
3. Ratify the map and story (ADR-090).
4. Promote the story to `accepted` before any implementation (ADR-096).

**Consequence of reopening** (architect advisory 2026-07-26): RFC-010 cannot reach `accepted` until T8 lands, because ADR-089's gate bites on the empty `stories:` array at that transition. This RFC therefore stays `proposed` for as long as the option pick stays unratified. That is the correct consequence of reopening scope rather than closing Phase 1 out.

**Tasks** (all blocked on step 1):

- [ ] **T4** — record the option pick as an amendment to ADR-074 surface 3 + ADR-066's unconfirmed definition. Deliberately NOT captured during the 2026-07-26 AFK iteration: minting a born-`unconfirmed` ADR mid-loop is itself dependent work resting on an unconfirmed pick (the P315 failure) and is literally the defect P425 describes. When T4 lands, the deferred `docs/decisions/README.md` compendium regen comes due — verify the `grep -ac "### ADR-"` entry count against HEAD before committing, given the known truncation failure mode.
- [ ] **T5** — apply the carve-out in lockstep to `packages/architect/agents/agent.md` and `packages/architect/scripts/is-decision-unconfirmed.sh` (sync contract: that script's header lines 12-18; drift test `packages/architect/scripts/test/is-decision-unconfirmed.bats`). **If the pick lands in the predicate layer rather than purely in agent.md verdict logic, `packages/architect/scripts/detect-unoversighted.sh` must move in lockstep too** — it is the canonical shape `is-decision-unconfirmed.sh` mirrors, and the drift test's `@test "agrees with detect-unoversighted …"` case fails if they diverge. Named explicitly so discovery does not depend on a RED test.
- [ ] **T6** — apply the same carve-out to the JTBD twin (`packages/jtbd/agents/agent.md`, `packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh`, and the corresponding canonical detector), which carries the identical guard via RFC-011. Omitting it leaves the deadlock live on the other gate.
- [ ] **T7** — add the positive-fire reproduction case to the existing `packages/architect/agents/eval/promptfooconfig.yaml`. Blocked on the fixture-corpus wiring named in that file's COVERAGE NOTE: the agent reads the live `docs/decisions` root because `run-agent-eval.sh` line 39 does `cd "$REPO_ROOT"`, so the half-built fixture at `packages/architect/agents/eval/fixtures/repo/docs/decisions/074-unratified-fixture.proposed.md` is never the cwd. Architect twin of the JTBD RFC-012 S1b slice — **P324 / RFC-012**. No structural test substitutes: ADR-052's 2026-06-09 amendment repealed both escape hatches, and line 135 directs such a case to block on the harness-gap ticket. Phase 1's own T3 structural bats is a known state of violation tracked by P290, not precedent.
- [ ] **T8** — back-fill the ADR-089 story (step 2 above) once the pick is ratified.

**Driving problem**: P425 (Known Error). **Sibling surfaces**: P453 + P419 — the JTBD-gate self-invalidation family, genuinely hash-vs-substance, where P425 is verdict statelessness. Not wired into `problems:` (they are sibling surfaces, not driven by this vehicle).

## Commits

(maintained automatically — RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **P318** — driving problem.
- **ADR-074** — this extends enforcement surface 1 (architect verdict) from new-decision-recording to build-on-existing-unratified.
- **ADR-066** — orthogonal status/oversight axes + the "unconfirmed = marker absent + not superseded" definition.
- **RFC-008** — built the predicate + the ITIL propose-fix guard; this is the architect-surface generalisation.

(captured via /wr-itil:capture-rfc; design settled by the user's proposed-vs-unratified correction. Advance via /wr-itil:manage-rfc.)
