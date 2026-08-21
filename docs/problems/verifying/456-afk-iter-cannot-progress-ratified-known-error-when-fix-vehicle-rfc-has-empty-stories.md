# Problem 456: AFK iter cannot progress a ratified Known Error when the fix-vehicle RFC has empty stories

**Status**: Verification Pending
**Reported**: 2026-07-15
**Priority**: 6 (Medium) — Impact: 2 (Minor — iter degrades to capture-and-hold; work preserved but implementation throughput lost) × Likelihood: 3 (Possible — fires on every AFK iter whose selected ticket's fix vehicle carries `stories: []`; 7 under-scoped skeleton RFCs + legacy empty-stories RFCs currently on disk) — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — design decision + bounded SKILL edits (work-problems selection classifier and/or drain-skill pre-ratification path) — cf. P409 (M)
**WSJF**: 6 — (6 × 2.0) / 2 (2026-07-26 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; multiplier 1.0 → 2.0)
**JTBD**: JTBD-006
**Persona**: developer

## Description

AFK work-problems iteration cannot progress a substance-ratified Known Error whose fix-vehicle RFC carries stories: [] — the ADR-089 story back-fill requires ADR-090 ratification and the ADR-096 accepted gate, both interactive-only, so the iter degrades to capture-story-infrastructure-and-hold. Witnessed 2026-07-15 P376 Gap 2 iteration: direction ratified 2026-07-04, ADR-074 gate satisfied, yet the SKILL rework could not land; the iter spent its budget on STORY-MAP-004 + STORY-045 captures plus three architect reviews and queued the implementation for the next interactive drain. Every future AFK iter selecting a ticket whose vehicle has empty stories hits the same wall. Candidate fix directions: work-problems Step 3 selection could down-rank or classify-skip tickets whose fix vehicle needs story ratification; or the interactive drain could pre-ratify story scaffolds; or ADR-090/096 could gain a bounded AFK carve-out for stories that decompose already-ratified substance (framework-mediated per ADR-060 I13).

## Symptoms

- 2026-07-15 P376 Gap 2 iter: three architect reviews (ISSUES FOUND ×2 → PASS on the held plan), STORY-MAP-004 + STORY-045 captured born-unconfirmed, implementation queued to `outstanding_questions`; the targeted SKILL rework did not land despite the ADR-074 substance gate being satisfied.
- 2026-07-26 P430 iter (second witness, and a stronger one — the ticket had NO fix vehicle at all, so the wall is not specific to a pre-existing `stories: []` RFC): the fix is a three-line env-var guard in one hook plus one SKILL export line, effort S, approach fully covered by four existing ADR precedents. It still could not land. The iter spent its budget on three architect reviews, two style-guide reviews, two voice-tone reviews, one accessibility review, and the authoring of RFC-050 + STORY-MAP-005 + STORY-047 — then held, because ADR-095 line 45 and ADR-096 lines 19/25/44 place ADR-090 human ratification at the `accepted` gate and ratification has no AFK path. Note the ratio: the governance vehicle for a 3-line fix is three new artefacts across three tiers. The architect explicitly refuted the "accept mechanically, ratify later" reading (`manage-story` SKILL.md line 179's "orthogonal to the `status:` lifecycle" describes the marker's *mechanism*, not an exemption from the gate) — so the mechanical loophole that would let an iter proceed is closed by decision even though it is open in code (see the sibling enforcement-hole ticket).

- 2026-07-26 P450 iter (third witness, and a **distinct sub-shape** the ratified direction below does not cover). In witnesses 1 and 2 the story *could* have been authored and it was the `accepted` gate that blocked. Here the story **cannot be authored at all**: the architect review established that the fix's approach-choice — whether durable verification evidence lives in the rendered problems index or in the ticket body — is not covered by any existing ADR, so per ADR-073's Confirmation it needs a newly ratified ADR before implementation. That choice determines the story's acceptance criteria almost entirely (one option writes a markdown cell; another adds a problem-ticket data-model section plus render changes across two skills), so any criteria authored now would be either placeholder (breaching ADR-095's real-user-value-and-≥1-real-criterion floor) or derived from an unratified pick (breaching ADR-074 / the P315 build-on-unratified failure). The iter authored RFC-055 with `stories: []` deliberately held at `proposed` and queued the storage decision. **Why this matters for the ratified direction below**: the selector-skip classifier keys off "fix-vehicle RFC exists with empty/unratified `stories:`", but at selection time P450 had *no fix vehicle at all* — the blocking decision was not discovered until the architect review mid-iter. A selection-time classifier cannot see this class; the block is only visible after diagnosis. Whatever ships for the ratified direction needs a mid-iter arm as well as a selection-time one, or this sub-shape passes the filter and hits the wall anyway.

## Workaround

The iter captures the story infrastructure (map + story, born `human-oversight: unconfirmed` per ADR-090), queues ratify → accept → wire → implement for the next interactive drain, and reports partial-progress. Work is preserved, not lost — but the fix always costs one extra interactive round-trip.

## Impact Assessment

- **Who is affected**: the developer running `/wr-itil:work-problems` AFK loops (JTBD-006)
- **Frequency**: every AFK iter whose selected ticket's fix vehicle RFC carries `stories: []` (7 under-scoped skeleton RFCs on disk as of 2026-07-15, plus legacy empty-stories RFCs per P409)
- **Severity**: Medium — throughput loss + queued-decision accumulation, no data loss
- **Analytics**: `wr-retrospective-check-autocreate-rfc-scope` TOTAL line (proposed_skeletons=8 under_scoped=7 on 2026-07-15)

## Root Cause Analysis

ADR-089 (every RFC has ≥1 story) + ADR-095 (story-map membership at capture) + ADR-090 (RFC may reference only ratified stories) + ADR-096 (no implement while draft; accepted gate is where ratification fires) compose into an interactive-only path from "ratified fix direction" to "implementable story". None carries an AFK carve-out, so the ADR-060 I13 framework-mediated story decomposition of already-ratified substance still cannot reach `accepted` inside an AFK iter.

### Investigation Tasks

- [ ] Investigate root cause
- [ ] Create reproduction test
- [ ] Decide the fix direction (selection-time classifier vs drain-time pre-ratification vs bounded ADR-090/096 AFK carve-out) — category-1 direction-setting, needs the user

## Ratified Direction - 2026-07-15 interactive loop surface

User picked fix direction **(a) selector-skip, ratify-at-ALL_DONE** via AskUserQuestion at the /wr-itil:work-problems mid-loop halt surface (P147 killed-iter halt, 2026-07-15 ~23:00 AEST): the work-problems selector classifies RFC-bound-without-ratified-story tickets as non-dispatchable (objective marker: fix-vehicle RFC exists with empty/unratified `stories:`), skips them without dispatching, and the accumulated story-ratification asks batch at the Step 2.4 loop-end gate ("skip them and ratify at all done"). Options (b) pre-ratify-at-drain and (c) bounded AFK carve-out were presented and not chosen. Implementation rides the normal RFC/story flow; the direction applies immediately as orchestrator conduct.

## Ratified Direction - 2026-07-26 (SUPERSEDES the 2026-07-15 block above)

The maintainer ratified option **(c) bounded AFK carve-out** verbatim in-session on 2026-07-26: *"the loop may accept-and-implement a story that only decomposes already-ratified substance, without a fresh human ratification."*

The 2026-07-15 block is left verbatim above as audit trail; it is not edited. The two are successive pins on one open question, and they **compose rather than conflict** — skip what is ineligible, accept what qualifies. Selector-skip is NOT cancelled. The third witness below (P450) remains a sub-shape the carve-out deliberately does not cover: its blocking decision is undiscoverable at selection time and it introduces new substance, so it fails the carve-out's condition (b) and stays held.

Recorded as **ADR-101** (`docs/decisions/101-afk-accept-carve-out-for-pure-decomposition-stories.proposed.md`), amending ADR-060 / ADR-090 / ADR-095 / ADR-096. The carve-out is opt-in per project and per story, and fires only when every decision, job, persona and map the story traces to is already human-confirmed AND each of its acceptance criteria names the confirmed clause it decomposes.

Machinery landed 2026-07-26 (see § Fix vehicle). The sibling defect P465 — the same gate being unenforced in code — is fixed in the same slice and unconditionally: an implementing commit against an unratified story is now blocked for every adopter, which it never was before.

## Open items - owed to the maintainer (drain these when working this ticket)

Tracked here rather than only in `outstanding_questions` because that queue is truncated once surfaced, so a queue entry alone would evaporate (the named-re-entry-is-not-cadence failure, P375). `/wr-itil:work-problems` drains this ticket automatically, which is the self-firing trigger.

- [ ] **P357 post-draft brief owed on ADR-101.** The maintainer's 2026-07-26 quote pins the POLICY, and the policy is not in doubt. What is unconfirmed is whether the drafted ADR records it without semantic drift — the two-condition conjunction, the opt-in split, the story-map drift boundary, the marker encoding, and the supersession recorded above. The maintainer directed the ADR be born `confirmed`; that write was refused by the P348 evidence-marker gate, which requires a same-session `AskUserQuestion` substance-confirm event that a non-interactive session cannot produce. Per the gate's own AFK directive and CLAUDE.md's P357 fallback it is born `unconfirmed`. `wr-architect:agent` independently dissented from born-confirmed on the same grounds; the dissent is recorded in the ADR. Brief the maintainer on what the ADR actually says, then confirm or amend.
- [ ] **Confirm whether this repo opts in.** The carve-out ships default-OFF and requires `.claude/itil.config.json` to set `afk_accept_pure_decomposition: true`. An earlier pass of this iteration wrote that file itself; both `wr-jtbd:agent` and `wr-architect:agent` flagged it, because the shipped README promises "Nothing ever writes this file for you" and ADR-101 makes the same thing an invariant — a machine-written opt-in converts opt-in into opt-out-by-stealth. The file and its pre-authorisation marker were deleted, and the path is now gitignored. Whether this repo turns the carve-out on is the maintainer's call, not the loop's.
- [ ] **STORY-054 deferred.** The carve-out cannot bootstrap itself: until ADR-101 is confirmed, a story implementing it fails the carve-out's own condition (a). So no story ships with the machinery — the fix vehicle RFC lands `proposed` with no `stories:` entry (a reserved ID would be a fabricated trace that `check-rfc-stories-ratified` resolves as missing). Once ADR-101 is confirmed, author STORY-054, add its STORY-MAP-002 card and its JTBD-006 reverse-trace row, and self-accept it under the carve-out — the first genuine exercise of the rule, and the evidence that it works end to end.
- [ ] **Re-ratify JTBD-002 / JTBD-006 / JTBD-008 in the same drain.** All three had a Desired Outcome materially rewritten by ADR-101's lockstep, which under ADR-068 clears their oversight marker. Each now carries an `oversight-downgraded` entry naming what changed; the `confirmed` marker is held pending re-ratification. They derive from the same substance as the ADR-101 brief, so they should re-ratify in the same pass rather than as four separate asks.
- [ ] **ADR-089 wording correction** rides the same brief: its escape hatch names a `draft` RFC, but the RFC lifecycle has no `draft` state and `proposed` is the de facto occupant. Retarget the state name while keeping the "before the fix is scoped" qualifier and the accepted-gate enforcement in the same sentence — without the qualifier it would read as a general licence and hollow out the one-story floor.

## Fix vehicle

Machinery landed 2026-07-26 under the maintainer's direct one-time authorisation for that iteration (NOT under the carve-out — see the bootstrap note above):

- `check-afk-accept-eligible.sh` — the two-condition eligibility predicate, opt-in and fail-closed.
- `itil-no-implement-draft-gate.sh` — the unconditional ADR-090 ratification check (the P465 fix) plus story-local carve-out re-assertion.
- `story-oversight.sh` — the card-excluding map hash that makes the carve-out satisfiable at all, since ADR-095 compels every new story to edit its map.
- `mark-story-oversight-confirmed.sh --pure-decomposition`, the `--with-afk-accepted` post-hoc drain listing, `manage-story` I12, and the adopter-facing config + README surfaces.

## Fix Released

Released in `@windyroad/itil@0.60.0` on 2026-07-29, via changeset `afk-accept-pure-decomposition.md`.

Awaiting user verification that the fix behaves as intended in the installed package.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P409 (back-fill legacy RFCs still carrying empty `stories: []` — shrinks the trigger population), P399 (ADR-073 auto-create emits skeleton RFCs — grows the trigger population), P376 (the witnessing iteration)

## Related

(captured via /wr-itil:capture-problem during the 2026-07-15 P376 AFK iteration retro; expand at next investigation)

- Hang-off pre-filter short-circuited at capture: 130 candidate tickets shared ≥1 signal (ADR-060/074/089/090/096 citations are ubiquitous) — over the 5-candidate cap, so the `wr-itil:hang-off-check` dispatch was skipped per the capture-problem Step 2b cap rule. Strongest absorb candidates for review-time re-evaluation: P409 (back-fill legacy empty-stories RFCs — adjacent data-hygiene concern, but this ticket is about the AFK capability boundary, not the legacy corpus), P399 (skeleton-RFC authoring).
- STORY-MAP-004 / STORY-045 (`docs/story-maps/draft/`, `docs/stories/draft/`) — the capture-and-hold artefacts from the witnessing iteration.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-058 | proposed | The AFK-accept carve-out, and the story-ratification check that was never implemented |
