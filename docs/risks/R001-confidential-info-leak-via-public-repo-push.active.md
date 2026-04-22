# Risk R001: Confidential information leak via public-repo push

**Status**: Active
**Category**: infosec
**Identified**: 2026-04-22
**Owner**: plugin-maintainer
**Last reviewed**: 2026-04-22
**Next review**: 2026-10-22

## Description

This repository is public (npm-published plugins). Authoring sessions naturally pull in context from other client engagements, internal business metrics, download/user counts, pricing, and roadmap details — any of which would be a policy breach if committed. The risk is not a single discrete leak event but the ongoing exposure of every edit to the possibility that an assistant (Claude Code, Codex, or others) or the user copies context from a non-public source into a file that gets committed and pushed.

Realised form: confidential strings appear in `docs/`, commit messages, code comments, problem tickets, or retro reports and are pushed to the public remote before review catches them. Cost of realisation is the combined effort of `git filter-repo` history rewrite, force-push coordination, and potential credential rotation — plus the reputation impact of having been publicly exposed prior to rewrite.

## Inherent Risk

Impact × Likelihood *before* controls.

- **Impact**: 3 (Moderate — per `RISK-POLICY.md` Impact level 3: "For public repo: confidential business metrics (client names, revenue, pricing) committed to repository")
- **Likelihood**: 4 (Likely — without controls, session context routinely pulls in non-public info; multiple near-misses observed)
- **Inherent Score**: 12
- **Inherent Band**: High

## Controls

- **`secret-leak-gate.sh` hook** — blocks Edit/Write containing API keys, tokens, passwords via regex scan. Implemented in `packages/risk-scorer/hooks/secret-leak-gate.sh`.
- **`RISK-POLICY.md` Confidential Information section** — written policy enumerates forbidden categories (client names, revenue, pricing, user counts, roadmap). Implemented in `RISK-POLICY.md` lines 17-26.
- **Pipeline Layer 2 confidential-info scan** — `wr-risk-scorer:pipeline` scores confidential-info risk on each commit/push/release. Implemented in `packages/risk-scorer/agents/pipeline.md`.
- **`git-push-gate.sh` hook** — blocks bare `git push`; forces push through `push:watch` which runs the pipeline scan. Implemented in `packages/risk-scorer/hooks/git-push-gate.sh`.

## Residual Risk

Impact × Likelihood *after* controls.

- **Impact**: 3 (Moderate — controls reduce likelihood, not impact; a leak that slips through is still Moderate)
- **Likelihood**: 3 (Possible — secret-regex controls do not catch prose confidentials e.g. client names; pipeline scan surfaces but does not hard-block; depends on reviewer judgement)
- **Residual Score**: 9
- **Residual Band**: Medium
- **Within appetite?**: No (appetite threshold is 4 Low; residual of 9 Medium exceeds)

## Treatment

**Mitigate**. Residual is above appetite and the impact category is policy-critical for a public repo. Residual stays Medium pending two control improvements: (a) a client-name / brand-term denylist in the secret-leak-gate (surfaced as a future problem ticket), and (b) a pre-push confidential-info structural scan that hard-blocks rather than scoring. Accept the Medium residual for now because every pipeline action scores and surfaces the risk, giving the reviewer a chance to catch it before push.

## Monitoring

- **Trigger to re-assess**: Any observed near-miss or realised leak. Any change to `RISK-POLICY.md` Impact level 3 definition. Any change to `secret-leak-gate.sh` or the pipeline's Layer 2 scan.
- **Metrics**: Count of pipeline reports flagging confidential-info at risk ≥ 1 per month; count of pre-push retractions caused by confidential content.

## Related

- Criteria: `RISK-POLICY.md` (Confidential Information section; Impact level 3)
- Realised-as: (none at time of creation — this is an in-flight standing risk surfaced repeatedly in session pipeline reports)
- Treatment ADRs: `docs/decisions/026-agent-output-grounding.proposed.md` (grounding of Layer 2 scan outputs)
- Personas affected: `docs/jtbd/tech-lead/persona.md` (auditability), `docs/jtbd/solo-developer/persona.md` (governance-without-slowing)

## Change Log

- 2026-04-22: Initial identification. Seeded as the first entry of the populated register (P102 MVP invocation surface).
