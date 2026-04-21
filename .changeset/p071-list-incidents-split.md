---
"@windyroad/itil": minor
---

P071 split slice 5: new `/wr-itil:list-incidents` skill

`/wr-itil:manage-incident list` is deprecated; the list-incidents user
intent now has its own skill so the `/` autocomplete surfaces it directly
(JTBD-001 + JTBD-101 + JTBD-201). This is slice 5 of the P071 phased-landing
plan, mirroring slice 1 (list-problems) verbatim.

- `packages/itil/skills/list-incidents/SKILL.md` — NEW read-only skill
  (`allowed-tools: Read, Bash, Grep, Glob` — no Write, no Edit, no
  AskUserQuestion). Reads `.investigating.md`, `.mitigating.md`, and
  `.restored.md` files from `docs/incidents/`; sorts by severity per
  ADR-011 ("Severity, not WSJF" — incidents are time-bound events where
  the WSJF effort divisor is meaningless).
- `packages/itil/skills/list-incidents/test/list-incidents-contract.bats`
  — NEW 10 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
  JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
- `packages/itil/skills/manage-incident/SKILL.md` — `deprecated-arguments:
  true` frontmatter flag per ADR-010 amended; Step 1 `list` argument now
  routes to a thin-router forwarder that delegates via the Skill tool and
  emits the canonical deprecation notice verbatim.
- `packages/itil/skills/manage-incident/test/manage-incident-list-forwarder.bats`
  — NEW 4 contract assertions for the forwarder contract.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment. Full itil bats suite green (241/241 + 14 new = 255/255).

Remaining phased-landing slices tracked on P071: `mitigate-incident`,
`restore-incident`, `close-incident`, `link-incident` (the remaining
manage-incident splits).
