# Problem 501: Project-specific content leaks into another adopter's generated plugin document

**Status**: Open
**Reported**: 2026-08-18
**Priority**: 9 (Medium) - Impact: 3 x Likelihood: 3. Impact 3: foreign project policy can silently shape an adopter's generated documentation and subsequent agent decisions. Likelihood 3: one concrete cross-project leak is confirmed and the shared generation surface is reused across adopters.
**Origin**: corrective-feedback
**Effort**: M - locate the producing surface, remove source-project exemplars from runtime input, and add one cross-project fixture.
**WSJF**: 9/2 = **4.5** (Open multiplier 1.0)
**JTBD**: JTBD-303
**Persona**: plugin-user

## Description

An architect review of a Project B document found sections named `Project A-Specific Sections` and `Project A Mode`. Content belonging to one adopter project had entered a document for another project.

Generated plugin content must be grounded in the current adopter's files and conventions. Examples, fixtures, source-repository guidance, and prior-project context may inform tests, but they must not become emitted adopter content unless the current project independently contains that substance.

## Symptoms

- A generated document names another project's product, mode, policy, or section taxonomy.
- The current repository has no source for the foreign section beyond a plugin example, fixture, or prior session.
- The reviewing agent must stop and ask whether the foreign content belongs, instead of trusting the generated document.

## Workaround

Before accepting generated plugin documentation, search each project-specific name back to a source file in the current repository and remove anything that resolves only to another project or a plugin fixture.

## Root Cause Analysis

The producing surface is not yet identified. Likely boundaries to inspect are shipped examples, generation prompts that treat examples as templates, and session context reused across project checkouts.

### Investigation Tasks

- [ ] Identify the command, skill, or agent that produced the Project B document.
- [ ] Trace `Project A-Specific Sections` and `Project A Mode` to their source input.
- [ ] Remove foreign project content from the shared generation path rather than filtering those two strings.
- [ ] Add a two-project fixture proving project A terminology cannot appear in project B output without a project B source.

## Dependencies

- **Blocks**: none.
- **Blocked by**: reproduction needs the generated Project B document or its producing transcript.
- **Composes with**: P424 and the portable-generated-output release vehicle; P298 covers the separate unresolved-internal-ID finding from the same review.

## Related

- User-supplied screenshot, 2026-08-18: architect review observed Project A terminology in a document for Project B.

(captured via /wr-itil:capture-problem; expand at next investigation)
