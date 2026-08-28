---
status: accepted
story-id: invoke-a-codex-skill-by-the-name-the-card-shows
reported: 2026-08-29
decision-makers: [Tom Howard]
problems: [P527]
jtbd: [JTBD-302]
rfcs: [RFC-074]
story-maps: [STORY-MAP-008]
estimated-effort: S
---

# STORY-068: Invoke a Codex skill by the name the card shows

**Reported**: 2026-08-29
**Problems**: P527
**JTBD**: JTBD-302
**RFCs**: RFC-074
**Story Maps**: STORY-MAP-008
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to invoke a skill by reading its name off the surface that offers it — rather than discovering by failure that the advertised string is not a string I can type — as a developer running these plugins in Codex, I want every skill Codex lists to carry exactly one plugin prefix, so the name I see is the name that works.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The `@windyroad/itil` Codex projection writes a **bare** frontmatter `name:` into each generated `skills-codex/<skill>/SKILL.md` — the skill's own directory name, with no plugin prefix — so the runtime's own namespacing produces exactly one prefix.
- [ ] The `@windyroad/architect` and `@windyroad/risk-scorer` pack transforms apply the same rewrite to their Codex-facing skill files, since they run the same script shape against the same defect.
- [ ] The runtime-neutral sources under `packages/*/skills/` are **unchanged**. Their existing contract tests stay green and the Claude Code surface is untouched, because Claude namespaces a bare skill name the same way (this repository already ships one such skill).
- [ ] Each skill's `agents/openai.yaml` `display_name` is untouched. Those values already carry the correct human branding and are the wrong lever for the invocation string.
- [ ] A behavioural check runs the generator and asserts on its output: every generated frontmatter `name:` equals its skill directory name, so no plugin prefix survives the projection. It exercises the generator rather than grepping the sources.
- [ ] A changeset bumps the affected packages so the fix reaches an installed Codex runtime.

## Driving problem trace (required — I7 invariant)

- **P527** — every skill of every windyroad plugin renders in Codex with the plugin prefix twice (`wr-itil:wr-itil:work-problems`), because the skill source carries a name that already includes the prefix and Codex namespaces it again. The displayed invocation cannot be typed.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-302 — trust that what the installed plugin tells you about itself is true. The skill list is the first and most-read claim a plugin makes about itself, and an invocation string that fails when typed is that claim being wrong on every entry.

## Related

- P527 (driving problem, Known Error), RFC-074 (the release row on STORY-MAP-008 activity B, *Read what it claims*).
- P526 — the other live defect in the same generator; different transform, different fix.
