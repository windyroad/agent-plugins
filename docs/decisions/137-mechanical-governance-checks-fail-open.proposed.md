---
status: proposed
date: 2026-10-04
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: []
informed: []
---

# Mechanical governance checks fail open when evidence cannot be evaluated

## Context and Problem Statement

Review transport failures repeatedly prevented edits and delivery after reviewers passed. Repairing receipt transport retained fail-closed behavior and therefore did not implement the maintainer's requested failure policy. On 2026-10-04 the maintainer explicitly directed implementation, release and installation of fail-open gates.

## Decision Drivers

- Preserve developer flow when governance infrastructure is unavailable.
- Keep substantive review obligations and known risk findings enforceable.
- Report unavailable evidence honestly without synthesizing approval.

## Considered Options

- Continue blocking whenever mechanical evidence cannot be evaluated.
- Warn and permit execution when mechanical evidence cannot be evaluated.

## Decision Outcome

Chosen option: warn and permit execution when mechanical evidence cannot be evaluated. Architecture, JTBD, Style, Voice and Risk receipt checks permit execution on missing, expired, drifted, mismatched, malformed or unreadable receipts. Parse errors and evaluator crashes are advisory. CI lookup/authentication/API/timeout failures and malformed responses are advisory; a successfully evaluated failed or pending CI result remains enforcing.

A valid applicable above-appetite risk score, known substantive FAIL and actual leak findings remain enforcing. The assistant must still obtain substantive reviews; missing receipts never count as PASS. Existing positive-only edit receipt stores cannot distinguish an explicit FAIL from missing transport, so substantive negative reviews remain the assistant's obligation rather than being inferred from marker absence.

Advisories must not skip later security checks. A crashed evaluator's partial denial output is discarded. No approval marker is manufactured or refreshed by fail-open evaluation. Installation and active runtime verification are reported separately.

This proposal narrowly supersedes the failure-policy clauses of [Gate Marker Lifecycle](009-gate-marker-lifecycle.proposed.md), [Reuse valid cumulative risk assessments](133-reuse-valid-cumulative-risk-assessments-across-pipeline-actions.proposed.md), and [External-comms gate](028-voice-tone-gate-external-comms.proposed.md). Their ratified bodies, receipt identity bindings, substantive enforcement and unrelated provisions remain unchanged. This implementation is user-directed; this proposal is not ratified and does not claim production validation.

## Consequences

- Good: infrastructure failures no longer stop authorized work.
- Bad: execution can proceed without mechanically verified approval; the warning and substantive assistant duties make that limitation explicit.
- Tests exercise hook outputs and dispatch composition, with known-denial controls.

## Confirmation

Behavioral checks exercise missing, expired, drifted and malformed receipts; unavailable CI lookup; crashed and malformed evaluator output; dispatch composition; and preserved known-denial controls. Release/install evidence does not prove active desktop loading. Confirm natural behavior separately without manufacturing review markers.

## Pros and Cons of the Options

### Continue blocking whenever mechanical evidence cannot be evaluated

- Good: avoids proceeding without mechanically verified evidence.
- Bad: infrastructure defects block work even after substantive reviewers passed.

### Warn and permit execution when mechanical evidence cannot be evaluated

- Good: meets the maintainer's requested failure policy and retains honest diagnostics.
- Bad: mechanical proof can be unavailable, so substantive review duties remain with the assistant.

## Reassessment

Reassess if advisories suppress known findings, or natural installed actions continue blocking solely on missing mechanical evidence. Ratification remains pending; no acceptance or production use is claimed.
