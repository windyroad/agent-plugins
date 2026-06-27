# Problem 387: changeset-discipline Check 2b is plugin-scoped not change-scoped — plugin-source commits ship undocumented when a sibling changeset already targets the plugin

**Status**: Verifying
**Reported**: 2026-06-27
**Priority**: 9 (Medium) — Impact: 3 x Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-006
**Persona**: plugin-developer
**Release vehicle**: `.changeset/wr-itil-p387-change-scoped-changeset-check.md` → `@windyroad/itil` patch (pending next release)

## Description

The `itil-changeset-discipline.sh` hook's Check 2b (`changeset-detect.sh:277`) is **plugin-scoped**, not **change-scoped**: a commit that touches shippable code under `packages/<plugin>/...` PASSES the gate if ANY in-scope changeset targets that plugin — even a changeset authored for a *different* change. So a code change can ship to npm with no CHANGELOG record of its own, riding a sibling changeset's coattails.

Witnessed this session (2026-06-27): P164's Phase 2 octal-eval script-surface `10#` fix (`extract-risks-from-reports.sh`) shipped in `@windyroad/risk-scorer` 0.13.5/0.14.0 **undocumented** because it rode the P374 + RFC-029 changesets (both targeting risk-scorer) into the release. The gap was only caught when work-problems iter 1 re-worked P164 and authored the missing changeset retroactively (commit a91b8ed5, released as the 0.14.1 CHANGELOG record).

## Symptoms

- A commit changing `packages/<plugin>/{src,bin,hooks,skills,scripts,lib,agents}` passes Check 2b with no changeset describing THAT change, as long as some other in-scope changeset targets `<plugin>`.
- The change ships to npm with no CHANGELOG entry; adopters get behaviour with no documentation of it.

## Workaround

Manual vigilance — author a changeset per change. Retroactive CHANGELOG records (as P164 did) once the gap is noticed.

## Impact Assessment

- **Who is affected**: adopters reading CHANGELOGs to understand what shipped; maintainers auditing release provenance.
- **Frequency**: any commit whose plugin already has an unrelated changeset queued (common during multi-ticket sessions).
- **Severity**: undocumented behaviour ships; no functional break, but audit-trail/CHANGELOG fidelity degrades (JTBD-006 audit-trail expectation).

## Root Cause Analysis

Check 2b answers "does this plugin have a changeset?" not "does THIS change have a changeset covering its files?". The two diverge whenever a plugin carries ≥1 changeset for an unrelated change.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Tighten Check 2b in `changeset-detect.sh` to **change-scoped** — keyed on **linked work-item ID** (`P<NNN>`/`RFC-<NNN>`/`STORY-<NNN>`), NOT raw file intersection. Rationale: a changeset declares no file manifest, so file-set intersection would deny later same-slice commits that touch different files than the changeset-introducing commit (over-fire on legitimate ADR-014 batches). The commit's work-item ID (from the `git commit` command the hook already parses) is matched against each in-scope covering changeset's IDs (filename + body). Deny only on positive evidence of an unrelated sibling: commit cites an ID, every covering changeset cites ID(s), none overlap.
- [x] Weigh against the ADR-014 batch-grain tradeoff — resolved by allow-on-ambiguity: a ticket-less commit, a prose-only changeset, or an overlapping ID all ALLOW. Same-slice multi-commit batches share the slice's ticket, so one changeset still covers them; prose-only / adopter changesets that carry no ticket ref are never over-fired.
- [x] Behavioural bats: unrelated-sibling DENIES; same-ticket allows; ticket-less commit allows; prose-only changeset allows (4 fixtures added; full suite 48/48 green)
- [x] Decide canonical vs synced hook locus — `changeset-detect.sh` is NOT synced (single copy in `packages/itil/hooks/lib/`); edited in place, no sync script needed.

## Dependencies

- **Blocks**: CHANGELOG/release-provenance fidelity for multi-ticket sessions
- **Blocked by**: (none)
- **Composes with**: P141 (the changeset-discipline hook this refines — P141's original plugin-scoped Check 2b shipped; this is the change-scoped tightening), P164 (the witness: octal fix shipped undocumented under P374's changeset), ADR-014 (batch-grain tradeoff to weigh)

## Related

- **P141** (`docs/problems/verifying/141-afk-iter-changeset-discipline-enforcement-hook.md`) — the hook this tightens. P141's plugin-scoped enforcement shipped and is in verifying; this ticket is the change-scoped follow-on the user directed 2026-06-27 ("tighten to change-scoped") after the P164 undocumented-ship witness.
- **P164** (`docs/problems/verifying/164-...md`) — the concrete witness: Phase 2 fix shipped undocumented under P374's changeset.
- `packages/itil/hooks/lib/changeset-detect.sh:277` — Check 2b locus.
- User direction 2026-06-27 (work-problems session, AskUserQuestion): "Tighten to change-scoped."
