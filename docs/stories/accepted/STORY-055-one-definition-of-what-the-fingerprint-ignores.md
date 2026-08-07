---
status: accepted
story-id: one-definition-of-what-the-fingerprint-ignores
reported: 2026-07-30
decision-makers: [Tom Howard]
problems: [P474]
jtbd: [JTBD-002, JTBD-001]
rfcs: [RFC-059]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-055: One definition of what the oversight fingerprint ignores

**Reported**: 2026-07-30
**Problems**: P474
**JTBD**: JTBD-002 (Ship AI-Assisted Code with Confidence), JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-059
**Story Maps**: STORY-MAP-002 (Decompose a Fix Into Coordinated Changes)
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to know that the next lifecycle mirror cannot be half-fixed, as a developer whose commits are gated on a story's oversight fingerprint, I want exactly one definition of what that fingerprint ignores — because the definition currently exists twice, verbatim, which is why the last mirror had to be found and fixed in two places and why a third copy could have been missed entirely.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] `oversight_content_hash` and `oversight_content_hash_excluding_stories` route through **one** extracted filter, so the definition of what is ignored exists once rather than twice.
- [ ] The extraction takes the **filter only**. Each function keeps its own input path, because they are not equivalent today: one passes the file to `grep` directly, the other round-trips through `$(cat)` which strips trailing newlines. Unifying the input paths would silently change the hash for any artefact with trailing blank lines.
- [ ] The excluded-key set is readable by tests through an `oversight_excluded_keys()` accessor, and a **bidirectional** agreement test asserts every accessor key appears in the operative pattern and every pattern branch appears in the accessor.
- [ ] The operative pattern stays a **literal**, not built from a variable. A pattern that ever expanded empty would make `grep -vE ''` suppress every line, hash the empty stream to a constant, and leave one artefact's stored hash validating against any content — and the consuming hook sources this lib under `2>/dev/null || exit 0`, so that failure would remove the gate silently rather than loudly.
- [ ] A frozen-reference equivalence matrix asserts the refactored functions are byte-identical to a verbatim copy of the pre-refactor implementation, across: no final newline, multiple trailing blank lines, CRLF, empty file, a criterion tick, a `data-status`, each excluded key present, and for the map variant zero ids / one id / the `STORY-05` vs `STORY-054` prefix collision.
- [ ] The equivalence matrix also runs over the **live corpus**, comparing old-implementation against new-implementation. That is self-maintaining and corpus-content-independent, so it needs no stored baseline and cannot redden on a later legitimate artefact edit.
- [ ] Golden hashes are pinned over **fixtures**, never over live artefacts. Pinning them to the live corpus would redden this suite on every subsequent legitimate edit to any of those artefacts — the refactor-blocking failure mode ADR-052 documents.
- [ ] A **corpus lint** asserts no story artefact or map carries a body mirror of any excluded frontmatter key, matching the mirror's **operative shape**: line-start, bold key, immediately followed by its value, **matched case-insensitively**. The case dimension is load-bearing, not incidental: every real mirror in this corpus is Title-Case (`**Status**:`) while the excluded keys the accessor holds are lowercase (`status`), and grep is case-sensitive by default — so a lint built naively from the accessor matches nothing on arrival *and* stays green when `**Status**: accepted` is reintroduced. That is P474 recurring underneath a lint that claims to guard it.
- [ ] The line-start anchoring is also load-bearing, and replaces an exclusion set. Unanchored, the pattern hits four live lines of legitimate prose *about* the defect — the stories README, two separate lines in STORY-054, and this story's own problem trace — so it would redden on arrival and need a list growing with every future story that discusses a mirror. Line-anchored it hits none of them, so no exclusion set is carried: a dead exclusion entry is indistinguishable from a wrong one. (Both counts are under case-insensitive matching; case-sensitively every figure here is zero, which is exactly the trap above.)
- [ ] The lint guards its search roots and asserts a non-zero artefact count, so a wrong or renamed path fails loudly instead of passing vacuously. Its RED state is demonstrated by injecting a line-start `**Status**: accepted` into a fixture — concretely that shape, because this criterion is the only thing standing between the lowercase-pattern mistake and a shipped no-op lint.
- [ ] A behavioural fixture test sits alongside that lint: construct an artefact, change an excluded key, assert ratification survives. It covers a mirror of *any* excluded key in *any* shape, including an HTML meta mirror, which the lint's `**Bold**:`-shaped pattern cannot reach.
- [ ] Every stored fingerprint in the corpus is unchanged after the refactor — verified against a pre-change baseline of all values for both functions, requiring zero differences.

## Driving problem trace (required — I6 invariant)

**P474** — the `**Status**:` body mirror was hashed while the frontmatter `status:` it duplicated was excluded, so accepting a story dropped its own ratification. The mirror had to be removed from two hash functions because the filter defining what to ignore was duplicated verbatim between them. RFC-059 shipped the fix but recorded the extraction as explicitly out of its own scope, so the duplication that caused the two-place omission is still there.

## JTBD trace (required — I9 invariant)

Traced per leg, because the legs serve different jobs:

**The extraction → JTBD-002** (Ship AI-Assisted Code with Confidence), whose outcome reads *"The refactor step is enforced and not skipped at green — structural quality lands with the tests, so the code is well-factored and not just test-passing."* That is literally what happened here: `@windyroad/itil@0.61.0` went green and RFC-059 recorded the refactor as out of scope because neither filter was touched by the chosen approach. This story is that skipped refactor step being paid rather than left.

**The equivalence evidence → JTBD-002** on its audit-trail axis, and this is a present-tense adopter guarantee rather than a future-defect story. Refactoring the filter that computes every stored `oversight-hash` is the highest-blast-radius edit available in this lib: if the extracted helper differs from the original on any edge shape an adopter's corpus actually contains — a trailing newline, CRLF, an empty file — then every ratified artefact in that corpus un-ratifies at once and the no-implement gate denies commits across their whole backlog. That is P474 at corpus scale rather than per-story. The frozen reference converts "we believe this refactor is safe" into "it is proven byte-identical across those shapes".

**The corpus lint → JTBD-001** (Enforce Governance Without Slowing Down), outcome *"No manual step is needed to trigger reviews — they happen on every edit."* P474's mirror audit was a one-time inspection; a one-time inspection has no cadence and does not happen again. Converting it into a lint that runs with the suite is the difference between having audited once and being guarded.

## Implementation notes

Honest scope: the extraction and the lint have no adopter-facing benefit beyond preventing a future defect, and are recorded as maintainer-facing rather than inflated. The `developer` persona's pain point *"Agents skip steps (architecture review, TDD, risk assessment)"* is that concern turned inward on the plugin's own code. The equivalence evidence is the one leg with a present-tense adopter guarantee.

**Known-uncovered siblings, named rather than implied.** Two things the lint does not catch, and the behavioural fixture test is the mitigation for both:

- The story-map `href` leg recorded as an open P474 task, where a card links `../../stories/<state>/…` so the lifecycle directory sits inside the map's hashed content while the card's `data-status` is normalised out. That is the same asymmetry in a shape no bold-key pattern can see, so the lint will be green while that defect is live.
- A mirror written with leading whitespace or inside a list item, which the line-start anchoring above deliberately trades away in exchange for not needing a growing exclusion set.

Wording the lint criterion as "no lifecycle state appears in hashed content" would be exactly the overstatement RFC-059 declines to make about itself.

**Map card: none in this change, deliberately.** This story's card is NOT added, matching STORY-054, whose card is likewise absent and already recorded as an open P474 follow-up. Deferring both keeps them consistent and costs nothing here: I8 at `accepted` requires only that `story-maps:` is non-empty and each id resolves to a file, not that a card exists, and STORY-MAP-002 is ratified with a stored hash so `oversight_map_leg_ok` takes its already-ratified branch and passes with the map untouched.

Two traps for whoever later adds them, which is why they are recorded here rather than left to be rediscovered. Add the cards **one at a time**: `oversight_map_leg_ok` passes a single story id to the excluding hash, so adding both in one edit leaves one card unexcluded, fails the map leg, and denies that commit — P474's shape re-enacted by hand. And do not touch the map's `jtbd` meta, currently `JTBD-008,JTBD-001,JTBD-006`; meta is not card-excluded, so editing it drifts the map hash and costs the map's ratification. A story carrying a job its map does not is established precedent — STORY-054 traces JTBD-009 the same way.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P474** (driving problem), **RFC-059** (fix vehicle, Scope amended to admit this leg), **STORY-054** (the shipped fix this completes), **STORY-MAP-002** (the map).
- **ADR-090** (the fingerprint contract), **ADR-052** (why the corpus lint is a lint rather than a test — a corpus property is data, and data has no behaviour to assert, so it homes under ADR-005's data-validation authority rather than claiming an exception), **ADR-005** (script/data validation).
