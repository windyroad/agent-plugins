# Problem 297: ADR-047 — governance-artefact scaffolding should be a SessionStart hook (per-project, automatic), not an inline `/install-updates` step

**Status**: Open
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — the inline-/install-updates mechanism only scaffolds for sibling projects reachable from THIS project's /install-updates run; it completely misses adopter projects on other machines, and any project where /install-updates is never run against it; the scaffold's whole point — that an adopter with a policy file gets its artefact — silently fails for the majority of real adopters) × Likelihood: 3 (Likely — most adopter projects are not reachable from this repo's /install-updates)
**Effort**: M — move the scaffold from an inline /install-updates step to a SessionStart hook (per-plugin, fires per-project-session) + reconcile with the ADR-040 SessionStart precedent
**WSJF**: 9/2 = **4.5** (Open multiplier 1.0) — corrected 2026-05-26: Impact 3 × Likelihood 3 = 9, prior Priority line said 6 in error

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-047 (install-updates scaffolds governance artefacts when a policy file is present but its artefact is missing) was presented for human-oversight confirmation, the user **rejected the mechanism**:

> User direction 2026-05-25 (drain): *"Inline scaffold step in `/install-updates` is the wrong choice. That happens from within this project for sibling projects. It would completely miss other projects on other machines. SessionStart hook scaffold unless you have a better option."*

ADR-047 chose "Option 1 — inline scaffold step in `/install-updates`". The defect: `/install-updates` runs **from this repo, pushing to sibling projects it knows about** — it is occasional, manual, and machine-local. It cannot reach adopter projects on other machines, and it never fires for projects that don't get `/install-updates` run against them. So the scaffold (policy-file-present-but-artefact-missing → scaffold the artefact) silently fails for the majority of real adopters.

The right mechanism is a **SessionStart hook** (per the cadence principle — memory `feedback_automatic_cadence_or_it_doesnt_happen`): it fires automatically in **every project on every machine** at session start, so any adopter with a policy file but a missing artefact gets it scaffolded locally. (Considered: no better option was identified — SessionStart is the natural per-project automatic trigger, matching ADR-040 / the ADR-066/068 oversight nudges. PreToolUse/edit-gate is edit-triggered, wrong shape; the inline /install-updates step is the rejected one.)

ADR-047 is **left unoversighted** (P283/ADR-066 marker withheld) until amended (mechanism → SessionStart hook) and re-confirmed.

## Symptoms

(deferred to investigation)

- ADR-047's scaffold only fires inside this repo's `/install-updates` run for enumerated sibling projects; adopters on other machines / unreached projects never get the scaffold.
- The scaffold's value (auto-create docs/risks/ when RISK-POLICY.md exists, etc.) is per-adopter-project, but the trigger is centralised-and-manual — a mechanism/intent mismatch.

## Root Cause Analysis

### Investigation Tasks — Phase 1 (landed 2026-06-08)

- [x] Amend ADR-047: changed chosen option from Option 1 (inline /install-updates step) to Option 3 (SessionStart hook nudge). In-place amendment under `## Amendment 2026-06-08 (P297)` heading; original Decision Outcome retained as historical.
- [x] Reconcile with ADR-040 / ADR-066 / ADR-068 / ADR-045: the new hook shape is read-only stderr nudge (not silent write), satisfying ADR-040's read-mostly contract. Hook mirrors the established ADR-066/068 nudge shape; ADR-045 Pattern 1 (silent-on-pass) + Pattern 5 (once-per-session) satisfied.
- [x] Scaffold interactivity decided: **nudge-then-scaffold-on-confirm**. The SessionStart hook emits a one-line stderr advisory pointing at `/wr-risk-scorer:bootstrap-catalog`; the scaffold write happens only when the user invokes the consumer skill. The hook never writes — respects [[feedback_lift_auto_decisions_to_human]] (governance artefact creation requires explicit user action).
- [x] `/install-updates` path retired (already done per the 2026-05-25 stale-reference cleanup in ADR-047 body — the inline step was already removed when install-updates was narrowed to a single global-cache refresh).
- [ ] Re-confirm amended ADR-047 via `/wr-architect:review-decisions` — **deferred to next interactive session**: AFK iter subprocess wrote `human-oversight: unconfirmed` per ADR-066 P348 (no AskUserQuestion access). The drain promotes once a human runs `/wr-architect:review-decisions` and substance-confirms via AskUserQuestion. User direction quote in the amendment body IS the substance, so the drain answer will be a one-step confirm.

### Investigation Tasks — Phase 2 (investigated 2026-06-08, awaiting user direction)

- [x] Inventory sibling plugin reactive surfaces for the policy-missing case:
  - `packages/voice-tone/hooks/voice-tone-enforce-edit.sh:71-73` — hard-BLOCKS UI edits when `docs/VOICE-AND-TONE.md` missing, directs to `/wr-voice-tone:update-guide`.
  - `packages/style-guide/hooks/style-guide-enforce-edit.sh:70` — same reactive BLOCK shape.
  - `packages/jtbd/hooks/jtbd-enforce-edit.sh:198-201` — same reactive BLOCK shape.
  - `packages/architect/hooks/architect-enforce-edit.sh:48-49` — silently exits 0 when `docs/decisions/` missing (no reactive surface).
- [x] Architect review (this iter, 2026-06-08 P297 Phase 2 architect verdict): the Phase 1 trigger shape `POLICY-FILE × ARTEFACT-DIR pair-missing` is **risk-scorer-specific**. None of voice-tone / style-guide / jtbd replicate the two-surface shape — for them the policy IS the artefact. architect has no policy-file analog at all (decisions ARE the artefact). The pair shape Phase 1 codified does NOT generalise.
- [x] Empirical conclusion: voice-tone / style-guide / jtbd are covered by their existing **reactive enforce-edit BLOCK** gates — a strictly stronger UX than an advisory SessionStart stderr nudge. Adding a SessionStart pre-warning would be redundant noise (fires in every UI-bearing project pre-policy authoring) without coverage gain.
- [x] Helper-extraction decision: NOT extracting `packages/shared/hooks/lib/scaffold-nudge.sh` — single Phase 1 instance is not duplication per ADR-017 / YAGNI. Re-evaluate if/when a second matching pair is identified.
- [x] Sibling-ADR decision: ADR-047 Amendment 2026-06-08 does NOT cleanly generalise (it is risk-scorer-shaped with `RISK-POLICY.md` + `docs/risks/` literals + an `Install-updates scaffolds...` title that is now stale). Under the empirical lean (no further plugins in scope), no new ADR is needed.

### Phase 2 substance question — direction-setting, awaiting user

Architect surfaced three viable options (A/B/C). **P356 folded in 2026-06-16 (iter-28)** adds a fourth (Option D) and a second framing lens (JTBD-302). **Architect advisory lean: Option A.** Substance ownership belongs to the user — queued as outstanding_question for next interactive session per [[feedback_run_decisions_by_user_before_drafting]] + [[feedback_confirm_decision_substance_before_building]].

- **Option A (architect lean) — Phase 2 = no further plugins in scope.** risk-scorer is the only POLICY-FILE × ARTEFACT-DIR pair in the suite. Sibling plugins covered by existing reactive enforce-edit BLOCK gates. architect has no policy-file analog. Close Phase 2 as investigated-no-build. No new hooks, no helper extraction, no sibling ADR. (Picking A = consciously accepting the status-quo reactive surfaces as sufficient, which also closes P356's guided-invocation concern below.)
- **Option B — Ship voice-tone + style-guide SessionStart pre-warnings anyway.** Cheaper UX than discovering the enforce-edit BLOCK on first relevant edit. Accept some redundancy with the reactive gate. Extract shared helper. Write a sibling ADR generalising the pattern (the ADR-047 amendment is risk-scorer-shaped, not pattern-shaped).
- **Option C — Architect-only Phase 2.** Add a SessionStart nudge for projects with NO `docs/decisions/` directory (the genuine silent-fail-open gap in `architect-enforce-edit.sh:48-49`). Re-shape the trigger from `POLICY × DIR-MISSING` to `PLUGIN-CONFIGURED × ARTEFACT-DIR-MISSING`. Different trigger shape from Phase 1; warrants its own ADR. Risk: fires noisily on every project without ADRs where the user may not want architect governance.
- **Option D (folded in from P356, 2026-06-16) — Strengthen the existing reactive surfaces into guided invocations rather than add a new SessionStart surface.** Empirically (verified iter-28), three of four plugins ALREADY surface the missing-guide case reactively: voice-tone (`voice-tone-enforce-edit.sh:71-72`), style-guide (`style-guide-enforce-edit.sh:69-70`), and jtbd (`jtbd-enforce-edit.sh:197-199`) hard-BLOCK with an explicit "Run `/wr-<plugin>:update-guide`" direction; voice-tone additionally emits the P200 PASS-with-advisory naming the skill. P356's argument: a skill named **in prose inside a BLOCK message or verdict** is weaker than an actual **guided invocation** (an active call-to-action / one-step affordance to author the guide now). Option D = upgrade those existing prose-directions into stronger guided affordances across all four plugins (and close the architect fail-open gap from Option C as the fourth). Addresses the JTBD-302 lens: README implies governance enforcement; the installed plugin should actively walk the adopter into authoring the guide, not just block-and-name. Cheapest delta where a reactive surface already exists; only architect needs a net-new surface.

**JTBD-302 framing lens (from P356):** this decision also serves *JTBD-302 — plugin-user "Trust That the README Describes the Plugin I Just Installed."* When the README implies governance enforcement but the installed plugin no-ops (architect) or only blocks-and-names-in-prose (voice-tone/style-guide/jtbd), the JTBD-302 outcome is partially unmet. Whichever option is chosen should be weighed against that trust outcome, not only against hook-budget/redundancy.

### Investigation Tasks — Phase 3 (conditional on user direction)

- [ ] If user picks **Option A**: transition Open → Verifying. Mark all Phase 2 investigation tasks complete. ADR-047 re-confirmation (Phase 1 outstanding task) remains the only blocker to ticket closure.
- [ ] If user picks **Option B**: implement SessionStart scaffold-nudges + bats for voice-tone + style-guide; extract `packages/shared/hooks/lib/scaffold-nudge.sh`; author sibling ADR (`Scaffold-nudge pattern for policy-file × artefact-directory pairs across the plugin suite`).
- [ ] If user picks **Option C**: implement SessionStart scaffold-nudge for architect on `docs/decisions/` missing; author ADR for the `PLUGIN-CONFIGURED × ARTEFACT-DIR-MISSING` trigger shape.
- [ ] If user picks **Option D** (P356): upgrade the prose-direction in `voice-tone-enforce-edit.sh` / `style-guide-enforce-edit.sh` / `jtbd-enforce-edit.sh` missing-guide BLOCK branches (and the voice-tone P200 advisory) into stronger guided-invocation affordances; close the architect fail-open gap with a guided surface; author an ADR for the guided-onboarding pattern. Measure against JTBD-302.
- [ ] Dependency: ADR-047 Phase 1 amendment remains `human-oversight: unconfirmed` — Phase 3 hook work that explicitly cites ADR-047 should wait until `/wr-architect:review-decisions` ratifies the amendment (or be queued behind it).

## Phase 1 deliverables (2026-06-08)

- `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh` — new SessionStart hook.
- `packages/risk-scorer/hooks/hooks.json` — registers the new hook under `SessionStart` matcher `"startup"`.
- `packages/risk-scorer/hooks/test/risk-scorer-scaffold-nudge.bats` — 7-case behavioural fixture.
- `docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md` — Amendment 2026-06-08 (P297) section + frontmatter flipped to `human-oversight: unconfirmed` pending drain promotion.
- `docs/decisions/README.md` — compendium regenerated.

## Phase 2 deliverables (2026-06-08, investigated-no-build pending direction)

- Empirical sibling-plugin reactive-surface inventory (above).
- Architect verdict: Phase 1 pair shape does not generalise; sibling plugins covered by reactive enforce-edit BLOCK gates; architect lacks policy-file analog.
- Three viable options (A / B / C) surfaced for user direction; substance question queued as outstanding_question for next interactive session.
- No code shipped in Phase 2. No new ADR. No helper extraction. Investigation findings persisted in this ticket body so the next iter (or next interactive session) does not repeat the analysis.

## Phase 2 direction ratified 2026-06-17 — Option D

User ratified **Option D (P356-driven) — Strengthen reactive surfaces into guided invocations** via AskUserQuestion during the 2026-06-17 outstanding-questions drain. Options A (architect-lean close-as-investigated-no-build), B (ship voice-tone + style-guide SessionStart pre-warnings), and C (architect-only Phase 2) are rejected.

**Phase 3 scope** (now unblocked):

1. **voice-tone** — `voice-tone-enforce-edit.sh:71-72` already BLOCKs with "Run `/wr-<plugin>:update-guide`" prose-direction; the P200 PASS-with-advisory also names the skill. Upgrade BOTH surfaces from "name the skill in prose" into a stronger guided-invocation affordance (e.g. structured `SUGGESTED_NEXT: /wr-voice-tone:update-guide` tag that the agent can act on as a one-step call-to-action, or a marker the SessionStart layer reads to surface as a guided prompt at next session start).
2. **style-guide** — `style-guide-enforce-edit.sh:69-70` carries the same BLOCK-and-name-prose pattern; same upgrade.
3. **jtbd** — `jtbd-enforce-edit.sh:197-199` carries the same pattern; same upgrade.
4. **architect** — close the silent-fail-open gap at `architect-enforce-edit.sh:48-49` (projects with NO `docs/decisions/`) by adding a guided-invocation surface that walks the user into authoring an ADR (or scaffolding the directory).
5. **Sibling ADR** — author an ADR codifying the "guided-onboarding pattern" — the cross-plugin convention for when a plugin's policy file / artefact directory is missing AND its enforce-edit gate would fire on the first relevant edit. Trace P297 + P356 + JTBD-302.
6. **Measurement against JTBD-302** — the README-implies-governance-enforcement / installed-plugin-no-ops outcome is the metric this Phase 3 closes; the ADR should cite the JTBD-302 outcome it serves.

**Implementation order**: define the guided-invocation tag/marker shape first (cross-plugin coherence); then apply to voice-tone / style-guide / jtbd (cheap delta — three reactive surfaces already exist); then close the architect gap (net-new surface); then author the ADR.

Next step: capture an RFC per ADR-060 tracing this ticket + P356 + the four plugin loci + the new ADR. Defer build under ADR-074 until RFC scope ratified.

## Dependencies

- **Blocks**: ADR-047 human-oversight confirmation (held until amended).
- **Blocked by**: none.
- **Composes with**: ADR-040 (SessionStart precedent), ADR-045 (hook budget), ADR-066/068 (existing SessionStart oversight nudges — same event), memory `feedback_automatic_cadence_or_it_doesnt_happen` (the per-project-automatic-trigger principle), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P287 / P289 / P290 / P291 / P292 / P293 / P294 / P295 / P296** — sibling drain-surfaced reworks.
- **P356 (Closed 2026-06-16, duplicate-of-P297, folded in here as Option D + JTBD-302 lens)** — "No prompt or guide when an adopter installs a policy-plugin without its guide doc." Same decision-space as Phase 2; its sibling-plugin audit was already complete here, and its guided-invocation-vs-prose framing is now Option D above. The Phase 2 substance decision (A/B/C/D) is the single user decision that resolves both tickets.
- **JTBD-302** (plugin-user — Trust That the README Describes the Plugin I Just Installed) — the load-bearing Job P356 anchors on; now a framing lens for the Phase 2 decision.
- **ADR-047** (`docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md`) — amendment target.
- **ADR-040** (SessionStart surface), **ADR-045** (hook budget), **ADR-066/068** (SessionStart oversight nudges) — the SessionStart neighbours to compose with.
