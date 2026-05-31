---
status: "proposed"
date: 2026-05-31
decision-makers: [unspecified — fill at canonical review]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-08-31
---

# Evidence-based relevance-close pass for the problem backlog (Phase 1: file-no-longer-exists; Phase 2: ADR-shipped-confirmed + named-skill-exists + self-marker-in-body + driver-child-closed + Phase 1 false-positive fixes)

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032 P156 amendment). Run /wr-architect:create-adr on this ID to expand the deferred sections canonically. Substance pinned by user direction 2026-05-31 verbatim (see Context). **Confirm-every-ADR gate (ADR-064)**: this ADR is recorded `proposed` with a pre-pinned decision but WITHOUT human review of the alternatives — MUST NOT be promoted to `accepted` until it has been through a `/wr-architect:create-adr` (or equivalent) `AskUserQuestion` review-and-confirm pass; `human-oversight:` frontmatter intentionally absent until then per ADR-066 line 50.

## Context and Problem Statement

The `/wr-itil:review-problems` skill has no path to close tickets that have become **no longer relevant**. Today's only closure paths are (a) ship a fix → Verifying → Closed, (b) Park (upstream/external block), or (c) no path at all for "this isn't worth doing anymore", "duplicates X", "the thing it's about no longer exists in the codebase". The result is a structural outflow gap: capture is automatic and cheap (P078 capture-on-correction, P342 retro auto-capture, ADR-062 inbound discovery, agent-observed mid-iter friction) while close requires real work + budget. The system is structurally guaranteed to grow ticket counts over time — captured in P346 with concrete trajectory data (47 days, 345 tickets, +2.82/day Active, no zero ETA).

User direction (verbatim, 2026-05-31): *"Ok, I'm happy for a skill executed as part of review problems that closes tickets that are no longer relevant, but not just because they are old"*.

This direction pins two hard constraints: (1) the relevance-close pass MUST execute as part of `/wr-itil:review-problems`, NOT as a standalone skill — composes with the WSJF re-rank flow; (2) the relevance signal MUST be observable per ADR-026 grounding — age may be a *gating* condition (don't bother evaluating fresh tickets) but never the *closing* condition.

## Decision Drivers

- **User direction 2026-05-31** (verbatim above) — primary driver; pins both constraints.
- **ADR-026 (Agent output grounding)** — every close decision must satisfy cite + persist + uncertainty. Age-based heuristics ("> 30 days" alone) FAIL this contract; observable evidence (file existence, git-grep verdict) PASSES.
- **ADR-022 (Verification Pending lifecycle)** — extended (not modified) by this ADR. The lifecycle today is Open → Known Error → Verifying → Closed; this ADR adds a sanctioned non-linear transition Open|Known Error → Closed-with-reason that bypasses Verifying when no fix was released. Precedent for the extend-not-modify pattern: ADR-026 line 109 extends ADR-022 with `Actual Effort:` field without modifying lifecycle mechanics.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — under-60s review-flow served by smaller queue.
- **JTBD-006 (Progress the Backlog While I'm Away)** — AFK pre-flight surface extension; mechanical evidence is NOT judgment-call.
- **JTBD-101 (Extend the Suite with Clear Patterns)** — Phase 1 = ONE evidence shape per slice; each future shape gets its own bats fixture + verdict line.
- **JTBD-201 (Restore Service Fast with an Audit Trail)** — `## Closed as no longer relevant` section preserves audit trail; reversible via `git revert`.
- **P334 / P336 close-on-evidence precedent** — the close pattern is already proven for a sub-class of "no longer relevant" (the fix shipped without the lifecycle close); this ADR generalises it to the broader "no-fix-needed" class.

## Considered Options

1. **Option A (chosen)** — Phase 1 auto-close on ONE evidence shape: "file no longer exists in codebase". A new Step 4.6 in `/wr-itil:review-problems` SKILL.md invokes the canonical evaluator script (`packages/itil/scripts/evaluate-relevance.sh` via the ADR-049 PATH shim `wr-itil-evaluate-relevance`). The script extracts file-path references from each `.open.md` / `.known-error.md` ticket body matching well-known repo subdirs `(packages|docs|.changeset|src|test|scripts)/...\.(md|sh|ts|tsx|js|jsx|json|yml|yaml|bats|py|txt|html)`, excludes self-references (`docs/problems/*`), and runs `git ls-files --error-unmatch` on each. A `CLOSE-CANDIDATE` verdict fires when ALL extracted paths return zero AND at least one was extracted AND the ticket is ≥ 7 days old. The auto-close action writes a `## Closed as no longer relevant` section (evidence shape + closed-on date + paths checked + reversibility clause per ADR-026 cite+persist+uncertainty) then `git mv` Open/Known Error directly to Closed (bypassing Verifying — no fix was released). All relevance-closes from one review pass batch into ONE commit per ADR-014 (mirroring `/wr-itil:transition-problems` P139 batch grain).
2. (deferred — see /wr-architect:create-adr canonical review for full taxonomy: surface-with-options interactive variant; per-evidence-shape cadence; closed-ticket reopen surface; alternative path-extraction regexes; alternative age-gate thresholds)

## Decision Outcome

Chosen option: **"Option A — Phase 1 auto-close on file-no-longer-exists evidence shape"**, because the file-existence signal is the most mechanical and highest-confidence of the candidate shapes (closest analog to P334/P336 evidence-close), the audit-trail contract is fixed (ADR-026 cite+persist+uncertainty), and the implementation is contained to one iter without sinking unbounded design effort. Subsequent evidence shapes (ADR-supersession, duplicate-of-X, "concern no longer concerning", SKILL-contract-superseded, incidentally-fixed-by-unrelated-commit) are deferred to sibling tickets — each shape gets its own bats fixture + its own verdict-line extension to the same script without re-design.

This is an **ADR-022 extension (not modification)** mirroring ADR-026 line 109's precedent — the lifecycle table in `/wr-itil:manage-problem` SKILL.md gains a row for the new Open|Known Error → Closed-with-reason transition; ADR-022's status-transition mechanics for Open / Known Error / Verifying / Closed remain unchanged.

## Phase 2 — Considered Options (2026-05-31, additive)

Phase 2 is the canonical-review expansion the Phase 1 `Considered Options` line 2 (`(deferred — see /wr-architect:create-adr canonical review for full taxonomy)`) anticipated. Phase 1 Option A and its pinned decision **remain unchanged**; Phase 2 rides as additive new-shape options that share the same script (`packages/itil/scripts/evaluate-relevance.sh`), the same PATH shim (ADR-049 `wr-itil-evaluate-relevance`), the same lifecycle bypass (ADR-022 extension already landed), the same audit-section contract (ADR-026 cite + persist + uncertainty), the same commit grain (ADR-014 batch), the same AFK silent-proceed disposition (ADR-013 Rule 5 + ADR-044 category 4).

**Empirical grounding (ADR-026)** — the 2026-05-31 foreground relevance-scan executed 5 batches of close-on-evidence transitions; 14 tickets closed across 4 evidence shapes Phase 1 does NOT implement. Each closure body carries a `## Closed as no longer relevant` section with the cited evidence shape. The labeled fixture set IS the regression suite per ADR-052:

| Shape | Phase | Empirical closes (2026-05-31) | Mechanical check |
|---|---|---|---|
| 1. file-no-longer-exists | Phase 1 (shipped) | 0 of 14 | grep ticket body for `(packages\|docs\|...)/...\.(md\|sh\|...)`; verify each via `git ls-files --error-unmatch` |
| 2. ADR-shipped-with-`human-oversight: confirmed` | Phase 2 | 8 — P012/P015/P018/P022/P033/P039/P194/P292 | grep ticket body for `ADR-NNN`; for each, verify `docs/decisions/<NNN>-*.md` exists AND frontmatter has `human-oversight: confirmed` |
| 3. named-skill-or-feature-exists | Phase 2 | 6 — P014/P034/P045/P079/P190/P289 | grep for `packages/<plugin>/skills/<name>/SKILL.md`, `packages/<plugin>/hooks/<hook>.sh`, `packages/<plugin>/agents/<agent>.md`, `/wr-<plugin>:<skill>` slash-command refs; verify each via `git ls-files` |
| 4. self-marker-in-body | Phase 2 | explicit in P289 (`Close to Verifying`); contributory in P033 (`Fix Released`) and others | grep for line-anchored literals: `^.*Close to (Verifying\|Closed)\b`, `^.*DONE 2026-`, `^## Fix Released`, `^.*fix shipped session`, `^.*awaiting K→V`. Pattern MUST anchor to line-start or markdown-boundary to avoid mid-prose false-positives (per architect review advisory A2 of this ADR amendment). |
| 5. driver-child-ticket-closed | Phase 2 | contributory in several closes (e.g. P014 cites closed P155 driver) | parse `## Related` section for `P<NNN>` references; check if any are in `docs/problems/closed/` (dual-tolerant: per-state subdir OR `.closed.md` suffix). KEEP if child has independent open investigation items (negative fixture; per architect review advisory A1). |

**Phase 1 false-positive fixes** — the Phase 1 iter-4 smoke test surfaced 5 CLOSE-CANDIDATEs of which 3 were false-positives with diagnosable causes. The fixes are Phase 2-scope because they require new evidence shapes (sibling detection / rename detection / state-suffix detection) the current script does not check:

- **P180 fix — state-suffix detection.** Before declaring an incident / problem / RFC file gone, check per-state subdirs (`open|known-error|verifying|closed|parked` for problems; `investigating|mitigating|restored` for incidents) AND `.<state>.md` suffix variants (RFC-002 migration window). If a state-suffix variant exists → KEEP-WITH-NOTE, not CLOSE-CANDIDATE.
- **P244 fix — sibling-file detection.** Dir-glob the parent dir; if any file with a similar slug-prefix exists (e.g. ticket cites `plugin-maturity-list.sh` and dir contains `plugin-maturity-render.sh` + `plugin-maturity-populate.sh`), the work likely shipped under a different filename within the same dir → KEEP-WITH-NOTE.
- **P251 fix — rename detection.** Use `git log --follow --diff-filter=AD --name-only -- <path>` to detect renames. If the file was renamed (Add+Delete pair on a different path) → KEEP-WITH-NOTE.

**Output extension** — Phase 2 adds two verdict shapes:

- `CLOSE-CANDIDATE-WITH-CAVEAT <basename> — shapes: <comma-joined-list> — caveat: <short-tag>: <one-line-prose>` — partial-scope umbrella case where the close-evidence is real but a documented caveat applies (e.g. P039 shared-template-not-built caveat; P194 deep-dive-bloat-remains caveat). The caveat is structured (short-tag + one-line) so the SKILL Step 4.6b template can splice it directly into the `## Closed as no longer relevant` audit section as a separate **Caveat** field, preserving ADR-026 uncertainty leg structurally (per architect review condition C2).
- `KEEP-WITH-NOTE <basename> — <note>: <evidence>` — Phase 1 false-positive class (state-suffix, sibling-file, rename detected); the verdict reroutes the candidate from "auto-close" to "log only" with the surfaced false-positive cause.

The base `CLOSE-CANDIDATE` verdict also extends — multiple matching shapes emit cumulatively per ADR-026 cite+persist+uncertainty (corroborating evidence is stronger than first-match-wins):

```
CLOSE-CANDIDATE <basename> — shapes: <comma-joined-list> — <per-shape-cite>; <per-shape-cite>; ...
```

The `## Closed as no longer relevant` template's **Evidence shape** field accepts the comma-joined list verbatim. The labeled fixtures empirically show multi-shape matches (e.g. P033 = shape 2 + shape 4; P289 = shape 3 + shape 4).

### Phase 2 Considered Options (enumerated)

1. **Option B (chosen)** — extend the same script with shapes 2-5 + the Phase 1 false-positive fixes + the cumulative + caveat verdict shapes + KEEP-WITH-NOTE. Add one bats fixture per shape (calibrated against the 14-fixture labeled set) plus negative fixtures per the architect advisories A1 (driver-closed + child-independent-work) and A2 (self-marker mid-prose). Update the `/wr-itil:review-problems` Step 4.6 SKILL prose to document the 5 shapes + the surface-batch-confirm flow the foreground scan demonstrated. Update the `/wr-itil:manage-problem` lifecycle-table row (line 59) cited-shape list to reflect Phase 1+2. Single `@windyroad/itil` minor changeset (feature work; not a fix).
2. (deferred — see /wr-architect:create-adr canonical review for additional shapes: ADR-supersession (the ticket's named ADR is `.superseded.md`); duplicate-of-X (semantic-comparator hit against another open ticket); concern-no-longer-concerning (the user direction the ticket captured has been reversed by a subsequent direction); test-passes-without-issue (the reproduction test from the ticket has been green for ≥30 days).)

## Phase 2 — Decision Outcome (2026-05-31, additive)

Chosen option: **"Option B — extend Phase 1 to 4 more evidence shapes + Phase 1 false-positive fix + cumulative + caveat verdict shapes"**, because:

- **Empirical grounding (ADR-026)** — the 14-fixture labeled set from the 2026-05-31 foreground relevance-scan IS the regression suite. Each shape is grounded in concrete observable closes that worked: shape 2 covers 8 of 14, shape 3 covers 6 of 14, shape 4 explicit in 1 + contributory in others, shape 5 contributory in several. Phase 1's file-no-longer-exists shape covered 0 of 14 — the shipped shape is necessary but not sufficient.
- **Mechanical-stage carve-out preserved (P132 / ADR-044 category 4)** — every new shape is a deterministic check: file existence + frontmatter scan + line-anchored grep. No user judgement is involved; AFK silent-proceed is correctly invoked per ADR-013 Rule 5.
- **Lifecycle bypass already extended in Phase 1** — `/wr-itil:manage-problem` SKILL.md line 59 already names the bypass generically; Phase 2 broadens the cited shape list (1 → 5 shapes) without adding a new lifecycle transition.
- **Cumulative shape annotation strictly stronger than first-match-wins** — preserves ADR-026 cite+persist+uncertainty by recording all matching evidence shapes; downstream tooling (the SKILL Step 4.6b template) reads the comma-joined list verbatim.
- **CLOSE-CANDIDATE-WITH-CAVEAT structured output** — partial-scope umbrellas (e.g. multi-phase ADR with some phases done, some outstanding) emit a structured caveat the maintainer's confirmation step can read mechanically; this preserves the "no silent-proceed on ambiguity" invariant from JTBD-006 ("Problems requiring my judgment ... are queued for my return, not guessed at"). The caveat short-tag enumeration starts with: `shared-template-not-built` (P039 class), `deep-dive-bloat-remains` (P194 class), `multi-phase-mixed-progress` (P136 class), `structural-follow-on-tracked-separately` (P190 class).
- **Phase 1 false-positive fixes addressed in-place** — the iter-4 smoke test's 60% false-positive rate is structurally diagnosed (state-suffix / sibling-file / rename), not punted. Each fix has a labeled false-positive case (P180/P244/P251) that bats pins as a regression test.
- **`human-oversight:` marker absence preserved (ADR-066)** — Phase 2 does NOT add `human-oversight: confirmed`. The orchestrator-level `/wr-architect:review-decisions` drain ratifies Phase 1 + Phase 2 together later; the build-upon guard (ADR-074) is satisfied by the user direction 2026-05-31 verbatim "Amend the ADR and the implementation" pinning the substance.

The Phase 1 Option A pinned decision remains unchanged. Phase 2 is strictly additive; existing adopters who haven't refreshed the marketplace cache continue running Phase 1 with no behavioural drift. Phase 1+2 ships in a single `@windyroad/itil` minor release per ADR-018's lean release principle (presence of releasable material within appetite is the trigger, not residual band).

## Consequences

### Good

- (deferred to /wr-architect:create-adr canonical review — preliminary: queue truthfulness improves; under-60s review-flow restored; backlog trajectory has a structural outflow path; audit trail preserved per ADR-026; reversible per `git revert`)

### Neutral

- (deferred to /wr-architect:create-adr canonical review)

### Bad

- (deferred to /wr-architect:create-adr canonical review — preliminary: false positives possible on tickets whose paths were renamed without ticket-body update; mitigated by reversibility + ≥7-day age gate)

## Confirmation

(deferred to /wr-architect:create-adr canonical review — preliminary: `packages/itil/scripts/test/evaluate-relevance.bats` exercises 5 scenarios: all-absent-old → CLOSE-CANDIDATE; mixed-present → KEEP; fresh → SKIP; no-paths → SKIP; self-references-only → SKIP)

## Pros and Cons of the Options

### Option A

- (deferred to /wr-architect:create-adr canonical review — preliminary: see Decision Drivers + Decision Outcome above)

## Reassessment Criteria

(deferred to /wr-architect:create-adr canonical review — default reassessment-date 2026-08-31; preliminary triggers: ≥3 false-positive closes within 60 days; user direction to expand Phase scope; emergence of an additional evidence shape with mechanical-confidence comparable to file-no-longer-exists)

## Related

- **P346** (`docs/problems/open/346-review-problems-no-path-to-close-no-longer-relevant-tickets-evidence-based.md`) — driver ticket.
- **ADR-022** (`docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md`) — **extended** (not modified) per the precedent ADR-026 line 109 set. The new Open|Known Error → Closed-with-reason transition rides ADR-022's lifecycle.
- **ADR-026** (`docs/decisions/026-agent-output-grounding.proposed.md`) — cite + persist + uncertainty contract honoured by the `## Closed as no longer relevant` audit section.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — commit grain for the batched relevance-close commits.
- **ADR-049** (PATH shim convention) — `wr-itil-evaluate-relevance` shim resolves the canonical script via `lib/` sibling per RFC-009 / P317.
- **ADR-052** (Behavioural tests default) — bats coverage per the standard contract.
- **ADR-013 Rule 5** (Below-appetite policy-authorised silent proceed) + **ADR-044 category 4** (silent framework action) — file-existence is empirical, not user judgment; AFK silent-proceed is correctly invoked.
- **ADR-066** — born-`proposed` without `human-oversight: confirmed`; orchestrator-level drain via `/wr-architect:review-decisions` ratifies later.
- **P334**, **P336** — close-on-evidence precedent for sub-class "fix shipped without lifecycle close".
- **JTBD-001**, **JTBD-006**, **JTBD-101** — personas served (JTBD review verdict 2026-05-31: ALIGNED; the audit-trail aspect is served by JTBD-001 + JTBD-006 already, not JTBD-201 — JTBD-201 is the incident-namespace persona per JTBD review minor observation).
- **P347** (`docs/problems/open/347-adr-079-phase-2-extend-evaluate-relevance-with-four-more-evidence-shapes.md`) — Phase 2 driver ticket. The user direction *"Amend the ADR and the implementation"* pinned the Phase 2 substance per ADR-074 build-upon guard.
- **Labeled CLOSE-CANDIDATE fixtures (2026-05-31 foreground relevance-scan, 14 total — the Phase 2 regression suite per ADR-052)**:
  - Batch 1 — `docs/problems/closed/014-aside-invocation-for-governance-skills.md` (shape 3 + 5: shipped-via-children — capture-problem + capture-adr SKILLs exist + driver P155 closed), `docs/problems/closed/034-centralise-risk-reports-for-cross-project-skill-improvement.md` (shape 3 via different shape — ADR-056 register pattern superseded the original `~/.risk-reports/` framing), `docs/problems/closed/045-auto-plugin-install-after-governance-release.md` (shape 3 via different shape — `/install-updates` shipped + wired into work-problems Step 6.5), `docs/problems/closed/079-no-inbound-sync-of-upstream-reported-problems.md` (shape 2 + 3 — ADR-062 shipped + review-problems Step 4.5 carries the inbound-discovery pipeline).
  - Batch 2 — `docs/problems/closed/012-skill-testing-harness.md` (shape 2 — ADR-037 shipped), `docs/problems/closed/015-tdd-vague-gherkin-detection.md` (shape 2 — ADR-025 shipped + confirmed), `docs/problems/closed/018-tdd-enforce-bdd-example-mapping-principles.md` (shape 2 — ADR-025 covers both P015 and P018 per ADR body verbatim), `docs/problems/closed/022-agents-should-not-fabricate-time-estimates.md` (shape 2 — ADR shipped), `docs/problems/closed/039-autonomous-loops-conflate-diagnose-with-implement.md` (shape 2 with caveat: shared-template-not-built — ADR-029 confirmed; per-SKILL discipline replaced the proposed shared subagent template).
  - Batch 3 — `docs/problems/closed/190-agent-designs-user-asked-classification-fields-instead-of-derive-or-eliminate.md` (shape 3 + 5 — Step 1.5 dispatch shipped + P287 sibling tracks the deeper structural follow-on), `docs/problems/closed/289-broaden-and-rename-solo-developer-persona-to-developer.md` (shape 3 + 4 — `docs/jtbd/developer/` exists + body literally says `Close to Verifying`).
  - Batch 4 — `docs/problems/closed/033-no-persistent-risk-register.md` (shape 2 + 4 — ADR-056 shipped + body has `Fix Released` heading; Known Error → Closed bypass per ADR-079 lifecycle extension shipped this iter 4).
  - Batch 5 — `docs/problems/closed/194-adrs-accumulate-forward-chronology-evidence-inline-instead-of-archiving-decisions-bucket-dominates-context.md` (shape 2 with caveat: deep-dive-bloat-remains — ADR-077 compendium pattern shipped for the routine-cost half; deep-dive bloat is sibling-tracked), `docs/problems/closed/292-reconcile-adr-018-release-cadence-with-p250-lean-release-sooner-and-dogfood-location.md` (shape 2 — ADR-018 amended verbatim per the ticket's premise).
- **Labeled KEEP fixtures (2026-05-31 — the Phase 2 negative regression suite per ADR-052)**:
  - `docs/problems/open/136-adr-044-alignment-audit-master.md` — multi-phase umbrella; Phase 2 done, Phase 3 outstanding. Correct classification: KEEP (or, depending on the cited-driver predicate, CLOSE-CANDIDATE-WITH-CAVEAT with `multi-phase-mixed-progress` caveat — the SKILL Step 4.6b template surfaces the umbrella's outstanding-phase list to the maintainer for confirmation).
  - `docs/problems/open/303-architect-gate-deadlocks-multi-adr-changes-verdict-grep-plus-drift-relock-plus-disk-state-review.md` — recent observation, no shipped evidence. Correct classification: KEEP.
  - `docs/problems/open/326-staged-index-cleared-after-risk-scorer-pipeline-delegation-forces-re-stage-before-commit.md` — recent observation, no shipped evidence. Correct classification: KEEP.
