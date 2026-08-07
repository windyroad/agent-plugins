---
status: "superseded"
date: 2026-07-26
human-oversight: confirmed
oversight-date: 2026-07-27
oversight-confirmed-date: "2026-07-27 — P357 post-draft brief surfaced via AskUserQuestion this session; maintainer confirmed the draft faithfully records the 2026-07-26 ratification (two-condition whitelist, opt-in/tightening split, map-leg card exclusion, post-hoc audit marker, supersession of the 2026-07-15 selector-skip pin). Maintainer note: RFCs themselves require no human oversight (ADR-070) — condition (a) correctly proxies through the RFC's adrs: (check-afk-accept-eligible.sh:145). The born-unconfirmed history + architect dissent below are retained as audit trail."
oversight-note: "SUBSTANCE IS RATIFIED; THE DRAFT WAS BORN UNCONFIRMED AND IS NOW CONFIRMED (2026-07-27, see oversight-confirmed-date). The maintainer ratified the policy verbatim in-session on 2026-07-26: \"the loop may accept-and-implement a story that only decomposes already-ratified substance, without a fresh human ratification\", and directed this ADR be born `confirmed` with the P357 post-draft brief queued. That marker could not be written: the session is non-interactive, so the AskUserQuestion the P348 evidence-marker gate requires was unavailable, and hand-landing the marker is the hollow-marker bug the gate exists to prevent. Per CLAUDE.md's P357 AFK fallback and the gate's own directive, this is born `unconfirmed` and the post-draft brief is QUEUED for the next interactive drain. wr-architect:agent independently dissented from born-confirmed on the same grounds (see Consequences § Architect dissent). What remains outstanding is ONLY the confirmation that this draft faithfully records the ratified policy without semantic drift — not the policy itself. The owed brief is ALSO tracked as an open item on the P456 ticket body, because outstanding-questions.jsonl is truncated once surfaced, so the queue entry alone would evaporate."
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-10-26
amends: [ADR-060, ADR-090, ADR-095, ADR-096]
superseded-by: ADR-103
---

# An AFK loop may accept and implement a story that only decomposes already-ratified substance

> **Superseded by [ADR-103](103-a-release-row-is-the-rfc-and-the-map-is-the-approval-surface.proposed.md) on 2026-08-07, and its machinery removed.**
>
> This carve-out existed for one reason: ADR-095 compels a card onto the map when
> a story is captured, and under ADR-090 drift-invalidation that re-opened the
> map's ratification — so authoring a story broke the very condition the story
> then had to satisfy. The carve-out worked around it by hashing the map with
> that story's own card excluded.
>
> ADR-103 removed the cause instead. Rows and the cards in them are scheduling,
> not substance, so they sit outside the fingerprint basis entirely and adding
> one no longer drifts anything. With nothing left to exclude, the map leg was a
> no-op. ADR-103 also made the map the approval surface, so the question this
> ADR answered — may a machine accept a *story* without human ratification — no
> longer arises: stories are not separately ratified.
>
> Removed with it: `check-afk-accept-eligible.sh` and its shim,
> `oversight_content_hash_excluding_stories`, `oversight_map_leg_ok`,
> `oversight_is_pure_decomposition`, `oversight_declares_pure_decomposition`,
> `mark-story-oversight-confirmed --pure-decomposition`,
> `detect-unratified-stories-maps --with-afk-accepted`, and the
> `afk_accept_pure_decomposition` config key. No story in the corpus ever
> declared `afk-accept: pure-decomposition`, so nothing was ever accepted under
> it — the retirement is inert for adopters as well as for this repo.


## Context and Problem Statement

ADR-090 gives stories and story maps a drift-invalidated human-oversight marker. ADR-095 puts map membership and content completeness at capture. ADR-096 removes the `draft → in-progress` auto-transition, so implementation requires `accepted`, and places ADR-090 ratification at that gate. Composed, they mean: **no code can be written until a human ratifies the story.**

Ratification has no AFK path. So an autonomous `/wr-itil:work-problems` iteration cannot land any code fix at all — it can only author governance artefacts and hold. P456 records three dated witnesses (2026-07-15 P376, 2026-07-26 P430, 2026-07-26 P450); the cross-session briefing records five more. The sharpest is P430 (2026-07-26): a three-line env-var guard in one hook, effort S, approach covered by four existing ADR precedents. It still could not land. The iteration spent its budget on three architect reviews, two style-guide reviews, two voice-tone reviews, one accessibility review and three new artefacts across three tiers — then held. The governance vehicle for a three-line fix was three new artefacts.

The inverse defect is real too. **P465**: nothing in code enforces the ratification ADR-095 and ADR-096 both name. `manage-story` gates `accepted` on I7 + I8 + I10 only; `itil-no-implement-draft-gate.sh` resolves `status:` and carries no ratification check whatsoever. So ADR-096's Decision Outcome — "no malformed or unratified story can ever be implemented" — is an over-claim its own Confirmation item (b) under-specifies. The gate is held closed by decision alone, and an agent reasoning from the code rather than the decisions finds it open.

The two tickets are one gate seen from both sides: too strict to pass under AFK, too loose to hold in code.

**Maintainer ratification, 2026-07-26, verbatim:** *"the loop may accept-and-implement a story that only decomposes already-ratified substance, without a fresh human ratification."*

That supersedes P456's 2026-07-15 direction, which picked option (a) selector-skip and explicitly did not choose option (c) bounded carve-out. The two are successive pins on one open question, and they **compose** rather than conflict: skip what is ineligible, accept what qualifies. Option (a) is not cancelled. P456's third witness, P450, is a sub-shape this carve-out deliberately does not cover — its blocking decision is undiscoverable at selection time and it introduces new substance, so it fails condition (b) and stays held.

## Decision Drivers

- The AFK loop must be able to land a fix whose substance a human has already confirmed. That is JTBD-006's core outcome, and today the loop fails it structurally rather than partially.
- Nothing whose substance a human has **not** confirmed may reach implementation. That is what ADR-090 exists for, and it must get stronger here, not weaker.
- The relaxation must be establishable **positively**. "Introduces no new design choice" is a negative existential an agent cannot discharge; a novelty blacklist fails open on exactly the subtle embedded decision that matters.
- Adopters must not inherit a governance loosening they never asked for. Ratifying an ADR is artefact consent; it is not consent to a self-accepting loop (P357's rule, applied to adopters).
- The carve-out must be satisfiable in practice. ADR-095 compels every new story to add a card to its map, so a naive reading of ADR-090 makes the carve-out unsatisfiable by construction.

## Considered Options

1. **Bounded AFK-accept carve-out** (P456 option (c)) — the loop may self-accept a story that is pure decomposition of confirmed substance.
2. **Selector-skip only** (P456 option (a), pinned 2026-07-15) — the loop classifies such tickets non-dispatchable and batches the ratification asks at loop end. Preserves the gate absolutely, but the loop still lands nothing.
3. **Pre-ratify at drain** (P456 option (b)) — the interactive drain pre-ratifies story scaffolds ahead of the AFK run. Requires predicting which stories a future run needs.

## Decision Outcome

Chosen option: **1, bounded AFK-accept carve-out — opt-in and fail-closed**, composed with option 2 rather than replacing it.

An AFK loop MAY transition a story `draft → accepted` with a machine-written `human-oversight: confirmed` marker carrying `oversight-basis: pure-decomposition`, and MAY then implement it, without a fresh human ratification, **if and only if** the project has opted in AND the story declares `afk-accept: pure-decomposition` in its frontmatter AND both conditions hold at the accept transition.

### (a) Parent substance confirmed

Every `adrs:` entry resolves and carries `human-oversight: confirmed`. Every `jtbd:` entry resolves and is confirmed, as is its persona. Every `rfcs:` entry resolves and every ADR in **that RFC's** own `adrs:` is confirmed. Every `problems:` entry resolves. Every `story-maps:` entry satisfies the map leg below.

The RFC tier holds no independent decisions per ADR-070 and therefore has no oversight marker of its own; condition (a) proxies through its `adrs:` rather than overlooking a tier. Map **lifecycle** status (`draft` / `accepted` / …) is out of scope — only the oversight marker is in scope.

Because a new persona, job or decision is always born `unconfirmed`, condition (a) rejects new substance-bearing artefacts automatically. That closure is deliberate and is half of why condition (b) can be narrow.

**The map leg.** ADR-095 requires map membership at capture, so authoring a story ALWAYS adds a `data-story-id` card to its map — which under ADR-090 drift-invalidation re-opens the map's ratification. Requiring a hash-matching map would make the carve-out unsatisfiable by construction: the act of capturing the story would break the condition the story must satisfy. So the map leg is a disjunction — the map is fully ratified (card already present when it was ratified), **or** it is `confirmed` and its stored hash matches a content hash computed with **this story's own card excluded**.

This **coarsens the drift trigger to a coherent edit-set**, which is precisely the remedy ADR-090's Reassessment Criteria authorises. It does **not** drop to write-once, which ADR-090 forbids: any map edit other than adding the named card still drifts the hash and still fails the leg. A fix adding two cards fails safe — only the accepted story's own card is excluded — and the escape hatch is a human ratification of the map.

### (b) No new substance, established positively

A whitelist, not a novelty blacklist. The story carries a `## Decomposition basis` section with **exactly one entry per acceptance criterion**, each entry naming the artefact whose already-confirmed clause that criterion decomposes; and **every artefact ID cited there must be a member of the set condition (a) proved ratified**. Frontmatter membership is not ratification — without that intersection the whitelist degrades to "cites something".

Acceptance criteria are counted from the `## Acceptance criteria` section only, matched by prefix (so the trailing qualifiers already in the corpus are tolerated) and terminated by the next `##`. The count is tick-insensitive, so implementation progress never flips the check, and the criterion literal is aligned with the content hash's normaliser so every counted line is a normalised line. **Zero matched criteria is FAIL-CLOSED** — an absent section is indistinguishable from absent criteria, and a vacuous pass here would gut the condition.

Secondarily, no open-decision marker may appear outside a fenced or backticked span. Fenced and backticked spans are stripped first so a story may **describe** the blocked vocabulary — as this decision's own story does — without tripping on it.

Absence of the declaration means no carve-out. Failure of either condition means the story stays held for a human. The failure direction is deliberately "conservatively hold a genuine decomposition" rather than "silently accept an embedded decision".

### The split: unconditional tightening, opt-in loosening

These are two halves and they are deliberately **not** coupled to one flag.

- **The ratification check ships enabled, unconditionally, for everyone.** `itil-no-implement-draft-gate.sh` denies a commit whose `Refs: STORY-NNN` trailer names an `accepted` or `in-progress` story that is not ratified. This is the P465 fix and it is a pure tightening. Putting an ADR-090-mandated check behind a flag would itself be the decision conflict.
- **The carve-out ships opt-in, defaulting off.** The eligibility checker returns not-eligible unless the project opted in, however well (a) and (b) are satisfied.

If both halves rode one flag defaulting off, adopters would get **neither** — the unratified accepted story would keep sailing through — and the loosening would be true only in this repo while the tightening was true nowhere.

Config surface mirrors **ADR-098**'s already-ratified shape rather than inventing a second convention: `.claude/itil.config.json` (project) then `~/.claude/itil.config.json` (machine) then the built-in default `false`, key `afk_accept_pure_decomposition`, JSON read with `jq` and never sourced. `WR_ITIL_AFK_ACCEPT` trumps both files — named here as a loosening override for tests and one-off use, **not** as a project-configuration surface. Scope is the Claude runtime; the Codex root (ADR-083, ADR-098's 2026-07-22 amendment) is deferred to the extraction below.

Config **resolution** fails open to the built-in default and never errors. Because that default is `false`, the **policy** outcome of every degraded path — no `jq`, no file, unreadable, unparseable, non-boolean — is not-eligible. Only the literal JSON `true` enables; the string form, `1`, `yes` and `null` do not, because a typo must never open a permission-loosening carve-out.

Two guards keep `.claude/itil.config.json` inside P131's permitted class rather than becoming agent scratch space: the file holds **only** user-owned config — never markers, caches, counters or run state — and **no automated path — installer, scaffold, or agent — ever writes a `true` value**. Auto-scaffolding it would convert opt-in into opt-out-by-stealth and defeat the split entirely.

### Where each condition is evaluated

A deliberate fork, not an implementation detail.

- **Condition (a) is accept-time only.** Its inputs are shared mutable artefacts. Re-evaluating it at commit time would let unrelated churn on a shared story map block every commit on an unrelated story — which is P456's own blocking shape, re-created by the fix for it. The outcome is recorded once, by `oversight-basis: pure-decomposition`.
- **The commit locus verifies story-local things only**: that the story is ratified (the unconditional P465 check), and — belt-and-braces — that a pure-decomposition story still declares itself and still has a basis matching its criteria. The load-bearing catch for a post-accept edit is the hash, since both the declaration and the basis section sit inside it; the structural re-check exists to yield a specific, actionable deny reason instead of a generic drift deny. Measured at roughly 45-70 ms on a commit-triggered path (30 story files hash in 0.67 s, ~22 ms each); no performance budget is in scope and none is warranted.

### Marker encoding

The carve-out writes the **same** `human-oversight: confirmed` marker a human ratification writes, distinguished by a sibling `oversight-basis: pure-decomposition` line. A novel marker value would fail `check-rfc-stories-ratified.sh` (ADR-090: an RFC may reference only ratified stories) and re-block the loop one tier up, and would require patching every consumer.

The two keys are treated asymmetrically, and the asymmetry is load-bearing. The `afk-accept:` declaration is an **authored claim** and stays INSIDE the content hash — editing it re-opens ratification, and it cannot be stripped to hide a story from the drain. The `oversight-basis:` record is **marker-adjacent** and is excluded from the hash exactly like `oversight-hash`, or a freshly-accepted story would read as drifted the instant it was marked. The basis record is markdown-story-only; a map is always human-ratified and never carries one.

Because a machine-confirmed story would otherwise never resurface for human review — re-creating at a new tier the exact failure the ADR-066/068/090 oversight family exists to prevent — `detect-unratified-stories-maps --with-afk-accepted` lists them on stderr for post-hoc human ratification, keyed on the **union** of the declaration and the record, and `/wr-itil:list-stories` renders the two acceptance bases distinctly. Stored-but-unrendered provenance would not serve JTBD-202's auditability outcome.

### Lockstep amendments

- **ADR-060** — story frontmatter schema gains an optional `adrs:` trace field and an optional `## Decomposition basis` body section, both required only when the carve-out is declared; `acceptance-criteria-count` is redefined from whole-body to the section-scoped, tick-insensitive count above.
- **ADR-090** — the map leg's coarsened drift trigger recorded against its Reassessment Criteria, which pre-authorised exactly this remedy.
- **ADR-095** — "`accepted` … carries human ratification" corrected to name the two acceptance bases.
- **ADR-096** — "no malformed or unratified story can ever be implemented" corrected likewise. This sentence is the over-claim P465 cites, so the correction discharges part of that ticket directly.

## Consequences

### Good

- The AFK loop can land a fix whose substance a human already confirmed — JTBD-006's core outcome, structurally unreachable before this.
- ADR-096's ratification claim becomes true in code rather than held closed by decision alone (P465). On the ratification axis the gate now blocks strictly more than before, for every adopter.
- The whitelist shape means an agent must positively name the confirmed clause each criterion decomposes, which is a burden an agent can actually discharge — unlike proving an absence.
- Adopters inherit the tightening and not the loosening.

### Neutral

- A second acceptance basis to read: `accepted` now means human-ratified **or** machine-accepted-as-pure-decomposition, distinguished by a rendered field.
- One human ratification pass over the story maps a project intends to run AFK against — paid once globally rather than once per fix. Today that means eight of ten maps in this repo, which are unconfirmed or carry no marker and fail under strict and coarsened rules alike.

### Bad

- **A commit that stages a substance edit to the story it references is denied**, because the edit drifts the story's hash. That denial is correct — substance changed, so re-ratify — but the recovery under AFK is a re-ratify write, which the loop may perform only while the story still satisfies the carve-out.
- A fix adding two cards to one map fails the map leg, since only the accepted story's own card is excluded. Fails safe; escape hatch is a human map ratification.
- One more configuration surface, and a second `.claude/<plugin>.config.json` consumer.

### Architect dissent (recorded, per P357)

`wr-architect:agent` dissented from this ADR being born `confirmed`, and the dissent stands:

> "User direction is not substance ratification, and a born-`confirmed` ADR-101 whose post-draft brief has never been surfaced is the hollow-marker shape P357 names. I accept that the maintainer owns that rule and has pre-authorised the marker with the gap explicitly acknowledged, and that the interactive remedy is genuinely unavailable this session."

The maintainer directed born-confirmed anyway, with the owed brief acknowledged. In the event the marker could not be written at all: the P348 evidence-marker gate refuses a `confirmed` marker with no same-session substance-confirm event, and hand-landing that marker is precisely the hollow-marker bug the gate exists to prevent. So this ADR is born `unconfirmed` per the gate's own AFK directive and CLAUDE.md's P357 fallback.

The 2026-07-26 quote pins the **policy**, and that policy is not in doubt. What is outstanding is only whether this draft records it without semantic drift — the (a)/(b) conjunction, the opt-in split, the map-leg boundary, the marker encoding, the supersession of P456's earlier direction. The owed brief is queued to `outstanding_questions` **and** tracked on the P456 ticket body, because the queue file is truncated once surfaced, so the queue entry alone would evaporate.

**Consequence for this decision's own delivery:** until this ADR is confirmed, a story implementing it fails condition (a), so the carve-out cannot bootstrap itself under AFK. The machinery below therefore landed under the maintainer's direct one-time authorisation for this iteration, not under the carve-out. The first genuine exercise of the carve-out is the next interactive session's, once this draft is confirmed.

## Confirmation

- A story declaring the carve-out with all parents confirmed is eligible; one with an unconfirmed parent is not; one whose basis entries do not match its criteria is not — behavioural tests.
- The carve-out is not-eligible when the project has not opted in, even when (a) and (b) both hold; and not-eligible when `jq` is absent or the config value is non-boolean — behavioural tests.
- A commit referencing an accepted-but-unratified story is blocked regardless of config; a ratified story's commit is allowed — behavioural tests (this is the P465 regression).
- A map re-ratified **with** the story's card already present still satisfies condition (a) — behavioural test for the disjunction.
- `detect-unratified-stories-maps` default stdout is byte-identical to before the flag existed — behavioural test.
- No automated path — installer, scaffold, or agent — writes a `true` opt-in value — behavioural test.
- The ratify write is the LAST write of the accept transition and the story is re-staged after it, so the **committed blob** carries the marker, not merely the worktree.

## Pros and Cons of the Options

### Option 1 — bounded carve-out (chosen)

- Good: the loop lands confirmed-substance work; the positive whitelist makes the relaxation auditable; the split protects adopters.
- Bad: a new eligibility predicate to maintain; `accepted` becomes two-valued; a configuration surface.

### Option 2 — selector-skip only

- Good: the gate is preserved absolutely; no new predicate.
- Bad: the loop still lands nothing — it defers the same work at lower cost. Retained as a composing behaviour, not as the answer.

### Option 3 — pre-ratify at drain

- Good: no relaxation at all.
- Bad: requires predicting which stories a future AFK run will need; the unpredicted case falls back to holding.

## Reassessment Criteria

Revisit if machine-accepted stories start arriving at the post-hoc drain with substance a human would have rejected — that would mean condition (b)'s whitelist is not discriminating, and the remedy is to narrow it, not to widen the carve-out. Revisit also if the map leg's coarsened trigger proves too coarse in practice.

At a **third** `.claude/<plugin>.config.json` consumer, or when this plugin's key set grows past one scalar, extract a shared config reader per ADR-017 and promote the convention to a plugin-neutral decision (or amend ADR-098's scope). Generalising on two consumers is premature and would cost the full canonical-plus-sync-plus-CI-drift apparatus for one boolean.

## Related

- **ADR-090** — drift-invalidated story/map oversight; its Reassessment Criteria authorise the coarsened map-leg trigger.
- **ADR-095 / ADR-096** — the capture-time and implementation-side gates this amends; ADR-096's closing Decision Outcome sentence is the over-claim P465 cites.
- **ADR-060** — the framework whose story schema gains the ADR trace field and the basis section.
- **ADR-098** — the config-file shape precedent (project, then machine, then default; env last-override; JSON never sourced).
- **ADR-070** — RFCs hold no independent decisions, hence no oversight tier; condition (a) proxies through their ADR traces.
- **ADR-066 / ADR-068 / ADR-074** — the oversight family and the confirm-substance-before-building principle this carve-out is bounded by.
- **P456** — the AFK ratification wall (three dated witnesses on the ticket, five more in the briefing); its 2026-07-15 selector-skip direction composes with this rather than being cancelled. **P465** — the unenforced gate.
- **JTBD-006** — the served job. **JTBD-002** — the governance-bypass outcome, amended to a two-axis claim. **JTBD-003** — supporting rationale for the opt-in shape (its own granularity is plugin-level install composition, so it is not the deciding authority; ADR-090 and P357 are). **JTBD-008** — the vocabulary source for "decomposition", not a served job.
- **STORY-022** — "ratify the story map and its stories after any change"; its "any change" is narrowed here to exclude the accepted story's own compelled card. STORY-022 itself is left byte-identical rather than edited, since editing it would trip the very rule it states.
