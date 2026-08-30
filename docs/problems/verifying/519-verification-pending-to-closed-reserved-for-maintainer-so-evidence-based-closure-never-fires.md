# Problem 519: The Verification Pending → Closed transition is reserved for the maintainer, so evidence-based closure never fires and the verification queue grows without bound

**Status**: Verification Pending
**Reported**: 2026-08-24
**Priority**: 20 (Very High) — Impact: 4 (Significant — a first-class lifecycle stage has no agent-driven exit path at all; 153 tickets are stranded and the governance audit trail systematically misrepresents which fixes are still unverified) × Likelihood: 5 (Almost certain — continuous; the reservation fires on every verifying ticket on every pass, 153/153 observed) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a. Eleven prose loci across two shipped packages plus one small predicate script, its ADR-049 shim, behavioural coverage, and a JTBD narrowing. No data-model change, no new ADR (see Root Cause Analysis), no migration. cf. P135 Phase 2 (same class of multi-locus ask-discipline sweep, landed in one session).
**WSJF**: 20 — (20 × 2.0) / 2 (Known Error multiplier 2.0 applied 2026-08-24 at the transition; Effort re-rated at the transition per P047 and held at M — the architect and JTBD reviews added the external-reporter carve-out, the gate-(0) enumeration fix and the release-row vehicle, but removed nothing, and it all landed in one session)
**JTBD**: JTBD-006, JTBD-001
**Persona**: developer

## Description

Shipped SKILL prose reserves the Verification Pending → Closed transition for the human maintainer. Because of that reservation, an agent holding concrete in-session or recorded evidence that satisfies a verifying ticket's own stated close criterion still declines to close it. The queue therefore has no agent-driven exit path, and it only ever grows.

The user raised this as an emphatic **repeat** correction on 2026-08-24, after the assistant found in-session evidence bearing on a verifying ticket and then declined to act on it:

> "NO! IT should not. I've told you this before. If you have evidence of a problem being closed then you close it. This explains why we have so many unclosed problems."

The reservation is not a live design choice — it is residue. Two shipped surfaces already implement the opposite, and one of them says so in as many words:

- `packages/itil/skills/review-problems/SKILL.md:116` (Bucket 1) — *"close it mechanically WITHOUT `AskUserQuestion` … A per-candidate ask here is lazy deferral."*
- Same file, `:124` — *"This **supersedes** the prior blanket 'do NOT auto-close verifying tickets — only the user can make that call', which pre-dated the P186 evidence-first cell."*
- `packages/retrospective/skills/run-retro/SKILL.md:428` (Step 4a sub-step 5) — *"Close-on-evidence (silent agent action per P135 / ADR-044) … WITHOUT firing `AskUserQuestion`"*, and it fires in AFK too.

So the corpus contradicts itself: `review-problems` and `run-retro` close on evidence, while `transition-problem`, `transition-problems`, `manage-problem` and `work-problems` refuse to. The refusing surfaces are the ones the AFK loop and every explicit close request actually route through, so the refusal wins in practice.

## Symptoms

- `docs/problems/verifying/` holds **153** tickets.
- The 2026-08-24 review pass reported every one of the 153 Verification Queue rows in `docs/problems/README.md` reads `Likely verified? = no — not observed`. Census: 153 rows, exactly **1** carries `yes — observed`.
- An agent that has just exercised a fix and can cite the exercise declines to close the corresponding ticket, and cites shipped prose as the reason.
- `/wr-itil:work-problems` classifies **every** verifying ticket non-dispatchable by recorded marker, so the AFK loop can never reach one — the queue is unreachable, not merely un-actioned.

## Workaround

Close by hand, or route the close through `/wr-itil:review-problems` Step 4 Bucket 1 or `/wr-retrospective:run-retro` Step 4a — the two surfaces that already permit evidence-based closure. Neither is reachable from the transition skills or the AFK loop's own classifier, so this is a detour, not a fix.

## Impact Assessment

- **Who is affected**: plugin-developer persona (the maintainer running the lifecycle and the AFK loop); secondarily every adopter of `@windyroad/itil` inheriting the same reservation.
- **Frequency**: continuous — every verifying ticket, every pass.
- **Severity**: Significant. The queue is the record of what is unverified. When nothing can leave it, the record stops meaning anything, and the real signal (a fix that genuinely regressed) is buried under 152 rows that are simply waiting for permission.
- **Analytics**: 153 verifying tickets; 1/153 evidence cells populated; 11 reservation loci across 2 packages.

## Root Cause Analysis

**Confirmed 2026-08-24** by `wr-architect:agent` review (read-only, pre-edit mode) and `wr-itil:hang-off-check` arbitration. Both verdicts are recorded below in full because they change the shape of the fix.

### Finding 1 — this is stale prose, not a ratified constraint being reversed

The reservation appears nowhere in ADR-022's **Decision Outcome**, whose literal text is *"Verification Pending status with `.verifying.md` suffix and WSJF multiplier 0"*. It appears only in ADR-022's Decision Drivers (`:44`) and Consequences (`:131`), both as restatements of a JTBD-006 persona constraint. Driver and Consequence prose is rationale, not the decided thing.

The approach-choice is already covered by ratified decisions: **ADR-044** (framework-resolution boundary — evidence-backed close is category 4, silent framework action), **ADR-026** (agent output grounding — cite, persist, state uncertainty), **ADR-013 Rule 5** (policy-authorised silent proceed), and **ADR-079** (evidence-based relevance-close pass — direct precedent for agent-authorised closure on the open/known-error side of the same lifecycle). All four carry `human-oversight: confirmed`.

Per ADR-073's Confirmation (*"A fix whose approach-choice is not covered by existing ADRs has a new ratified ADR before implementation"*), the covering set is present, so **no new ADR and no ADR amendment is required**. Amending ADR-022 is in fact prohibited: it carries `human-oversight: confirmed` and **ADR-116** makes ratified decisions changeable only by supersession.

### Finding 2 — the three loci first identified were a third of the sweep

The reservation is stated **eleven** times across two packages. Fixing only the three obvious ones leaves the user's symptom fully in place, because the load-bearing locus is not a close precondition at all — it is the AFK loop's dispatchability classifier.

**Must fix — the change does not work without these:**

| # | Locus | Text |
|---|---|---|
| 1 | `packages/itil/skills/transition-problem/SKILL.md:122` | *"The user has explicitly confirmed the fix works in production (this skill never auto-closes on inference …)"* |
| 2 | `packages/itil/skills/transition-problems/SKILL.md:109` | *"AFK callers … MUST supply the close pair via prior user authorisation …; this skill never auto-closes on inference."* |
| 3 | `packages/itil/skills/work-problems/SKILL.md:932` | *"V→C remains the maintainer's surface (persona constraint per JTBD-006) …"* |
| 4 | `packages/itil/skills/manage-problem/SKILL.md:838-840` | *"**Verification Pending → Closed** (user confirms): Only the user can make this call."* — the ADR-010 P093 copy-not-move sibling of #1; editing #1 without #4 re-opens the drift class. |
| 5 | `packages/itil/skills/manage-problem/SKILL.md:46, 48, 49` | *"closed ONLY after the user verifies the fix in production"*; *"**Never assume the fix works — always wait for explicit user confirmation before closing.**"* — the strongest blanket reservation in the corpus, in the most-loaded SKILL. |
| 6 | `packages/itil/skills/manage-problem/SKILL.md:61` | Lifecycle-table Closed row — needs the evidence arm alongside the existing ADR-079 arm. |
| 7 | `packages/retrospective/skills/run-retro/SKILL.md:406` | *"the close decision remains the user's"* — directly contradicts sub-step 5 twenty-two lines below it. Pre-P135 residue. |
| 8 | `packages/itil/skills/work-problems/SKILL.md:367` | Gate (0) non-dispatchable classifier: *"it is `verifying` / carries `## Fix Released` awaiting user verification"*. **This is the structural reason the queue has no agent-driven exit path.** Fix #3 and leave this, and the 153 rows still never move. |
| 9 | `packages/itil/skills/work-problems/SKILL.md:351` | Stop-condition #2 — evidence-bearing verifyings are no longer interactive-only, so they can no longer license `ALL_DONE`. |
| 10 | `packages/itil/skills/work-problems/SKILL.md:524` | Step 4 classifier table: `.verifying.md` → *"**Skip** — awaiting user verification"*. |
| 11 | `packages/itil/skills/transition-problems/SKILL.md:38` | Argument vocabulary: *"`close` — Verification Pending → Closed (user has confirmed the fix works in production)"*. |

**Should fix — stale/contradictory, cheap, leaves the corpus coherent:** `review-problems/SKILL.md:24` (stale, mislabels the transition as K→C); `run-retro/SKILL.md:466`; `work-problems/SKILL.md:847, 1152` (worked-example output showing *"Awaiting user verification"* as a terminal skip reason — cosmetic, but it is the example agents pattern-match against).

**Deliberately left alone:** `work-problems/SKILL.md:343` (the WSJF-ranking exclusion — ADR-022's multiplier-0 ranking exclusion is untouched by this change; the drain is its own pass, not dev-work ranking). `manage-problem/SKILL.md:997`, `review-problems/SKILL.md:85`, `list-problems/SKILL.md:59` (these define the `yes — observed:` evidence-cell vocabulary — they are the durable evidence surface the drain consumes, not reservations). Descriptive *"awaiting user verification"* status glosses that remain accurate for a ticket with no evidence.

**Confirmed clean:** no hook and no agent under `packages/*/hooks/` or `packages/*/agents/` encodes the reservation. No gate will block the edits.

### Finding 3 — one non-shipped artefact genuinely collides, and its ratification gate is already open

`docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md` contradicts the fix at three places: `:25` Desired Outcome (*"Problems requiring my judgment (verification, …) are queued for my return, not guessed at"*), `:26`/`:27` Amendment (*"**verification is untouched** — the loop still never decides that a fix works"*), and `:38` Persona Constraint (*"Does not trust the agent to make judgment calls (verify fixes work, …)"*). Left unedited, the fix's own authority would contradict the job it cites.

The gate is already open: JTBD-006 carries `human-oversight: unconfirmed` (downgraded 2026-08-21 by the ADR-103 lockstep) and is already queued for the next `/wr-jtbd:confirm-jobs-and-personas` drain. ADR-116 governs *decisions* and does not reach an unratified job; ADR-110 forbids writing an oversight marker without a real confirm event. So the compliant move is to edit it, leave the marker `unconfirmed`, and ride the already-queued re-ratification — adding no new debt.

### Finding 4 — flipping the reservation is necessary but not sufficient

The census is its own warning: 153 rows, exactly 1 carrying `yes — observed`. The evidence cell is the durable input that agent-authorised closure consumes. Flipping the reservation alone authorises the agent to close **one ticket**. The other half is a pass that actually populates evidence cells against the standing 153, reading each ticket's `## Fix Released` section and testing it against the tree. Recorded here so a later reader does not observe "the change landed, tests passed, queue still 152" and wrongly conclude the reservation was never the cause. See the Fix Strategy's Phase 2.

**Release vehicle**: RFC-072 — release row "A fix I can prove works gets closed without me" on `docs/story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html`, carrying STORY-066. Drawn 2026-08-24 per ADR-071 / ADR-073 / ADR-119 (a fix proposal draws a release row, not a document), via `story-map-edit.mjs` + `render-story-map.mjs` so the row lives in the map's JSON island rather than only in the rendered grid — a hand-edited grid is dropped by the next render and leaves the problem reading as untraced. The map's oversight marker correctly stays `confirmed`: under ADR-103 releases and their cards are scheduling, not substance, so the hash is unchanged (`oversight_map_substance_keys` in `packages/itil/lib/story-oversight.sh` is the authority).

### Investigation Tasks

- [x] Confirm the reservation is stale rather than ratified — architect review 2026-08-24, Finding 1.
- [x] Enumerate the full locus set — architect review 2026-08-24, Finding 2 (eleven must-fix, four should-fix, six deliberately-left-alone).
- [x] Establish whether an ADR is needed — no. Covering set is ADR-044 / ADR-026 / ADR-013 Rule 5 / ADR-079, all confirmed; ADR-022 is immutable under ADR-116 and does not carry the reservation in its Decision Outcome anyway.
- [x] Hang-off arbitration against P450 and the wider backlog — PROCEED_NEW.
- [x] Amend the eleven must-fix loci + the should-fix set — done 2026-08-24, plus four the post-edit reviews caught (see below).
- [x] Narrow JTBD-006 `:22` / `:25` / `:26` / `:27` / `:38`; marker left `unconfirmed`, post-change ratification queued per P357.
- [x] Land the DO-NOT-CLOSE predicate + ADR-049 shim + behavioural coverage — `packages/itil/scripts/is-close-blocked.sh` + `packages/itil/bin/wr-itil-is-close-blocked`, 16/16 bats green, validated over the live corpus (6 of 153 verifying tickets block, 147 do not).
- [ ] Phase 2 — populate the standing queue's evidence cells (see Fix Strategy). Not in this vehicle.

## Post-edit review findings (2026-08-24) — four defects the reviews caught after the sweep landed

Recorded because three of them would have shipped a change that read correctly and did not work.

1. **The evidence vocabulary listed "a release cycle that shipped it" as qualifying evidence** — which is satisfied by every row in the queue *by construction*, since a ticket is in `verifying` precisely because a fix was released. The three-state split would have collapsed to "close everything", and it contradicted the inference clause one line below it in three of the five files. Narrowed to "a post-release invocation of the shipped artefact that behaved as the fix contracts". Caught by `wr-jtbd:agent`.
2. **The P500 external-reporter boundary was named in this ticket's own Related section and never implemented.** `transition-problem` Step 7b fires on every transition including `close`, dispatching `/wr-itil:update-upstream`, which runs `gh issue close` against a third party's issue. The K→V comment we post promises the reporter we will close *after their confirmation or a quiet period*; our own test passing is neither, and the Step 6.1 drain would have made this a bulk path over 18 inbound-reported verifying tickets. Fixed with an ADR-117-shaped carve-out: an evidence-authorised close records `closed-on-evidence`, and that marker makes the upstream leg comment-and-stop. Caught by `wr-jtbd:agent`.
3. **Gate (0)'s re-scan never enumerated `verifying/`, and routed dispatchables to Step 3.** The dispatchable-verifying arm had no input set, so the fix was inert exactly where the ticket said the structural defect lived; and had it fired, Step 3 selects only from the WSJF-ranked set, which excludes verifying — leaving a ticket with no consumer while the gate forbids `ALL_DONE`, a livelock. The glob now covers the verification queue and verifying-class dispatchables route to Step 6.1, never Step 3. Caught by `wr-architect:agent`.
4. **Two loci were half-applied** — `transition-problem/SKILL.md:21` (the argument-vocabulary twin of the plural skill's `:38`, which *was* fixed) and JTBD-006 `:22` ("skip problems needing verification" as the AFK safe default, three lines above the bullet that removes it). Both are the copy-not-move drift class Finding 2 row #4 warns about, reproduced inside the fix for it. Caught by both reviews independently.

The reviews also carried the fix from three prose loci to eleven, before any of the above.

### Third pass — three more, two of which meant the fix did not work

5. **The `closed-on-evidence` marker had no durable home, so the carve-out for finding 2 failed open.** It was to be written into the `Likely verified?` cell — but that cell lives in the README's Verification Queue table, and the close deletes that row before the upstream leg ever reads it. There was also no write locus: all three V→C blocks updated only the Status field. Net effect: `gh issue close` would still have run against a reporter's issue. Fixed by writing the basis into the ticket's own Status line — the shape the 2026-07-15 closes already used (`docs/problems/closed/186-*.md:3`) — and repointing the reader there. Caught by `wr-architect:agent`.
6. **The release row was hand-authored into the rendered grid.** The map renders from a JSON island (ADR-102 / ADR-105); the island had no `rfc-072` release and no STORY-066 task, so the next render would have dropped the row and `check-fix-rfc-trace.sh` would have read P519 as untraced — the vehicle recorded above would not have been real. Redone through `story-map-edit.mjs` + `render-story-map.mjs`. Caught by `wr-architect:agent`.
7. **The two backward pairings landed on the singular skill only** — the same copy-not-move drift as finding 4, committed a second time inside the fix for it, this time in the repair rather than the original sweep. `transition-problems` Step 2b now carries them too.

The external-comms review of the changeset independently caught that the published entry advertised `/wr-itil:transition-problem <NNN> known-error` as the undo path while the skill's reachability table rejected it — which would have made the reversibility argument licensing agent-authorised closure fiction. Both backward pairings landed here as a result; the rest of that gap stays on P512.

## Fix Strategy

### The line the prose must draw

Three states, not two:

1. **Evidence-backed → agent closes.** Concrete in-session or recorded evidence meeting the ticket's own stated close criterion. The agent closes, cites the evidence in the closure record per ADR-026, and surfaces the reversible recovery path (`/wr-itil:transition-problem <NNN> known-error`). Mechanical stage per P132 — **no `AskUserQuestion`**.
2. **No evidence → agent does not act.** *"Never auto-closes on inference"* is preserved in its true sense, and this is the half that must not be lost. Inference remains forbidden; **absence of evidence is not evidence**; the ticket stays open and queues for the user. Closing tickets nobody exercised is the opposite failure and is just as wrong.
3. **Genuine ambiguity → the user's surface.** Contested evidence, a partial fix, or an explicit DO-NOT-CLOSE regression marker. `docs/problems/verifying/151-published-skills-reference-repo-relative-script-paths.md` § *"Regression / incomplete observed 2026-07-25 — DO NOT CLOSE"* is the live instance; that shape must keep blocking closure.

This is verbatim the shipped `review-problems` Bucket 1 / 2 / 3 split. The fix propagates an existing, already-reviewed template rather than inventing a policy.

### Phase 1 — the sweep (this ticket)

Amend the eleven must-fix loci and the should-fix set to the three-state shape. Constraints:

- `/wr-itil:transition-problem` stays the sole authoritative executor of V→C per ADR-010 amended P093 — callers dispatch, never re-implement rename / Status / commit.
- `manage-problem` Step 7 and `transition-problem` Step 4 are declared siblings; both move or neither.
- The WSJF-ranking exclusion at `work-problems:343` stays — the drain is its own pass.

Ship the DO-NOT-CLOSE marker as a mechanically-checkable predicate rather than prose the next agent must happen to notice: `packages/itil/scripts/is-close-blocked.sh` plus its ADR-049 `bin/` shim, mirroring `packages/architect/scripts/is-decision-unconfirmed.sh`. The pattern must be line-anchored so a mention inside a code fence or mid-sentence is not a false positive — the ADR-079 advisory-A2 lesson.

### Phase 2 — populate the standing queue (follow-on)

An evidence pass over the 153 verifying tickets: read each `## Fix Released` section, test it against the tree, and write `yes — observed: <citation>` where the evidence holds. Without this, Phase 1 lands correctly and the queue barely moves (Finding 4). Complementary to P450, which builds the *ongoing* write path; this is the one-off backfill of the standing backlog.

### Coverage (ADR-052 / P081 — behavioural, not structural grep on SKILL prose)

Primary harness is **promptfoo** per ADR-075, since this is SKILL-prose behaviour — exactly what P081 says bats grep is bad at. Configs already exist for all four skills.

- `transition-problem` — evidenced verifying fixture + `close`, no user turn present → transitions, closure record names the evidence, no `AskUserQuestion`. Unevidenced fixture + `close` → refuses. DO-NOT-CLOSE fixture (shaped from the real P151 marker) **plus** otherwise-satisfying evidence → refuses and names the marker. `no — observed regression` cell → routes to flip-back, never closes.
- `transition-problems` — mixed batch (one evidenced, one not) closes exactly one and reports the other unclosed with its reason.
- `work-problems` — **the case that pins the user's complaint**: a backlog whose only remaining tickets are verifying rows carrying `yes — observed:` must classify them **dispatchable** in the printed gate-(0) table and must **not** emit `ALL_DONE` on stop-condition #2. Paired negative: `no — not observed` rows stay non-dispatchable and `ALL_DONE` is legitimate.
- `run-retro` — negative assertion that the summary never states the close decision belongs to the user (guards locus #7 from regressing).
- bats: the DO-NOT-CLOSE predicate gets genuine behavioural coverage — marker present → blocked; absent → not blocked; marker inside a code fence or mid-prose → **not** a false positive.
- Expected RED to repair, not delete (P081-class stale grep): `transition-problem-contract.bats`, `transition-problems-contract.bats`, `review-problems-contract.bats:209-217`.

### Changesets

`@windyroad/itil` **minor** — `work-problems` gains a capability it structurally lacked (the AFK loop can drain the verification queue). `@windyroad/retrospective` **patch** — behaviour-affecting prose at `run-retro:406`/`:466`. No changeset for `docs/`.

**Release vehicle**: .changeset/evidence-backed-closure-agent-authorised.md

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — P512 is a composes-with, see Related; it sharpens the recovery path but does not gate this fix, since `/wr-itil:transition-problem <NNN> known-error` is the documented reopen route already relied on by the shipped `review-problems` Bucket 1 and `run-retro` Step 4a closes.)
- **Composes with**: P450, P512, P504, P500, P463, P136

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-066 | STORY-066: A fix I can prove works gets closed without me | accepted |

## Fix Released

Released in `@windyroad/itil@2.1.0` and `@windyroad/retrospective@0.27.5` (merge commit `cf5cf39a0f6623eb4ccaf434e6239f2d641d0ea8`, PR #451, released 2026-08-27; version-packages commit `cb749f1f53650ae933106aaefd5f93b8ea47e1c4`).

The released update authorises evidence-backed closure across the transition and unattended backlog workflows, preserves fail-closed handling for absent or contested evidence, and adds the mechanical DO-NOT-CLOSE predicate and foreign-reporter authority boundary.

Awaiting user verification. Phase 2's separate standing-queue evidence backfill remains tracked as follow-on work and does not block verification of this release vehicle.

## Related

- **P450** (`docs/problems/known-error/450-...md`) — complementary half, not a duplicate. P450 is the missing **write path** for evidence (nothing populates the `Likely verified?` cell from subsequent-session exercises); this ticket is the missing **close authority**. The distinction is load-bearing: P450's own § *"Why the alignment argument holds"* asserts *"sub-step 5 already establishes close-on-evidence as a framework-resolved silent action"* — it is **built on the premise that close authority is settled**, which on the itil transition surface it is not. Amend that paragraph once this lands. Fix loci are disjoint (P450: `run-retro` Step 4a; this: four itil skills). P450 is additionally `Held (ADR-096)` behind an unratified storage-locus decision with no AFK path, so folding a top-priority user-directed correction into it would strand it.
- **P512** (`docs/problems/verifying/512-...md`) — composes-with, same file different defect. P512 adds missing **pairings** to `transition-problem`'s validation table (`Open → verifying`, `verifying → known-error`); this ticket changes a **guard condition on a pairing that already exists**. P512 carries the task *"Re-check Step 4a's silent-close justification once the route exists: it argues from reversibility, which was not true when written"* — landing P512 hardens the reversibility premise this fix rests on.
- **P504** (`docs/problems/open/504-...md`) — no skill surface reopens a closed ticket. This fix increases agent-initiated closes and so leans harder on the recovery route P504 says is under-served.
- **P500** — constraint, not overlap: the fix must stay **local-only**. It must not enable auto-close of a linked external reporter issue (JTBD-301 / plugin-user trust boundary).
- **P463** — opposite failure direction (a predicate closing on *insufficient* evidence). Useful as the calibration counterweight: P463 is the harm from over-firing, this is the harm from never firing.
- **P136** / 2026-07-04 — **precedent**: the `review-problems` Step 4 three-way bucket split (`yes — observed:` closes mechanically; `no — not observed` routes to the ask; `no — observed regression` never batch-closes) is a shipped, architect- and JTBD-reviewed template for exactly this amendment, including the ambiguity carve-out. This ticket does not falsify P136's audit so much as show a surface P135 Phase 2 cleared and the reservation later out-lived.
- **P078** — capture-on-correction: this ticket exists because the correction was a repeat. The class signal is *"agent cites shipped prose to decline an action the user has already directed"*.
- **ADR-116** — binding on how this is recorded: no amendment section, no `amends:` key, no marker-clearing on any confirmed ADR.
- Hang-off arbitration 2026-08-24 (`wr-itil:hang-off-check`): **PROCEED_NEW**. Per-candidate: P450 assumes the opposite premise (absorbing would put a self-contradiction in one ticket) and is held behind an unratified gate; P463 and P500 are the opposite failure direction; P507 is a different queue and mechanism; P504 is the inverse transition; P512 is a dependency not a parent; P136's live scope is enumerated cosmetic cross-refs plus six named unaudited SKILLs, all three loci sit in SKILLs already cleared, and its WSJF 2.25 plus *"NOT picked up automatically by work-problems"* marker would strand a top-priority fix.
- Architect review 2026-08-24 (`wr-architect:agent`): **ISSUES FOUND** — scope, not direction. No ADR needed; sweep extended from 3 to 11 must-fix loci; JTBD-006 edit required with its ratification gate already open; advisory that ADR-022's `reassessment-date: 2026-07-19` has passed and a future superseding ADR (never an amendment) is its ADR-116-compliant home.
