# Governance Workflow — Archive (pre-2026-04-26)

Forward-chronology archive. Sibling: [`governance-workflow.md`](./governance-workflow.md) carries 2026-04-26 onward + foundational rules.

## What You Need to Know (archived 2026-05-17 — 2026-05-04 / 05 / 12 batch)

- **Meta-recursive bootstrap is acceptable when introducing framework primitives** — a new primitive's (RFC/lifecycle-stage/ADR-class) first artefact may live under the old structure pending Phase 1; acknowledge the recursion explicitly rather than papering over it. Soft-challenge signal: *"are these X or Y?"* on a list mixing two task classes — apply the structural split inline. <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-05-04 -->
- **`docs/risks/` is the persistent catalog of per-action risks, NOT a separate aggregation from `.risk-reports/`** — per-action assessments READ the catalog, filter to applicable risks, assess controls against the same 4/Low appetite, and append new risk classes back. No per-action-vs-lifetime distinction; same appetite uniformly. A catalog residual above appetite signals baseline controls are insufficient. <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-05-04 -->
- **Substantive ADR amendments after architect+JTBD reviews trigger a 3-pass review cycle on accept** — when ≥ 5 amendments land, the rename + status-flip re-fires the JTBD policy-changed gate (and the architect if a cited driver changed). Budget 3 passes for substantively-amended ADRs; light amendments (≤ 3 edits) usually skip it. <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-05-05 -->
- **Bootstrap-exemption marker is the canonical pattern for retroactive migration into a newly-introduced framework primitive** — new artefacts ship with `<!-- bootstrap-exempt: <scope> per <ADR> -->` inline with frontmatter to bypass runtime invariant gates (I7/I8/I9/I10 stories; I3/I4 story-maps) during one-time migration; non-bootstrap captures with the marker fail per behavioural test (ADR-060, ADR-053 precedent). <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-05-12 -->
- **Single-trailer vocabulary for story-tier commits**: `Refs: STORY-NNN` for BOTH capture and implementation commits; discrimination is on commit-subject prefix (`feat(itil): capture STORY-NNN ...` = capture), NOT trailer verb. Avoid the two-trailer split — it re-introduces parser-precedence complexity. Same shape for RFC-tier (`Refs: RFC-NNN`). ADR-060 + 2026-05-10 N2. <!-- signal-score: 0 | last-classified: 2026-05-25 | first-written: 2026-05-12 -->

## Rotated 2026-05-26 (Tier-3 split-by-date — oldest entries from governance-workflow.md)

### The human-oversight drain is a high-yield systematic-review pattern (2026-05-25)

The ADR-066 + ADR-068 oversight mechanism (`human-oversight: confirmed` marker + grep detector + session-start nudge + `/wr-architect:review-decisions` / `/wr-jtbd:confirm-jobs-and-personas` drains) surfaces systematic decision drift, not just bookkeeping. The 2026-05-25 drain confirmed ~37 ADRs and surfaced 13 reworks (1-in-3 hit rate) — auto-made governance artifacts drift from intent, and confirming them one-by-one is how you catch it. Two recurring drift themes, now user-stated principles: (1) automatic cadence over deferral/on-demand ("if there's no automatic cadence, it doesn't happen"); (2) adopter-facing content must be self-contained (no internal IDs / governance plumbing in published artifacts). Held ADRs awaiting rework stay unoversighted on purpose — don't write the marker until the rework lands and re-confirms.
<!-- signal-score: 2 | last-classified: 2026-05-25 | first-written: 2026-05-25 -->

### Slice-handoff stub markers preserve refactor seams across an RFC's lifecycle (2026-05-15)

When a slice ships a temporary stub a later slice replaces, mark it inline with an HTML comment naming the stub + the slice that owns the replacement (e.g. `<!-- SLICE-C-FLAG-STUB: ... Slice F owns proper parsing; remove when Slice F lands -->`). The marker makes the seam discoverable, lets the test surface assert stub-present (early slice) and stub-absent (later slice), and survives RFC-document edits because it lives in the runtime artefact. Architect-approved; reusable across any multi-slice RFC.
<!-- signal-score: 2 | last-classified: 2026-05-25 | first-written: 2026-05-15 -->

### ADR-against-SKILL numbering reconciliation via substring anchors (2026-05-15)

When an ADR is authored against a stale view of a SKILL's step numbering, do NOT mid-stream-amend the ADR for naming pedantry (violates ADR-006). Instead insert the new step at the current numbering's natural position AND preserve the ADR's substring anchors verbatim via an HTML comment marker, so `ADR-XXX § Confirmation criterion N` stays grep-anchorable without rewriting either document.
<!-- signal-score: 2 | last-classified: 2026-05-25 | first-written: 2026-05-15 -->

### R009 SKILL-prose-class above-appetite is the standing catalog baseline, not a per-action regression (2026-05-15)

The pipeline scorer flags R009 (functional defects in shipped behaviour) at 8/25 Medium on every SKILL/agent-prose ship — above the 4/Low appetite. This is the documented catalog baseline per RISK-POLICY.md § Risk Catalog clause 3. Per-action controls (architect + JTBD + external-comms PASS + bats coverage) suffice to proceed via acknowledged-residual + `BYPASS_RISK_GATE=1` citing clause 3. The R009 floor stays Medium until P012 master harness lands behavioural synthetic-channel coverage.
<!-- signal-score: 2 | last-classified: 2026-05-25 | first-written: 2026-05-15 -->

### Dual-tolerant flat + per-state-subdir enumeration must dedup on ticket ID, NOT basename (2026-05-26)

When widening a script to walk both the flat (`docs/problems/<NNN>-*.<state>.md`) and per-state-subdir (`docs/problems/<state>/<NNN>-*.md`) layouts per RFC-002 T4 / ADR-031, dedup on **ticket ID** (`${base%%-*}`), not basename — the subdir layout drops the `.<state>` suffix, so the same ticket has different basenames across layouts (`182-foo.open.md` vs `182-foo.md`) and a basename key double-counts. Per-state subdir wins (run its loop second). `reconcile-readme.sh` keys on ID for this reason; architect caught it on the P182 design pass. Verify any NEW dual-tolerant consumer keys on ID (existing ones — evaluate-graduation, update-jtbd-references, edit-gates — are correct).
<!-- signal-score: 0 | last-classified: 2026-05-26 | first-written: 2026-05-26 -->

## Rotated 2026-06-08 (Tier-3 split-by-date — older 2026-05-26 entries)

### Known Error semantics: root cause + workaround, NOT "fix ready" — the RFC/fix comes AFTER (2026-05-26)

A problem reaches **Known Error** when its **root cause is identified AND a workaround is documented** — there is no fix and no RFC yet (ADR-022 is the authority; it says Known Error = "root cause confirmed, fix not yet shipped"). Only *after* Known Error do you **propose a fix**, which is what **produces the RFC**. And `Fix Released` is **not** a separate state — releasing the fix **is** the `Known Error → Verifying` transition. So the lifecycle is `Open → Known Error → Verifying → Closed`. Consequence for any fix-time gate: the RFC is required at the **propose-fix step on a Known Error**, NOT at `Open → Known Error` (a problem gets to Known Error with no fix). I (and RFC-005 F1 → ADR-072) got this wrong — placed the gate at `Open → Known Error` on a "Known Error = fix is real" misreading; the oversight drain caught it, rework = P314. **Cite ADR-022 when reasoning about Known Error / fix-time placement** — the wrong-model placement landed precisely because ADR-022 wasn't referenced.
<!-- signal-score: 0 | last-classified: 2026-05-26 | first-written: 2026-05-26 -->

### reconcile-rfcs false-flags reverse-traces on per-state-subdir tickets — verify by inspection (2026-05-26)

`wr-itil-reconcile-rfcs docs/rfcs` emits spurious `MISSING_REVERSE_TRACE RFC-NNN in PNNN ## RFCs` for problem tickets that DO carry the reverse-trace, because its reverse-trace check globs the flat `docs/problems/*.md` only and misses the per-state subdirs (`open/`, `verifying/`, …) — the RFC-002-class dual-tolerant-glob gap already fixed in `update-problem-rfcs-section.sh`. Trust direct inspection of the ticket's `## RFCs` section (or the helper that renders it) over the reconciler's MISSING lines until fixed. Pre-existing rfcs-README rankings/closed drift (RFC-001/002/003/004) is separate + real. See **P312**.
<!-- signal-score: 0 | last-classified: 2026-05-26 | first-written: 2026-05-26 -->
