---
status: proposed
job-id: generated-output-respects-adopter-conventions
persona: plugin-user
secondary-persona: plugin-developer
date-created: 2026-07-26
human-oversight: unconfirmed
---

# JTBD-303: Have Plugin-Generated Content Respect My Project's Own Conventions

## Job Statement

When a `@windyroad/*` plugin generates content into my repository — an ADR skeleton, a regenerated decisions compendium, a rendered verification-queue cell, an audit-log entry — I want that content to satisfy the content conventions my own project enforces, so my own Edit/Write policy hooks do not fire on text I did not author and cannot fix, and I am not scrubbing the same characters back out after every regeneration.

## Desired Outcomes

- Generated content defaults to the most portable form (plain ASCII) rather than a typographically richer form a stricter project will reject, wherever the plugin cannot know the adopter's convention.
- Conformance holds at **every regeneration**, not just at first write. The adopter's cost is per-regen, so a re-introducing loop is a live defect, not a cosmetic one.
- No adopter-side remedy is expected: no patching a cached plugin, no post-processing of generated output, no local scrub script. The fix ships upstream and arrives on `npm install`. Composes with P423.
- When plugin-generated content and an adopter policy hook conflict, **the plugin-side default is the one that yields**. The adopter is never left holding a block they cannot clear.
- A plugin-side regression signal exists, so a newly introduced violating character on a generated-output surface is caught before release rather than by an adopter's hook mid-session.

## Persona Constraints

- **Low context on repo internals.** The adopter does not read this monorepo's ADRs, problem tickets, or source. The generating template is not a surface they can reach.
- **No `node_modules/` archaeology expected.** Expecting the adopter to locate and patch the emitting template inside a cached plugin defeats the plugin distribution model (ADR-036).
- **The cost recurs per regeneration.** A manual scrub is a treadmill, not a workaround: the next compendium refresh, ADR capture, or audit-log pass re-introduces the character.
- **The plugin is a guest in the adopter's repo** and must respect house rules it did not set. The adopter's policy is not wrong for being stricter than ours.

## Current Solutions

- **Source side**: nothing. Generated-output surfaces carry whatever glyphs the emitting template or the authoring agent produced. There is no gate over the bytes a plugin writes into an adopter tree, and no test that a generated artefact is portable.
- **Adopter side**: scrub the characters out by hand after each regeneration, or disable the policy hook that is doing its job correctly. Both are treadmills; the second gives up a control the adopter deliberately installed.
- **Adopter-side fallback**: report it upstream and wait. Five reporters have done exactly this (inbound #185, #186, #219, #223, #319), which is the signal that no self-service path exists.

## Relationship to Adjacent Jobs

Authored explicitly so this job is not later challenged as redundant with its neighbours:

- **JTBD-302** (trust the README describes the installed plugin) is the **currency** axis on hand-maintained prose. JTBD-303 is the **conformance** axis on tool-generated output. Different failure mode, different remedy surface. The sharpest discriminator: JTBD-302 is *our* documented contract being wrong, and the remedy is for us to correct our own prose; JTBD-303 is *their* convention being violated by us, and the remedy is for our output to yield to a rule we did not write. The two jobs share persona constraints because they share a persona, not because they share a failure.
- **JTBD-101** (extend the suite with new plugins) is the secondary anchor rather than a sibling. The half of this job that is plugin-developer work — packaging the emission fix so an adopter's next `npm install` carries it, and adding the pre-release regression signal — belongs to the producer persona. The adopter-facing half above is the primary. Same split, and the same `secondary-persona: plugin-developer` frontmatter, as JTBD-011.
- **JTBD-001 / JTBD-002** are edit-review-shaped: every edit is reviewed against relevant policy before it lands. JTBD-303 is the inverse case, where the adopter's policy fires correctly and there is no remedy behind it.
- **JTBD-011** (have a correction to the agent's conduct hold everywhere) is conduct-persistence. P423's ship-adopter-facing outcome composes with this job but does not cover it: this is a code-path emission defect, not a conduct correction the user delivered.
- **JTBD-003** (compose only the guardrails I need) is about which of our guardrails the adopter installs. JTBD-303 is about installed-plugin output colliding with a guardrail the adopter wrote themselves.

## Related problem tickets

- **P424** — originating ticket. Governance tooling emits U+2014 em-dashes into generated artefacts, tripping adopter no-em-dash Edit/Write hooks on content the adopter cannot edit. Five inbound reports.
- **P210** — the narrow, already-fixed precedent (a single em-dash in the work-problems AFK fallback marker). Fixed one instance; this job names the class it belonged to.
- **P423** — a fix that should govern adopters must land as a shipped plugin surface, never as a local scrub or project-local memory. The third desired outcome above is this constraint restated for generated output.
- **P137 / P151** — sibling adopter-facing content-quality axes (semantic correctness; executable correctness). Same persona, same "content ships from the cached plugin and the adopter cannot fix it" shape.

## Related decisions

- **ADR-036** — plugin content ships from the marketplace cache. The reason the adopter has no editable surface, and therefore the reason this job cannot be discharged adopter-side.
- **ADR-052** — behavioural tests default. The fifth desired outcome (a regression signal) has to be a test that exercises an emitter and asserts on the bytes it writes, not a structural grep over a template.
- **ADR-049** — plugin scripts resolve via `bin/` on `$PATH`. Sibling adopter-context decision on the executable-correctness axis; established the precedent that source-repo dogfooding masks adopter-context defects.
- **ADR-008** — JTBD directory structure. Establishes the `docs/jtbd/<persona>/JTBD-NNN-<title>.<status>.md` layout this file follows.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-051 | STORY-051: Have generated content respect my project's conventions | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-008 | STORY-MAP-008: Have a plugin behave like a guest in my repository | draft |
