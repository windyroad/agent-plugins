# Problem 404: Implement ADR-089 + ADR-090 in the skills and tests (≥1-story-per-RFC + story-map/story ratification)

**Status**: Known Error (reopened 2026-07-05 — verification FAILED, see § Verification Failed below)
**Reported**: 2026-07-02
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 = 12. Rated at review 2026-07-02: implement ADR-089+090 in skills+tests.
**Origin**: internal
**Effort**: L. WSJF = (12 × 2.0) / 4 = 6.0 (Known Error multiplier 2.0).
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

The deferred implementation ripple from the 2026-07-02 ratification of **ADR-089** (every RFC has ≥1 story) and **ADR-090** (story maps and stories carry a drift-invalidated human-oversight marker). Both ADRs are `human-oversight: confirmed`; this ticket makes the behaviour real in the skills + tests. Two coupled phases sharing the `capture-rfc` / `manage-rfc` surface.

### Phase 1 — ADR-089 (every RFC has ≥1 story)

- Remove the empty-stories fallback branch in the `work-problem` / `manage-problem` Known-Error traversal + the `Refs: RFC-NNN` atomic trailer path.
- Update `capture-rfc` + `manage-rfc` to **require ≥1 story** — an RFC cannot reach `accepted` with an empty `stories: []`; drop the lazy-empty `## Stories`-omission-on-`[]` logic.
- **Flip the four currently-GREEN bats** that assert the empty-stories fallback is legal to assert it is **rejected**: `rfc-stories-extension.bats`, `working-the-problem-traversal.bats`, `check-rfc-rejected-alternatives.bats`, `list-stories-contract.bats`. These are the highest-signal item — they are green now and **must flip in the same slice** that ships the behaviour, or CI goes red the moment the doc change is consumed.
- Legacy-data question: do existing on-disk RFCs with `stories: []` (e.g. RFC-003 frontmatter) need back-filling one story each?

### Phase 2 — ADR-090 (story-map/story drift-invalidated human-oversight)

- Add the `human-oversight:` marker field + write path to the story-map/story skills (`capture-story-map`, `manage-story-map`, `capture-story`, `manage-story`).
- Add the **drift-invalidation trigger**: any edit to a map or story re-opens its marker to `unconfirmed` (hook- or skill-side; ADR-009 TTL/drift lineage, NOT ADR-066 write-once).
- Add the **RFC-references-only-ratified-stories gate** to `capture-rfc` / `manage-rfc` (composes with Phase 1: the atomic fix's single story must itself be ratified before its RFC lists it).
- Add an unratified-story-map detector mirroring `wr-architect-detect-unoversighted`.
- Behavioural bats for the marker + drift-reopen + the reference gate.

## Symptoms

(deferred to investigation)

## Workaround

None needed — this is a governance-implementation gap, not a runtime break. The framework runs on the pre-ADR model (RFCs may carry `stories: []`; the story tier has no oversight axis) until the fix ships; existing behaviour is unaffected. The gap is the *absence* of the newly-ratified enforcement — nothing to work around, only to build.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause:** ADR-089 + ADR-090 were ratified this session (both `human-oversight: confirmed`) but never implemented. `capture-rfc`/`manage-rfc`/`work-problem`/`manage-problem` still encode the empty-`stories: []` atomic-RFC fallback, and the story-map/story tier has no `human-oversight` marker, drift-invalidation trigger, RFC-reference gate, or detector.

**Evidence (reproduction):** four bats are green *asserting the empty-stories fallback is legal* — they must flip. RFC-036 shipped this session with `stories: []`, the live artifact of the un-fixed model. Story maps/stories carry no oversight axis (STORY-MAP-002's markers were added by hand this session, not by tooling).

### Investigation Tasks

- [x] Re-rate Priority and Effort (2026-07-02: Impact 3 × Likelihood 4 = 12 High; Effort L; WSJF now (12 × 2.0)/4 = 6.0 as Known Error)
- [x] Decide the implementation vehicle: **standalone RFC-037** (P404 is distinct from RFC-005's P251/P399; architect PASS 2026-07-02)
- [x] Phase 1: require ≥1 story + remove empty-stories fallback (2026-07-03). Accept gate = `check-rfc-has-stories` predicate wired into `manage-rfc` proposed→accepted (commit 3e3300a3); empty-stories atomic fallback removed from the `manage-problem`/`work-problem` Known-Error traversal (commit d2eb97d5). Bats: only `working-the-problem-traversal.bats` actually needed flipping (it was coupled to the removed prose); `rfc-stories-extension` / `check-rfc-rejected-alternatives` / `list-stories-contract` verified green — their empty-stories references are draft-legal renderer behaviour + incidental fixtures, NOT the removed fallback. `rfc-stories-extension` title/comment reframed to ADR-089. 36/36 green.
- [x] Phase 1: legacy `stories: []` back-fill — **DECISION (2026-07-03): back-fill for ADR-089 consistency, but low-urgency.** Existing accepted RFCs (RFC-036, RFC-003) with `stories: []` never re-fire the transition-time accept gate, and `check-rfc-has-stories` surfaces them at any future `manage-rfc accepted`. Deferred to a follow-up slice (real INVEST-story authoring per RFC, not mechanical).
- [~] Phase 2: marker field + drift-invalidation trigger + reference gate + detector + bats — **mostly done (2026-07-03)**. Shipped: the RFC-references-only-ratified-stories gate (`wr-itil-check-rfc-stories-ratified`, wired into `manage-rfc` accept); the **lazy-fingerprint drift-invalidation** (chosen over eager-hook per user decision — `packages/itil/lib/story-oversight.sh` + `wr-itil-mark-story-oversight-confirmed`; any edit drifts the `oversight-hash` and re-opens ratification); the drift-aware unratified detector (`wr-itil-detect-unratified-stories-maps`); and bats for all (marker + drift-reopen + reference gate + detector, 23 new). The 5 cohort stories + STORY-MAP-002 back-filled with fingerprints. **Remaining Phase-2 wiring**: (a) ✅ detector wired into `/wr-itil:work-problems` Step 2.4 gate (a) drain (2026-07-03). (b) **NOT DONE — this is the one substantial piece left**: `manage-story` / `manage-story-map` have **no ratification flow at all** (verified 2026-07-03 — zero `ratif`/`oversight`/`confirm` references). The 5 cohort stories + STORY-MAP-002 were ratified ad-hoc via the primary agent's per-artefact `AskUserQuestion` this session, not via a skill. Building the ratify flow = a design piece mirroring the architect's `review-decisions` / create-adr Step 5 machinery: a human-confirm `AskUserQuestion` step that, on confirm, calls `wr-itil-mark-story-oversight-confirmed` to write the fingerprint, with the P348 born-confirmed discipline (explicit `CLAUDE_SESSION_ID`, same-turn confirm event, no hollow markers). (c) ✅ all four skills (`capture-story`, `manage-story`, `capture-story-map`, `manage-story-map`) exist — no skill-creation needed, only the ratify-flow addition in (b).
- [ ] **Use STORY-MAP-002 as the golden exemplar**: its hand-authored, fully-ratified map + 16 stories (built + ratified end-to-end this session) are the worked example of the *output* the implemented map/story-authoring tooling must produce — same shape, INVEST value-first statements, per-beat/release structure, and drift-invalidated oversight. Assert the tooling can (re)produce an artefact of this quality.

## Fix Strategy

Implement via **RFC-037** (authored 2026-07-02; traces `problems: [P404]`; architect + JTBD PASS). Two-phase catalogue — Phase 1 ADR-089 enforcement (cross-cutting) + Phase 2 ADR-090 story-map/story tooling. Its `stories:` are STORY-MAP-002's A3 tooling stories (STORY-020/021/022/024/025), which must transition `draft → accepted` (INVEST gate via `manage-story`) before implementation. STORY-MAP-002 + its stories are the golden exemplar the tooling must reproduce.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — ADR-089/090 are ratified; this is their implementation)
- **Composes with**: RFC-005 / STORY-MAP-002 (the RFC-first work this may land within)

## RFCs

- **RFC-037** — the RFC-first fix for this problem (authored 2026-07-02). Implements ADR-089/090 in two phases; its `stories:` are STORY-MAP-002's A3 tooling stories (020/021/022/024/025). This is the RFC we should have created *before* decomposing — dogfood gap closed.

## Related

- **ADR-089** (every RFC has ≥1 story) + **ADR-090** (story-map/story drift-invalidated oversight) — the authorities, both confirmed 2026-07-02.
- **STORY-MAP-002** / **RFC-005** — the RFC-first vehicle this may land within as new stories (per the ADRs' "consider hanging off" note); the A3 ratify/create/add/reuse stories on the map are the natural home. **STORY-MAP-002 is also the hand-authored exemplar** — the golden reference for what a good, ratified USM + its INVEST stories look like (see the Investigation Task above).
- Hang-off pre-filter (skipped subagent, >5 candidates) surfaced the RFC-first cluster for review-time consolidation: **P399** (author full RFC not skeleton), **P314** (I13 gate rework), **P310** (RFCs carry independent decisions), **P315**, **P312**. A reviewer should decide whether Phase 1/2 fold into RFC-005's implementation or that cluster rather than standing alone.

## Fix Released

**Implementation complete 2026-07-03 via RFC-037 (all 5 stories done + ratified); release queued via `.changeset/` (publishes on the next release drain).**

Phase 1 (ADR-089): commits `3e3300a3` (has-stories accept gate + predicate), `d2eb97d5` (traversal fallback removal), `af49f7e6` (framing + legacy back-fill decision).
Phase 2 (ADR-090): the ratified-stories reference gate, the unratified detector, the lazy-fingerprint drift-invalidation (substance-only, refined 2026-07-03), the born-`unconfirmed` markers + ratify UX across capture/manage-story(-map), and the work-problems drain wiring.

~~Awaiting user verification that the shipped tooling behaves as intended, then → Closed.~~ **Verification FAILED 2026-07-05 — see below.** Legacy `stories: []` back-fill (RFC-036/RFC-003) is separately tracked as P409.

## Verification Failed — reopened 2026-07-05 (user observation, corrective feedback)

The user observed the live AFK flow (P160 iter, session 2026-07-05) producing exactly the artefacts the shipped fix was supposed to make impossible:

1. **Task-based RFC.** RFC-045 (quota-pace throttle) was authored with a `## Tasks` work-breakdown (T1–T6) plus "deferred follow-on stories" as free checkbox items (D1–D3) — no story decomposition. Its only story linkage was STORY-039 buried in `## Related`. User: *"WTF is this task based RFC??? It's supposed to be story based."*
2. **Story without a story map.** STORY-039 was captured with `story-maps: []` and header prose "(none — populate at accepted transition per I8)". User-pinned invariant: **a story MUST belong to a story map** — membership is mandatory at capture, not deferrable to the accepted transition.
3. **No story maps ever created.** The tooling has never authored a story map: the only two on disk (STORY-MAP-001, STORY-MAP-002) are hand-authored. Post-fix tool-captured stories STORY-037 and STORY-038 also sit at `story-maps: []`.

(RFC-045 and STORY-039 were discarded uncommitted when the user killed iter36; the evidence is the user's 2026-07-05 screenshots and the surviving STORY-037/038 frontmatter.)

**Why the shipped fix didn't bind:** all Phase 1/2 enforcement was hung off `accepted`-transition gates (`check-rfc-has-stories` at `manage-rfc` proposed→accepted; I8 story→map membership at story accepted). The AFK flow authors RFCs and stories that sit in `proposed`/`draft` indefinitely — the gates never fire on the path that actually produces the artefacts. Capture-time surfaces (`capture-rfc`, `capture-story`) still scaffold task-based bodies and mapless stories, and nothing anywhere authors or extends a story map. Same class as P251 (invariant not enforced at the time work actually happens).

### Phase 3 — capture-time enforcement + story-map authoring (reopen scope)

**Governance landed 2026-07-07 (the ratification-gated core):** the capture-time-enforcement + no-implement-draft design was architect-reviewed (twice, on the widened scope) and **user-ratified via the draft-then-confirm flow** (AskUserQuestion, per P357 — I initially mis-marked an ADR confirmed off the pre-draft choice; user corrected, flipped to draft-then-confirm). Shipped:
- **ADR-095** (confirmed) — story-map membership (I8) + the story-content INVEST subset (Valuable + Testable) enforced at CAPTURE; refuse-and-route when no map; documented ADR-032 deviation; `draft` state redefined.
- **ADR-096** (confirmed) — a `draft` story is never implementable: remove ADR-060's `draft → in-progress` auto-transition; implementation requires `accepted`; **commit-trailer gate** (`Refs: STORY-NNN` → block if the story is not `accepted`) is the primary enforcement locus.
- **ADR-060** amended in lockstep (I8/I10 enforcement points, draft/in-progress lifecycle rows, capture-story/manage-story surfaces, `Refs:` trailer vocab). `docs/rfcs/README.md` template aligned (stories not tasks). Compendium regenerated.

**Implementation progress — ENFORCEMENT CORE COMPLETE 2026-07-07 (the P404 failure class is closed):**
- [x] `capture-story` I8 + content-subset at capture: rejects `story-maps: []` → refuse-and-route; requires real user-value + ≥1 acceptance criterion; bootstrap-exempt honored; SKILL swept consistent; bats 14/14. **DONE.**
- [x] **ADR-096 commit-trailer gate** (`itil-no-implement-draft-gate.sh`, PreToolUse:Bash, wired): blocks a commit whose `Refs: STORY-NNN` names a draft story → route to `manage-story <NNN> accepted`; capture + bootstrap-exempt exempt; fail-open; `BYPASS_NO_IMPLEMENT_DRAFT=1`; bats 7/7. **DONE.**
- [x] `manage-story`: `draft → in-progress` auto-transition removed; `accepted → in-progress` on first implementing commit (description, transition section, table, ADR ref). **DONE.**
- [x] `work-problem` dispatch: the Known-Error story traversal refuse-and-routes on a draft story (no longer a silent skip), queues under AFK; auto-transition prose corrected. **DONE.**
- [x] `capture-rfc`: template `## Tasks` → `## Stories`; `--fix-time` routes to capture-story-map + capture-story (stories on a map, not tasks) — closes the AFK path that produced the task-based RFC. **DONE.** (`docs/rfcs/README.md` already aligned.)
- [x] `itil-commit-trailer-transition-advisory.sh` realigned to `accepted → in-progress`.

**Why the core is complete:** the three surfaces the AFK flow used to produce the P404 artefacts are now all gated — a mapless story cannot be captured (capture-story refuse-and-route), a task-based RFC is not scaffolded (capture-rfc → stories-on-a-map), and a draft story cannot be implemented (the commit-trailer gate blocks it). `capture-story-map` already exists, so the refuse-and-route has a real destination. All released via `@windyroad/itil` (changeset `p404-story-lifecycle-gates`).

**Residual cleanup (does NOT block the failure-class closure):**
- [ ] Back-fill the two legacy mapless survivors **STORY-037** (P408, verifying — commit-gate cadence, JTBD-001) and **STORY-038** (P345, known-error — fix-titled lifecycle, JTBD-006). Neither fits the two existing maps (STORY-MAP-001 RFC-framework-bootstrap; STORY-MAP-002 decompose-a-fix/JTBD-008), and they are unrelated to each other — fabricating a map for two disconnected legacy stragglers is worse than leaving them. Correct handling is per-story: confirm whether each is still needed given its parent problem's progress (P408's fix shipped), then either author/assign an appropriate map via `capture-story-map` or archive the redundant straggler. Small, specific, human-judgment task.
- [ ] promptfoo eval case exercising the capture-time refuse-and-route on the AFK path (the CI eval-agents gate is the behavioural harness; bats cover the observable invariants).

**Newly-discovered lineage-integrity sub-gaps (2026-07-07 quota-pacing audit, witness RFC-046 / P443).** The 2026-07-05 quota-pace iter's surviving RFC (RFC-046) demonstrates that the shipped capture-time + accepted-transition gates still leave three lineage-integrity holes — the enforcement fires on *authoring shape* but not on *referential integrity* or *cross-artefact lifecycle consistency*:

- [ ] **Dangling story / story-map reference validation.** RFC-046 carries `stories: [STORY-039]` and `## Related` cites `STORY-MAP-003`, both of which point at files that **do not exist** on disk. No gate rejects an RFC (or story) whose frontmatter/body references a nonexistent STORY-NNN / STORY-MAP-NNN. Add a referential-integrity check (capture + accept + a reconcile-time sweep) so a lineage edge cannot name a missing artefact.
- [ ] **RFC-`proposed`-while-linked-problem-`verifying`/`Fix Released` lifecycle-inversion detection.** RFC-046 sits at `status: proposed` while its linked problem P160 is `Verification Pending` with a `## Fix Released` section — shipped code hanging off an unaccepted RFC. Nothing flags this cross-artefact lifecycle inversion. Add a detector (reconcile-time / SessionStart nudge) that surfaces "problem is verifying/released but its RFC never reached accepted".
- [ ] **Build-on-unratified-JTBD at the ship boundary.** RFC-046 anchors to JTBD-006 (status `proposed`) and, more fundamentally, to the *wrong/absent* grounding job (see P443). ADR-074's substance-confirm-before-build is enforced at ADR/decision surfaces but not at the RFC→ship boundary for the JTBD anchor. Consider extending the propose-fix / accept gate to require the anchoring JTBD be ratified (or at least surface it) before the RFC's fix ships.

These are the referential + cross-lifecycle complement to the authoring-shape gates already shipped (a mapless story can't be captured, a task-based RFC isn't scaffolded, a draft story can't be implemented — but a *dangling* reference or a *lifecycle-inverted* RFC still slips through). P443 owns the one-off repair of RFC-046's specific breakage; this ticket owns the durable gates.

Original reopen tasks (superseded/subsumed by the above where ticked):

- [x] `capture-story` / `manage-story`: story-map membership is **mandatory at capture** — `story-maps: []` is invalid. If no suitable map exists, the flow must create/extend one (delegate to `capture-story-map` / `manage-story-map`), not emit an empty list. Kill the "(populate at accepted transition per I8)" deferral prose; amend I8 (ADR-060) accordingly — architect review required.
- [~] `capture-rfc` / `manage-rfc`: RFC work-breakdown is **stories, not tasks** — stop scaffolding `## Tasks` for new RFCs; the `stories:` list is populated at authoring time with stories that live on a story map. Update `docs/rfcs/README.md` template guidance. **PARTIAL (2026-07-06)**: `docs/rfcs/README.md` `## Tasks` section reframed SUPERSEDED-by-Stories + `## Stories` lazy-empty language removed (aligned with ratified ADR-089). REMAINING (ratification-gated, folded with the I8 amendment below): the `capture-rfc`/`manage-rfc` SKILL bodies still scaffold `## Tasks` skeletons — changing them to author stories-on-a-map is coupled to the ADR-060 I8 capture-time-enforcement amendment.
- [ ] Story-map authoring wired into the fix flow: `work-problems` / `work-problem` / I13 fix-vehicle creation must produce (or extend) a story map whose stories the RFC references — STORY-MAP-002 is the golden exemplar of the output shape.
- [ ] **Enhancement (2026-07-08) — the `capture-story-map` skeleton + `manage-story-map` authoring templates + ADR-060 § Phase 2 HTML schema still scaffold the OLD crude `.backbone/.rib/.slice` vocab, so every good map is hand-crafted above the template.** Good maps ARE achievable and routinely hand-authored to a rich Patton standard — evidenced by windyroad `STORY-MAP-002` (goal-banner / activity-card / release bands / status-coloured slices) AND a recent sibling-project story map (built 2026-07-08 via `/wr-itil:manage-story-map`: `.activity` journey columns with per-step JTBD tags, `.task` cards with now/next/later badges, a persona field, ARIA labels). **The enhancement (not a blocker): promote one of these exemplars into the skill templates so agents don't re-hand-craft the visual system each time.** NB — the 2026-07-08 STORY-MAP-003 crude hand-roll was NOT caused by this gap: good maps are hand-authorable above the template (a rich sibling-project map was authored the same day); the miss was authoring discipline (copied the crudest example, STORY-MAP-001, instead of a recent good exemplar). Also fold in the Patton-modelling discipline from memory `project_story_maps_html_convention` (backbone = user activities ending at real value; walking skeleton = one operable slice per activity).
- [ ] Behavioural bats proving the capture-time gates fire on the AFK path (not just the accepted transition): a `capture-story` without a resolvable map is rejected; a new RFC with a `## Tasks` body / empty `stories:` is rejected at authoring.
- [ ] Back-fill/repair the mapless survivors: STORY-037, STORY-038 (assign to a map or fold into one).
