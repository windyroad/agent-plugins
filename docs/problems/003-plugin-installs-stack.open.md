# Problem 003: Plugin Installs Stack Instead of Replacing

**Status**: Open
**Reported**: 2026-04-14
**Priority**: 6 (Medium) — Impact: Minor (2) x Likelihood: Almost Certain (5)

## Description

Running `claude plugin install wr-architect@windyroad --scope project` multiple times adds duplicate entries instead of replacing the existing installation. This results in 6x copies of each plugin in `claude plugin list`, and potentially 6x hook executions per event.

## Symptoms

- `claude plugin list` shows every windyroad plugin 6 times
- Hook overhead may be multiplied by the number of duplicate installations
- No error or warning when installing over an existing installation

## Workaround

Uninstall the plugin before reinstalling: `claude plugin uninstall <name>` then `claude plugin install <name>@windyroad --scope project`.

## Impact Assessment

- **Who is affected**: Anyone who reinstalls plugins (e.g., after marketplace updates)
- **Frequency**: Every reinstall cycle
- **Severity**: Medium — causes visual clutter and potential performance overhead
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

This may be a Claude Code platform issue (not our plugin code). The `claude plugin install` command may not check for existing installations before adding. Alternatively, our installer (`install-utils.mjs`) may need to uninstall before installing.

### Investigation Tasks

- [ ] Confirm whether this is a Claude Code platform bug or our installer's responsibility
- [ ] Check if `claude plugin install` has an `--update` or `--replace` flag
- [ ] Update installer to uninstall before installing if needed

## Related

- `packages/shared/install-utils.mjs` — shared installer
- ADR-004 — project-scoped plugin install
