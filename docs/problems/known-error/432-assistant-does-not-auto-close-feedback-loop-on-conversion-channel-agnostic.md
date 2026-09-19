# Problem 432: Assistant does not auto-close the feedback loop on inbound-feedback conversion (channel-agnostic)

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#347)
**Effort**: M — unchanged on the Known Error transition (2026-09-19). Investigation confirmed the shape estimated at capture: the conversion contract gains a channel-qualified source reference, the conversion routes gain a shared close-the-loop call, and one channel adapter (GitHub) is implemented behind it. The acknowledgement leg needs no new decision record; the channel-qualified origin record does — see `## Fix Strategy`. The reach is wider than one skill but each edit is small.
**WSJF**: (9 × 2.0) / 2 = **9.0** — re-rated on the Open → Known Error transition 2026-09-19 (status multiplier 1.0 → 2.0 per P498; Priority 9 and Effort M both unchanged)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

When inbound feedback is converted into a local ticket, the assistant does not, in the same pass, (a) mark the source entry's triage-state → converted and link the created ticket ID, nor (b) author a user-facing acknowledgement. The close-the-loop step is left to a later manual prompt. This is the conversion-time leg of the JTBD-301 inbound loop, and it should be defined against a channel-agnostic feedback interface (GitHub issue + bespoke sources, e.g. Firestore), not GitHub-only.

## Symptoms

- Inbound report converted to a ticket; the source entry stays untriaged/open and the reporter gets no acknowledgement until a human intervenes.

## Impact Assessment

- **Who is affected**: inbound reporters (plugin-user); the feedback loop stays open at conversion time.
- **Frequency**: every conversion.
- **Severity**: Medium — reporters churn / re-file; erodes the inbound-discovery trust loop.

## Workaround

Run `/wr-itil:update-upstream <NNN>` by hand after the conversion. Its inbound-origin leg (I1-I6) posts a reporter-facing comment on the originating issue and logs what it sent. Three limits make it a workaround and not the fix: it only resolves a source whose provenance can be reconstructed from the committed discovery cache, it only fires verdict comments for the fix-released and closed transitions (so there is no accepted-into-backlog message at conversion time), and it has no path at all for a source that did not arrive as a GitHub issue. For a bespoke channel the acknowledgement has to be written by hand.

## Root Cause Analysis

Closing the loop at conversion is a **side effect of one branch of the GitHub discovery pipeline**, not a property of conversion itself. Nothing watches the conversion event; only that one branch happens to send a message while it is passing through.

Three findings, in the order they compound:

1. **Only one conversion route acknowledges.** The acknowledgement lives in `/wr-itil:review-problems` Step 4.5e step 6 (the safe-and-valid branch). A report only reaches it by being discovered, unmatched, and classified within a single discovery pass. Every other route to a ticket — a maintainer or agent running `/wr-itil:capture-problem` against something they were told about, or a report the semantic comparator matches to a ticket that already exists — skips it silently. There is no failure; the branch simply never runs.

2. **Nothing writes the source's own state.** No route marks the originating entry as converted. The only record is `matched_local_ticket` in `docs/problems/.upstream-cache.json`, which is maintainer-side, invisible to the reporter, and regenerable — so it is a cache of a conclusion, not the source's state. The source entry itself is left exactly as the reporter left it.

3. **The one durable conversion record cannot name a channel.** The ticket records `**Origin**: inbound-reported (#NN)` — a bare number with no channel qualifier. `/wr-itil:update-upstream` I1 says so outright ("that untyped number is not proof of an issue") and has to reconstruct the channel by searching the cache, abandoning the leg as `inbound-channel-unresolved` when it cannot. A source that is not a GitHub issue has nowhere to record what it is, so no dispatch can reach it even once an adapter exists.

### Evidence (observed 2026-09-19)

- This ticket's own source, issue #347, was converted to P432 on 2026-07-06. Seventy-five days later it carries **zero comments, zero labels, and is still open**. The reporter has never been told the report was received, accepted, or acted on.
- Across the whole tracker, **41 of the 53 converted inbound reports (77%) have never received a single comment**. Counted by taking every cache entry carrying a `matched_local_ticket` and reading each issue's comment count from the tracker.
- The cache classification distribution shows the split directly: 16 entries reached the acknowledging branch (`safe-and-valid-local-ticket-created`); 37 were converted by some other route (`matched-local-ticket`).
- `docs/problems/.upstream-channels.json` configures three channels, all GitHub. No bespoke channel is configured anywhere in the repo, and no channel-agnostic feedback interface exists — the term appears only in this ticket.

### Why it is channel-agnostic by construction

The harm observed today is entirely on GitHub, so the temptation is to fix it with `gh` calls at each conversion route. That rebuilds the same trap one layer up. The durable defect is finding 3: the conversion record cannot say where the report came from. Fixing that — a channel-qualified source reference written at conversion, dispatched through a lookup rather than an assumption — is what makes the fix work for the next channel without a second rewrite. Building an adapter for a bespoke source that no config names would be speculative; refusing to hard-code GitHub into the contract is not.

### Reproduction

Recount the harm from the committed cache and the live tracker — every converted report, and how many of them have ever been answered:

```bash
jq -r '[.channels[].reports[]? | select(.matched_local_ticket != null) | .number] | .[]' \
  docs/problems/.upstream-cache.json | sort -n > /tmp/converted.txt
gh issue list --repo windyroad/agent-plugins --state all --limit 300 \
  --json number,comments -q '.[] | "\(.number) \(.comments|length)"' > /tmp/issues.txt
awk 'NR==FNR{c[$1]=1;next} ($1 in c){tot++; if($2==0) zero++} END{print zero" of "tot" converted reports have no comment"}' \
  /tmp/converted.txt /tmp/issues.txt
```

Observed 2026-09-19: `41 of 53 converted reports have no comment`. The single-report form is cheaper still — `gh issue view 347 --repo windyroad/agent-plugins --json comments,labels` returns an empty comment list and an empty label list for the report that became this ticket. The count is the regression check: it must fall to zero for conversions made after the fix, and any conversion that adds to it is the defect recurring.

### Investigation Tasks

- [x] Establish which conversion routes exist and which of them acknowledge — one of three does (finding 1).
- [x] Establish whether any route marks the source entry's triage-state — none does (finding 2).
- [x] Establish why the existing mechanism cannot serve a non-GitHub source — the origin record is an untyped number (finding 3).
- [x] Quantify the reporter-visible harm — 41 of 53 conversions unacknowledged; this ticket's own source among them.
- [ ] Implement: at conversion, record a channel-qualified source reference and mark the source converted, then send the accepted-into-backlog acknowledgement through the existing gate chain — on every conversion route, dispatched by channel. GitHub is the one implemented adapter; an unrecognised channel records and queues rather than failing.

## Fix Strategy

The fix is the release row **RFC-097 — "Every conversion answers the reporter, whatever channel they used"**, drawn on [STORY-MAP-004](../../story-maps/draft/STORY-MAP-004-close-the-loop-with-someone-who-reported-a-problem.html) under its existing "B. Hear it landed" activity, carrying [STORY-093](../../stories/draft/STORY-093-every-conversion-tells-the-reporter-it-landed.md).

The work splits into two legs, and they are not in the same state.

**The acknowledgement leg is already decided and only needs building.** [ADR-062](../../decisions/062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md) decides that a conversion posts an acknowledgement carrying the local ticket reference, that the branch decision is mechanical, and that the body strips maintainer-internal vocabulary; [ADR-028](../../decisions/028-voice-tone-gate-external-comms.proposed.md) supplies the gate chain the comment rides. Moving that acknowledgement from one branch of the discovery pipeline to the conversion event repairs an implementation gap against substance already ratified. No new decision is needed for it.

**The channel-qualified origin record is not decided, and implementation waits on it.** Recording the channel on the ticket changes the `**Origin**` vocabulary [ADR-076](../../decisions/076-inbound-reported-problems-rank-ahead-via-sort-tier.proposed.md) ratified, and it runs into [ADR-121](../../decisions/121-owned-tracker-issues-close-on-evidence.proposed.md), which requires an inbound mutation to resolve to exactly one committed cache record or do nothing. ADR-121 names this exact trigger in its own reassessment criteria ("reassess if the origin field becomes channel-typed"), so the route is a new decision superseding ADR-076 in part rather than an amendment. Three options are on the table — extend the `**Origin**` field in place, add a separate on-ticket field beside it, or keep provenance in the cache and channel-type it there. The choice is the maintainer's and is queued; nothing is implemented on it in the meantime.

Note also that under ADR-121 the routes this ticket wants to cover — a maintainer converting something they were told about — are exactly the ones with no committed cache record, so they fail closed and post nothing today. That is why STORY-093 carries an explicit fail-closed criterion rather than leaving the ambiguous-resolution case to the adapter.

## Dependencies

- **Composes with**: P363 (fix-released verdict leg — reopened), P270 (file-on-detect leg), P229 (verdict-shaped ack), P080 (outbound bidirectional update). This is the conversion-time leg of the same JTBD-301 close-the-loop family; the channel-agnostic abstraction argues for a standalone ticket.

## Related

- Inbound issue #347 — the source report, still unacknowledged. It is both this ticket's origin and its live reproduction.
- **Upstream report pending** -- false positive; detection misfire. The words "upstream" and "external" appear throughout the root cause because the subject matter is this project's own inbound/outbound machinery (`docs/problems/.upstream-cache.json`, `/wr-itil:update-upstream`). Every finding is internal to this repo's skills; nothing here needs reporting to anyone else.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-093 | STORY-093: Every conversion tells the reporter it landed | draft |
