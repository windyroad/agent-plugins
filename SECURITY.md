# Security Policy

## Reporting a Vulnerability

**Do not file a public issue for security vulnerabilities.**

Use [GitHub Security Advisories](https://github.com/windyroad/agent-plugins/security/advisories/new) to disclose privately. Maintainers receive an email; the report stays private until a fix ships.

A useful report includes:

- The affected plugin(s) and version(s) (e.g. `@windyroad/itil@0.7.2`).
- The Claude Code version (`claude --version`).
- Reproduction steps that demonstrate the impact.
- Your assessment of impact (data loss, code execution, escalation, secret leak, etc.).
- Any suggested fix or mitigation.

## What's in scope

Code shipped from this repository:

- All `@windyroad/*` packages on npm.
- The `npx @windyroad/agent-plugins` umbrella installer.
- The hook scripts under `packages/*/hooks/` and the skill definitions under `packages/*/skills/`.
- Repo-local skills under `.claude/skills/`.

## What's out of scope

- Vulnerabilities in [Claude Code](https://github.com/anthropics/claude-code) itself -- report those to Anthropic.
- Vulnerabilities in third-party MCP servers, agents, or plugins from other publishers -- report to their maintainers.
- Issues that require an attacker to already have local code-execution on the user's machine.

## Disclosure timeline

We aim to:

- **Acknowledge** the report within 7 calendar days.
- **Provide an initial assessment** (in scope, severity, planned fix) within 14 days.
- **Ship a fix** within 90 days for confirmed vulnerabilities, with most resolved sooner.
- **Coordinate disclosure** with the reporter so a public advisory and credit can be published when the fix lands.

If we cannot meet a 90-day timeline, we will say so in the advisory thread before the deadline.

## Credit

Reporters who follow this private-disclosure path are credited in the published advisory unless they ask to remain anonymous.
