---
risk_id: R003
slug: confidentiality-leakage-via-outbound-prose
status: Active
category: infosec
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [gh issue create / pr create / api ., npm publish, .changeset/*.md, packages/*/CHANGELOG.md, README.md commits, security advisory bodies]
cascade_scope: every adopter session that authors outbound prose; every release pipeline that publishes CHANGELOG/release-notes
afk_class: both
reversal_class: npm-permanent (changesets land in CHANGELOG which lands in every npm tarball; gh issue/pr bodies are public-cached); some surfaces (gh issue comments) editable, some (npm publish, security advisory) effectively permanent
control_budget_class: free-hook (PreToolUse:Bash + PreToolUse:Edit) + per-edit-llm (wr-risk-scorer:external-comms agent invocation when regex pre-filter doesn't match)
dogfood_days: ~8 (P064 external-comms gate held since 2026-04-26)
authority_class: framework-resolved (regex pre-filter is mechanical); deviation-approval (BYPASS_RISK_GATE=1 explicit user override)
prompt_cache_window: ongoing
ci_a: confidentiality (per ISO 27001 §6.1.2 — primary); reputational impact dimension is brand
agentic_category: drift (prompt-context leakage), cascade (outbound prose flows to permanent surfaces)
---

# Risk R003: Confidentiality leakage via outbound prose

## Description

The agent has Read access to source content + session context + adopter-project files, and Write access to outbound-prose surfaces (gh issue/pr/api bodies, npm publish content, `.changeset/*.md` bodies that land in CHANGELOG.md and every npm tarball). When the agent drafts outbound prose, the prose can inadvertently include business metrics (revenue, user counts, pricing, traffic volumes), client names, internal roadmap details, or other confidential-information classes defined in `RISK-POLICY.md` `## Confidential Information`.

The risk is structurally novel for agentic systems: the agent sees the full prompt context (which may include confidential info from a prior turn unrelated to the current outbound action), and the per-tool-grant access control (Edit/Write boundary) is too coarse — the prompt itself is the leakage vector.

**Source → event → consequence chain**: source = agent context contains confidential class (file content read, prior turn, MCP tool output); event = agent drafts outbound prose verbatim or paraphrased; consequence = confidential info lands on a permanent public surface (gh issue, npm tarball, security advisory) where retraction is partial/impossible.

## Inherent Risk

- **Impact**: 5/5 (Severe) — for the public-repo case where business metrics or client names land in a CHANGELOG that ships in every npm tarball; ISO 27001 confidentiality dimension is the load-bearing concern. Reputational and legal exposure both apply. RISK-POLICY.md Impact Levels §3 explicitly classifies "confidential business metrics (client names, revenue, pricing) committed to repository" as Moderate impact (level 3) for general public repos and §5 escalates to Severe when published packages are involved (which is exactly the changeset → CHANGELOG → npm tarball path).
- **Likelihood**: 3/5 (Possible) — corpus evidence: 5+ "Confidential information disclosure" risk items in the report sample (`#### Risk 2: Confidential information disclosure` × 3, `Risk 3: Confidential information disclosure` × 2). The agent has triggered the regex pre-filter often enough that the gate's catch is a measurable surface, not theoretical.
- **Inherent Score**: 15
- **Inherent Band**: High

## Controls

- **`packages/risk-scorer/hooks/external-comms-gate.sh`** (P064; held for dogfood since 2026-04-26) — PreToolUse:Bash + PreToolUse:Edit gate intercepts outbound prose author surfaces. Two-stage: (1) `hooks/lib/leak-detect.sh` regex pre-filter on credentials + business-context-paired financial figures + user counts → immediate deny; (2) anything not pre-filtered routed to `wr-risk-scorer:external-comms` subagent for context-aware review against `RISK-POLICY.md` Confidential Information classes. **Effectiveness**: high for the catch-classes the regex covers; medium for the LLM-walk path (subject to false-negative if the agent reviewer misses a class). Reduces likelihood from 3 to 1 for regex-covered classes; from 3 to 2 for prose-context classes.
- **PostToolUse marker hook** — writes per-draft marker keyed on `sha256(draft + '\n' + surface)` when `EXTERNAL_COMMS_RISK_VERDICT: PASS` is emitted. Prevents re-prompting on the same draft+surface combination. **Effectiveness**: medium (UX more than security); reduces friction so the gate stays opt-in not workaround-target.
- **`RISK-POLICY.md` `## Confidential Information`** — defines the canonical class taxonomy (revenue, client names, user counts, pricing, traffic volumes, internal roadmap). **Effectiveness**: medium — naming the classes is the first step; effectiveness depends on reviewer fidelity.
- **`BYPASS_RISK_GATE=1` env-var override** — documented escape for cases where the user has confirmed the content is safe (e.g. "client name" is the publishing org itself per ADR-055 namespace-prefix). **Effectiveness**: control-relaxation, not control; documented to surface intentional overrides for audit trail.
- **Held-changeset pattern** (R008) — mitigates the gate-regression-ships-to-adopters cascade for the gate-hook itself.

## Residual Risk

- **Impact**: 4/5 (Significant) — controls reduce probability of the leak occurring but don't change consequence shape if a leak does land. Reduced from Severe because the typical failure path (regex pre-filter catches it) cuts off the npm-publish trajectory before it reaches permanent surfaces.
- **Likelihood**: 1/5 (Rare) — three independent control paths (regex pre-filter + LLM-walk subagent + per-draft marker hash) each fire in the routine flow; bypass is explicit env-var requiring conscious user action. Observed false-negative rate on the regex pre-filter is near zero in dogfood window (~8 days, ~10 outbound-prose author actions per day estimate, zero observed leaks).
- **Residual Score**: 4
- **Residual Band**: Low
- **Within appetite?**: Yes (= 4/Low).

## Treatment

**Mitigate**. Continue dogfood window for P064 external-comms gate; promote to released-on-npm when held-area's reinstate trigger fires (user signals comfort OR scorer downgrades residual after extended dogfood observation).

**Active mitigations**:
1. Continue running the gate on every outbound-prose author surface.
2. Extend regex pre-filter as new confidential-class shapes surface in the corpus.
3. Audit BYPASS_RISK_GATE=1 invocations quarterly (each should have a one-line rationale comment in the calling commit).

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: a confidential-class leak reaches a public surface (gh issue/pr/CHANGELOG/npm). Or: BYPASS_RISK_GATE=1 invocation rate exceeds 1 per 10 outbound-prose actions (signals the gate is too noisy and users are routing around it). Or: regex pre-filter catches a new class shape that should be promoted into `leak-detect.sh`.
- **Metrics**: count of regex-pre-filter denies / week; count of LLM-walk-subagent FAIL verdicts / week; count of BYPASS_RISK_GATE=1 invocations / month; count of confirmed leaks reaching permanent public surfaces (target 0).

## Related

- **Criteria**: `RISK-POLICY.md` `## Confidential Information` section.
- **Realised-as**: P064 (external-comms gate driver ticket — verifying); P073 (voice-and-tone gate on changeset authoring — open, related-domain). The 5+ "Confidential information disclosure" risk items across `.risk-reports/` are the recurring instances this risk class covers.
- **Treatment ADRs**: ADR-013 Rule 5 (silent proceed for marker-cleared drafts), ADR-026 (grounding sentinel applies to LLM-walk verdict shape), ADR-042 (auto-apply remediations for above-appetite outbound prose), ADR-055 (namespace-prefixed permalinks; defines what's our-own-org-publishing vs external-client).
- **Personas affected**: plugin-maintainer (release-time outbound prose); plugin-user (audit-day exposure if leak landed); tech-lead (JTBD-202 audit-trail integrity).

## Source Evidence

- `.risk-reports/*.md` corpus — "Confidential information disclosure" risk items recurring (5+ instances counted in the sample).
- `packages/risk-scorer/hooks/external-comms-gate.sh` — control implementation.
- `packages/risk-scorer/hooks/lib/leak-detect.sh` — regex pre-filter implementation.
- `packages/risk-scorer/agents/external-comms.md` — LLM-walk subagent prompt.
- `docs/problems/064-external-comms-leak-via-outbound-prose-gate.verifying.md` (or current state) — driver ticket.
- `docs/changesets-holding/wr-risk-scorer-p064-external-comms-gate.md` — held for dogfood; reinstate trigger documented.
- `RISK-POLICY.md` lines 19-29 (`## Confidential Information` section) — control authority.

## Change Log

- 2026-05-04: Bootstrapped from corpus evidence post-wipe. The pre-wipe R001 ("Confidential information leak via public-repo push") covered the same theme at residual 9/Medium under pre-correction scoring (4 controls, 1-band reduction); the corrected `## Control Composition` rule + the dogfood evidence on P064's regex catch-rate justifies residual 4/Low when the gate is shipped.
