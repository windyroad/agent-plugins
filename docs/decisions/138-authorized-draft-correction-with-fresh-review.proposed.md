---
status: proposed
date: 2026-10-08
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2027-01-08
---

# Authorized draft correction with fresh external-comms review

## Context and Problem Statement

A release-note voice review rejected multiple sentences and incorrect tense. The calling assistant stopped and requested permission to rewrite, citing the assessment skill's prohibition. The maintainer explicitly corrected this behaviour: an already-authorized draft should be corrected and reviewed again without a new approval round trip.

ADR-028's historical automatic-rewrite exclusion requires human review before reposting. This proposal replaces only that restriction with caller-owned remediation. It preserves the gate's independent evaluators and exact-draft review contract. Proposed decisions may guide implementation under ADR-136; this proposal is not yet human-ratified or accepted.

## Decision Drivers

- Finish authorized work without asking the maintainer to resolve routine wording failures.
- Preserve the draft's authorized intent, facts, destination and disclosure authority.
- Review the actual revised text before publication.

## Considered Options

- Correct authorized drafts and obtain fresh external-comms reviews.
- Retain human approval before every correction, the existing rule rejected by the maintainer.

## Decision Outcome

Chosen option: Correct authorized drafts and obtain fresh external-comms reviews. The calling assistant corrects routine wording, formatting and tense failures, or safely removes detected confidential content, within the existing authorization. It submits the exact revised draft to every applicable evaluator. A previous verdict does not approve changed text. Reviewers remain read-only and hooks do not rewrite drafts or fabricate approval.

When correction requires a material choice about intent, claims, destination or disclosure authority that the existing instructions do not resolve, the calling assistant requests that choice. It does not publish a substantively failed draft or bypass a failed evaluator. In unattended work, unresolved choices follow ADR-013's queue-and-continue contract.

This proposal is a successor to the automatic-rewrite restriction in ADR-028; all other decisions in ADR-028 remain applicable.

## Consequences

### Good

- Routine failed drafts are repaired within the authorized workflow.
- Fresh reviews preserve confidentiality and voice requirements for the revised text.

### Neutral

- Publication still requires the existing action authorization and applicable reviews.

### Bad

- The caller must distinguish an ordinary correction from a material change; an incorrect distinction could alter the intended message.
- A revised draft may fail again and require further remediation or a substantive user choice.

## Confirmation

- Actual installed use corrects a release note rejected solely for sentence count and tense, obtains fresh reviews of the changed text, and completes the authorized action without requesting rewrite permission.
- Actual use retains a user decision when removing a disclosure would materially change the authorized message.
- Changed drafts never reuse previous draft approval or publish after a substantive FAIL.

No successful actual production-use evidence has yet been recorded for this proposal.

## Pros and Cons of the Options

### Correct authorized drafts and obtain fresh external-comms reviews

- Good, because routine compliance corrections preserve developer flow while retaining independent review.
- Bad, because identifying material changes requires contextual judgement by the caller.

### Retain human approval before every correction

- Good, because the human sees every revision before publication.
- Bad, because a routine grammar failure blocks already-authorized work and requires avoidable human intervention.

## Reassessment Criteria

Reassess if routine corrections change authorized meaning, confidential information is disclosed after remediation, or agents continue to ask for permission to fix mechanical wording failures.
