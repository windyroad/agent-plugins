---
status: "proposed"
date: 2026-11-19
human-oversight: unconfirmed
decision-makers: ["Tom Howard"]
consulted: ["Architect reviewer", "Risk reviewer", "Test reviewer"]
informed: ["Windy Road plugin maintainers"]
reassessment-date: 2027-02-19
---

# Architect report completeness at the existing review boundary

> Captured via /wr-architect:capture-adr from the current delivery investigation. Substance is derived and human oversight remains unconfirmed; ratification follows successful actual production use.

## Context and Problem Statement

Architect qualification has observed required assessments omitted despite explicit instructions. A low-traffic callback response incorrectly skipped the independent per-request handler trigger. Other responses supplied complete unknown-data assessments. Repeated prompt representation changes did not establish reliable completion. The existing consumer recognizes the operative verdict but does not establish that required assessments accompany it. A review can therefore be mechanically recognized while incomplete.

## Decision Drivers

- Detect missing required assessment content without inventing factual certainty or measurements.
- Preserve independent trigger categories, honest unknowns and substantive ADR review.
- Keep the existing fail-open treatment of unavailable or malformed mechanical evidence.
- Use the existing Architect caller and shared completion consumer rather than a new reviewer or hook framework.

## Considered Options

1. **Architect-local typed completeness contract (proposed choice)** — carry bound applicability facts and assessment state through the existing caller and shared completion consumer.
2. **Continue prompt-only qualification (rejected)** — retain the existing interface and revise wording or repeat model requests. The observed failures do not support that as a new risk-reduction mechanism.

## Decision Outcome

Propose an Architect-local report-completeness contract at the existing review boundary. The caller supplies evidence-linked applicability facts bound to the artifact and policy under review; absence of caller facts remains unknown, rather than nonapplicable. The reviewer independently assesses applicability and may explicitly dispute a supplied fact. The report carries one bounded machine-readable payload alongside its human-readable findings. The existing authoritative verdict heading remains operative; the payload mirrors that verdict and is bound to the same artifact and request. Disagreement between them makes completeness unverified and cannot mint a PASS receipt.

For an applicable performance review, CPU, memory, network, workload, aggregate load and budget each have a supported, unavailable or disputed assessment. Supported quantities retain their units, cited source and uncertainty. Unavailable inputs remain explicit unknowns. A disputed state identifies the contested fact and supporting evidence. An unresolved applicability dispute is not nonapplicability and does not itself satisfy the required assessment. Unknown resource values can satisfy completeness. A genuinely nontriggered change does not require resource estimates. Low traffic does not cancel an independently applicable handler or response trigger.

The existing shared completion consumer validates structure, bound scope and associations with the request facts available to it. It must not infer applicability from filenames, caller silence or a reviewer-controlled false value. A structurally complete report is not proof that its facts, arithmetic, trigger interpretation or architecture are correct; substantive review remains necessary. Conflicting applicability or substantive findings remain visible to the caller.

Missing or malformed payloads, unavailable bound request context and evaluator crashes produce an honest advisory, no fabricated PASS receipt, and the existing fail-open execution behavior. Completeness validation cannot erase an independently established substantive FAIL. Unverifiable completeness is not proof of substantive incompleteness: a complete legacy prose review may lack mechanical evidence without becoming an architectural FAIL. Detected report incompleteness is not automatically an architectural FAIL. The caller must not describe an unfinished assessment as a fulfilled review obligation. Qualification can fail when it successfully detects incomplete required content; this does not convert a transport failure into a runtime action denial.

This extends ADR-023's prompt-only performance reporting interface with Architect-local completeness checking. It does not introduce automated performance-budget enforcement. ADR-026's cite/persist/uncertainty rule remains unchanged: this is not a central validator of numerical grounding across agents. ADR-137's mechanical failure policy remains unchanged.

## Consequences

### Good

- A recognized verdict is distinguishable from a complete assessment.
- Explicit unknown data satisfies completeness without new measurement tasks.
- Both runtime completion paths and qualification share the same interpretation.

### Neutral

- Caller-supplied applicability facts remain reviewable claims, not trusted architectural truth.
- Existing substantive and delivery obligations remain at their current boundaries.

### Bad

- The report interface and request binding add maintenance and compatibility costs.
- A complete fabricated report can still pass structural checks; semantic review remains necessary.
- Fail-open policy intentionally prevents a guarantee that unavailable completeness evidence blocks dependent actions.

## Confirmation

Actual production reviews demonstrate that the existing completion boundary distinguishes a triggered but omitted assessment, a complete unknown-data assessment and a valid nontriggered change. Artifact and request bindings remain attributable. Malformed evidence advises and permits execution without an invented approval. Known substantive failures remain actionable. Human ratification and successful actual production use are both required before acceptance; synthetic qualification alone is insufficient.

## Pros and Cons of the Options

### Architect-local typed completeness contract

- Good: creates a directly checkable completeness boundary while retaining unknowns and existing runtime policy.
- Bad: cannot prove factual accuracy or eliminate false applicability claims, and adds an interface to maintain.

### Continue prompt-only qualification

- Good: no new interface or compatibility burden.
- Bad: another wording change or repeated request has no demonstrated prevention mechanism for the observed omission.

## Reassessment Criteria

Reassess if actual reviews show material false completeness, erroneous applicability binding, drift between runtime consumers, or excessive review friction. A requirement to block actions when mechanical completeness evidence is unavailable is a separate failure-policy decision and must not be introduced as a rider.
