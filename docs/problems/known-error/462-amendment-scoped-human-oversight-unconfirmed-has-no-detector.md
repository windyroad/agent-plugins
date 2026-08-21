# Problem 462: Amendment-scoped `human-oversight: unconfirmed` has no detector — unratified amendment substance never reaches the oversight drain

**Status**: Known Error
**Reported**: 2026-07-26
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**WSJF**: 12 — (12 × 2.0) / 2 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

When an ADR is amended in-window (the established pattern for correcting a registry table or a
Decision Outcome clause without minting a new ADR), ADR-066's rule is that a mechanism
tightening does NOT clear the ADR's top-level `human-oversight` marker — only a change to the
Decision Outcome should. The house convention that follows from this, modelled verbatim at
`docs/decisions/024-cross-project-problem-reporting-contract.proposed.md:16`, is to scope the
unconfirmed-ness to the amendment paragraph in **prose**:

> this amendment's substance is `human-oversight: unconfirmed` — it does NOT re-stamp ADR-024's
> top-level `human-oversight` (which stays confirmed for the core contract), and a
> `category: direction` outstanding_question is queued for the next interactive drain

That convention is correct, and it is also **structurally invisible**. Nothing reads it.

`packages/architect/scripts/detect-unoversighted.sh` extracts the **frontmatter block only**
(lines 41-47: an awk that exits at the closing `---`) and then `continue`s — skipping the file
entirely — on `^human-oversight:[[:space:]]*confirmed`. An amended ADR correctly retains
`human-oversight: confirmed` at frontmatter level, so it is skipped, so it never appears in the
`/wr-architect:review-decisions` drain list or the SessionStart oversight nudge. The in-body
amendment marker has no reader.

The net effect: **amendment-level unratified substance has no oversight surface at all.** The
only thing carrying it to a human is the prose claim that a question "is queued" — which depends
entirely on the authoring agent also emitting that queue entry, and on someone reading the queue.
The decision quietly becomes de-facto ratified by nobody.

## Symptoms

- An ADR amended with `human-oversight: unconfirmed` prose does not appear in
  `/wr-architect:review-decisions` output, nor in the SessionStart unoversighted-count nudge.
- `wr-architect-is-decision-unconfirmed ADR-<NNN>` returns exit 1 (confirmed / OK to build on)
  for an ADR whose most recent amendment is explicitly unratified — so the ADR-074 / P315
  substance-confirm-before-build guard reads it as safe to build on.
- The unratified amendment is discoverable only by reading the ADR body, which is exactly the
  manual-vigilance path the oversight drain exists to replace.

## Workaround

Emit the ratification question into the AFK orchestrator's `outstanding_questions` queue (or
surface it interactively at once) at amendment time, and record the held/unratified state as an
unchecked Investigation Task on a WSJF-ranked problem ticket so the work-problems cadence
re-surfaces it. Both are authoring-time discipline, not detection — they fail silently if the
authoring agent skips them.

## Impact Assessment

- **Who is affected**: maintainers relying on the oversight drain to enumerate what still needs
  ratification; any agent using `wr-architect-is-decision-unconfirmed` as the ADR-074 build-guard
  predicate.
- **Frequency**: every in-window ADR amendment whose substance is genuinely new. ADR-014 carries
  four precedent amendment paragraphs and ADR-024 six, so the pattern is routine rather than rare;
  at least two amendments presently on disk declare unconfirmed substance in prose.
- **Severity**: High — this is the P348 hollow-marker class inverted. P348 was "a confirmed marker
  written without a confirm event"; this is "an unconfirmed marker written correctly that no
  detector can see". Both end with unratified substance treated as ratified.

## Root Cause Analysis

**Verified 2026-07-26** (during the P429 iteration, which amended both ADR-014 and ADR-024 and hit
this directly). `packages/architect/scripts/detect-unoversighted.sh`:

```sh
fm="$(awk '
  NR==1 && $0 != "---" { exit }
  NR==1 { next }
  /^---[[:space:]]*$/ { exit }
  { print }
' "$f")"

if printf '%s\n' "$fm" | grep -qiE '^human-oversight:[[:space:]]*confirmed[[:space:]]*$'; then
  continue
fi
```

The awk terminates at the closing frontmatter delimiter, so the body is never in `$fm`. The
grep then short-circuits the whole file. The detector is correct for its original contract
(whole-ADR oversight) and simply has no concept of amendment-level oversight.

### Investigation Tasks

- [ ] Decide the representation. The in-body prose marker is not machine-readable; a structured
      carrier is needed. Candidate shapes: a frontmatter `amendments-unconfirmed: [2026-07-26, ...]`
      array; a per-amendment HTML-comment marker the detector greps; or a distinct top-level value
      (e.g. `human-oversight: confirmed-with-unratified-amendments`) that the drain renders
      differently. This is a ≥2-option design decision — surface the substance before building
      (ADR-074).
- [ ] Extend `detect-unoversighted.sh` to emit amendment-level entries, distinguishable from
      whole-ADR entries so the drain can render "ADR-014 — amendment 2026-07-26 pending" rather
      than implying the whole ADR is unratified.
- [ ] Decide whether `wr-architect-is-decision-unconfirmed` (the ADR-074 build-guard predicate)
      should fire on an unratified amendment. It probably should when the dependent work builds on
      the amended clause specifically — but a blanket fire would block all work citing a
      long-amended ADR, which is the over-firing failure P132 warns about.
- [ ] Update `/wr-architect:review-decisions` to drain amendment-level items.
- [ ] Behavioural bats: an ADR with `human-oversight: confirmed` frontmatter AND an unratified
      amendment marker is reported by the detector; one with no such amendment is not.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P348 (iter subprocesses set `human-oversight: confirmed` without a confirm
  event) — the inverse failure at the same trust boundary. P357 (user direction is not substance
  ratification; brief-and-ratify after governance edits) — P357 mandates the post-change
  ratification that this ticket observes has no durable surface when the edit is an amendment.

## Related

- Captured via `/wr-itil:capture-problem` during the P429 iteration (2026-07-26), which amended
  ADR-014's commit-message registry and ADR-024 Step 8 and hit this gap directly. The
  `wr-risk-scorer:pipeline` agent independently flagged it while scoring that commit, verifying
  both that the outstanding_questions queue had no matching entry and that the detector is
  frontmatter-only.
- P310 (closed) — "RFCs carry independent decisions invisible to ADR-066 oversight" is the same
  class at a different surface: a decision-bearing artefact the oversight detector cannot see.
  Worth reading its resolution before picking a representation here.
- `docs/decisions/024-cross-project-problem-reporting-contract.proposed.md:16` — the canonical
  wording of the amendment-scoped-unconfirmed convention this ticket says is unreadable.
- `docs/decisions/066-human-oversight-marker-and-review-decisions-drain.proposed.md:61` — the rule
  that a mechanism tightening does not clear the top-level marker, which is what creates the gap.
- Duplicate-check (3-keyword title-only grep on `oversight` / `unconfirmed` / `detector`) matched
  16 filenames; all reviewed. The closest are P348 and P310 (both closed, both cited above as
  composing context) and P411 (open, but scoped to the risk register's pending-review entries, a
  different artefact tier). No open ticket absorbs this scope.
