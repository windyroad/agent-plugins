---
status: proposed
rfc-id: afk-accept-carve-out-and-story-ratification-enforcement
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P456, P465]
adrs: [ADR-101, ADR-090, ADR-095, ADR-096, ADR-060]
jtbd: [JTBD-006]
stories: []
---

# RFC-058: The AFK-accept carve-out, and the story-ratification check that was never implemented

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P456, P465
**ADRs**: ADR-101, ADR-090, ADR-095, ADR-096, ADR-060
**JTBD**: JTBD-006

## Summary

Two halves of one gate. An unattended loop could not accept a story, so it could not land any code fix at all; and nothing in code enforced the ratification that gate was supposed to carry, so an accepted-but-unratified story sailed through. This RFC lands the bounded carve-out that unblocks the first, and the enforcement check that closes the second.

## Driving problem trace

**P456** (Known Error) — ADR-090, ADR-095 and ADR-096 compose into an interactive-only path from "ratified fix direction" to "implementable story": implementation requires `accepted`, and ratification fires at that gate. Ratification has no unattended path, so an autonomous `/wr-itil:work-problems` iteration can author governance artefacts and nothing else. Three dated witnesses are on the ticket, five more in the cross-session briefing. The sharpest is P430 — a three-line env-var guard, effort S, four existing ADR precedents — which still could not land after three architect reviews, two style-guide reviews, two voice-tone reviews, one accessibility review, and three new artefacts across three tiers.

**P465** (Open) — the same gate is enforced nowhere. `manage-story` gates `accepted` on I7 + I8 + I10 only; `itil-no-implement-draft-gate.sh` resolves `status:` and carries no ratification check at all. ADR-096's Decision Outcome nevertheless claims "no malformed or unratified story can ever be implemented" — an over-claim its own Confirmation item (b) under-specifies, since (b) specifies a status-only check. An agent proposed exactly this bypass during the P430 iteration, and it would have worked.

## Scope

Ratified by the maintainer verbatim on 2026-07-26: *"the loop may accept-and-implement a story that only decomposes already-ratified substance, without a fresh human ratification."* Recorded as **ADR-101**, which amends ADR-060, ADR-090, ADR-095 and ADR-096.

The work splits along a line that is load-bearing rather than presentational.

**The tightening ships enabled, unconditionally, for everyone.** The commit-trailer gate — which ADR-096 itself names as the primary locus, precisely because it is the only one that catches a hand-written commit — now denies a commit whose `Refs: STORY-NNN` trailer names an `accepted` or `in-progress` story that is not ratified. Putting an ADR-090-mandated check behind a flag would itself have been the decision conflict. Blast radius was measured before landing: all four then-implementable stories are genuinely ratified, so nothing in flight was blocked.

**The loosening ships opt-in, defaulting off**, keyed on `afk_accept_pure_decomposition` in `.claude/itil.config.json` per ADR-098's already-ratified config shape (project, then machine, then built-in default; environment last-override; JSON parsed, never sourced). An adopter who ratifies their own decisions has given artefact consent; they have not consented to a self-accepting loop, and P357's rule applies to them as much as to us. Coupling both halves to one flag was considered and rejected: adopters would then get **neither**, the unratified accepted story would keep sailing through, and the claim that the hooks block strictly more than before would be true only in this repo.

Landed 2026-07-26 under the maintainer's direct one-time authorisation for that iteration — **not** under the carve-out, which cannot bootstrap itself (see § Stories).

- `packages/itil/lib/story-oversight.sh` — the record field excluded from the content hash, or a freshly-accepted story would read as drifted the instant it was marked; a map hash that excludes the accepted story's own card, which is what makes the carve-out satisfiable at all, since ADR-095 compels that card and the unqualified drift rule would therefore break the condition the story must satisfy; the declaration, record and map-leg predicates.
- `packages/itil/scripts/check-afk-accept-eligible.sh` (new, with its ADR-049 shim) — the two-condition eligibility predicate. Condition (b) is a whitelist rather than a novelty blacklist: "introduces no new design choice" is a negative existential an agent cannot discharge, so the story must positively name, per acceptance criterion, the confirmed clause it decomposes, and every citation must intersect the set condition (a) proved ratified.
- `packages/itil/hooks/itil-no-implement-draft-gate.sh` — the unconditional ratification check, plus a story-local re-assertion of the carve-out that yields a specific deny reason rather than a generic drift deny. Condition (a) is deliberately **not** re-evaluated here: its inputs are shared mutable artefacts, and unrelated churn on a story map blocking an unrelated story's commits would be P456's own shape re-created by the fix for it.
- `mark-story-oversight-confirmed.sh --pure-decomposition`; `detect-unratified-stories-maps --with-afk-accepted` for the post-hoc human-ratification drain; `manage-story` I12 with the ratify-last write ordering; `list-stories` rendering the two acceptance bases distinctly, since a report that counts them together overstates how much a human has seen; `packages/itil/README.md` configuration section.
- Behavioural tests mapping one-for-one onto ADR-101's confirmation criteria, and the coupled draft-gate case split into both directions.

## Stories

Deliberately empty, and the emptiness is the point.

The carve-out cannot accept its own story. Until ADR-101 is confirmed, a story implementing it fails condition (a), because ADR-101 is one of its own parents — and ADR-101 is born unconfirmed under the evidence-marker gate, which requires a same-session substance-confirm event that a non-interactive session cannot produce. Reserving a story ID instead would be a fabricated trace: `wr-itil-check-rfc-stories-ratified` resolves an unauthored ID as missing, and the reverse-trace reconciler would chase it. ADR-089 places its one-story floor at the `accepted` gate, so a `proposed` RFC with no story is inside the rule; this RFC does not advance to `accepted` until its story exists.

Once ADR-101 is confirmed at the interactive drain, the story is authored, added to STORY-MAP-002 on its JTBD-006 co-anchor at backbone A4 ("Implement the coordinated changes" — the map's `<meta name="jtbd">` lists JTBD-008, JTBD-001 and JTBD-006), and self-accepted under the carve-out. That is the first genuine exercise of the rule and the evidence it works end to end.

The open items are tracked on the **P456 ticket body** rather than only in the outstanding-questions queue, because that queue is truncated once surfaced and a queue entry alone would evaporate. They include the owed post-draft brief on ADR-101, whether this repo opts in at all, re-ratification of JTBD-002 / JTBD-006 / JTBD-008 (all three carry `oversight-downgraded` entries, since ADR-101's lockstep materially rewrote a desired outcome in each), and a wording correction to ADR-089, whose escape hatch names a `draft` RFC while the lifecycle has no such state and `proposed` is the de facto occupant. That correction must retarget the state name while keeping the "before the fix is scoped" qualifier and the accepted-gate enforcement in the same sentence — without the qualifier it would read as a general licence and hollow out the one-story floor, since every RFC transits `proposed`.

Because the code ships now while the story waits, the drain sees the shipped code in scope too: if it amends the two-condition conjunction, the opt-in split or the map-leg boundary, `check-afk-accept-eligible.sh` moves with the decision.

## Commits

(rendered from `git log --grep "Refs: RFC-058"` by `/wr-itil:manage-rfc` per ADR-085.)

## Related

- **P465 is a defect in RFC-037's delivered scope.** RFC-037 Phase 2 shipped the ADR-090 marker machinery, and its confirmation reads as though the ratification gate shipped with it. It did not. RFC-037 stays `verifying` and untouched — `verifying` is irreversible under ADR-060, and re-opening it would make its state a lie — but its eventual close should not silently claim a gate that never existed.
- **ADR-101** — the carve-out; amends ADR-060, ADR-090, ADR-095, ADR-096. **ADR-098** — the config shape precedent. **ADR-070** — RFCs hold no independent decisions, which is why condition (a) proxies through an RFC's decision trace.
- **JTBD-006** — the served job; its "queued for my return, not guessed at" outcome is narrowed here, with verification explicitly untouched. **JTBD-002** — narrowed on the machine-accept axis, strengthened on the ratification axis. **JTBD-003** — supporting rationale for the opt-in shape. **JTBD-008** — the vocabulary source for what decomposition means.
- `.claude/itil.config.json` is user-controlled policy config in the same permitted class as the sibling per-project consent files, not a project-generated artefact. It is gitignored, so no automated path can commit an opt-in.
