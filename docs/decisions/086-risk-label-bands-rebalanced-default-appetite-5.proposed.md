---
status: "proposed"
date: 2026-06-25
human-oversight: confirmed
oversight-date: 2026-06-25
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, downstream adopters]
reassessment-date: 2026-09-25
supersedes: [065-pipeline-gate-threshold-from-risk-policy-appetite]
---

# Risk label bands rebalanced for severe-rare feasibility; default appetite 4 → 5

## Context and Problem Statement

The risk matrix multiplies `Impact × Likelihood` (integers 1-25). The label bands map scores to severity:

| Score Range | Label |
|---|---|
| 1-2 | Very Low |
| 3-4 | Low |
| 5-9 | Medium |
| 10-16 | High |
| 17-25 | Very High |

A class of risks has Impact = 5 (Severe) and no impact-reducing control available — likelihood can be driven down to Rare (1), but the impact dimension is fixed at 5. Their minimum residual is `5 × 1 = 5`, which lands in Medium under the current bands.

For projects whose RISK-POLICY.md sets appetite ≤ 4 (Low), these severe-but-rare risks can never be within appetite. The policy is mathematically infeasible for that class — no amount of control work brings the residual below 5 — yet the gate continues to block the action. The user surfaced this in `../voder-mcp-hub` and pointed to this repo's own `docs/risks/R008-credentials-in-committed-files.active.md` as the canonical case: residual 5 (Medium, above appetite), with the explicit note *"No additional detection control will drop residual below 5 (the Impact floor caps it). Treatment is post-incident: rotation-runbook readiness for WHEN-not-IF the gate's false-negative rate eventually fires."*

ADR-065 set the gate's default appetite at 4 to reproduce the prior hardcoded `score >= 5` behaviour. It did not address the band semantics, so the infeasibility hole persisted at the matrix level rather than the gate level.

## Decision Drivers

- **Policy feasibility** — a project's stated appetite must be reachable through control work, not aspirational. A multiplicative-score matrix that produces unreachable bands is a defect.
- **Adopter default consistency** — the gate's default fallback should align with the matrix's Low ceiling. ADR-065's default 4 sat at the old Low ceiling; that alignment must hold.
- **User-facing clarity** — appetite tighter than the new Low ceiling is policy-authorised (an organisation may explicitly choose to prohibit severe-impact activities), but the consequence — a class of activity becomes effectively prohibited — must be a conscious choice, not a quiet trap.
- **Minimal restructure** — preserve labelling for every score except the one whose semantics this fix is targeting (5). Surgical change beats sweeping rework.
- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — the audit trail must remain truthful; the gate's deny message must state a threshold the project can actually meet.
- **JTBD-003 (Compose Only the Guardrails I Need)** — the default appetite is the no-policy adopter's experience; it must be the right shape for that adopter.
- **JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover)** — tech-lead persona; consistent standards across projects; auditability of the appetite-setting decision.
- **ADR-052 behavioural-tests-default** — band-change verification is bats fixtures asserting gate PASS/FAIL behaviour, not structural greps over the band table.

## Considered Options

1. **Rebalance bands so Low includes 5; shift default appetite 4 → 5; interactive warning at update-policy Step 6 when appetite < 5 (chosen).** Surgical — only `score = 5` changes label (Medium → Low). The default tracks the new Low ceiling. The warning surface preserves the policy author's freedom to set appetite < 5 while making the consequence concrete via register-cited examples.

2. **Asymmetric matrix — score lookup cell-by-cell rather than multiplied.** The user explored and rejected this. Most expressive (encodes severe-rare ≠ frequent-low directly) but requires committing every adopter's RISK-POLICY.md to a full 5×5 ratings grid. User's verdict: too ceremonial relative to the surgical change needed.

3. **Impact-dominant floor — multiplicative score as before, but any Impact = 5 floors the rating at "High" regardless of likelihood.** The user explored and rejected this. Encodes "we will not normalise catastrophic outcomes by rarity" but trades infeasibility-for-Low for permanent-High — severe-impact risks can never drop below High, forcing appetite ≥ 10. Same shape of problem at a higher band.

4. **No matrix change; advise users to raise appetite if they want severe-rare residuals to be reachable.** Rejected: the matrix would silently produce an unreachable Low appetite for the dominant adopter shape (small org, conservative default). Putting the burden on every adopter to discover the math floor and document around it is the inverse of the framework's job.

## Decision Outcome

**Chosen option: Option 1.**

### New label bands

| Score Range | Label |
|---|---|
| 1-2 | Very Low |
| 3-5 | Low |
| 6-9 | Medium |
| 10-16 | High |
| 17-25 | Very High |

The only score whose label changes is `5` (Medium → Low). Every other score retains its current band.

### Default appetite: 5 (was 4)

`packages/risk-scorer/hooks/lib/risk-gate.sh` falls back from `N = 4` to `N = 5` when:
- `RISK_APPETITE` env override is unset, AND
- `RISK-POLICY.md` is absent OR its `## Risk Appetite` section is unparseable.

This is a defensive fallback, not the normal path. The normal path is `/wr-risk-scorer:update-policy` building a policy interactively with the user.

### Interactive warning surface (update-policy Step 6)

When the user picks appetite < 5 in `/wr-risk-scorer:update-policy` Step 6, the skill fires a second `AskUserQuestion` confirm-with-warning. The warning:

1. Scans `docs/risks/R*.active.md` for entries whose Inherent or Residual `**Impact**:` field is `5` (Severe).
2. Cites up to three matching entries by descriptive activity-class first, with the R-ID as the audit pointer (P350 brief-before-ID):
   *"Setting appetite to N means residual-5 risks like credentials-in-committed-files (R008 in your register) and confidential-disclosure-in-outbound-prose (R001) can never be within appetite under this policy — those activities become effectively prohibited."*
3. If `docs/risks/` is empty or contains no Impact=5 entries, falls back to citing the Impact=5 row from the policy's own Impact Levels table (the user has just authored or is editing it, so it's in their working memory).
4. Offers two options: confirm-and-continue (user explicitly accepts the prohibition) or revise (go back to the appetite question).

The warning is interactive rather than a one-shot prose callout because the consequence is load-bearing and a prose warning would be silently consumed under AFK / non-interactive runs.

### This repo's own appetite shifts 4 → 5

`RISK-POLICY.md` in this repo updates from `Threshold: 4 (Low)` to `Threshold: 5 (Low)` per the post-ratify direction 2026-06-25. The plugin packages publish into users' development environments and the brand-reputation impact of a broken install is real, but under the new bands `Threshold: 5` IS still the Low ceiling — the same conservative stance, expressed against the rebalanced matrix.

The classification of `docs/risks/R008-credentials-in-committed-files.active.md` flips from "above appetite" to "within appetite" as a consequence: residual 5 ≤ appetite 5. The post-incident rotation-runbook control that R008's Treatment section already names continues to be the right residual control; what changes is the framing — it's no longer a *rationalization for accepting an above-appetite residual*, it's the *residual control that brings the action within appetite*. Author intent is preserved; only the verdict text and band label move.

### Consequences

**Good**
- Severe-but-rare residuals are now reachable under the default appetite. Adopters who never wrote a RISK-POLICY.md can ship Impact=5-controlled-to-Rare changes without the policy being silently infeasible.
- The default tracks the new Low ceiling — no internal asymmetry between "what counts as Low" and "what the default lets through".
- Surgical: only `score = 5` changes label; the Medium band shrinks by one number (5-9 → 6-9). High and Very High are unchanged.
- The interactive warning makes tighter-than-5 appetite a conscious choice, not a quiet trap. Adopters who genuinely want to prohibit severe-impact activities (e.g. health/safety domains, regulated finance) can still do so — the warning surfaces the consequence so they know they're doing it.
- Pre-existing band drift in `update-policy/SKILL.md` (4-band Low/Medium/High/Critical) gets fixed in the same change, restoring single-source-of-truth between agent prose and policy-creation prose.

**Neutral / accepted**
- Behavioural change for the default fallback: under prior bands a score of 5 was Medium and FAILED the default-4 gate; now it PASSES under default-5. Affects adopters who installed `@windyroad/risk-scorer`, never wrote a `RISK-POLICY.md`, and were silently relying on the default to block score-5 actions. Opt-out is one line in their RISK-POLICY.md (`**Threshold: 4 (Low)**`) — the same configuration this repo uses.
- ADR-042 (auto-apply scorer remediations) and ADR-014 (release cadence) reference the appetite semantically — "within appetite means score ≤ N where N is the policy's threshold" — not by literal value. No amendment needed; the sweep is a grep over scripts to confirm no literal-`4` constant was load-bearing on the old default.
- `docs/risks/R008-credentials-in-committed-files.active.md` Residual band recomputes from Medium to Low AND the verdict shifts from "above appetite" to "within appetite" because this repo's appetite also shifts to 5 in the same change. The Treatment section's named control (rotation-runbook readiness) is preserved as the residual control; only the framing changes — from "accepting an above-appetite residual" to "residual control that brings the action within appetite". Mechanical recomputation, not re-rating.

**Bad / watch**
- A no-policy adopter who was relying on the default to block score-5 actions now passes them silently after their next plugin update. Mitigation: the `risk-scorer-scaffold-nudge.sh` hook nudges to scaffold the register when `RISK-POLICY.md` exists but `docs/risks/` does not; **no nudge yet fires when the policy itself is missing**. The user's intent — *"if there is no policy, the user is interviewed and a policy is created"* — needs an enforcement surface. Captured as a separate problem ticket (see Related).
- Fractional scores (the ADR-065 watch-out) carry forward at the new default: `score = 5.5` now FAILS under default 5; the bats fixture pins the delta to keep the integer-only-equivalence claim auditable.

## Confirmation

Verified by behavioural bats fixtures in `packages/risk-scorer/hooks/test/risk-gate.bats` per ADR-052 behavioural-tests-default — gate PASS/FAIL fixtures against the new default, not structural greps over the band table:

- `RISK-POLICY.md` absent → default appetite 5; score 5 PASSES, score 6 FAILS.
- `RISK-POLICY.md` "Threshold: 5" parse → score 5 PASSES, score 6 FAILS.
- `RISK-POLICY.md` "exceeds 4" — explicit-policy override of default-5 → score 4 PASSES, score 5 FAILS.
- Fractional `score = 5.5` → FAILS under default 5 (integer-only-equivalence delta carried forward from ADR-065, scaled to new default).
- `RISK_APPETITE` env override still takes precedence over the policy parse.

Verified by file inspection:

- `RISK-POLICY.md` (this repo) Label Bands table reflects new boundaries; appetite shifts to `Threshold: 5 (Low)` with updated within-appetite description text.
- `packages/risk-scorer/agents/pipeline.md` Label Bands matches the new shape.
- `packages/risk-scorer/skills/create-risk/SKILL.md` Label Bands restatement matches.
- `packages/risk-scorer/skills/update-policy/SKILL.md` Step 5 band table matches (also fixes pre-existing 4-band Low/Medium/High/Critical drift to the 5-band Very Low / Low / Medium / High / Very High shape).
- `packages/risk-scorer/skills/update-policy/SKILL.md` Step 6 contains the AskUserQuestion confirm-with-warning logic when appetite < 5, with register-derived Impact=5 examples and the policy-row fallback.
- `docs/risks/R008-credentials-in-committed-files.active.md` Residual band recomputed from Medium to Low; verdict shifted from "above appetite" to "within appetite" under the new Threshold: 5; Treatment narrative reframed (rotation-runbook is the residual control, not a rationalization).
- ADR-065 renamed to `065-pipeline-gate-threshold-from-risk-policy-appetite.superseded.md`; `docs/decisions/README.md` regenerated.

## Pros and Cons of the Options

### Option 1: Rebalance + default 5 + interactive warning (chosen)
- Good: matches Low ceiling to default appetite; surgical (one score's label changes); the warning surface keeps tight-appetite intentional rather than silently broken.
- Bad: behavioural change for quiet-default adopters; small ongoing maintenance for the warning surface (must keep its scan robust against register schema drift).

### Option 2: Asymmetric matrix (rejected)
- Good: most expressive — encodes severe-rare ≠ frequent-low directly per row/column cell.
- Bad: requires every adopter to commit to a 5×5 ratings grid in RISK-POLICY.md; heavier policy doc; user verdict: too ceremonial relative to the surgical change needed.

### Option 3: Impact-dominant floor (rejected)
- Good: encodes "severe events are not normalised by rarity".
- Bad: trades infeasibility-for-Low for permanent-High; severe-impact risks can never drop below High, forcing appetite ≥ 10 — same shape of problem.

### Option 4: No change; raise appetite (rejected)
- Bad: leaves the matrix silently infeasible for the conservative default appetite shape; the symptom resurfaces in every fresh adopter; inverts the framework's responsibility.

## Reassessment Criteria

Revisit if:

- Adopters report that the default-5 fallback silently passes score-5 actions they expected blocked (signals the default needs to be revisited, OR the policy-absence auto-trigger gap needs urgent closure).
- A second class of impact-floored risks emerges where the new Low ceiling at 5 still can't reach (e.g., a future risk class with no controls drops residual exactly to 5 and the project wants the band tighter than Low).
- The Step 6 interactive warning fires so rarely that it's dead code, or so frequently that users learn to dismiss it without reading — both signal a calibration miss.
- The ratio of register entries with Impact=5 vs Impact<5 shifts materially across adopters (signals the Low ceiling should move).
- `update-policy` SKILL drifts again from the agent's band shape (signals the inline restatement pattern is fragile; consider extracting bands into a single source).

## Related

- **ADR-065** (Pipeline gate threshold from RISK-POLICY.md appetite) — superseded by this ADR. The threshold-derivation mechanism (parse policy, env override, default fallback) is preserved; the default value and band boundaries are revised.
- **ADR-013** (Below-appetite output rule), **ADR-042** (Auto-apply scorer remediations), **ADR-014** (Release cadence) — these reference the appetite semantically, not by literal value. No amendment needed.
- **ADR-052** (Behavioural tests default) — Confirmation fixtures follow this default.
- **ADR-026** (Cite + persist + uncertainty) — the warning's "concrete register-derived examples" pattern grounds the consequence in a re-readable artefact.
- **ADR-077** (Decisions compendium auto-generation) — `docs/decisions/README.md` regenerates after this ADR lands and after the ADR-065 rename.
- **R008-credentials-in-committed-files** — canonical Impact=5 register entry; the worked example for the warning.
- **R001-confidential-disclosure-in-outbound-prose** — additional Impact=5 register entry for the warning's example list.
- **P??? (deferred)** — separate problem ticket to capture: no nudge fires when `RISK-POLICY.md` is missing; the user's intent (interview-and-create on policy-absence) needs an enforcement surface. Out of scope for this ADR.
- **Voder-mcp-hub** — adopter project where the user surfaced the matrix infeasibility problem; this ADR's release flows downstream via the `/install-updates` cache refresh.
- **JTBD-002**, **JTBD-003**, **JTBD-202** — personas whose needs drive this decision.
