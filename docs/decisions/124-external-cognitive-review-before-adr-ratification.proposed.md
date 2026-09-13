---
status: "proposed"
date: 2026-09-13
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, cognitive-accessibility]
informed: []
reassessment-date: 2026-12-13
human-oversight: confirmed
oversight-date: 2026-09-13
oversight-note: "The decision-maker was shown the cognitive-accessibility-PASS ADR and offered three substantive choices: require the external reviewer, always use the bundled reviewer, or prefer the external reviewer with a bundled fallback. Tom Howard selected the external reviewer with bundled fallback."
jtbd: [JTBD-003, JTBD-001]
persona: developer
---

# Cognitive Accessibility Review Before ADR Ratification

## Context and Problem Statement

Today, an architecture decision record (ADR) can be shown for ratification before anyone checks whether the document is easy to understand.

The architect plugin must support ADR ratification when installed by itself. When a specialist accessibility reviewer is installed, the plugin should use it. Otherwise, the plugin should use its bundled reviewer.

## Decision Drivers

- Make each ADR understandable before ratification.
- Keep standalone architect installs usable.
- Use one rubric for both reviewer paths.
- Prevent clarity edits from changing architectural substance.
- Stop rather than claim `PASS` when no reviewer succeeds.
- Retain automated test evidence that the workflows behave as intended.

## Options and Trade-offs

### Require the external reviewer

- Good: Uses the specialist reviewer every time.
- Bad: Makes standalone architect installs unusable for ADR ratification when the external plugin is absent.

### Always use a bundled reviewer

- Good: Keeps standalone installs simple and predictable.
- Bad: Ignores a stronger specialist reviewer when one is installed.

### Prefer the external reviewer and use a bundled fallback

- Good: Uses specialist review when available and preserves standalone availability.
- Bad: Adds fallback routing that tests must cover.

## Decision Outcome

Chosen option: **"Prefer the external reviewer and use a bundled fallback"**, because it provides specialist review without breaking standalone installs.

The architect plugin includes one set of review criteria that both reviewers use. Before showing the decision-maker the summary, ADR file, or ratification question, each ADR workflow sends the complete ADR to a reviewer. The ADR must have `human-oversight: unconfirmed`.

In Claude Code, the workflow first calls the external cognitive accessibility reviewer, `accessibility-agents:cognitive-accessibility`. It starts this reviewer in a separate process, supplies the review criteria and complete ADR, and prevents the reviewer from changing project files. If the external reviewer is unavailable or fails to start, the workflow starts the bundled `wr-architect:cog-a11y` reviewer with the same restriction.

In Codex, the workflow first calls the external cognitive accessibility reviewer, `cognitive-accessibility`. It uses that reviewer only when its access to project files is confirmed as read-only. Otherwise, the workflow calls the bundled reviewer, `wr-architect-cog-a11y`. This fallback applies when the external reviewer is unavailable, fails to start, or does not have confirmed read-only access.

The reviewer does not edit the ADR. It returns either `PASS` or `ISSUES FOUND`. An `ISSUES FOUND` result must identify the exact passages and provide replacements that preserve the decision's substance.

The ADR workflow applies only clarity fixes that do not change the decision. It then sends the revised ADR through the same reviewer path as the preceding review. An `ISSUES FOUND` result does not cause a switch to the fallback reviewer. The fallback reviewer is used only when the preferred reviewer cannot run safely. If a proposed fix could change the decision, the workflow stops and asks the user what to do.

If neither reviewer can run, the workflow stops before ratification. A `PASS` result is valid only for the current ADR workflow run. A later workflow must review the ADR again instead of reusing the earlier result.

The authoring workflow orders work as follows:

1. Draft the ADR.
2. Make any optional edits that improve the draft without changing the decision.
3. Run cognitive accessibility review until it passes.
4. Present the summary, the ADR file, and a ratification question with explicit response choices.

The ADR text does not change between the final `PASS` and presentation. If the decision-maker chooses another option, the workflow rewrites the ADR, reviews it again, and then presents it again.

The workflow for reviewing existing decisions follows these steps:

1. Group the ADRs by shared topic or architectural concern.
2. For each ADR in a group, load the complete ADR.
3. Run cognitive accessibility review until the ADR passes.
4. Present that ADR's summary, file, and ratification question with explicit response choices.

If the decision-maker asks for an amendment, the workflow applies it, reviews the updated ADR, and presents it again before recording that the ADR was ratified.

The ADR capture workflow, `capture-adr`, remains unchanged. ADRs created through it are later presented for ratification by the decision-review workflow, `review-decisions`.

## Consequences

### Good

- Standalone architect installs remain usable.
- An installed specialist reviewer is preferred.
- ADRs become easier to understand before ratification.

### Neutral

- ADR ratification includes at least one reviewer call and may include repeats after clarity fixes.
- Reviewing the complete ADR requires the reviewer to process more text than reviewing only a summary.

### Bad

- Supporting both an external reviewer and a built-in fallback adds a second review path, although both use the same review criteria.
- The external and bundled reviewers may still produce different results despite using the same review criteria.

## Confirmation

- Automated tests that exercise the workflow confirm that the external reviewer can return `PASS` and that review occurs before the ADR is presented for ratification.
- Automated workflow tests confirm that the bundled reviewer runs when the external reviewer cannot run.
- Automated workflow tests confirm that the same review path runs again after issues are fixed.
- Automated workflow tests confirm that ratification stops when neither reviewer can run.
- Automated workflow tests confirm that changing the chosen option or amending the ADR triggers another review before the ADR is presented again.
- Installer tests confirm that the base architect reviewer and bundled cognitive accessibility reviewer each install, repair, and uninstall.
- The bundled reviewer and shared review criteria ship with the architect package.
- Tests confirm that the repository's Codex agent files remain consistent with their source files.

## Reassessment Criteria

Reassess this decision if the reviewers produce meaningfully different results, the review process unacceptably delays decisions, or every architect installation is guaranteed to include the specialist reviewer.
