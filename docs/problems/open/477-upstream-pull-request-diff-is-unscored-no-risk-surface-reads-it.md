# Problem 477: The upstream pull-request diff is unscored — no risk surface reads a diff against an upstream's policy or contribution standards

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture from the description per Step 4a. Impact 3: an unreviewed diff lands in a third party's repository under our name; the failure mode is a rejected contribution, or worse, an accepted-and-regretted one. Reputational and recipient harm, no shipped-package damage — RISK-POLICY.md rates this band Moderate. Likelihood 3: fires on every interactive pull request opened under ADR-102, which is now the preferred outbound artefact — cf. P464 (external-comms dispatch obligations, same outbound surface).
**Origin**: internal
**Effort**: L — derived at capture per Step 4a. Needs a new scorer action in ADR-015's taxonomy (or an upstream-policy mode on the pipeline scorer), a notion of an upstream's contribution standards as a machine-readable input, and a definition of "within appetite" for a repository we do not own. ADR-102:110 says closing it needs its own work informed by what a first real pull request actually hits.
**WSJF**: 2.25 — (9 × 1.0) / 4
**JTBD**: JTBD-001, JTBD-010
**Persona**: developer

## Description

[ADR-102](../../decisions/102-prefer-an-upstream-pull-request-over-an-issue.proposed.md) makes a pull request the preferred outbound artefact for `/wr-itil:report-upstream` when the upstream accepts pull requests. A pull request carries **two** outbound surfaces where an issue carries one: the prose, and the diff.

The prose is already covered and needs no work. ADR-028's external-comms gate arms on `gh pr create`, `gh pr comment` and `gh pr edit` — verified on disk at `packages/shared/hooks/external-comms-gate.sh:162-167` — so both `wr-risk-scorer:external-comms` and `wr-voice-tone:external-comms` fire on a pull request title and body exactly as they do on an issue body.

**The diff is not covered.** Nothing scores it:

- The external-comms gate reads prose only.
- The pipeline scorer does read diffs, but against **our** policy. `packages/risk-scorer/agents/pipeline.md` reads the local `RISK-POLICY.md` for impact levels and the appetite threshold (`:171`, `:180`) and the local `docs/risks/` catalog for standing risks (`:56`). It has no notion of an upstream's policy or contribution standards.
- Its action taxonomy is fixed as commit, push and release. ADR-015:90 registers `assess-release` as "Commit/push/release risk score". There is no action for "open a pull request against a repository we do not own".

The gap therefore sits across ADR-015's action taxonomy and `RISK-POLICY.md`, not in any single decision that owns it.

This ticket exists to satisfy ADR-102's Confirmation criterion at `:159` — *"The unscored-diff surface is either closed or carries its own problem ticket."* ADR-102:110 is explicit: *"Naming this surface is part of this decision. Closing it is not."* It is deliberately NOT closed by the skill change that implements ADR-102, and it must not be closed ahead of the evidence named under Dependencies.

## Symptoms

- A pull request opened by `/wr-itil:report-upstream` carries a diff no gate has read.
- JTBD-001 (Enforce Governance Without Slowing Down) Desired Outcome 1 at `docs/jtbd/developer/JTBD-001-enforce-governance.proposed.md:19` — *"Every edit to a project file is reviewed against relevant policy before it lands"* — is not met on the pull-request surface. A pull request diff is an edit that lands.
- There is no `assess-*` skill an operator can invoke to score a contribution diff even manually.

## Workaround

Human review of the diff before `gh pr create`.

Under AFK there is no exposure today: ADR-102:80 degrades the pull-request branch to the issue branch and queues the drafted pull request to `## Queued Upstream Report`, so no unattended session opens a pull request at all. The gap is live only on the interactive path, where a human is present and can read the diff.

## Impact Assessment

- **Who is affected**: upstream maintainers receiving our contributions; the maintainer's standing as a contributor; adopters who inherit the skill's behaviour against their own upstreams.
- **Frequency**: every interactive pull request opened under ADR-102. Zero under AFK, by construction.
- **Severity**: Medium (9) — no shipped-package damage; the harm is a rejected or regretted contribution and the reputational cost of it.
- **Analytics**: 2026-08-08 — gap named in ADR-102 `:108` and booked as a Bad consequence at `:142`; ticketed at capture rather than closed, per that ADR's own instruction at `:110`.

## Root Cause Analysis

The risk-scoring corpus was built for a single-repository model. Every scorer reads the local policy because, until ADR-102, every diff the loop produced landed locally. A contribution inverts that premise: the diff is judged by someone else's conventions, against a policy we cannot read and may not be able to discover.

### Investigation Tasks

- [ ] Decide whether the upstream-diff surface warrants a new scorer action in ADR-015's taxonomy, or an upstream-policy mode on the existing pipeline scorer.
- [ ] Determine what an upstream's contribution standards look like as a machine-readable input — `CONTRIBUTING.md`, linter config, CI workflow files — and whether any of it is reliably discoverable.
- [ ] Decide what "within appetite" means for a repository we do not own. `RISK-POLICY.md`'s impact levels are expressed in terms of our packages and our adopters; neither applies.
- [ ] Wait for evidence before designing. ADR-102:110 says closing this must be informed by what a first real pull request actually hits.
- [ ] Behavioural coverage: a pull-request path carrying a diff no gate has read is detectable.

## Dependencies

- **Blocks**: (none) — ADR-102's Confirmation criterion `:159` is discharged by this ticket's existence, not by its closure.
- **Blocked by**: evidence from a first real pull request driven end to end under ADR-102 (that ADR's Confirmation criterion `:161`).
- **Composes with**: ADR-015 (action taxonomy — one of the two local homes of this gap), `RISK-POLICY.md` (the other), ADR-028 (the prose half, already covered, needs no change), ADR-023 (no performance budget governs the `gh` call surface either — a sibling ungoverned-budget gap ADR-102:96 names).

## Related

- [ADR-102](../../decisions/102-prefer-an-upstream-pull-request-over-an-issue.proposed.md) (Prefer an upstream pull request over an issue when the upstream accepts pull requests) — the governing decision, ratified 2026-08-08. Names this surface at `:108`, books it at `:142`, requires it be closed or ticketed at `:159`. Its Reassessment Criteria at `:193` make "a pull request rejected or reverted on grounds the unscored-diff surface would have caught" a trigger to promote closing this gap from follow-on work to a precondition.
- Captured via `/wr-itil:capture-problem` while implementing ADR-102 in `/wr-itil:report-upstream` (2026-08-08), as that ADR instructed. Mirrored as public GitHub tracking issue [#416](https://github.com/windyroad/agent-plugins/issues/416) so the pull request implementing ADR-102 can link it; the GitHub issue is a pointer, this ticket is the backlog record.
- **P464** (`docs/problems/open/464-agent-self-limits-external-comms-as-out-of-scope-in-afk-preflight.md`) — sibling on the same outbound surface: there the agent under-dispatches external comms it is authorised to send; here the framework under-scores a surface it is not yet equipped to read. Both are consequences of the outbound path growing faster than the gates around it.
