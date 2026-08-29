---
status: accepted
story-id: use-generated-codex-skills-after-upgrading-without-repairs
reported: 2026-08-30
decision-makers: [Tom Howard]
problems: [P526]
jtbd: [JTBD-101]
rfcs: [RFC-080]
story-maps: [STORY-MAP-008]
estimated-effort: S
---

# STORY-074: Use generated Codex skills after upgrading without repairs

**Reported**: 2026-08-30
**Problems**: P526
**JTBD**: JTBD-101
**RFCs**: RFC-080
**Story Maps**: STORY-MAP-008
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to use a generated Codex skill after upgrading without repairing it, as a plugin developer, I want the generator to preserve parseable YAML metadata and copy every skill file regardless of its parent directory names.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A fresh Codex projection preserves valid YAML frontmatter in every generated skill.
- [x] A projection built from a checkout whose parent path contains a `test` component copies every skill file.
- [x] The packed ITIL artefact passes the same generated-output checks.

## Driving problem trace (required — I6 invariant)

P526 records that whole-file title expansion corrupts generated YAML frontmatter and that an absolute-path exclusion filter suppresses all copied skill files under parent directories named `test`, `eval`, or `evals`.

## JTBD trace (required — I9 invariant)

JTBD-101 requires plugin structure and packaging checks that keep every generated runtime surface installable for users.

## Implementation notes (optional)

Keep frontmatter outside prose sanitisation, scope exclusions relative to each skill source, and cover both paths in the existing Codex projection test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P526
- RFC-080
- STORY-MAP-008
