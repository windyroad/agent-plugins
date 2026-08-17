# Problem 499: Architect ADR pairing hook reads the task checkout instead of the command checkout

**Status**: Known Error
**Reported**: 2026-08-17
**Priority**: 20 (Very High) - Impact: 4 x Likelihood: 5
**Origin**: incident-linked
**Effort**: S
**WSJF**: 40 - (20 x 2.0) / 1
**JTBD**: JTBD-001
**Persona**: developer

## Description

The architect ADR pairing hook evaluates the Git index in the hook process checkout, not the checkout selected by the commit command. In Codex, an isolated command can declare a different `workdir` while the hook process remains rooted in the task's original checkout. A clean target commit is then allowed or denied using unrelated staged files.

## Symptoms

- A commit in a clean isolated clone was denied because an unrelated ADR was staged in the task's original dirty checkout.
- The same defect blocked two independent downstream delivery paths.
- Existing behavioural tests always run the hook process and the commit fixture in the same repository, so they cannot detect cross-checkout contamination.

## Workaround

Run the commit from a task whose own workspace root is the exact target checkout. If that is unavailable, stop. Do not bypass the pairing hook or alter another checkout's index.

## Root Cause Analysis

`packages/architect/hooks/architect-readme-pairing-check.sh` calls `git rev-parse --show-toplevel` without first entering the checkout named by `tool_input.cwd`, `tool_input.workdir`, or an explicit leading `cd`. It therefore inherits the hook process cwd. The risk-scorer gate already resolves these command checkout signals before inspecting pipeline state; the architect hook does not.

### Investigation Tasks

- [x] Confirm the target clone index contained no ADR file.
- [x] Confirm the denied ADR existed only in the task's original checkout.
- [x] Confirm architect 0.20.1 and 0.20.2 carry the same process-cwd implementation.
- [x] Confirm the risk-scorer hook family already has command-checkout resolution semantics and behavioural coverage.

## Fix Strategy

Resolve the actual command checkout before reading the staged index. Prefer `tool_input.cwd`, then `tool_input.workdir`, then an explicit leading absolute `cd`, then top-level `cwd`; retain process cwd only for legacy payloads that declare none. Deny an invalid declared checkout. Preserve the existing ADR pairing and intentional bypass rules unchanged.

## Dependencies

- **Blocks**: downstream commits whose execution checkout differs from the task workspace.
- **Blocked by**: none; RFC-069 and STORY-063 use existing ADR-078 and ADR-083 direction.

## Story Maps

- STORY-MAP-002 - Take a problem from noticed to resolved

## RFCs

- RFC-069 - Honor the command checkout in ADR pairing

## Related

- ADR-078 - Compendium Decision Outcome: architect-on-edit compendium entries
- ADR-083 - Codex CLI as second runtime
- ADR-052 - Behavioural-tests default for skill testing

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-063 | STORY-063: Check ADR pairing in the checkout being committed | accepted |
