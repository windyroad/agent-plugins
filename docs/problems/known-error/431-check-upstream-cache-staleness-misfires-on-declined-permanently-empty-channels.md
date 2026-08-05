# Problem 431: check-upstream-cache-staleness helper misfires on a declined-permanently (empty channels) config

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#341)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**WSJF**: 12 — (6 × 2.0 known-error multiplier) / 1 (re-ranked 2026-07-26 on root-cause confirmation)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`wr-itil-check-upstream-cache-staleness` treats a present-but-empty channels config the same as first-run (cache absent): `review-problems` short-circuits, the cache is never written, so every subsequent loop re-dispatches a guaranteed no-op upstream-discovery pre-flight.

## Symptoms

- A repo that has explicitly declined upstream channels (empty channels list) gets a redundant review-problems pre-flight dispatched every work-problems loop, because the staleness helper never sees a written cache.

## Impact Assessment

- **Who is affected**: adopters who declined upstream channels; wasted per-loop dispatch.
- **Frequency**: every work-problems loop in such a repo.
- **Severity**: Medium — wasted cost, no incorrect action.

## Root Cause Analysis

Confirmed 2026-07-26 by reading the helper and reproducing the misfire in a scratch tree.

`should_promote_inbound_discovery_preflight` (`packages/itil/lib/check-upstream-cache-staleness.sh` lines 38-49) tests only whether `docs/problems/.upstream-channels.json` **exists**. It never inspects `channels[]`. The declined-permanently stub that `/wr-itil:review-problems` Step 4.5a writes — `{"channels": [], "ttl_seconds": 86400, "declined_at": "<ISO>"}` — therefore satisfies the existence test, falls past it to the cache check, and returns `first-run-cache-absent`, which work-problems Step 0b maps to *dispatch a `claude -p` review-problems pre-flight subprocess*.

Reproduced in situ against the live helper:

```
declined-permanently stub  -> first-run-cache-absent   (dispatch)
config absent              -> no-channels-config       (silent-pass)
```

The declined tree gets *more* work than the never-configured tree, which inverts the intent. The dispatched subprocess then polls zero channels and writes no `.upstream-cache.json`, so the next loop re-derives `first-run-cache-absent` and dispatches again — the cache that would have quieted it via the TTL branch is never created.

Two structural enablers sit behind the instance:

1. **The collection lives inside a file.** Both sibling staleness helpers derive their collection by scanning the filesystem — `check-outbound-responses-staleness.sh` greps for `## Reported Upstream` back-links and returns `no-back-link-tickets` on zero; `check-deferred-placeholder-staleness.sh` counts placeholders and returns `no-deferred-placeholders` on zero. Emptiness was unavoidable for them. The inbound helper reads its collection out of a JSON file, so it could mistake the file's *existence* for the collection's *non-emptiness*, and did. Both siblings were audited and are clean; there is no second instance.

2. **The symmetry guard is narrower than the contract it protects.** The `INBOUND-CACHE-STALENESS-CONTRACT-SOURCE` marker (lib header lines 8-13, duplicated at work-problems SKILL.md line 193) states its obligation over the *branch set*, but its binding clause narrows to *"any change to TTL semantics"* and its pointer names only Step 4.5b. This defect is a branch-set divergence in Step **4.5a**, with TTL untouched — exactly the class the guard's own wording lets through. `/wr-itil:review-problems` Step 4.5a has no empty-channels branch either: it says only *"File exists and parses cleanly → continue to 4.5b with the parsed `channels[]` list"*, so an empty list routes into a poll loop over nothing, while line 151 of the same file promises the stub makes future invocations *"parse cleanly + skip silently"*. The prose does not implement its own stated contract.

### Investigation Tasks

- [x] Distinguish empty-channels (declined → silent-pass / no-channels-config) from first-run-cache-absent; short-circuit without re-dispatching when channels are explicitly empty. — root cause confirmed; fix scoped in RFC-051 as a sixth helper outcome `no-channels-declared`.
- [x] Audit the two sibling staleness helpers for the same empty-collection blind spot — both clean (they scan rather than read a file), so the fix stays at the witnessed instance.

## Workaround

Delete `docs/problems/.upstream-channels.json` outright instead of keeping the declined-permanently stub. The absent-file branch returns `no-channels-config` and silent-passes, so the redundant dispatch stops immediately.

The cost is that `/wr-itil:review-problems` Step 4.5a's auto-bootstrap routine (P351) treats an absent file as *never asked* and re-offers the bootstrap prompt once per interactive invocation — which is precisely the ceremony the stub was introduced to retire. Acceptable while the fix is pending; not a substitute for it.

## Fix Strategy

Teach the helper to read the answer it was given, per RFC-051:

- After confirming the channels file exists, read `channels[]` in the `jq` call that already reads `.ttl_seconds` from the same file — no additional process spawn, because Step 0b runs on every work-problems invocation and this ticket is itself about per-loop cost.
- When the list is empty, return a sixth outcome `no-channels-declared` and silent-pass. Named for what the helper actually observes: it branches on list length, never on `declined_at`, so a hand-authored `{"channels": []}` must not be reported as a decline that never happened. The name is also parallel to the siblings' `no-back-link-tickets` / `no-deferred-placeholders`.
- Give it its own iter-summary annotation rather than reusing the absent-config one — that string asserts the file is missing, which would be false on an audit surface (JTBD-006 expects every AFK action to be traceable).
- Add the missing empty-channels branch at `/wr-itil:review-problems` Step 4.5a, and widen the symmetry-marker prose (both copies) from *"TTL semantics"* to *"TTL semantics or the branch set"*, with the pointer naming 4.5a as well as 4.5b — otherwise the fix closes the instance and leaves the class open.

Rejected: making review-problems write `.upstream-cache.json` even on a zero-channel poll, so the TTL branch quiets the dispatch to one per day. Direction is already pinned against it — ADR-062 § Downstream-adopter non-obligation and review-problems SKILL.md line 151 say *skip silently*, and one no-op subprocess per day is not silently.

## Dependencies

- **Composes with**: P406 (discussions channel HTTP 410 — adjacent upstream-channel robustness), P373.
- **Lineage**: RFC-017 (P351 auto-bootstrap) introduced the declined-permanently stub this helper fails to honour. It is context, not this ticket's fix vehicle — its task set is closed out and awaiting release.

## Related

- Inbound issue #341 — filed by a reporter exercising JTBD-301; that job was discharged when the report became this ticket, and is not what the fix serves.
- **JTBD-006** (progress the backlog while I'm away) — names the Step 0b pre-flight mechanism as a desired outcome verbatim; this defect is that named mechanism misfiring.
- **JTBD-101** (extend the suite) — secondary: ADR-062 frames the non-obligation contract as closing a JTBD-101 ceremony-tax risk, and a per-loop subprocess charged to someone who declined is that tax accruing anyway.
- **JTBD-010** (sustain my token quota) — sharpens the impact: the waste is a full `claude -p` subprocess per loop, forever, in an affected tree.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-051 | proposed | Inbound-discovery pre-flight honours a declined channel list |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-048 | STORY-048: Gate the inbound-discovery pre-flight on the channel list | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-006 | STORY-MAP-006: Decline upstream discovery once and stay declined | archived |
| STORY-MAP-004 | STORY-MAP-004: Close the loop with someone who reported a problem | draft |
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
