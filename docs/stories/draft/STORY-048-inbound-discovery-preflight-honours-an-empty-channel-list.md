---
status: draft
story-id: inbound-discovery-preflight-honours-an-empty-channel-list
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P431]
jtbd: [JTBD-006]
rfcs: [RFC-051]
story-maps: [STORY-MAP-006]
estimated-effort: S
human-oversight: unconfirmed
---

# STORY-048: Gate the inbound-discovery pre-flight on the channel list

**Status**: draft
**Reported**: 2026-07-26
**Problems**: P431
**JTBD**: JTBD-006
**RFCs**: RFC-051
**Story Maps**: STORY-MAP-006
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to have "no thanks" stay answered — so that declining upstream discovery costs
nothing rather than a full pre-flight subprocess on every loop, forever — as a developer
running autonomous backlog loops, I want the staleness check to read the channel list it was
given, so a recorded decline silent-passes the way an absent config already does.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] `should_promote_inbound_discovery_preflight` in
  `packages/itil/lib/check-upstream-cache-staleness.sh` returns `no-channels-declared` when
  the channel list is empty, checked after the file-existence branch and before the cache
  branch.
- [ ] Both empty shapes reach it: `"channels": []`, and a config carrying no `channels` key at
  all.
- [ ] The emptiness read is folded into the existing `jq` invocation that already reads
  `.ttl_seconds` from the same file — the helper spawns no more processes than it does today.
  Step 0b runs on every `work-problems` invocation, so a fix about per-loop cost must not add
  per-loop cost.
- [ ] A config with a NON-empty `channels[]` and an absent cache still returns
  `first-run-cache-absent` — the fix silences declines, never genuine first runs.
- [ ] The lib header's `# Output (one of):` enumeration lists six outcomes, not five.
- [ ] `packages/itil/skills/work-problems/SKILL.md` Step 0b: the outcome table carries a
  `no-channels-declared` row marked Silent-pass, and the prose sentence above the table reads
  "one of six outcomes".
- [ ] That step's iter-summary annotation list gains its own distinct string for the new
  outcome — reusing the absent-config string would assert the file is missing when it is
  present carrying a `declined_at` timestamp, and JTBD-006's audit-trail constraint depends on
  the two being distinguishable.
- [ ] `packages/itil/skills/review-problems/SKILL.md` Step 4.5a carries an explicit
  empty-`channels[]` branch that skips Step 4.5 silently, so the prose implements the "parse
  cleanly + skip silently" promise it already makes at its decline-permanently branch.
- [ ] The `INBOUND-CACHE-STALENESS-CONTRACT-SOURCE` marker binds on "any change to TTL
  semantics or to the branch set", not TTL alone, and its pointer names Step 4.5a as well as
  Step 4.5b — in the lib header and in the verbatim duplicate in work-problems SKILL.md.
- [ ] A third copy of that marker sits at review-problems Step 4.5a, giving the inbound axis
  the same three anchors the outbound axis has. The missing anchor is why an editor working in
  4.5a never saw the obligation.
- [ ] Cases 2-7 of
  `packages/itil/skills/work-problems/test/work-problems-step-0b-cache-staleness-behavioural.bats`
  are re-authored with a non-empty `channels[]`, each preserving its original intent
  (cache-absent / null-last-checked / fresh-within-TTL / TTL-expiry / custom `ttl_seconds` /
  defaulted `ttl_seconds`). Case 7 keeps `ttl_seconds` absent while gaining a real channel. All
  six write `{ "channels": [] }` today and go RED the moment the helper short-circuits.
- [ ] That suite's header contract block enumerates the sixth outcome, and lists case 7, which
  it currently omits.
- [ ] New behavioural cases cover the three empty shapes: the declined stub with `declined_at`,
  a hand-authored `{"channels": []}` with no `declined_at`, and an absent `channels` key. All
  three return `no-channels-declared` — the helper never reads `declined_at`, so it must not
  claim a decline it did not observe.
- [ ] `check-outbound-responses-staleness.sh`'s header comment names `no-channels-declared` as
  the inbound analogue of `no-back-link-tickets`, replacing the now-inaccurate
  `no-channels-config`.
- [ ] A `.changeset/*.md` bumps `@windyroad/itil` patch, authored in the same commit as the
  code it describes.

## Driving problem trace (required — I7 invariant)

- **P431** — the helper tests whether the channels config file exists and never reads
  `channels[]`, so the declined-permanently stub returns `first-run-cache-absent` where an
  absent config returns `no-channels-config`. Reproduced in situ: the declined tree gets a
  dispatch, the never-configured tree gets a silent pass. Arrived as inbound report #341.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006 (progress the backlog while I'm away), whose Desired Outcomes name this exact
mechanism — the orchestrator checking inbound-discovery cache freshness before opening the
work loop, so upstream-reported problems stay visible. A repo with a declared-empty channel
list has no upstream reports to keep visible, so the outcome's own purpose clause already
implies the silent pass. Two of its persona constraints bind directly: the loop must be safe
to run for extended periods, which a forever-repeating no-op subprocess is not; and every AFK
action must be traceable, which is why the new outcome gets its own annotation string rather
than borrowing a neighbour's.

## Implementation notes

Read the collection, not the container. Both sibling staleness helpers already do — they
derive their collections by scanning the filesystem, so emptiness was unavoidable to handle.
This helper reads its collection out of a JSON file, which is why it alone could mistake the
file's existence for the list's non-emptiness. `jq '.channels // [] | length'` collapses both
empty shapes to the same answer, so the branch is one comparison on a document the helper
already parses.

The naming is deliberate: `no-channels-declared`, not `channels-declined-empty`. The helper
branches on list length and never reads `declined_at`, and the reason string surfaces verbatim
on an audit surface, so it must not assert a decline that a hand-authored empty list never
made.

## Related

- RFC-051 (the fix vehicle), STORY-MAP-006 (the map), P431 (the driving problem), inbound #341.
- RFC-017 introduced the declined-permanently stub this work teaches the helper to honour —
  lineage, not vehicle.
