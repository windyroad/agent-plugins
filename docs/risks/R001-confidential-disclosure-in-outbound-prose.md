# R001: Confidential / business-metric disclosure in outbound prose

A draft outbound prose body (gh issue/pr/api, npm publish content, `.changeset/*.md` body, ticket body that may be published in CHANGELOGs) contains content matching a `RISK-POLICY.md` `## Confidential Information` class — credentials, business-context-paired financial figures, user counts, client names, pricing, traffic volumes, internal roadmap. Once the prose lands on a public/permanent surface (CHANGELOG → npm tarball; published GitHub issue), retraction is partial-or-impossible.

Distinct from prompt-injection or source-content leakage to the LLM provider — this class is specifically about **prose drafted by the agent for outbound surfaces**. For credentials/secrets entering committed files (which is git-history-permanent immediately), see R008.

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 3 (Moderate) — `RISK-POLICY.md` L63 explicitly classes "confidential business metrics (client names, revenue, pricing) committed to repository" as Moderate. CHANGELOG → npm tarball amplifies the surface but the per-incident impact class is Moderate. (Auth-token / private-key sub-class would escalate to Severe but that's R008's surface.)
- **Likelihood**: 4 (Likely) — agent has Read access to confidential session context; without an outbound-prose gate, leakage on every drafted body is the default trajectory.
- **Inherent score**: 12
- **Inherent band**: High

## Residual risk

Per `RISK-POLICY.md` `## Control Composition`:

- **Likelihood after controls**: 2 (Unlikely) — two independent paths reduce 2 bands from 4: regex pre-filter (catches structured leak shapes) + LLM-walk subagent (catches prose-context leaks the regex misses). Marker hash, BYPASS env-var, and policy-class taxonomy are operational/relaxation/declarative, not band-reducing.
- **Residual score**: 6
- **Residual band**: Medium

**Gap-to-appetite**: residual exceeds appetite (4/Low). One more independent control path (e.g., semantic-similarity check on draft against confidential-class corpus; ML content classifier; second-pass review by a different agent) would drop residual likelihood to 1 and the score to 3/Low.

## Controls

- `packages/risk-scorer/hooks/external-comms-gate.sh` (P064) — PreToolUse:Bash + PreToolUse:Edit gate on outbound-prose author surfaces; routes to regex pre-filter (`hooks/lib/leak-detect.sh`) and the `wr-risk-scorer:external-comms` subagent for prose-context review.
- PostToolUse marker hook keyed on `sha256(draft + '\n' + surface)` — skips re-prompt on the same draft+surface combination.
- `RISK-POLICY.md` `## Confidential Information` — names the canonical classes the gate scans for.
- `BYPASS_RISK_GATE=1` — explicit override (e.g., publishing-org's own namespace per ADR-055; not a leak when it's our own).

## Watch-out

- `.changeset/*.md` bodies count as outbound prose because they land verbatim in CHANGELOG.md and every published npm tarball (P073).
- The subagent path can emit a placeholder `EXTERNAL_COMMS_RISK_KEY` instead of the actual SHA, causing the marker hook to reject and the gate to re-fire (P163, P166). Precompute the SHA in the calling skill.
- "Cross-context leak" sub-class (an agent invoked for purpose A sees confidential info from prior turn purpose B and uses it in outbound prose) — the gate catches this on the regex/subagent path; doesn't catch suppression failure when the agent paraphrases.
