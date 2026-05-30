# Retro — work-problems iter 8 (P281 K→V)

Date: 2026-05-30
Iter: 8
Scope: P281 (`capture-problem` SKILL template references pre-ADR-031 flat-path shape) Known Error → Verifying lifecycle transition per ADR-022
Session role: AFK iteration-worker subprocess (`claude -p` per P086)
Orchestrator: `/wr-itil:work-problems`

## What changed this iter

- `docs/problems/known-error/281-...md` → `docs/problems/verifying/281-...md` (per-state-subdir rename per ADR-031).
- Ticket Status: `Known Error` → `Verifying`.
- Ticket body: appended `## Fix Released` section with full `wr-itil-derive-release-vehicle P281` citation block — third real-world dogfood of the helper after P267 (iter-2) and P316 (iter-5).
- `docs/problems/README.md`: P281 WSJF Rankings row removed; Verification Queue row inserted at Released-ASC tiebreak position between P267 (ID 267) and P282 (ID 282).
- `packages/itil/scripts/reconcile-readme.sh` exits 0 post-edit (no drift).
- Single commit landed: `c8455c5` (`chore(itil): transition P281 Known Error → Verifying per ADR-022`).

## Pipeline Instability (Step 2b)

### Helper-UX gap (Category 2: Skill-contract violation)

**Signal**: `wr-itil-derive-release-vehicle <ticket-id>` exits 2 (`no .changeset/<name>.md reference in <ticket-file>`) when the ticket body does not yet carry a changeset reference. Observed this iter:

- Initial probe: `packages/itil/bin/wr-itil-derive-release-vehicle P281` → `exit=2`.
- Resolution: inline-edit the ticket's Root Cause Analysis "Fix shipped this iter" bullet to add `.changeset/p281-capture-problem-skill-path-template.md`. Re-run: exit 0, citation emitted.

**Class-of-behaviour**: the helper's contract assumes the changeset reference is already on the ticket BEFORE the K→V transition runs. But the K→V transition itself is typically the surface that writes the `## Fix Released` section carrying the citation — so for a clean iter-N fix → iter-N+1 K→V cycle, the reference isn't there until the K→V edit lands. The current contract forces a pre-edit pass to seed the reference, then the helper, then the citation edit. That's three-touch where one-touch would suffice (e.g. helper accepting a `--changeset <name>` flag for first-K→V cases, OR `manage-problem` Step N inserting the changeset reference inline at fix-ship time as part of `Fix Shipped: <date>` shape).

**Citations**:
- Bash: `packages/itil/bin/wr-itil-derive-release-vehicle P281 2>&1` returned `ERROR: no .changeset/<name>.md reference in docs/problems/known-error/281-...md` (helper script line 109 in `packages/itil/scripts/derive-release-vehicle.sh`).
- Edit: added `- Changeset: ` line to the ticket's `## Root Cause Analysis` "Fix shipped this iter" bullet at line 65 of the source-state ticket.
- Re-run: `packages/itil/bin/wr-itil-derive-release-vehicle P281` returned the full RELEASE_VEHICLE block (release-date 2026-05-30, PR #177, version-packages commit 63d5bd6, merge commit a7d47b9).

**Category**: Skill-contract violation (helper-contract surface) + minor Repeat-work friction (pre-edit-before-helper applied across all three K→V dogfoods this session — iter-2 P267 had the reference baked in via prior session work, iter-5 P316 and iter-8 P281 both needed the inline edit).

**Decision**: queued to `outstanding_questions` for orchestrator pickup (`cause: skill_unavailable` — capture-* skills carved out for AFK per ADR-032; manage-problem-mid-iter is heavier than the iter scope warrants).

**Dedup**: no existing ticket. P267 itself codified the helper but did not anticipate the changeset-reference-precedence question (P267 ticket body covers helper contract + first-dogfood validation; this is a downstream UX gap surfaced by the second + third dogfoods).

### README inventory currency (advisory, ADR-069)

Did not invoke `wr-retrospective-check-readme-jtbd-currency` this iter — iter scope was metadata bookkeeping, not skill-inventory affecting. Existing skill-inventory drift (if any) is the orchestrator-end retro's surface, not the iter retro's.

## Ask Hygiene (Step 2d / ADR-044)

See `docs/retros/2026-05-30-work-problems-iter8-p281-kv-ask-hygiene.md`. **Lazy count: 0** (no AskUserQuestion fired this iter; iter scope was framework-resolved end-to-end).

## Verification Candidates (Step 4a)

Did not run sub-step 9 (prior-session evidence drain) — iter scope is orchestrator-directed single-ticket K→V; cross-session evidence drain is the orchestrator-end retro's surface (134 KB Verification Queue exceeds the iter retro's budget per P282 evidence).

## Codification Candidates (Step 4b Stage 2)

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| improve | skill or script | `packages/itil/scripts/derive-release-vehicle.sh` + `/wr-itil:manage-problem` Step N "Fix Shipped" inline insert | helper-contract assumes changeset reference is already on ticket before K→V; K→V is typically the edit that adds it | 3 of 3 K→V dogfoods this session needed pre-edit-then-helper-then-citation-edit (P267 inherited the reference from prior session work; P316 + P281 needed the inline edit) | Stage 1 ticketing deferred — `cause: skill_unavailable` (AFK ADR-032 carve-out on capture-*); queued to ITERATION_SUMMARY.outstanding_questions for orchestrator-end Stage 1 |

## Briefing Changes

None this iter — no briefing-tree edits warranted by a narrow K→V lifecycle iter. Tier 3 budget pass + signal-vs-noise scoring would consume far more context than the iter's primary work; both are orchestrator-end retro surface.

## Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| `wr-itil-derive-release-vehicle` requires pre-existing `.changeset/<name>.md` reference in ticket body before K→V; reference often only added by the K→V transition itself (3rd dogfood evidence) | `skill_unavailable` (AFK ADR-032 capture-* carve-out per orchestrator constraint) | Step 2b helper-UX-gap signal, this retro |

## No Action Needed

- ADR-022 K→V workflow held end-to-end without amendment.
- ADR-014 single-commit grain held (one commit, `c8455c5`).
- reconcile-readme P062 contract held (exit 0 post-edit).
- Helper deterministic citation correctly named PR #177, version-packages commit 63d5bd6, merge commit a7d47b9, release-date 2026-05-30 — matches `git log` ground truth.
