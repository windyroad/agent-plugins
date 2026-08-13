---
status: proposed
rfc-id: inbound-discovery-preflight-honours-declined-channel-list
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P431]
adrs: [ADR-013, ADR-026, ADR-052, ADR-062, ADR-099]
jtbd: [JTBD-006, JTBD-101]
stories: []
---

# RFC-051: Inbound-discovery pre-flight honours a declined channel list

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P431 (the Step 0b staleness helper treats a declined-permanently empty-channels stub as a first run)
**ADRs**: ADR-013 (Rule 5 below-appetite silent-pass — the declined branch opens no user-attention surface), ADR-026 (agent output grounding — the reason string and its iter-summary annotation are audit surfaces and must state what was observed), ADR-052 (behavioural bats default), ADR-062 (inbound-discovery surface; § Downstream-adopter non-obligation is the contract this defect breaches), ADR-099 (changesets are release metadata, not shipment controls)
**JTBD**: JTBD-006 (progress the backlog while I'm away), JTBD-101 (extend the suite — secondary)
**Story maps**: STORY-MAP-004 (Close the loop with someone who reported a problem)

## Summary

`should_promote_inbound_discovery_preflight` decides whether to pre-flight
`/wr-itil:review-problems` at the head of every `/wr-itil:work-problems` loop. It tests
whether `docs/problems/.upstream-channels.json` exists; it never reads `channels[]`. So the
declined-permanently stub that review-problems Step 4.5a writes — an empty channel list plus a
`declined_at` timestamp — passes the existence test and returns `first-run-cache-absent`,
which dispatches a full `claude -p` subprocess. That subprocess has nothing to poll, so it
writes no cache, so the next loop dispatches it again. A project that said no gets more work
than a project that never configured anything.

This RFC is the fix vehicle for P431 (ADR-071 / ADR-072 / ADR-073: a fix proposed on a Known
Error requires a problem-traced RFC, authored as a deliberate pre-implementation step). It
carries a single story.

## Driving problem trace

- **P431** (Known Error) — arrived as inbound report #341. Its Root Cause Analysis confirms
  the file-existence-versus-collection-emptiness confusion and records the in-situ
  reproduction: the declined stub returns `first-run-cache-absent` where an absent config
  returns `no-channels-config`.

## Scope

The list below is the ratification-gated implementation slice: none of it lands until
STORY-048 is ratified at its `accepted` gate (ADR-090 / ADR-096), which has no AFK path.
That deferral is cadenced, not parked — `/wr-itil:work-problems` Step 2.4 gate (a) runs
`wr-itil-detect-unratified-stories-maps` at every loop end and surfaces STORY-048 for
ratification, and `itil-rfc-oversight-nudge.sh` (SessionStart) counts this RFC in its
every-session unoversighted-RFC nudge on interactive sessions while the `human-oversight:
unconfirmed` marker stands.

**The fix being proposed.** Make the helper read the answer the adopter already gave.

1. `packages/itil/lib/check-upstream-cache-staleness.sh` gains a sixth outcome,
   `no-channels-declared`, returned when the channel list is empty. It is a silent-pass,
   alongside `no-channels-config`. "Empty" covers both on-disk shapes — `"channels": []` and
   an absent `channels` key — which `jq '.channels // [] | length'` already collapses to the
   same answer.
2. The emptiness read folds into the `jq` invocation at line 44 that already reads
   `.ttl_seconds` from the same file, so the branch costs **no additional process spawn**.
   Step 0b fires on every `work-problems` invocation; a fix whose whole subject is per-loop
   cost must not add per-loop cost.
3. `packages/itil/skills/work-problems/SKILL.md` Step 0b: the outcome table gains the row,
   the prose sentence at line 169 goes from "one of five outcomes" to six, and the
   iter-summary annotation list gains its **own distinct string**. Reusing the absent-config
   annotation would assert the file is missing when it is present carrying a `declined_at`
   timestamp — false on an audit surface, and it erases the distinction JTBD-006's
   audit-trail constraint depends on.
4. The lib header's `# Output (one of):` enumeration gains the sixth entry.
5. `packages/itil/skills/review-problems/SKILL.md` Step 4.5a gains the symmetric explicit
   branch it currently lacks. Today it says only "File exists and parses cleanly → continue to
   4.5b with the parsed `channels[]` list", which routes an empty list into a poll loop over
   nothing, while line 151 of the same file promises the stub makes future invocations "parse
   cleanly + skip silently". The prose does not implement its own stated contract.
6. The `INBOUND-CACHE-STALENESS-CONTRACT-SOURCE` marker prose widens from "any change to TTL
   semantics" to "any change to TTL semantics **or to the branch set**", and its pointer names
   Step 4.5a as well as Step 4.5b, in both existing copies (the lib header and the verbatim
   duplicate at work-problems SKILL.md line 193) — **plus a third anchor at review-problems
   Step 4.5a itself**. The inbound marker has two anchors where the outbound sibling has
   three, and the missing one is the file the pointer names: an editor working in Step 4.5a
   never saw the obligation, which is the mechanism by which this defect got in. Widening the
   wording without widening the reach would fix the instance and leave the class open.
7. `packages/itil/skills/work-problems/test/work-problems-step-0b-cache-staleness-behavioural.bats`
   cases 2-7 are re-authored with a **non-empty** `channels[]`, preserving each case's original
   intent (cache-absent / null-last-checked / fresh-within-TTL / TTL-expiry / custom
   `ttl_seconds` / defaulted `ttl_seconds` — case 7 keeps the field absent while gaining a real
   channel). All six currently write `{ "channels": [] }` because emptiness was never
   load-bearing, so all six go RED the moment the helper short-circuits. Case 2 re-authored
   **is** the regression guard that the fix does not silence genuine first runs. The suite
   header's enumeration gains the sixth outcome, and picks up case 7, which it never listed.
8. New cases: the declined stub silent-passes with `no-channels-declared`; a hand-authored
   `{"channels": []}` carrying no `declined_at` gets the same outcome; a config with no
   `channels` key at all gets the same outcome.
9. A patch changeset for `@windyroad/itil`.

**Why the reason string is `no-channels-declared`.** The helper branches on list length; it
never reads `declined_at`. A hand-authored `{"channels": []}` written by someone who never saw
the decline prompt hits the same branch, and an audit line claiming a decline that never
happened is an ADR-026 grounding failure. The chosen name states what was observed, and is
parallel to the sibling helpers' `no-back-link-tickets` and `no-deferred-placeholders`. The
outbound sibling's header comment, which currently names `no-channels-config` as the inbound
analogue of `no-back-link-tickets`, is corrected to name this outcome instead — post-fix it is
the true empty-collection counterpart.

**Why no new ADR** (ADR-073's default reflex — lean on what is already decided): the approach
choice is covered by the existing corpus. ADR-062 § Downstream-adopter non-obligation makes
adoption opt-in; review-problems SKILL.md line 151 already commits the framework to *skip
silently* on the stub; ADR-013 Rule 5 authorises the below-appetite silent pass; ADR-026
settles the naming. The helper is simply not honouring decisions already made. Per ADR-070
this RFC records no independent decisions.

**No ADR-062 amendment is triggered.** Its Confirmation item 5 requires the inbound marker be
"anchored in both spots"; a third anchor and a widened binding clause leave that criterion
satisfiable as a strict superset. The lag is descriptive, not drift.

**No changeset is authored in the vehicle-authoring commit.** A changeset describing a fix
that does not yet exist in the package is untruthful release metadata, which is the
distinction ADR-099 draws. The changeset lands with the code, in the implementation slice —
not withheld from it.

**Empty `stories:` is transient, not the atomic shape.** P431 already carries a full Fix
Strategy, so this RFC is scoped, not pre-scoped. The array is empty only until STORY-048 is
ratified — ADR-090 forbids an RFC referencing an unratified story — and is wired before the
`accepted` transition, where ADR-089's at-least-one-story criterion binds. This is not the
`stories: []` atomic fallback that ADR-089 and ADR-071 disavowed.

## Out of scope

- **The sibling staleness helpers.** Both were audited during P431's root-cause work and both
  already silent-pass on an empty collection: `check-outbound-responses-staleness.sh` returns
  `no-back-link-tickets`, `check-deferred-placeholder-staleness.sh` returns
  `no-deferred-placeholders`. They derive their collections by scanning the filesystem, so
  emptiness was unavoidable to handle; the inbound helper reads its collection out of a file,
  which is why it alone could confuse existence with non-emptiness. There is no second
  instance and no class-wide remediation is needed. Recorded here so a future reader does not
  re-run the audit.
- **Making review-problems write the cache on a zero-channel poll.** This is the other viable
  fix locus — it would let the TTL branch quiet the dispatch to one per day rather than one per
  loop. It is not a live option: direction is pinned by ADR-062 § Downstream-adopter contract
  and by review-problems SKILL.md line 151's *skip silently*, and one no-op subprocess per day
  is not silently. The reasoning lives in P431's Fix Strategy, which is its home.

## Stories

Decomposed as STORY-048 (Gate the inbound-discovery pre-flight on the channel list) on
STORY-MAP-004 (Close the loop with someone who reported a problem).

## Commits

(rendered from `git log --grep "Refs: RFC-051"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs`
per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no commits yet.)

## Related

- **P431** — driving problem, inbound report #341.
- **STORY-MAP-004** — the story map this RFC's work sits on.
- **RFC-017** (P351 auto-bootstrap on missing precondition config) — lineage only. Its work
  *introduced* the declined-permanently stub that this helper fails to honour, but its task
  set is closed out and awaiting release; it is not this ticket's fix vehicle, and wiring P431
  into its `problems:` array would fragment attribution across two vehicles.
- **P406** (discussions channel HTTP 410), **P373** (title-prefix hard filter dropped a
  report) — adjacent upstream-channel robustness problems.
