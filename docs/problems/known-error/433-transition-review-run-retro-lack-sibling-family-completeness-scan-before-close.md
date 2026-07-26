# Problem 433: transition-problem / review-problems / run-retro Step 4a lack a sibling-family completeness scan before close

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#187)
**Effort**: L. WSJF = (12 × 2.0) / 4 = 6.0.
**WSJF**: 6 — (12 × 2.0) / 4 (re-rated 2026-07-26 at the Known Error transition: M → L per P047. The
creation-time M assumed a single-surface edit. The confirmed root cause spans a new script + its ADR-049
`$PATH` shim + behavioural bats + three call sites, one of which lives in a second plugin
(`packages/retrospective`), so it is no longer a "few files, moderate change".)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The close paths (`transition-problem`, `review-problems`, `run-retro` Step 4a) do not scan for open / known-error sibling tickets in the same friction-class / Composes-with family before allowing a close. A ticket closes while related siblings that should close (or be re-linked) with it are left stranded, and vice-versa.

## Symptoms

- A ticket is closed on evidence, but sibling tickets covering the same class remain open with no prompt, or a close proceeds without noticing an overlapping sibling that changes the picture.

## Impact Assessment

- **Who is affected**: maintainer; backlog drifts as sibling families fall out of sync at close time.
- **Frequency**: any close with an open sibling family (common in this corpus).
- **Severity**: High — silent family drift; the highest-priority of the newly-triaged set.

## Root Cause Analysis

**Confirmed 2026-07-26.** The close-gate pre-flight contract on every close path is expressed as a
**per-ticket** invariant list. There is no **family-level** invariant, and the family-edge data that
would feed one has no mechanical consumer anywhere in the codebase.

Two independent legs of evidence:

**Leg 1 — the close gates only ever look at the ticket in hand.**

- `/wr-itil:transition-problem` Step 4 `Verification Pending → Closed` carries exactly ONE pre-flight
  checkbox: *"The user has explicitly confirmed the fix works in production"*. Nothing reads any other
  ticket.
- The same skill's `Known Error → Verification Pending` pre-flight DOES carry a body-scanning gate —
  the P184 conditional-deferral check (grep the body for `^### (Phase|Slice|Tier) N` sections, resolve
  whether each named gating condition has lifted, halt-or-surface). That is the exact shape this ticket
  wants, but its axis is **intra-ticket** (this ticket's own deferred phases), never **inter-ticket**.
- `/wr-itil:review-problems` Step 4 Bucket 1 (close-on-evidence) and Step 4.6 (ADR-079 relevance-close)
  each perform their own `git mv` to `closed/` — they do NOT dispatch through `transition-problem`, so a
  gate added only there would miss them. Their pre-close checks read the closing ticket's `Likely
  verified?` cell / relevance-evidence shapes and nothing else.
- `/wr-retrospective:run-retro` Step 4a categorises `.verifying.md` tickets on in-session citations, then
  dispatches `/wr-itil:transition-problem <NNN> close`. Its evidence scan is likewise single-ticket.

**Leg 2 — the family graph exists on disk and has zero consumers.**

- 212 `**Composes with**:` edges are authored across `docs/problems/{open,known-error,verifying}/`. The
  `## Dependencies` section shape is defined in the manage-problem Step 5 ticket template, so the data is
  structured, not incidental.
- `grep -rn "Composes with\|Blocked by" packages/*/scripts/*.sh packages/*/lib/*.sh packages/*/hooks/*.sh`
  returns **two hits, both prose comments** (`check-rfc-stories-ratified.sh:9`,
  `enumerate-postrelease-kv-candidates.sh:13`). No script parses the dependency graph. Even the
  `**Blocked by**` transitive-effort rule (P076, manage-problem SKILL.md § Transitive dependencies) is
  agent-read prose with no committed implementation.
- Measured blast radius: **29 close events** in `docs/problems/closed/` name a `**Composes with**` sibling
  that is *still* in `open/` or `known-error/` today (e.g. P097/P099/P100/P101/P107 all closed naming
  P091, still open; P106/P112/P120 closed naming P045, still open). A stranded sibling is not by itself
  wrong — a close can legitimately proceed with family work outstanding — but in all 29 the edge was
  never surfaced at the close, so no one made that call.

**One-line root cause**: the family-edge data is authored for humans and read by nobody; the close gates
enforce per-ticket invariants only, so there is no point in the lifecycle at which an open sibling can
influence, or even be visible to, a close decision.

### Investigation Tasks

- [x] Confirm the close-gate pre-flight contracts are per-ticket only — read `transition-problem` Step 4,
      `review-problems` Step 4 Bucket 1 + Step 4.6, `run-retro` Step 4a.
- [x] Confirm the `**Composes with**` graph has no mechanical consumer — grep all plugin scripts/lib/hooks.
- [x] Measure the blast radius — 29 stranded family edges across already-closed tickets.
- [ ] Ship the scan + wire it into the three close paths (held at the ADR-096 story-ratification wall; see
      Fix Strategy).

## Workaround

Before closing any ticket, run the family scan by hand and read the result:

```bash
# forward edges — siblings this ticket names
grep -o '\*\*Composes with\*\*.*' docs/problems/*/<NNN>-*.md | grep -oE 'P[0-9]{3}'
# reverse edges — siblings that name this ticket
grep -rlE '\*\*Composes with\*\*.*P<NNN>' docs/problems/open docs/problems/known-error
```

Any hit still living under `open/` or `known-error/` is a family member that will be stranded by the
close. Decide explicitly whether it closes with this ticket, gets re-linked, or is knowingly left open —
then proceed. This is exactly the manual policing the fix automates.

## Fix Strategy

**Mechanism** — one advisory script, three one-line call sites:

1. `packages/itil/scripts/scan-sibling-family.sh` + a `wr-itil-scan-sibling-family <problem-file>` `$PATH`
   shim per ADR-049 (never repo-relative from a SKILL — P151/P153/P219/P317 class). Given a ticket file it
   emits one line per still-actionable family member: **forward** edges (P-refs on this ticket's
   `**Composes with**` line) plus **reverse** edges (tickets whose `**Composes with**` line names this
   PID), filtered to those currently under `open/` or `known-error/`.
2. Siblings under `verifying/`, `parked/`, or `closed/` contribute nothing — mirroring the already-ratified
   upstream-status carve-out in the P076 transitive-effort rule, where closed/verifying/parked upstreams
   contribute 0.
3. **Exit 0 always.** The scan surfaces, it never blocks. This is the AFK-safety requirement (an
   orchestrated close must not halt on an advisory) and it is what keeps the mechanism outside ADR-013
   Rule 6's halt-and-route class.
4. Call sites: `transition-problem` Step 4 (`close` pre-flight), `review-problems` Step 4 Bucket 1 +
   Step 4.6 (before each `git mv` to `closed/`), `run-retro` Step 4a (before the dispatch). Output rides
   the existing close report / retro summary — no new surface.
5. Behavioural bats per ADR-052 / P081: drive the script against fixture ticket trees and assert on its
   emitted lines (forward-only, reverse-only, both, sibling-in-verifying-suppressed, no-edges-silent).
   No structural grep of SKILL.md prose.

**Why Composes-with edges and not friction-class keyword overlap.** The ticket as filed names both
signals. The edge scan is Phase 1 and the keyword scan is Phase 2, deliberately deferred rather than
dropped, for two reasons: (a) 212 authored edges already exist, so the deterministic half has real
coverage on day one; (b) inferring a "friction class" from keyword overlap is precisely the over-firing
failure mode P463 records against the relevance-close evaluator (a citation read as a fix-shipped signal).
Landing an inferential scan on a close gate before the deterministic one has proven insufficient would
re-run that mistake at a higher-stakes surface. Phase 2 ships when Phase 1's miss rate is observed, not
on speculation. **This is a scope split the maintainer has not ratified** — queued as a design question,
see below.

**Held at the ADR-096 wall.** The fix is a code change (script + shim + SKILL wiring), so it requires a
story at `accepted`, and story ratification has no AFK path. This iteration authors the fix vehicle and
stops short of implementation.

## Dependencies

- **Composes with**: P076 (transitive-dependency WSJF — the sibling half of the same unread dependency
  graph. P076 wants `**Blocked by**` edges to propagate effort into WSJF; this ticket wants
  `**Composes with**` edges to surface at close. Same `## Dependencies` section, same "authored but never
  parsed" root cause, different consumer. A parser shipped for either should be shaped so the other can
  reuse it.)
- **Composes with**: P463 (relevance-close evaluator over-fires, reading a citation as a fix-shipped
  signal — the cautionary precedent that keeps this ticket's Phase 1 deterministic and defers the
  inferential keyword half to Phase 2).
- **Composes with**: P346 / RFC-013 Phase 3 (`wr-itil:hang-off-check`) — the inflow-side twin. Hang-off-check
  answers "does this new capture belong inside an existing ticket?" at **capture** time via a mechanical
  shared-signal pre-filter feeding a fresh-context arbiter; this ticket answers "does this family still
  hold together?" at **close** time. Same family-signal question at opposite ends of the lifecycle. If the
  Phase 2 keyword half ever ships, its pre-filter should be the hang-off-check pre-filter, not a second
  implementation.

## Related

- Inbound issue #187.
- `/wr-itil:transition-problem` SKILL.md § "Conditional-deferral check on K→V (P184)" — the shape precedent.
  A body-scanning pre-flight gate that halts-or-surfaces already exists and is ratified; this ticket adds a
  second axis to that pattern rather than inventing a new gate class.
