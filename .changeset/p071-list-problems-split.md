---
"@windyroad/itil": minor
---

P071 split slice 1: new `/wr-itil:list-problems` skill

`/wr-itil:manage-problem list` is deprecated; the list-problems user intent
now has its own skill so the `/` autocomplete surfaces it directly (JTBD-001
+ JTBD-101). This is phase 1 of the P071 phased-landing plan (audit landed
in the prior commit — 2 offenders, both in @windyroad/itil).

- `packages/itil/skills/list-problems/SKILL.md` — NEW read-only skill
  (`allowed-tools: Read, Bash, Grep, Glob` — no Write, no Edit, no
  AskUserQuestion). Reuses the git-log-based README cache freshness check
  from `manage-problem review` per P031 + architect Q4.
- `packages/itil/skills/list-problems/test/list-problems-contract.bats` —
  NEW 9 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
  JTBD-001 + @jtbd JTBD-101 traceability).
- `packages/itil/skills/manage-problem/SKILL.md` — `deprecated-arguments:
  true` frontmatter flag per ADR-010 amended; Step 1 `list` argument now
  routes to a thin-router forwarder that delegates via the Skill tool and
  emits the canonical deprecation notice verbatim.
- `packages/itil/skills/manage-problem/test/manage-problem-list-forwarder.bats`
  — NEW 4 contract assertions for the forwarder contract.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment. Full bats suite green (467/467).

Remaining phased-landing slices tracked on P071: `work-problem`,
`review-problems`, `transition-problem`, plus the `manage-incident`
splits (`list-incidents`, `mitigate-incident`, `restore-incident`,
`close-incident`, `link-incident`).
