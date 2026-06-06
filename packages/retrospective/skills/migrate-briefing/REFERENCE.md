# migrate-briefing — Reference

Edge cases, algorithm detail, and recovery procedures for `/wr-retrospective:migrate-briefing`. SKILL.md is the canonical contract surface; this file expands the points the SKILL summary defers per ADR-038 progressive disclosure.

## Heading-extraction algorithm

The legacy `docs/BRIEFING.md` is walked line-by-line by `bin/migrate-briefing.sh`. The walker maintains two pieces of state:

- `in_fence` — boolean, toggled when a ` ``` ` or `~~~` fence opens or closes at column 0. Lines inside a fence are emitted to the **current** topic body without heading-pattern matching.
- `current_slug` — the active topic slug. Defaults to a special `__preamble__` slug for content before the first H2.

For each input line:

1. If the line is a fence delimiter at column 0, flip `in_fence` and emit verbatim.
2. Else if `in_fence` is true, emit the line verbatim to the current topic body.
3. Else if the line matches `^## ` (H2 marker at column 0), close the previous topic, derive a new slug from the heading text, and start a new topic body. The H2 line itself becomes the first line of the new topic body (so the heading is preserved in the per-topic file).
4. Else emit the line verbatim to the current topic body.

Output per topic:

- `__preamble__` → contents (if non-empty) written into the README index under a "Preamble" section.
- Every other slug → written to `docs/briefing/<slug>.md`.

### Slug derivation

```
slug = heading_text
  | lowercase
  | replace non-[a-z0-9]+ runs with '-'
  | trim leading and trailing '-'
  | truncate to 60 chars
```

If the resulting slug is empty (e.g. an H2 with no alphanumeric content), substitute `topic-<N>` where `<N>` is the sequential topic index.

### Collision handling

A flat slug-set is maintained. When a derived slug collides with one already taken:

```
candidate = slug
n = 2
while candidate in taken:
  candidate = slug + "-" + str(n)
  n += 1
slug = candidate
```

Worked example — legacy file with three `## Hooks` sections:

- First section → `hooks.md`
- Second → `hooks-2.md`
- Third → `hooks-3.md`

Collisions are surfaced in the final report so the adopter can rename for clarity.

## Code-fence-awareness rationale

A legacy briefing entry that documents a hook script may include a fenced bash block with `## Some heading` as a literal source line. Without fence-awareness, the walker would treat that line as a topic marker and shred the code block across two files. The fence guard preserves the example intact in whatever topic owns the surrounding prose.

The guard is column-anchored (`^\\\`\\\`\\\``) — indented fences inside list items are NOT recognised as fence delimiters. This is deliberate: GFM fenced blocks inside list items use different parsing rules and rarely contain heading-pattern lines that would mislead the splitter; the simpler column-anchored detector covers >95% of real briefing content without the parser complexity of full CommonMark fence handling.

## README index shape

The generated `docs/briefing/README.md` has the structure:

```markdown
# Project Briefing

Migrated from legacy `docs/BRIEFING.md` via `/wr-retrospective:migrate-briefing` on <YYYY-MM-DD>.

## Critical Points (Session-Start Surface)

_To be populated by the next `/wr-retrospective:run-retro` Step 1.5 signal-vs-noise pass (per ADR-040)._

## Topic Index

| File | Source heading |
|---|---|
| [hooks.md](./hooks.md) | Hooks |
| [releases.md](./releases.md) | Releases |
| ... | ... |

## Preamble

<contents of the legacy file before its first H2, if any>
```

The "Source heading" column is the raw H2 text from the legacy file — useful when the slug truncation or collision-suffix obscures the original meaning.

## Recovery

If the migration produces output the adopter is unhappy with:

```bash
git checkout HEAD -- docs/BRIEFING.md docs/briefing/
```

reverts the migration entirely. The skill commits its work as a single coherent commit per ADR-014, so revert is a single `git revert <sha>` or a checkout of the pre-skill HEAD.

The legacy file is moved (not deleted) to `docs/BRIEFING.md.migrated-<date>` in the working tree before the commit, so adopters who want to inspect the original after the fact can still see it under that name in any pre-revert clone.

## Scope exclusions

- **Does NOT seed Critical Points**. The roll-up surface ADR-040 defines is populated from per-entry signal scores in the run-retro pass; pre-seeding from heading text would be lossy guesswork. The migrated tree's index leaves the section as a placeholder for the next retro to populate.
- **Does NOT classify entries**. No signal-vs-noise grading happens during migration — that is run-retro Step 1.5's mechanical pass, not this skill's responsibility.
- **Does NOT detect or split H3 subsections**. H2 is the only topic boundary. Deeper nesting stays inside the parent topic file and can be split manually if needed.
- **Does NOT carry archives forward**. The legacy file is treated as the live current state; if it already has `## Archive` sections, they are migrated as their own topic files (named per the slug rule). No special archive-rotation handling.
- **Does NOT touch `docs/briefing/` if a tree is already present**. The idempotency contract is hard: tree-present → no-op. Use `--force` to override.

## Verification

Behavioural fixture in `test/migrate-briefing-fixture.bats` exercises:

- Empty repo (no legacy file) → no-op exit 0
- Empty legacy file (`-s` returns false) → no-op exit 0
- Tree already migrated (README.md exists) → no-op exit 0
- Synthetic legacy file with three H2 sections → three per-topic files + index
- Slug collision (two identical H2 texts) → `-2` suffix applied
- Code-fence-protected H2 inside a fenced block → not promoted to topic marker
- Idempotent re-run → no-op exit 0 (no second migration)

Contract bats in `test/migrate-briefing-contract.bats` asserts:

- SKILL.md frontmatter declares the skill name + description
- ADR-032 (foreground-synchronous), ADR-014 (self-commit), ADR-038 (progressive disclosure), ADR-040 (target shape), ADR-052 (behavioural tests) all cross-referenced
- Idempotency clause present (two-direction no-op)
- Rule 6 audit section present (ADR-013)

## Related

- P204 — the ticket this skill closes
- ADR-040 — target tree contract
- JTBD-007 — adopter currency (pending amendment to extend scope to artefact-layout-currency per P204 new-jtbd-flag; queued for next /wr-itil:review-problems)
- `feedback_no_repo_relative_paths_in_published_artifacts.md` — why the helper script ships via `bin/` shim per ADR-049
