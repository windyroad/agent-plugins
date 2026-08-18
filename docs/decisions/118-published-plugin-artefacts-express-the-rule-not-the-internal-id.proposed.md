---
status: "proposed"
date: 2026-08-18
human-oversight: confirmed
oversight-date: 2026-08-18
oversight-note: "2026-08-18 - Tom Howard approved Option 1: published plugin artefacts express governing rules inline and omit source-repository identifiers."
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users, Windy Road plugin developers]
reassessment-date: 2026-11-18
supersedes: [ADR-055]
---

# Published plugin artefacts express the rule, not the internal ID

## Context and Problem Statement

Published plugin skills, agents, hooks, READMEs, and changelog entries cite this repository's internal ADR, problem, RFC, story, risk, and JTBD identifiers. Adopter projects do not receive those source corpora. At best the tokens are meaningless; at worst an agent resolves a same-numbered identifier in the adopter's own repository and applies the wrong rule.

The namespace-prefix approach recorded in the superseded decision prevents direct identifier collisions but still asks adopters to interpret references they cannot read. A 2026-08-18 adopter review reproduced the failure: the plugin appeared to cite roughly 31 decisions while shipping no decision corpus.

## Decision Drivers

- Published instructions must be self-contained at the point where an adopter or agent acts on them.
- An adopter's own governance identifiers must never be mistaken for Windy Road source identifiers.
- Maintainer traceability remains useful in source-only documents and version-control history.
- The package should not ship its private governance corpus merely to explain runtime instructions.

## Considered Options

1. **Express the governing substance inline and omit internal IDs from published artefacts (chosen)** - makes every runtime rule readable and collision-free while retaining source-side traceability outside the package.
2. **Keep namespace-prefixed IDs and add links** - prevents same-number collisions but leaves runtime instructions dependent on external context.
3. **Ship the internal decision corpus with every plugin** - makes references resolvable but increases package and context size, exposes unrelated maintainer history, and couples adopter behavior to source-repository structure.

## Decision Outcome

Plugin-published artefacts must express each governing rule in self-contained prose and must not expose source-repository identifiers as part of the instruction. This applies to runtime-loaded skills and agents, adopter-visible hook output, package READMEs, and newly generated changelog content.

Source-only governance documents, tests, structured source annotations, changesets before changelog generation, and version-control metadata may retain internal identifiers. Build and release checks distinguish those source-only locations from package-published content.

Existing packages migrate incrementally in bounded per-package changes. The architect package is first because the reproduced failure occurred while its runtime instructions were being used and because unresolved decision references can alter architecture review behavior.

The internal decision corpus is not added to npm packages. Published rules stand on their own; maintainers use source history for provenance.

## Consequences

### Good

- Adopter agents receive the rule they need without searching for unavailable documents.
- Same-numbered adopter decisions cannot be mistaken for Windy Road decisions.
- Published context becomes smaller and more directly actionable.

### Neutral

- Source-only governance documents continue to use internal identifiers normally.
- Migration can proceed package by package rather than as one repository-wide rewrite.

### Bad

- Maintainers must preserve traceability in source-side records instead of relying on runtime prose.
- Rephrasing references requires judgment; a mechanical token deletion is insufficient when the identifier was carrying unstated substance.

## Confirmation

- A package-content check fails when a published runtime artefact contains a source-repository identifier.
- The architect package's skills and agent remain behaviorally equivalent after their internal references are replaced with self-contained rules.
- A packed architect tarball contains no internal decision corpus and no unresolved source-repository identifiers in adopter-loaded prose.
- An adopter review no longer searches its own decision tree to interpret Windy Road runtime instructions.

## Pros and Cons of the Options

### Express the rule inline

- Good, because the instruction is complete where it is consumed.
- Bad, because maintainers must avoid duplicating rationale that belongs only in source history.

### Keep prefixed IDs and links

- Good, because it is easy to generate and preserves direct provenance.
- Bad, because it leaves the adopter-facing text dependent on another repository.

### Ship the corpus

- Good, because every reference becomes locally readable.
- Bad, because each plugin would carry unrelated governance history and pay its context cost.

## Reassessment Criteria

Reassess if Codex or Claude Code gains a native, collision-proof package-reference mechanism that resolves source provenance without loading it into adopter context.

## More Information

- P298 records the rejected namespace-prefix mechanism and the adopter failure mode.
- ADR-055 is the superseded namespace-prefix decision.
