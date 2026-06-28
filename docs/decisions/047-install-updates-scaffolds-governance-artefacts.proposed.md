---
status: "proposed"
date: 2026-04-28
human-oversight: confirmed
oversight-date: 2026-06-10
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, addressr-mcp maintainer, addressr-react maintainer, very-fetching maintainer]
reassessment-date: 2026-07-28
---

# Install-updates scaffolds governance artefacts when policy file is present but artefact is missing

## Context and Problem Statement

P033 reopened from Verifying on 2026-04-28 with a 99% miss-rate regression. Surveying 7 adopter projects on the user's machine: 6/7 have `RISK-POLICY.md` (per-change pipeline scoring is configured), all 6 have `.risk-reports/` accumulating (~285 cumulative reports), but only **1/6 has populated `docs/risks/`** and **4/6 don't even have `docs/risks/` scaffolded**. The risk REGISTER (the standing-risk inventory required by ISO 31000 § 6.4.2 and ISO 27001 § 6.1.2/6.1.3) is missing on every adopter where it would matter.

The P033 / P102 / P110 fix triplet shipped the *plumbing* (scaffolding pattern, `/wr-risk-scorer:create-risk` skill, `RISK_REGISTER_HINT:` from the pipeline agent) but no *trigger* fires the scaffold into existence on adopter projects. Adopters install the risk-scorer plugin, configure `RISK-POLICY.md`, watch `.risk-reports/` accumulate — but `docs/risks/` never appears because nothing creates it. The hint surface is opt-in and undiscoverable; the create-risk skill is opt-in and undiscoverable; the directory scaffold is opt-in and undiscoverable.

User's load-bearing direction (verbatim, 2026-04-28 mid-investigation): *"for each risk mentioned in the .risk-reports, there should be something in the risk register"*. The register MUST exist before the back-channel can populate it. This ADR addresses the **directory-scaffolding precondition** — the back-channel implementation (Phase 2+) needs `docs/risks/` to write into.

**Question**: where does the trigger that creates `docs/risks/` live? Architect verdict (2026-04-28): inside `/install-updates`, fired per-sibling during the install loop. Alternatives considered and rejected below.

## Decision Drivers

- **JTBD-001 (Enforce Governance Without Slowing Down)** — primary fit. Idempotent scaffolding when `RISK-POLICY.md` is present is exactly "governance enforced automatically without manual step". The 99% miss rate is the "agents skip steps" pain point.
- **JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover)** — tech-lead audit-trail need. Missing `docs/risks/` means accumulated `.risk-reports/` have no canonical home for ISO 31000 / 27001 audit.
- **JTBD-006 (Progress the Backlog While I'm Away)** — AFK-safe. Existence of `RISK-POLICY.md` IS the prior user authorisation; scaffolding is the unambiguous safe default per ADR-013 Rule 5.
- **P033** — driver ticket; this ADR is Phase 1 of its multi-phase fix.
- **P102 / P110** — sibling tickets; their back-channel work (Phase 2+) is the consumer of this ADR's scaffolding output.
- **ADR-030** — `/install-updates` is a repo-local skill governed here; this ADR extends the skill's scope.
- **ADR-036** — direct precedent. `scaffold-intake` skill scaffolds `.github/ISSUE_TEMPLATE/`, `SECURITY.md`, etc., into adopter projects. This ADR applies the same shape to governance-artefact scaffolding (policy-file → directory pair).
- **ADR-013** — Rule 5 (policy-authorised silent proceed) governs the auto-scaffold; Rule 6 (AFK fail-safe) is the non-interactive escape.
- **ADR-014** — commit discipline applies to the scaffold writes.
- **ADR-038** — progressive disclosure; SKILL.md change ships the runtime contract, REFERENCE.md takes the deep-context.

## Considered Options

1. **Inline scaffold step in `/install-updates`** (chosen) — install-updates already enumerates siblings, runs in foreground with consent gate, has ADR-013 Rule 6 fallback, and writes to sibling project trees. Adding "scaffold `docs/risks/` if `RISK-POLICY.md` exists and the directory is absent" is one additive step within existing scope.
2. **New `/wr-risk-scorer:scaffold-register` skill** — symmetric with `scaffold-intake`. Lives in the risk-scorer plugin. Rejected: scaffold-intake fires on-demand (user-invoked) AND on first-run-prompt from manage-problem. A scaffold-register skill would need a similar trigger surface, but the natural surface is install-time (when plugins are being refreshed) NOT runtime. Adding two trigger paths (skill + first-run-prompt) for a one-shot directory-and-template-write is over-engineered for Phase 1.
3. **SessionStart hook scaffold** — fire on every session start. Rejected: too aggressive; SessionStart is read-mostly per ADR-040, and silent writes at session start violate the user's session-start trust contract. Also fires too often for an idempotent one-shot.
4. **Defer scaffolding entirely; rely on manual user action** — current state. Rejected: this is exactly what produced the 99%-miss-rate regression. The user has explicitly directed that scaffolding NOT be left to manual action.
5. **Embed scaffolding inside `/wr-risk-scorer:create-risk`** — only scaffolds when the user invokes create-risk. Rejected: conflates two surfaces (create-a-risk and create-the-register-that-holds-risks) and still leaves 99% miss rate when create-risk is never invoked.

## Amendment 2026-06-08 (P297) — chosen option changed to SessionStart hook nudge

**The chosen option is now Option 3** (SessionStart hook scaffold), reshaped from the rejected `silent write` framing to a `read-only stderr nudge` framing. The remainder of the original Decision Outcome below documents the now-superseded Option 1 mechanism (inline `/install-updates` step) and is retained for historical traceability.

### User direction (verbatim, 2026-05-25 P283/ADR-066 drain)

> *"Inline scaffold step in `/install-updates` is the wrong choice. That happens from within this project for sibling projects. It would completely miss other projects on other machines. SessionStart hook scaffold unless you have a better option."*

This is a substance-confirm answer per ADR-074 (P314) — the option is named explicitly ("SessionStart hook scaffold") and the conditional clause ("unless you have a better option") is the option-shaped permission. P297 captured the rework; this amendment closes it.

### Why Option 3's original rejection rationale no longer holds

The 2026-04-28 Considered Options block rejected Option 3 on the grounds that *"SessionStart is read-mostly per ADR-040, and silent writes at session start violate the user's session-start trust contract."* That rationale assumed a write-on-session-start design. The Phase 1 mechanism shipped under this amendment **does not write at session start** — the SessionStart hook is a read-only stderr nudge (one-line advisory pointing at the on-demand `/wr-risk-scorer:bootstrap-catalog` skill); the scaffold write happens only when the user invokes that skill. The hook is the discovery surface; the skill is the consent + write surface. This is the established ADR-066 / ADR-068 nudge shape applied to a scaffold-class concern rather than an oversight-class concern.

### Mechanism — Phase 1 (this iter, risk-scorer plugin)

1. New hook script `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh`. Modelled on `packages/architect/hooks/architect-oversight-nudge.sh` (ADR-066 shape).
2. Registered in `packages/risk-scorer/hooks/hooks.json` under `SessionStart` matcher `"startup"` (ADR-040 lifecycle).
3. Detection: `<project>/RISK-POLICY.md` exists AND `<project>/docs/risks/` is absent. Silent on every other state.
4. Emission on positive detection: a single stderr line —
   `[wr-risk-scorer] RISK-POLICY.md present but docs/risks/ is missing — run /wr-risk-scorer:bootstrap-catalog to scaffold the standing-risk register.`
5. AFK self-suppress: respects `WR_SUPPRESS_OVERSIGHT_NUDGE=1` per ADR-068 (the suite-wide guard variable). One env var silences every oversight-class nudge, scaffold-class included — extending ADR-068's "do NOT split into per-plugin guard vars" principle to the category axis.
6. Behavioural bats fixture at `packages/risk-scorer/hooks/test/risk-scorer-scaffold-nudge.bats` exercises the four-state matrix plus the AFK-guard semantics.
7. Hook budget: silent-on-no-condition per ADR-045 Pattern 1; SessionStart's once-per-session lifecycle satisfies Pattern 5 for free.

### Mechanism — Phase 2 (deferred to follow-on iter)

Generalise the scaffold-nudge pattern across the plugin suite where a policy-file → artefact-directory pair exists:

- `docs/VOICE-AND-TONE.md` → `docs/voice-tone/` (voice-tone plugin — needs scope confirmation; the policy-file → directory pair may not be the right shape for voice-tone).
- `docs/STYLE-GUIDE.md` → `docs/style-guide/` (style-guide plugin — same scope confirmation).
- Architect (`docs/decisions/`) and JTBD (`docs/jtbd/`) **do not need a scaffold-nudge** — decisions live IN the directory, there is no separate policy file pointing AT it, and oversight nudges (ADR-066 / ADR-068) already cover the analogous gap for ratification, not scaffolding.

Phase 2 lands when the policy/artefact-pair semantics are confirmed for voice-tone and style-guide (likely a sibling ADR generalising the pattern, with a shared scaffold-nudge helper extracted from this Phase 1 implementation).

### Drivers (amendment-time)

- **ADR-040** (SessionStart surface) — lifecycle host; the nudge respects ADR-040's read-mostly contract because no write happens in the hook.
- **ADR-066 / ADR-068** (oversight-nudge shape precedents) — the canonical one-line stderr + silent-on-no-content + AFK-guard shape this hook follows.
- **ADR-045** (hook injection budget) — Pattern 1 (silent-on-pass) + Pattern 5 (once-per-session) compliance.
- **ADR-013** Rule 5 / Rule 6 — policy-authorised silent proceed semantics. The hook does not write, so Rule 5/6 apply to the consumer skill (`/wr-risk-scorer:bootstrap-catalog`), not to the hook itself.
- **ADR-059** (consume-catalog + bootstrap-from-reports) — the on-demand consumer skill the nudge points at. Already-ratified scaffold surface; this amendment is the missing trigger.
- **ADR-049** (PATH shim grammar) — the hook is invoked via `${CLAUDE_PLUGIN_ROOT}/hooks/...` per the suite's standard registration grammar; no new PATH shim is needed for Phase 1.
- **JTBD-001** (Enforce Governance Without Slowing Down) — primary fit. The hook surfaces the documented 99%-miss-rate gap (4/6 surveyed adopters lacked `docs/risks/`).
- **JTBD-006** (Progress the Backlog While I'm Away) — `WR_SUPPRESS_OVERSIGHT_NUDGE=1` honour clause.
- **P297** — driver ticket.

### Frontmatter

`human-oversight: unconfirmed` set on this amendment commit because the amendment was applied by an AFK iter subprocess under `/wr-itil:work-problems` and the substance-confirm marker pipeline (`wr-architect-mark-oversight-confirmed`) requires an AskUserQuestion-shaped event the AFK subprocess cannot produce. The user direction quote above carries the substance, but the marker write is deferred to the next interactive session's `/wr-architect:review-decisions` drain pass per ADR-066 P348. `supersede-ticket: P297` is removed because the supersede has been applied in-place by this amendment.

### Confirmation (amendment-time)

> The original Confirmation block below (Source review + Bats fixture test + Behavioural replay) is **historical** per the 2026-05-25 stale-reference cleanup note and is retained for traceability. The amendment-time Confirmation criteria are:

- `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh` — exists, is executable, follows the `architect-oversight-nudge.sh` shape (AFK-guard short-circuit at the top, silent-on-no-condition, one-line stderr on positive detection).
- `packages/risk-scorer/hooks/hooks.json` — registers the hook under `SessionStart` matcher `"startup"`.
- `packages/risk-scorer/hooks/test/risk-scorer-scaffold-nudge.bats` — behavioural fixture exercising: (a) emits on policy-present + dir-absent, (b) silent on policy-present + dir-present, (c) silent on policy-absent (with and without dir), (d) AFK-guard suppression, (e) guard value other than 1 does not suppress, (f) silent on non-existent CLAUDE_PROJECT_DIR.
- `docs/decisions/README.md` — compendium regenerated to reflect this amendment per ADR-077.

---

## Amendment 2026-06-28 (P379) — policy-ABSENT predicate added to the scaffold-nudge hook

**The same `risk-scorer-scaffold-nudge.sh` hook now also nudges on the inverse predicate: when `RISK-POLICY.md` is ABSENT ENTIRELY** (not just when it exists and the register dir is missing). On bare policy-absence the hook emits a one-line stderr advisory pointing the adopter at `/wr-risk-scorer:update-policy`. Same read-only shape, same `WR_SUPPRESS_OVERSIGHT_NUDGE=1` envelope (ADR-068).

### The predicate this reverses

The Phase 1 hook (P297 amendment above) deliberately silent-skipped on policy-absence, reasoning: *"The policy file presence is the user authorisation for the register to exist; without it, the absence of docs/risks/ is not a governance gap."* That rationale is sound **for the register concern** — without a policy there is no register expectation. But it left a second, distinct gap uncovered: an adopter who installs `@windyroad/risk-scorer`, never authors a `RISK-POLICY.md`, and runs sessions for weeks gets the gate's default appetite (5 per ADR-086) silently, with no surfacing that a policy can be authored at all. The capability sits dormant and undiscoverable. P379 records that bare policy-absence IS a (separate, discovery-class) gap, scoped to capability-discoverability rather than register-completeness. The Phase 1 comment is reworded in-source to scope its silence to the register concern.

### Decision driver and the alternative considered

The P379 architect review surfaced an alternative — Option B: nudge **only** when there is positive evidence of risk-scorer usage without a policy (e.g. `.risk-reports/` exists but `RISK-POLICY.md` is absent), to avoid firing every session on adopters who deliberately run policy-free per-change scoring. The chosen option (A, bare-absence nudge) follows the documented user intent in P379's Description (*"if RISK-POLICY.md is absent in an adopter project, the adopter should be auto-interviewed by /wr-risk-scorer:update-policy"*) and the orchestrator's scoping of that intent to a read-only advisory. Option B is queued to the next `/wr-architect:review-decisions` drain as a possible narrowing — see Frontmatter.

### Mechanism

1. A project-dir-exists guard (`[ -d "$PROJECT_DIR" ] || exit 0`) precedes the policy check so a stale `CLAUDE_PROJECT_DIR` stays silent.
2. Policy-absent arm: `[ ! -f "$POLICY_FILE" ]` → one stderr line citing `/wr-risk-scorer:update-policy`, then exit 0 (the register/curation arms below never run when there is no policy).
3. AFK self-suppress unchanged — the top-of-file `WR_SUPPRESS_OVERSIGHT_NUDGE=1` short-circuit governs all arms.
4. Behavioural bats extended: policy-absent → nudge cites update-policy; policy-absent + register-dir-present → nudge still fires (policy-absence wins); policy-absent + AFK guard → silent; non-existent dir → silent.

This supersedes the Phase 1 Confirmation bullet (c) ("silent on policy-absent") — that state now nudges.

### Frontmatter

`human-oversight: unconfirmed` applies to this amendment (the top-level marker stays `confirmed` from the 2026-06-10 drain that ratified the P297 amendment). This P379 amendment was applied by an AFK iter subprocess under `/wr-itil:work-problems`; the substance-confirm marker pipeline requires an AskUserQuestion-shaped event the AFK subprocess cannot produce (P357). Two items are queued to the next interactive `/wr-architect:review-decisions` drain per ADR-066 P348: (1) ratify this amendment's chosen predicate, and (2) the Option B narrowing (gate on `.risk-reports/` evidence) as a possible refinement.

---

## Decision Outcome

**[Historical — superseded by Amendment 2026-06-08 above. The original Option 1 mechanism is retired; the SessionStart hook nudge per Option 3 is now in force.]**

**Chosen option: Option 1** — inline scaffold step in `/install-updates`.

### Trigger contract

Per sibling project enumerated in install-updates Step 3 (and the current project, treated as an implicit sibling for ADR-004 scope):

1. **Detect** `<project>/RISK-POLICY.md` (file-existence test).
2. **Detect** `<project>/docs/risks/` (directory-existence test).
3. **Trigger condition**: `RISK-POLICY.md` present AND `docs/risks/` absent.
4. **Action**: scaffold `docs/risks/README.md` and `docs/risks/TEMPLATE.md` from this repo's templates at `.claude/skills/install-updates/templates/risk-register-{README,TEMPLATE}.md.tmpl`.
5. **No substitution tokens** in v1 — the templates are project-agnostic. Adopters fill in their own register entries; the scaffold provides only the shell (table headers, ISO mapping, structure documentation, per-risk file format).
6. **Idempotency**: per-file `create-if-absent`. If `README.md` exists but `TEMPLATE.md` does not (partial scaffold, e.g. user deleted one), only the missing file is written. Existing files are NEVER overwritten.

### Scope semantics

- Fires per-sibling AFTER the consent gate (Step 5b/c) confirms the sibling is in scope. Existing consent grants the install; scaffolding is a sibling artefact of the install.
- Fires AFTER the install loop (Step 6) so the final report can include scaffold rows alongside install rows.
- Fires REGARDLESS of whether the install loop ran (e.g. if `npm view` showed all plugins already up-to-date and no install happened, scaffolding still fires). The trigger is `RISK-POLICY.md` presence, not plugin-update presence.
- Cache-hit consent path (P120) preserves the scaffold trigger. The cached consent authorises BOTH the plugin install AND the scaffold pass. No new consent gate is added — the existing per-sibling consent is sufficient because the scaffold writes only to siblings already authorised.
- Dry-run consent answers do NOT scaffold. Scaffolding is a write; dry-run is read-only by contract.

### ADR-013 Rule audit

| Branch | Resolution |
|---|---|
| Cache-hit / cache-miss with consent granted (Rule 5) | Scaffold fires silently. Existence of `RISK-POLICY.md` plus prior consent IS the policy authorisation. Logged in the final report's scaffold rows. |
| Non-interactive subagent invocation (Rule 6) | Scaffold does NOT fire. Same fail-safe as the install path: dry-run table only; user must re-run interactively. The scaffold trigger inherits the consent gate's interactivity requirement. |
| Sibling consent answer was "Current project only" | Scaffold fires for current project only. Other siblings are skipped (consent boundary respected). |

### Final-report integration

The Step 7 final report grows a scaffold column or scaffold rows. Recommended shape: per-sibling, append rows like:

```
| <sibling> | docs/risks/ | — | scaffolded | ✓ created (RISK-POLICY.md present) |
| <sibling> | docs/risks/ | (present) | (present) | ⊘ skipped (already exists) |
| <sibling> | docs/risks/ | — | — | ⊘ skipped (no RISK-POLICY.md) |
```

User sees a single audit trail of plugin installs AND scaffolds in one table. JTBD-006 transparency outcome respected.

### Marker semantics

No marker file is written. The scaffold is idempotent by file-existence test alone — if `docs/risks/README.md` exists, the scaffold no-ops. This is simpler than the `.intake-scaffold-done` marker (ADR-036) because the scaffolded files themselves serve as the "done" signal. There is no "decline" path because the scaffold has no interactive gate.

### Template content

Two files at `.claude/skills/install-updates/templates/`:

- `risk-register-README.md.tmpl` — adopter-flavoured copy of this repo's `docs/risks/README.md`. Empty register/retired tables. ISO mapping section. Structural diagram. "How to add" instructions citing `TEMPLATE.md`. NO "Last reviewed" date in the scaffolded copy (adopters set their own).
- `risk-register-TEMPLATE.md.tmpl` — verbatim copy of this repo's `docs/risks/TEMPLATE.md`. Risk-file shape (Status, Category, Inherent, Controls, Residual, Treatment, Monitoring, Related, Change Log).

Templates are read at install-updates runtime from THIS repo's working tree (the install-updates skill is repo-local; templates ship with it). Sibling adopters never read the templates directly.

## Scope

### In scope (this ADR / Phase 1)

- Detection: `<sibling>/RISK-POLICY.md` AND `<sibling>/docs/risks/`.
- Templates: `risk-register-README.md.tmpl`, `risk-register-TEMPLATE.md.tmpl` at `.claude/skills/install-updates/templates/`.
- Step 6.5 in `.claude/skills/install-updates/SKILL.md` — scaffold-per-sibling step.
- REFERENCE.md section "Governance-artefact scaffold (P033)" — deep context.
- Final-report integration — scaffold rows in Step 7 table.
- Behavioural bats test exercising the scaffold-and-skip-existing contract against a mock adopter fixture.
- ADR-013 Rule 5 + Rule 6 audit.

### Out of scope (follow-up ADRs / phases)

- **Phase 2 (P033 / P110 back-channel)** — `wr-risk-scorer:pipeline` agent writes/updates `docs/risks/R<NNN>-*.active.md` entries when reports identify register-worthy risks. Load-bearing per user direction; deferred to follow-on iter because it requires architect-design depth (autonomy boundary, dedupe-by-risk-name, evidence-log appending, marker-driven backfill gating). This ADR's scaffolding output is the precondition. **Phase 2a landed via ADR-056 (queue-write contract); Phase 2b drain + Phase 3 bootstrap superseded by ADR-059 (consume-catalog and bootstrap-from-reports register population).**
- **Phase 3 (P033 backfill)** — one-time pass over each adopter's existing `.risk-reports/*.md` to identify distinct risks and create register entries for each. Per-project marker-gated (`.claude/.risk-register-backfill-done`). **Superseded by ADR-059 (bootstrap-from-reports); per-project marker no longer needed since bootstrap idempotency is by file-existence per slug per ADR-056 dedupe key.**
- **Phase 4 (Fix candidate 4) — behavioural test** — contract assertion that every risk-id in `.risk-reports/*.md` has a matching `docs/risks/R<NNN>-*.md` entry. Fails CI / scoring run if absent.
- **Other policy-file → directory-scaffold pairs** — ADR-policy → `docs/decisions/`, JTBD-policy → `docs/jtbd/`, voice-tone-policy → `docs/VOICE-AND-TONE.md`. JTBD review surfaced this as a possible generalisation. Out of scope this ADR; if the pattern proves out via P033 Phase 1 adoption, generalise via a future ADR.
- **Cross-template drift** — when this repo's `docs/risks/README.md` evolves, adopter scaffolds stay frozen at the version they were scaffolded with. Mirror of ADR-036's template-drift consequence; same mitigation (re-invocation diff) once a re-scaffold path lands.
- **Substitution tokens** — Phase 1 templates have none. If adopter-specific values are needed (e.g. project name in README header), add via mustache-style tokens following ADR-036's pattern.
- **Sibling skill `/wr-risk-scorer:scaffold-register`** — the on-demand surface for scaffolding the register from the risk-scorer plugin. Deferred: install-updates trigger is sufficient for Phase 1; on-demand surface adds value when adopters want to scaffold mid-session without an install. Add when usage demand surfaces.

## Consequences

### Good

- Phase 1 closes the 99%-miss-rate gap for `docs/risks/` directory existence. Adopters with `RISK-POLICY.md` get the register scaffold on next `/install-updates` invocation. Surveyed 4/6 adopters benefit immediately.
- Idempotent file-existence test means the step is safe to fire on every install-updates run. No marker management, no TTL, no drift.
- Reuses ADR-036's directory-pair-scaffold pattern; no new architectural primitive.
- Reuses install-updates' existing consent gate (ADR-030); no new consent surface.
- Template content is project-agnostic — no adopter-specific substitution complexity in v1.
- Final-report integration gives the user one audit trail covering both plugin installs and scaffolds.
- AFK-safe by inheritance from install-updates' Rule 6 fallback.
- Independent of Phase 2 (back-channel): the scaffold lands without the back-channel, so the directory exists for users who manually populate it (current bbstats pattern) even before the back-channel ships.

### Neutral

- `.claude/skills/install-updates/SKILL.md` grows by one step. Already at 7 steps + sub-steps; one more is within budget per ADR-038 (REFERENCE.md takes the depth).
- Templates colocated at `.claude/skills/install-updates/templates/` mirror scaffold-intake's `packages/itil/skills/scaffold-intake/templates/` structure but at a different path because install-updates is repo-local, not packaged.
- Per-sibling scaffold pass adds an O(N siblings) file-existence test pair to install-updates' runtime cost. Negligible (~6 stat calls in the surveyed workspace).
- ADR-030's Confirmation criteria do not change: consent gate is still the first interactive action; scaffolding fires after consent, not before.

### Bad

- **Template drift** (mirror of ADR-036's same flag): when this repo's `docs/risks/README.md` evolves (e.g. ISO mapping table grows), scaffolded adopter copies stay frozen. Mitigation: future re-scaffold path or scaffold-version metadata. Not blocking for Phase 1.
- **Adopter-specific README customisation lost**: an adopter who customised their `docs/risks/README.md` and then deleted it would get the canonical scaffold back on next install-updates run. Mitigation: idempotent `create-if-absent` per file means the user must explicitly delete to re-trigger; this is intentional. The "I want my customisation back" path is git history.
- **Scaffold runs even when adopter doesn't use the risk-scorer plugin** — false-positive risk. The trigger is `RISK-POLICY.md` presence, not plugin enablement. Surveyed evidence: every adopter with `RISK-POLICY.md` also has `wr-risk-scorer@windyroad` enabled, so this is hypothetical. If a user removes the plugin but keeps RISK-POLICY.md, they still get docs/risks/ — arguably correct (the policy file still expects a register).
- **No interactive opt-out**. An adopter cannot decline scaffolding. Mitigation: the user can `git rm -r docs/risks/` after scaffold; the directory will be re-scaffolded on next install-updates run only if they also remove all files inside it (idempotent file-existence is per-file, not per-directory). Better mitigation if this becomes a pain point: add a `.claude/.risk-register-scaffold-declined` marker honoured by the trigger condition, paralleling ADR-036's `.intake-scaffold-declined`. Deferred until evidence shows it's needed.
- **Phase 1 ships scaffolding without the back-channel**. The directory exists but is empty; the user could read this as "still broken" if Phase 2 doesn't ship promptly. Mitigation: P033 ticket body explicitly enumerates Phase 2 as the load-bearing follow-up; ITERATION_SUMMARY for this iter calls out the deferred phases.

## Confirmation

### Source review (at implementation time)

> **Stale-reference cleanup note (2026-05-25):** Step 6.5 no longer exists in `install-updates`. The template scaffold this ADR added was wiped 2026-05-04 (the templates encoded the wrong content shape — see the SKILL.md Step 6.5 note that recorded the wipe), and the bootstrap auto-trigger that replaced it (ADR-059 verdict A6) was retired 2026-05-25 when `install-updates` was narrowed to a single global-cache refresh run (ADR-030 amendment 2026-05-25; ADR-059 amendment 2026-05-25). **This ADR's coupling to `install-updates` is fully dissolved** — the Source review and Behavioural replay items below that reference a Step 6.5 / `.claude/skills/install-updates/templates/` are historical and no longer hold. The governance-artefact register-scaffold concern now lives entirely in the on-demand `/wr-risk-scorer:bootstrap-catalog` skill (ADR-059 verdict A4). Status stays `proposed`.

- `.claude/skills/install-updates/SKILL.md` — Step 6.5 "Scaffold governance artefacts (per-sibling)" exists between Step 6 (Install) and Step 7 (Final report). Step 6.5 names `RISK-POLICY.md` as the trigger condition, `docs/risks/README.md` and `docs/risks/TEMPLATE.md` as the scaffolded files, idempotent per-file create-if-absent semantics, and ADR-047 + ADR-013 Rule 5/6 citations. **[Historical — retired per the 2026-05-25 cleanup note above.]**
- `.claude/skills/install-updates/REFERENCE.md` — new section "Governance-artefact scaffold (P033)" present with the trigger contract, idempotency rule, ADR-013 audit, and template-source-of-truth pointer.
- `.claude/skills/install-updates/templates/risk-register-README.md.tmpl` — present; adopter-flavoured (no R001 row, no "Last reviewed" date).
- `.claude/skills/install-updates/templates/risk-register-TEMPLATE.md.tmpl` — present; verbatim copy of this repo's `docs/risks/TEMPLATE.md`.
- `docs/problems/033-no-persistent-risk-register.known-error.md` — Phase 1 marked complete with ADR-047 citation; Phases 2-4 enumerated as deferred follow-up.

### Bats fixture test

- `.claude/skills/install-updates/test/install-updates-p033-register-scaffold.bats` — fixture test:
  1. Mock adopter with `RISK-POLICY.md` and no `docs/risks/` → assert both files scaffolded; content tokens match templates.
  2. Mock adopter with `RISK-POLICY.md` and `docs/risks/` already populated → assert no writes.
  3. Mock adopter without `RISK-POLICY.md` → assert no `docs/risks/` written.
  4. Mock adopter with `docs/risks/README.md` present but `docs/risks/TEMPLATE.md` missing (partial state) → assert TEMPLATE.md is written, README.md is preserved.
  5. Re-invocation idempotency — second pass produces zero diff.

### Behavioural replay

1. Fresh sibling project with `RISK-POLICY.md` and no `docs/risks/`. Run `/install-updates`. Verify: scaffold rows in Step 7 final report; `docs/risks/README.md` and `docs/risks/TEMPLATE.md` present in the sibling.
2. Re-run `/install-updates`. Verify: scaffold rows say "skipped (already exists)" for the same sibling; no diff.
3. Sibling without `RISK-POLICY.md`. Verify: no scaffold attempted; no scaffold row in final report (or row says "skipped (no RISK-POLICY.md)").

## Reassessment Criteria

Revisit this decision if:

- Adopter `docs/risks/` populate-rate stays near zero 3+ months post-Phase-2 release. Signal: scaffold landed but back-channel didn't fix the populate-rate. Revisit Phase 2 design.
- Template drift causes operational pain (adopter README/TEMPLATE 6+ months stale). Signal: design re-scaffold path or scaffold-version metadata.
- Adopters complain about unwanted `docs/risks/` creation (false-positive trigger). Signal: add `.claude/.risk-register-scaffold-declined` marker path, paralleling ADR-036.
- Other policy-file → directory-scaffold pairs surface (ADR / JTBD / style-guide / voice-tone). Signal: generalise the pattern via a follow-up ADR with a registry of policy-file → scaffold-target pairs.
- A `/wr-risk-scorer:scaffold-register` on-demand skill becomes preferable to the install-time trigger (e.g. user wants to scaffold mid-session). Signal: add the on-demand skill alongside the install-updates trigger; both feed the same templates.

## Related

- **P033** — driver ticket; Phase 1 of multi-phase fix.
- **P102** — invocation surface for risk register; sibling-in-fix.
- **P110** — pipeline back-channel hint; Phase 2 consumer of this ADR's output.
- **P065 / ADR-036** — direct precedent (downstream OSS intake scaffold).
- **ADR-030** — install-updates host skill; this ADR extends scope additively.
- **ADR-013** — Rule 5 (cache-hit silent proceed) + Rule 6 (AFK fail-safe).
- **ADR-014** — commit discipline.
- **ADR-038** — progressive disclosure (SKILL.md / REFERENCE.md split).
- **ADR-040** — SessionStart read-mostly contract (rationale for not putting the trigger in SessionStart).
- **ADR-004** — project-scope only (current project as implicit sibling).
- **JTBD-001** — primary fit (governance without slowing down).
- **JTBD-006** — AFK transparency outcome.
- **JTBD-202** — tech-lead audit-trail need.
- `RISK-POLICY.md` — trigger condition file.
- `docs/risks/README.md` — template source-of-truth (this repo).
- `docs/risks/TEMPLATE.md` — template source-of-truth (this repo).
- `.claude/skills/install-updates/SKILL.md` — implementation site (symlink → source-of-truth at `scripts/repo-local-skills/install-updates/SKILL.md` per P139 relocation).
- `.claude/skills/install-updates/templates/` — template files location (under source-of-truth at `scripts/repo-local-skills/install-updates/templates/` per P139).
