# Problem 439: External-review round-trips waste cycles on stale repo artifacts (unpushed commits + stale IDE buffer)

**Status**: Verification Pending
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#326)
**Effort**: M — re-rated from S on 2026-07-26 at the Known Error transition. The comparable prior is P438, re-rated S → M the same day for the same shape of work: design and ship a portable behavioural-rule surface whose plugin home is an open decision, with coverage as a prose eval rather than a bats gate. Nothing distinguishes this ticket's fix from that one on size, so S was an under-rate (ADR-026 comparable-prior grounding).
**WSJF**: 6.0 — (6 × 2.0) / 2, Known Error multiplier on M effort (re-rated 2026-07-26; was 6 — (6 × 1.0) / 1 as an Open S)
**JTBD**: JTBD-011 (re-anchored 2026-07-26 from the capture default JTBD-001 — see Related)
**Persona**: developer

## Description

When the user relays a repo artifact to an external reviewer, the assistant assumes the remote / IDE buffer the reviewer sees is current. With unpushed commits or a stale IDE buffer, the reviewer re-flags already-fixed issues, wasting round-trips. The assistant should proactively hand over the current committed content (SendUserFile + checksum, or offer to push) rather than assume freshness.

## Symptoms

- Reviewer repeatedly re-flags fixed issues because they're reading a stale copy; the assistant does not verify the reviewer's source is current before the round-trip.

## Impact Assessment

- **Who is affected**: the user, on external-review workflows.
- **Frequency**: any review round-trip with unpushed commits / stale buffer.
- **Severity**: Medium — wasted cycles; erodes trust in the review.

## Workaround

The user pushes before asking for the review, or pastes the current content into the review
thread themselves. Both work, and both put the burden on the person who was trying to delegate
the reading.

## Root Cause Analysis

**Confirmed by corpus read on 2026-07-26, not inferred.** A grep of `packages/*/hooks`,
`packages/*/skills`, `packages/*/agents`, `packages/*/lib` and `docs/decisions/` for any
statement of a handover-freshness rule — anything telling the agent to establish that an outside
reader can reach the content it is describing — returns nothing.

The corpus does carry unpushed-commit material, and it is the near-miss worth naming so a later
reader does not mistake it for coverage: P116 (closed), ADR-018, ADR-020 and the `risk-scorer`
agents all reason about local-only commits. Every one of them governs **the pipeline's** posture
toward unpushed work — which commit CI blames for a regression, whether a batch push is safe to
score. None governs **the agent's** posture toward a third party reading the repository. The
adjacency is why the gap survived: a keyword search for "unpushed" finds plenty and the absence
does not announce itself.

So the agent's assume-freshness default has no rule contradicting it anywhere on a surface the
agent reads. That is why in-conversation correction has never made it hold — the correction dies
with the session, and the next session's default is unchanged. This is the P423 class: a
correction that should govern the plugins or their adopters must land as a shipped surface,
never as project-local memory.

### Investigation Tasks

- [x] Establish whether any shipped surface states the rule — corpus read above. None does.
- [x] Distinguish the gap from the adjacent unpushed-commit material (P116 / ADR-018 / ADR-020 /
  risk-scorer) so the fix is not mis-scoped onto the pipeline surface.
- [x] Author the fix vehicle: RFC-053, STORY-050, and the "Current handovers" rib on
  STORY-MAP-007.
- [ ] Ratify STORY-050 at its `accepted` gate, and JTBD-011's sixth desired outcome alongside it
  — no AFK path; queued for the next interactive drain.
- [ ] Settle the mechanism ADR (which surface carries the rule, which plugin ships it) — shared
  with P438 and P445.
- [ ] Implement per STORY-050's acceptance criteria and land the promptfoo behavioural eval.

## Fix Strategy

Ship a portable, adopter-installed rule stating that before the assistant relays a repository
artefact to a party outside the session, it establishes that the recipient can reach the content
it is describing — by handing over the current committed content directly, or by naming what is
unpushed and offering to push — rather than assuming the recipient's copy is current. The
fix vehicle is **RFC-053**, carrying **STORY-050** on **STORY-MAP-007**'s "Current handovers"
rib.

Two properties are load-bearing and easy to lose:

- **The trigger is conditional, not standing.** The cheapest implementation is an unconditional
  per-prompt line, and that is the one JTBD-010's constraint rules out — governance injection
  already trades per-session verbosity against a weekly quota the developer cannot see ahead of
  time, and this behaviour fires on a minority of turns. A per-turn `git log origin..HEAD` probe
  is the same mistake in a more expensive form.
- **It must not over-swing.** A relay from a clean tree should complete without a freshness
  ceremony. Narrating a check the user did not need is the P445 failure mode wearing this
  ticket's clothes.

**Held pending ratification.** Two questions are deliberately open and blocked on a ratified ADR
per ADR-073: which surface carries the rule, and which plugin ships it — the latter is
substantive rather than mere placement, because under ADR-002 it decides who ever receives the
rule. Pinning either inside STORY-050's acceptance criteria would ratify it silently, which is
the build-on-then-rejected failure ADR-074 exists to prevent. Both are shared with P438 and
P445; one ADR settles all three, or states why they differ.

## Fix Released

Released in `@windyroad/itil@1.0.0` on 2026-08-13, via changeset `retire-afk-accept-carve-out.md`.

Awaiting user verification that the fix behaves as intended in the installed package.

## Dependencies

- **Composes with**: P116 (unpushed-commit CI blame — distinct surface: reviewer stale-copy vs
  CI), P438 and P445 (sibling portable-conduct-rule instances under the same job and map,
  blocked on the same mechanism ADR).

## Related

- Inbound issue #326.
- **JTBD re-anchor (2026-07-26)**: moved from the capture default **JTBD-001** (Enforce
  Governance Without Slowing Down) to **JTBD-011** (Have a Correction to the Agent's Conduct
  Hold Everywhere), on the JTBD gate's ruling. JTBD-001's four desired outcomes are all
  per-edit-review-shaped and this ticket involves no edit and no gate. JTBD-202 (Run Pre-Flight
  Governance Checks Before Release or Handover) was the one competing home its title suggests
  and does not fit: it is a tech-lead job about running an on-demand assessment before work
  leaves your control, not about the freshness of the copy a third party is reading. JTBD-011
  gained a sixth desired outcome in the same commit, covering third-party handover freshness —
  without it this ticket would have been the only grounding instance with no outcome measuring
  its own fix.
- **P423** — the master class this ticket belongs to.
- **RFC-053** (fix vehicle), **STORY-050** (the story), **STORY-MAP-007** (the map).
- **Upstream report pending** -- false positive; detection misfire. The P063 scan matches
  "external" throughout this ticket, but the word describes the *reviewer* who reads our
  repository, not an external root cause. The root cause is a rule missing from our own shipped
  surfaces, and #326 is an inbound report to us — there is no upstream party to report to.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-053 | proposed | Ship a portable rule requiring a verified-current handover before an external-review round-trip |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-050 | STORY-050: Have my reviewer read the version I actually have | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
