# Risk Policy — Windy Road Agent Plugins

> ISO 31000-aligned risk criteria for pipeline risk scoring.
> Last reviewed: 2026-06-16

> Reviewed quarterly and after any significant change to distribution channels, package architecture, or CI/CD infrastructure.

## Business Context

This repository contains the Windy Road Agent Plugins suite — independently installable npm packages (`@windyroad/*`) that provide architecture governance, risk management, TDD enforcement, and delivery quality plugins for AI coding agents (Claude Code, Codex, Cursor, and others). These plugins promote Windy Road Technology's consulting services at windyroad.com.au.

Packages are distributed via:
- **npm registry** (`latest` and `preview` tags) with provenance signing
- **Claude Code marketplace** (agents and hooks)
- **Skills package** (slash command skills with autocomplete)

Users install via `npx @windyroad/agent-plugins` or individual packages like `npx @windyroad/architect`. The installer orchestrates both npm and marketplace distribution.

## Confidential Information

This is a **public repository**. The following must never appear in committed files:

- Client names, project names, or engagement details
- Revenue figures, pricing, or financial metrics
- User counts, download statistics, or traffic volumes
- Internal business strategy or roadmap details

Use generic descriptions (e.g., "users", "clients") instead of specific names. If confidential information is accidentally committed, treat it as a Moderate impact incident requiring immediate remediation (git history rewrite).

## Inbound Report Risk Classes

Inbound reports filed against this repo's intake (`problem-report.yml` issues, Q&A discussions, security-advisory submissions) are reviewed by the `wr-risk-scorer:inbound-report` subagent (per ADR-062 § Sibling subagent — sibling of `:external-comms`, NOT extension). The subagent classifies each report against two axes; a match on either axis routes the report away from the safe-and-valid branch.

**Direction note**: this section governs third-party prose flowing INWARD. `## Confidential Information` above governs OUR outbound prose. The two sections cover opposite directions of risk; both apply per their respective gates.

### Axis 1 — Request-risk (is the report itself an attack vector?)

- **Info-extraction**: requests for repository internals, build secrets, deployment paths, credentials, contributor PII, or other non-public information that a legitimate problem report does not require.
- **Backdoor request**: requests disguised as feature/bug reports that would add a backdoor, weaken a safety check, disable a security feature, or expose an internal API.
- **Malicious-code injection**: requests to incorporate user-supplied code (script snippets, regex patterns, prompt templates, hook payloads, dependency additions) that read as likely-malicious in the context they would execute.

A clear-malicious match on Axis 1 routes to the **clear-malicious-close-with-verdict** branch (per ADR-062 step 5): the assessment-pipeline posts a brief gated verdict comment (P064 risk + P038 voice-tone gates per ADR-028 amended), closes the upstream issue, and appends the reporter handle to `docs/audits/inbound-discovery-log.md`. P123 block-list enforcement consumes this audit-log when that ticket lands.

An above-threshold (ambiguous) Axis 1 match routes to the **above-threshold-pushback** branch (per ADR-062 step 4): the pipeline posts a gated declining comment; the maintainer decides closure manually.

### Axis 2 — Fix-risk (what is the risk profile of doing the work the report asks for?)

Some legitimate-looking reports request changes that are themselves high-risk to ship. These are not malicious — they are requests-for-work-that-must-be-weighed.

- **Privilege escalation**: the requested fix would let the requester (or others, including downstream adopters) escalate privilege within the suite.
- **Removal of load-bearing safety check**: the requested fix removes a check whose removal increases risk to users (e.g. removing a gate that prevents an accidental destructive operation).
- **Adopter-attack-surface expansion**: the requested fix would expand the attack surface across all adopters (e.g. shipping a credential-handling pattern, broadening a permissive default, adding a network-access primitive to a hook script).

A `safe-low-fix-risk` classification on Axis 2 continues to the **safe-and-valid-local-ticket-create** branch with no flag.

A `safe-high-fix-risk` classification continues to the same branch but flags the local ticket for maintainer attention before any implementation begins — the pipeline creates the ticket so JTBD-301's acknowledgement contract is honored, but the fix-risk class is surfaced to the maintainer at the next interactive `review-problems` invocation.

A `clear-malicious` Axis 2 match (rare; covers cases where a request is so high-fix-risk that it crosses the malicious threshold even without Axis 1 attack-intent signals) routes to the **above-threshold-pushback** branch.

### Verdict combinations

The subagent emits one of four classifications: `safe-low-fix-risk` / `safe-high-fix-risk` / `above-threshold-risk` / `clear-malicious-request`. Branch routing per the table in `packages/risk-scorer/agents/inbound-report.md` § Verdict combinations.

### Grounding

Every FAIL verdict cites the specific class violated (verbatim — copy the bullet from this policy), the axis the class belongs to, and the exact substring or metadata signal that triggered the match. Per ADR-026 grounding discipline.

## Risk Appetite

**Threshold: 5 (Low)**

Pipeline gates block when cumulative residual risk exceeds 5. This means:
- Very Low (1-2) and Low (3-5) risk changes proceed without intervention
- Medium (6-9) and above require explicit acknowledgement or risk reduction

This conservative threshold reflects that these packages are installed into users' development environments and promote a professional services brand. Broken installs or misbehaving hooks directly damage user trust and brand reputation.

The threshold tracks the new Low ceiling under ADR-086's rebalanced label bands (was 4 under superseded ADR-065). The shift admits residual=5 (the Impact=5/Likelihood=1 floor for severe-but-rare risks like R008-credentials-in-committed-files) within appetite, with the residual control being the post-incident rotation-runbook readiness named in those risks' Treatment sections.

## Risk Catalog

The persistent catalog of per-action risks for this project lives in `docs/risks/`. Each `R<NNN>-<title>.active.md` file documents a risk class — description, controls, inherent and residual scores, treatment, monitoring — using the shape in `docs/risks/TEMPLATE.md`.

The catalog is consumed by **per-action risk assessments** (commit / push / release / external-comms / etc.):

1. The assessing agent reads `docs/risks/` and filters to risks that apply to THIS action.
2. For each applicable risk, it assesses whether the documented controls are in effect for this action and computes residual against the **same 5/Low appetite**.
3. If residual exceeds appetite, the agent applies additional controls, or blocks/halts the action per the gate-specific rules.
4. If the agent conceives a new risk class during assessment that is not yet documented, it adds an entry to `docs/risks/` so it carries forward to the next assessment.

The catalog eliminates the wasted effort of re-deriving the same risk classes on every assessment, and reduces the chance that a previously-recognised risk is missed because the agent didn't think of it this time.

A catalog-documented residual above appetite is a **real signal** — it means baseline controls are not sufficient for the typical action that triggers this risk class. Either add more controls (drop baseline residual into appetite) or accept that per-action assessments must add specific controls each time.

Same appetite (5/Low). Same risk-matrix scoring. The catalog is the persistent record; per-action assessments are the live application.

## Impact Levels

| Level | Label | Description |
|-------|-------|-------------|
| 1 | Negligible | Docs, comments, or internal tooling only — no effect on published packages or installed plugins |
| 2 | Minor | CI workflow or dev tooling affected — published packages and installed plugins unaffected |
| 3 | Moderate | npm publish or marketplace distribution disrupted — users can't install updates. For public repo: confidential business metrics (client names, revenue, pricing) committed to repository |
| 4 | Significant | Installed plugins degrade developer workflow — hooks fire incorrectly, skills fail to load, or installer breaks for users who already have the packages |
| 5 | Severe | Installer silently corrupts user's Claude Code config, publishes packages with malicious/broken bin scripts, or leaks npm auth tokens via CI logs |

## Likelihood Levels

| Level | Label | Description |
|-------|-------|-------------|
| 1 | Rare | Requires specific, unusual conditions. Extensive test coverage or architectural safeguards make occurrence very unlikely. |
| 2 | Unlikely | Could happen but controls (tests, CI gates, review hooks) significantly reduce probability. |
| 3 | Possible | Moderate complexity or limited test coverage. Could happen under normal conditions. |
| 4 | Likely | High complexity, many code paths, or limited controls. Expected to occur without intervention. |
| 5 | Almost certain | Known gap, no controls in place, or previously observed failure mode. |

## Risk Matrix

| Impact ↓ · Likelihood → | 1 Rare | 2 Unlikely | 3 Possible | 4 Likely | 5 Almost certain |
|---|---|---|---|---|---|
| 1 Negligible | 1 | 2 | 3 | 4 | 5 |
| 2 Minor | 2 | 4 | 6 | 8 | 10 |
| 3 Moderate | 3 | 6 | 9 | 12 | 15 |
| 4 Significant | 4 | 8 | 12 | 16 | 20 |
| 5 Severe | 5 | 10 | 15 | 20 | 25 |

### Label Bands

| Score Range | Label |
|-------------|-------|
| 1-2 | Very Low |
| 3-5 | Low |
| 6-9 | Medium |
| 10-16 | High |
| 17-25 | Very High |

Boundaries per ADR-086. Only `score = 5` differs from the superseded ADR-065 bands: previously Medium, now Low — restoring feasibility for severe-but-rare residuals (Impact=5 × Likelihood=1).

This risk matrix is referenced by both the **risk-scorer agent** (pipeline risk assessment) and the **problem management process** (`/wr:problem` skill for problem severity classification).

## Control Composition

When a risk lists multiple controls, residual likelihood is reduced based on the number of **independent** control paths. ISO 31000 § 6.4.2 leaves the composition rule implementation-defined; this section codifies the project's rule so residual computations are grounded (per ADR-026) rather than ad-hoc. The rule applies uniformly — both when authoring or re-rating a catalog entry in `docs/risks/`, and when assessing a per-action risk in a `.risk-reports/` entry.

### Rule

| Independent control paths | Likelihood band reduction |
|---------------------------|---------------------------|
| 0 | 0 (residual likelihood = inherent likelihood) |
| 1 | 1 band |
| 2 | 2 bands |
| 3+ | 3 bands |

Cap at the 1/Rare floor — likelihood does not go below 1.

### Independence test

Two controls are **independent** if a single failure cannot bypass both:

> If control A fails (regression, mis-configuration, bypass), does control B still fire on the same input?

Examples:
- A regex-based pre-commit hook AND a pipeline-time content scan are independent.
- Two regex hooks reading the same denylist are NOT independent (denylist = shared failure mode).
- Written policy alone counts as **0 paths** — informs operator behaviour and shapes inherent likelihood, but is not a runtime control.

### Shared-failure-mode flag

When two listed controls share a failure mode, flag the dependent ones with an HTML comment: `<!-- shared-failure-mode: depends on same X as <other-control> -->`. Prevents double-counting on re-rate.

### Impact reduction

Most controls reduce likelihood, not impact. A control that constrains blast radius (rollback, version pinning, audit log) MAY reduce impact by 1 band — only with explicit rationale in the risk file's `## Treatment` section.

### Worked example (hypothetical)

Inherent Impact 4 (Significant) × Likelihood 4 (Likely) = 16 (High), with 4 listed controls:

| # | Control | Path classification |
|---|---------|---------------------|
| 1 | Pre-commit hook scanning input | Independent path 1 |
| 2 | Pipeline-time content scan | Independent path 2 |
| 3 | Push-time gate | Independent path 3 (different surface from path 1) |
| 4 | Written policy citation | NOT a runtime control — 0 paths |

Independent paths = 3 → 3-band reduction. Likelihood 4 → 1 (Rare, capped at floor). Impact unchanged. Residual = 4 × 1 = 4 (Low).

Had path 3 shared a failure mode with path 1, independent paths = 2 → 2-band reduction → residual = 4 × 2 = 8 (Medium), above appetite. Either an additional independent control is needed in the catalog, or per-action assessments must add context-specific controls.

### Re-rating discipline

When this rule is first applied to an existing risk file, the file's `## Change Log` must record: prior residual, new residual, count of independent paths used, and citation back to this section. Re-rating may move residuals **up or down** depending on the prior author's conservatism; both directions are valid outcomes of grounding the math.
