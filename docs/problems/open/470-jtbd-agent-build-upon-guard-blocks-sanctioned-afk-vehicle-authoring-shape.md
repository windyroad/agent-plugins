# Problem 470: The JTBD reviewer's build-upon guard blocks the sanctioned AFK vehicle-authoring shape and prescribes a remedy with no AFK path

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 12 (High) — Impact: 4 (Significant — a shipped agent surface degrades the adopter's AFK workflow; its prescription, followed literally, ends an iteration with no fix vehicle) × Likelihood: 3 (Possible — it fired on the P439 iteration and withdrew when challenged, so it is not deterministic, but nothing in the agent prevents a recurrence) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — teach `packages/jtbd/agents/agent.md` the same-drain carve-out plus a behavioural eval asserting both directions; cf. P438's same-day M for a comparable agent-surface rule change
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

When an AFK iteration authors a fix vehicle — an RFC and a story that cite a job born
`human-oversight: unconfirmed` — `wr-jtbd:agent` fires `[Unratified Dependency]` per ADR-068
item 7 and prescribes: ratify the job first, then land the dependents.

That prescription has no AFK path. Ratification runs through
`/wr-jtbd:confirm-jobs-and-personas`, which requires `AskUserQuestion`, which an autonomous
iteration does not have. Followed literally, the iteration ends with the problem still Open and
no vehicle authored.

It is also wrong on the framework's own terms, and the framework says so in three places the
agent does not consult:

- `packages/itil/skills/work-problems/SKILL.md` line 382 — *"The drain is NOT a halt —
  `unconfirmed` markers are explicit-by-design AFK signals (the iter wrote them KNOWING the user
  would need to confirm), and the drain is the documented path."*
- `packages/itil/skills/capture-story/SKILL.md` line 252 — *"born-unconfirmed is the
  load-bearing default."*
- ADR-090 is the framework's own calibrated answer to this exact question: when it wanted to
  enforce build-upon at this tier it wrote a narrow reference gate (an RFC may not list an
  unratified story in `stories:`, enforced by `wr-itil-check-rfc-stories-ratified`) rather than
  barring authoring. It bars *referencing*, not *authoring*.

On the P439 iteration (2026-07-26) the agent withdrew the block after being shown these, and
found the work-problems line itself — but only on the third spawn. The first pass ruled the
anchor; the second fired the guard and prescribed the AFK-impossible remedy; the third withdrew
it. Two of those three spawns bought nothing.

The operative test the agent should apply, and currently has no knowledge of: an artefact is
riding the same drain, not building upon the job, when it (a) is born
`human-oversight: unconfirmed`, (b) ratifies at the same drain event as the cited job, and
(c) ships no implementation. ADR-068's harm model — inherited from ADR-074 and witnessed at
P315 — is unratified substance leaking into **live, already-ratified surfaces** or shipped
implementation. Co-authored artefacts quarantined in the same drain queue are not that shape.

## Symptoms

- `wr-jtbd:agent` returns `ISSUES FOUND` with `[Unratified Dependency]` on an RFC or story whose
  only unratified citation is a job authored in the same commit.
- The prescribed remedy names `/wr-jtbd:confirm-jobs-and-personas`, unreachable under AFK.
- Two or more jtbd spawns per vehicle-authoring iteration, where one should do.
- The gate marker stays unwritten across the wasted spawns, so the writes stay blocked.

## Second witness (P436 AFK iter, 2026-09-19) — the over-reach is factual, not just procedural

Same agent, same AFK vehicle-authoring path, new failure shape: this time the reviewer asserted
a **governance-mechanics fact** that is outside its domain and wrong on the framework's own
terms, then prescribed the same AFK-impossible remedy.

Reviewing a plan to draw release row RFC-096 plus one story card on STORY-MAP-004 (a map
carrying `human-oversight: confirmed`), `wr-jtbd:agent` returned:

> "Item 2 adds a release row and a story card — a substance change that invalidates that marker.
> Under AFK the map must drop to `unconfirmed` with the post-change ratification queued. Landing
> item 2 while leaving `confirmed` in place would be a hollow marker."

`wr-architect:agent`, reviewing the same plan in the same turn, said the opposite and cited
ADR-103: drawing a release row and adding a story to a row are both outside the map's drift
basis, so the `oversight-hash` does not move and the map stays ratified.

Settled empirically rather than by picking a reviewer. The hash was captured before and after
the two `story-map-edit.mjs` operations and is byte-identical
(`e309468b99c8eaa55873df0630180f19b23d9efd84f6f1c7d4e87a6adce71cd7`). The architect was right;
the JTBD reviewer's claim was false. The briefing already records this — the Critical Points
roll-up states "adding it to the map no longer drifts the map's fingerprint" — so the agent
contradicted a briefed, script-verifiable fact.

Had the prescription been followed, a correctly ratified map would have been downgraded to
`unconfirmed` for no reason, manufacturing exactly the ratification debt the reviewer was
warning about, and — since ratification has no AFK path — stranding every other story on that
map behind a needless re-confirm.

Widens the fix from "teach the agent the same-drain carve-out" to also bounding its authority:
the reviewer should not issue marker-lifecycle verdicts at all. Whether a given edit moves a
map's fingerprint is determined by the shipped renderer, not by a JTBD reviewer's reading, and
the cheap check (read the hash, apply the edit, read it again) is available to any caller.

## Workaround

Put the carve-out in the first jtbd prompt: cite work-problems SKILL.md line 382, capture-story
SKILL.md line 252, and ADR-090's narrow `stories:` reference gate, and state the (a)/(b)/(c)
test explicitly. The agent then passes on the first spawn. Recorded in
`docs/briefing/afk-ratification-hold.md`.

## Impact Assessment

- **Who is affected**: the plugin-developer running `/wr-itil:work-problems` AFK, and any
  adopter whose loop authors fix vehicles — which, per ADR-071 / ADR-089 / ADR-095, is every
  fix-implementation ticket.
- **Frequency**: every AFK iteration that authors a vehicle citing a newly-authored job. The
  JTBD gate demands a new grounding job whenever the story's acceptance criteria map to no
  documented outcome (witnessed on P438 and P439), so the two co-occur by construction.
- **Severity**: High — the wasted spawns are the visible cost; the real exposure is an iteration
  that takes the prescription at face value and halts with nothing authored.
- **Analytics**: N/A.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm where the guard is expressed — `packages/jtbd/agents/agent.md` prose, or inherited
  from ADR-068 item 7's wording — and whether the fix belongs on the agent, the ADR, or both.
- [ ] Decide whether the (a)/(b)/(c) same-drain test is stated normatively (an ADR-068
  amendment) or only taught to the agent. ADR-090's existing reference gate is evidence the
  normative answer is already implicit; making it explicit is the smaller change.
- [ ] Behavioural eval per ADR-052 asserting both directions: a born-unconfirmed artefact citing
  a born-unconfirmed job in the same commit passes; unratified substance entering a live
  ratified surface or shipped implementation still fires the guard.
- [ ] Check whether `wr-architect:agent` carries the symmetric gap for ADR-074.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P456 (AFK iter cannot progress a ratified Known Error when the fix
  vehicle's `stories:` is empty — adjacent AFK-hold friction), P465 (the story `accepted` gate
  does not enforce ADR-090 ratification — the inverse failure, where the guard is too weak
  rather than too strong).


### Witness 2026-09-19 (P290 iter) — the guard also blocks an annotation-only edit that ADDS ratified citations

A second shape, from a retro on an unattended P290 iteration. The proposed edit was to append
`# @jtbd JTBD-202` and `# @jtbd JTBD-101` — both ratified — to the annotation block of
`packages/jtbd/agents/eval/promptfooconfig.yaml`, so that a job-to-coverage trace carried by a
structural bats file being retired would survive on its behavioural successor. The reviewer itself
had asked for that migration on its prior pass.

It then blocked the edit it had just prescribed. The reasoning: the annotation block already cites
JTBD-001, JTBD-002 and JTBD-011, all unratified, so appending to it "re-authors that citation
manifest" and counts as an explicit build-upon. The prescribed remedy was again
`/wr-jtbd:confirm-jobs-and-personas`, again with no AFK path.

Two things make this shape worse than the one above:

- **The edit adds only ratified citations and creates no new assertion.** Nothing is built on the
  unratified jobs; the unratified lines are pre-existing and untouched. Treating an append to a
  comment block as re-authoring every line in it is the inverse-P078 over-fire the agent's own
  guard prose warns against.
- **One of the three jobs cannot be ratified at all.** That config's first fixture hard-codes
  JTBD-011 as its unratified subject, so ratifying JTBD-011 turns the merge-blocking `eval-agents`
  fixture red. A user-facing job is held unconfirmed by test infrastructure, and the drain the
  guard prescribes would break CI if followed in full. The scoped drain (JTBD-001 + JTBD-002 only)
  is recorded on P290.

Cost: the iteration narrowed its scope three times across four reviewer spawns, ending with two
retirements instead of four. The two deferred retirements are recorded on P290 with this gate named
as their blocker. Note the carve-out this ticket already proposes would not have cleared this shape
— the same-drain carve-out is about artefacts the iter itself authors born-unconfirmed, whereas
here the unratified citations were pre-existing and the edit was additive. Whatever rule lands
needs to distinguish *adding a line to a block* from *depending on every line already in it*.

## Related

- Captured via `/wr-itil:capture-problem` from the P439 iteration retro (2026-07-26).
- **Hang-off pre-filter (Step 2b)**: 12 candidates shared a signal (ADR-068 / ADR-090 /
  `/wr-jtbd:confirm-jobs-and-personas`), exceeding the 5-candidate cap, so the fresh-context
  `wr-itil:hang-off-check` dispatch was skipped per the SKILL's latency short-circuit. The
  candidate list is recorded here for review-time re-evaluation: P290, P297, P395, P401, P411,
  P443, P444, P457, P465, P313, P350, P351. Manually screened, the two nearest are P401
  (capture-problem shoehorns or discards persona/JTBD instead of interviewing — a different
  surface: capture-time derivation, not the reviewer's build-upon guard) and P465 (the story
  `accepted` gate under-enforces ADR-090 — the inverse polarity). Neither absorbs this scope.
- **ADR-068** (JTBD/persona human-oversight marker and confirm drain) — item 7 is the guard;
  the fix likely amends its wording or the agent's reading of it.
- **ADR-090** — the framework's calibrated precedent: a narrow reference gate, not an
  authoring bar.
- **ADR-074** / **P315** — the harm model the guard inherits, and the witness that defines its
  real shape (unratified substance in live surfaces, not co-authored drafts).
- `docs/briefing/afk-ratification-hold.md` — carries the workaround.
- **Detector aside from the same retro**: ADR-068 Confirmation item 6 documents
  `wr-jtbd-is-job-or-persona-unconfirmed`'s exit codes as "marker-present→0, marker-absent→1,
  superseded→0" — all three inverted versus the script's own header and its measured behaviour
  (`0` = unconfirmed / guard fires; `1` = confirmed or superseded). The script is right, the ADR
  prose is wrong, and it would lead a future implementer to invert the guard. Belongs to the
  architect surface at `docs/decisions/068-jtbd-persona-human-oversight-marker-and-confirm-drain.proposed.md`;
  recorded here so it is not lost.
