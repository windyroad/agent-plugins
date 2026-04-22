# Risk Policy — Windy Road Agent Plugins

> ISO 31000-aligned risk criteria for pipeline risk scoring.
> Last reviewed: 2026-04-23

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

## Risk Appetite

**Threshold: 4 (Low)**

Pipeline gates block when cumulative residual risk exceeds 4. This means:
- Very Low (1-2) and Low (3-4) risk changes proceed without intervention
- Medium (5-9) and above require explicit acknowledgement or risk reduction

This conservative threshold reflects that these packages are installed into users' development environments and promote a professional services brand. Broken installs or misbehaving hooks directly damage user trust and brand reputation.

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
| 3-4 | Low |
| 5-9 | Medium |
| 10-16 | High |
| 17-25 | Very High |

This risk matrix is referenced by both the **risk-scorer agent** (pipeline risk assessment) and the **problem management process** (`/wr:problem` skill for problem severity classification).
