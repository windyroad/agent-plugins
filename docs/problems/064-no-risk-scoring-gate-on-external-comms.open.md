# Problem 064: No risk-scoring gate on external communications

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 12 (High) — Impact: Significant (4) x Likelihood: Possible (3)
**Effort**: L — new PreToolUse hook surface covering `gh issue create`, `gh issue comment`, `gh pr create`, `gh pr comment`, `gh api .../security-advisories`, `gh api .../comments`, `npm publish` (with README diff), plus leak-pattern rules and integration with `wr-risk-scorer` subagent. Likely needs its own ADR (sibling to the ADR-028 voice-tone-gate ADR) or an extension of ADR-028's surface list.
**WSJF**: 3.0 — (12 × 1.0) / 4 — High-severity leak risk, moderate effort; ranks behind the smaller trigger-wiring gap (P063) but ahead of most medium-WSJF items.

## Description

The `wr-risk-scorer` plugin governs risk on **inbound** pipeline changes — commit, push, release — via `packages/risk-scorer/hooks/git-push-gate.sh` and the `wr-risk-scorer:pipeline` / `assess-release` scoring paths. There is **no equivalent gate on outbound prose** produced for external surfaces:

- `gh issue create` / `gh issue comment` — upstream or cross-repo issue bodies can carry client names, internal prod URLs, schema excerpts, pricing figures, user counts, or other confidential metadata scraped from the local repo context.
- `gh pr create` / `gh pr comment` — PR descriptions against external repos have the same exposure surface.
- `gh api repos/.../security-advisories` — advisory drafts can leak exploitation detail that belongs in a private channel only.
- `npm publish` with a README diff — publishing a package whose README mentions an unannounced feature, a client-specific integration, or a pre-GA capability exposes commercially-sensitive material.
- RapidAPI / marketplace push surfaces — product-page copy sent to third-party marketplaces is external communication with the same exposure pattern.

P038 (No voice-and-tone gate on external communications) covers the **style/tone** half of "Missing voice/risk checks on external output" (the friction category named in the 30-day insights report). This ticket covers the **risk/leak** half, which P038 names in its analytics line but does not scope in its own fix. The two gates are architecturally parallel (both are PreToolUse hooks on the same surface list) but evaluate different content:

- **Voice-and-tone gate (P038)**: rewrites prose to match `docs/VOICE-AND-TONE.md`, strips AI-tell patterns, age-checks target issues.
- **Risk-scoring gate (this ticket)**: detects leak patterns (client names, revenue figures, prod URLs, credentials-shaped tokens, internal roadmap references, any content flagged as `Contains confidential business metrics` by RISK-POLICY.md), halts and surfaces to the user before the outbound call lands.

Absent this gate, every `/wr-itil:report-upstream` invocation (ADR-024), every upstream comment, every npm README publish, every marketplace push is a potential leak event that depends on ad-hoc user review rather than a deterministic gate.

## Symptoms

- Agents draft upstream issue bodies from local-ticket content that includes client names, prod URLs, or internal-system references; the user catches these after-the-fact during a read-through (or doesn't).
- README updates ship via `npm publish` with descriptions of features that are still under embargo or tied to a specific customer rollout.
- PR comments to external repos include repro data (transcripts, log excerpts) whose surrounding context would leak internal architecture or client identity.
- `gh api .../security-advisories` bodies describe exploitation steps in a level of detail that belongs only in the vendor-private channel — agent cannot tell which detail is safe for eventual public advisory publication.
- RISK-POLICY.md's confidential-metrics exclusion applies to the risk-report artefacts (`.risk-reports/`) but not to external-comms bodies — the confidentiality bar is inconsistent across inbound and outbound surfaces.
- `/Users/tomhoward/.claude/usage-data/report.html` 30-day report: "Missing voice/risk checks on external output" is one of the three top friction categories; P038 addresses the voice half but the risk half stays open.

## Workaround

User manually reviews every external-comms draft before it lands. This is the same manual-policing pattern P038 documents as the "manually police AI output" pain point — doubled in practice, because the user has to check both tone AND leak risk on every outbound call. For `/wr-itil:report-upstream` specifically, the skill's voice-tone gate (ADR-028) catches tone issues but has no matching risk-scoring pass.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001)** — every external-comms tool call is a leak-risk moment the persona must police manually; "Enforce governance without slowing down" fails here because the governance surface doesn't cover the highest-consequence outbound channel.
  - **Tech-lead persona (JTBD-201)** — audit trail gains outbound records (good) but those records can carry content that should not have left the repo (bad); the fix-fast-with-audit-trail promise becomes a liability when audit contents leak.
  - **Plugin-developer persona (JTBD-101)** — reusable patterns for external-comms reporting (P055 Part B, `report-upstream`) ship without the risk gate their architecture assumes, so downstream adopters inherit the same exposure.
  - **Anyone receiving upstream reports from this suite** — upstream maintainers (whose repos are targeted by `/wr-itil:report-upstream`) receive reports whose content the sender hasn't risk-scored.
- **Frequency**: Every external-comms tool call. Observed rate across the 30-day insights window: dozens of outbound calls per week across `gh issue`, `gh pr`, and `npm publish` combined.
- **Severity**: Significant. The worst-case outcome is a public issue, advisory, or npm README carrying a client name, revenue number, or unannounced-product detail. Unlike voice-tone (reputational, recoverable), risk-leak incidents are durable (public artefacts are hard to unpublish) and can be contractually serious.
- **Analytics**: `/Users/tomhoward/.claude/usage-data/report.html` — friction category "Missing voice/risk checks on external output" (shared with P038); the insights report explicitly recommends a mandatory pre-flight check on every external surface.

## Root Cause Analysis

### Structural

`wr-risk-scorer` was scoped for inbound pipeline risk (commit/push/release) driven by `RISK-POLICY.md`'s commit-layer / push-layer / release-layer model. External communications were never in scope — ADR-015 (on-demand assessment skills) and ADR-022 don't cover outbound surfaces, and the existing push-gate hook (`packages/risk-scorer/hooks/git-push-gate.sh`) only intercepts `gh pr merge` (to route to `release:watch`). There is no PreToolUse hook fired for `gh issue create`, `gh issue comment`, `gh pr create`, `gh pr comment`, `gh api .../security-advisories`, `gh api .../comments`, or `npm publish` content diffs.

P038's Description (lines 17–26) names the external-comms surface list but scopes enforcement to voice-and-tone only. The risk/leak half is named in the friction category ("Missing voice/risk checks on external output") and in the analytics line but does not appear in P038's fix steps — a scope seam that left the risk-gate work unscheduled.

### Candidate fixes

The gate should be architecturally **parallel to P038's voice-tone hook**, sharing the surface-list inventory but evaluating different content:

1. Inventory the external-comms tool-call patterns that the gate must intercept:
   - `gh issue create` (upstream issue bodies).
   - `gh issue comment` (comment bodies).
   - `gh pr create`, `gh pr comment`, `gh pr review` (PR-body prose).
   - `gh api repos/.../security-advisories` (POST body).
   - `gh api repos/.../comments` (any REST surface accepting a prose body).
   - `npm publish` with a README diff against the previous published version.
   - RapidAPI CLI pushes, marketplace product-page updates (if in scope).
2. Design leak-pattern rules:
   - Confidential-business markers per RISK-POLICY.md (client names, revenue figures, user counts, pricing, internal roadmap references).
   - Credential-shaped tokens (API keys, bearer tokens, AWS keys, GitHub PATs).
   - Prod-URL patterns specific to the user's deployment footprint.
   - Internal-only module names, unannounced-product codenames, embargoed-feature references.
3. Hook implementation:
   - New `packages/risk-scorer/hooks/external-comms-gate.sh` (PreToolUse:Bash for matching command-line patterns; PreToolUse:Write for npm README diffs).
   - Delegates to a new scoring path (subagent `wr-risk-scorer:external-comms` or extension of `wr-risk-scorer:pipeline` — architect review needed).
   - Emits the same deny-plus-delegate pattern ADR-028's voice-tone gate uses, so the two gates compose cleanly on the same surface.
4. Integration with `/wr-itil:report-upstream`:
   - Skill Steps 5 and 6 already document the ADR-028 voice-tone-gate interaction. Add the risk-scoring gate to the same section so the skill documents both.
   - AFK branch: if risk-scoring fires halt-and-surface above appetite, save the drafted report to the local ticket's `## Drafted Upstream Report` section and halt the orchestrator (same pattern as the security-path halt per ADR-024 Consequences).
5. ADR scoping:
   - Likely a sibling ADR to ADR-028 (e.g. `NNN-risk-scoring-gate-external-comms.proposed.md`) rather than an extension, because the content-evaluation surface is materially different (leak patterns vs. voice profile). Architect review will decide whether to split or combine.
   - Update ADR-002 inventory if the hook lives in `packages/risk-scorer/hooks/`.
6. Regression fixtures:
   - Known-bad drafts (containing client names, revenue figures, prod URLs, credentials) — expect the gate to halt.
   - Known-good drafts (sanitised upstream reports, generic bug descriptions) — expect the gate to pass.
   - Borderline cases (repro data that mentions a package name vs. repro data that mentions an internal module) — document the pass/fail call in the fixture.

### Investigation Tasks

- [ ] Inventory external-comms surfaces (reuse P038's list; add any surfaces P038 missed — notably `gh api .../security-advisories`).
- [ ] Draft leak-pattern rules with RISK-POLICY.md authority (confidential-business markers are already defined there; credentials and prod-URLs need rule definitions).
- [ ] Decide gate implementation shape: PreToolUse hook only, skill only, or both (P038 chose both — likely the same answer here for consistency).
- [ ] Decide scoring path: new subagent `wr-risk-scorer:external-comms`, or extend `wr-risk-scorer:pipeline` with an external-comms layer. Architect review.
- [ ] Draft the ADR (sibling to ADR-028). Cross-reference ADR-015 (assessment skills), ADR-028 (voice-tone gate), ADR-024 (report-upstream contract), and RISK-POLICY.md.
- [ ] Build regression fixtures from the 30-day insights window's "FFS" outputs that also carried leak content.
- [ ] Update `/wr-itil:report-upstream` SKILL.md's "Voice-tone gate interaction" section (currently only ADR-028) to document both gates composing on the same surface.
- [ ] Coordinate with P038's implementation so both gates ship together (sharing the surface inventory and the hook scaffolding), or in consecutive iterations.

## Related

- **P038** — voice-and-tone gate on external comms; sibling "external comms needs a gate" scope (voice-tone half).
- **P063** — manage-problem does not trigger `/wr-itil:report-upstream`; sibling wiring gap on the same skill.
- **P055** — parent shipping of `/wr-itil:report-upstream`; the primary external-comms skill that would benefit from this gate.
- **P034** — centralise risk reports; shares the cross-project analytics-driven pattern.
- **ADR-015** (on-demand assessment skills) — the architectural pattern for on-demand risk evaluation.
- **ADR-028** (voice-tone gate on external comms) — the sibling gate; architecture to mirror.
- **ADR-024** (cross-project problem-reporting contract) — the primary consumer; the report-upstream skill relies on outbound-surface gates.
- **RISK-POLICY.md** — authoritative definition of confidential-business markers; extend with credential / prod-URL / embargoed-product rules as part of this fix.
- `packages/risk-scorer/hooks/git-push-gate.sh` — existing risk-scorer hook; only intercepts `gh pr merge`; the new hook will extend the same plugin.
- `/Users/tomhoward/.claude/usage-data/report.html` — insights report (2026-03-17 to 2026-04-16); "Missing voice/risk checks on external output" category.
- **JTBD-001**, **JTBD-101**, **JTBD-201** — the three personas whose constraints this ticket protects.
