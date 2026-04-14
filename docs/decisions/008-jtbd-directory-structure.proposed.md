---
status: "proposed"
date: 2026-04-14
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-14
supersedes: [007-jtbd-project-wide-enforcement]
---

# JTBD Directory Structure

## Context and Problem Statement

The JTBD plugin currently stores all jobs in a single `docs/JOBS_TO_BE_DONE.md` file. This was adequate for initial setup, but does not scale. The bbstats project already outgrew this format and migrated to a directory structure with individual files per persona and per job (bbstats commits `9a215dd` and `d961668`). That migration was done with local hook changes that are now lost since bbstats switched to the marketplace plugin.

The directory structure enables:
- Per-persona directories with dedicated persona definitions
- Individual job files with lifecycle status (`.proposed.md` -> `.validated.md`)
- Structured frontmatter (status, job-id, persona, screens, hateoas-actions)
- `@jtbd` code annotations linking source files to specific jobs
- Git history per job (not per document)

## Decision Drivers

- **Proven in production**: The bbstats project successfully uses this structure with 18 jobs across 3 personas
- **Per-job lifecycle**: Jobs move from proposed to validated independently — a single file can't track this
- **Traceability**: `@jtbd` annotations in source code link to specific job files, enabling the agent to review only relevant jobs for a given file change
- **Scalability**: 5 jobs fit in one file; 18+ jobs across 3 personas do not
- **Backward compatibility**: Projects with an existing `docs/JOBS_TO_BE_DONE.md` should continue to work

## Considered Options

### Option 1: Directory Structure with Backward Compatibility

Migrate to `docs/jtbd/` directory. Support both formats: if `docs/jtbd/README.md` exists, use the directory; if only `docs/JOBS_TO_BE_DONE.md` exists, use the single file. The update-guide skill offers migration.

### Option 2: Keep Single File

Status quo. All jobs in `docs/JOBS_TO_BE_DONE.md`. No per-job lifecycle or code annotations.

## Decision Outcome

**Chosen option: Option 1 — Directory structure with backward compatibility**, because it has already been proven in the bbstats project and the single-file format does not support the lifecycle, traceability, or scalability needs.

This decision supersedes ADR-007 (JTBD Project-Wide Enforcement). The project-wide enforcement scope from ADR-007 is preserved — the change is to the document structure, not the enforcement scope.

## Directory Structure

```
docs/jtbd/
  README.md                              # Index — tables of personas and jobs by status
  <persona-name>/
    persona.md                           # Persona definition (who, constraints, pain points)
    JTBD-NNN-<kebab-title>.proposed.md   # Proposed job (not yet validated)
    JTBD-NNN-<kebab-title>.validated.md  # Validated job (confirmed with users)
```

### Persona File Format (`persona.md`)

```markdown
---
name: <persona-name>
description: <one-line description>
---

# <Persona Name>

## Who
<who this persona is>

## Context Constraints
<bullet list of constraints>

## Pain Points
<bullet list>
```

### Job File Format (`JTBD-NNN-<title>.<status>.md`)

```markdown
---
status: proposed | validated
job-id: <kebab-case-id>
persona: <persona-name>
date-created: YYYY-MM-DD
screens:
  - <route or screen path>
---

# JTBD-NNN: <Title>

## Job Statement
When [situation], I want to [motivation], so I can [expected outcome].

## Screen Mapping
- Primary screen: <route>
- Entry points: <routes>

## Desired Outcomes
<bullet list>

## Persona Constraints
<relevant constraints from persona>

## @jtbd Annotations
<list of source files with @jtbd annotations>
```

### ID Ranges

Each persona gets a range to avoid collisions:
- First persona: 001-099
- Second persona: 100-199
- Third persona: 200-299
- etc.

### README.md Index

The index groups jobs by persona and status (Validated, Proposed), with links to each file.

## Plugin Changes

### Eval Hook (`jtbd-eval.sh`)

Check for `docs/jtbd/README.md` first. Fall back to `docs/JOBS_TO_BE_DONE.md`. If neither exists, suggest `/wr-jtbd:update-guide`.

### Enforce Hook (`jtbd-enforce-edit.sh`)

- Hash `docs/jtbd` directory for drift detection (instead of single file)
- Exempt `docs/jtbd/` files from the gate (replaces P002's `docs/JOBS_TO_BE_DONE.md` exemption)
- Fall back to `docs/JOBS_TO_BE_DONE.md` if `docs/jtbd/` doesn't exist

### Mark-Reviewed Hook (`jtbd-mark-reviewed.sh`)

- Store hash for `docs/jtbd` directory (instead of single file)
- Fall back to `docs/JOBS_TO_BE_DONE.md` if `docs/jtbd/` doesn't exist

### Agent (`agents/agent.md`)

- Read `docs/jtbd/README.md` for the index
- Read relevant persona and job files matching the route being edited
- Fall back to `docs/JOBS_TO_BE_DONE.md` if `docs/jtbd/` doesn't exist

### Update-Guide Skill (`skills/update-guide/SKILL.md`)

- Generate the directory structure with persona directories and individual job files
- If `docs/JOBS_TO_BE_DONE.md` exists, offer to migrate its content to the directory structure
- Generate the README.md index

### Drift Detection

The `review-gate.sh` shared library already supports directory hashing. Changing the policy path from `"docs/JOBS_TO_BE_DONE.md"` to `"docs/jtbd"` uses the directory branch automatically. The `README.md` in `docs/jtbd/` should be included in the hash (it is the index and its structure matters).

## Consequences

### Good

- Per-job lifecycle (proposed -> validated) tracked in filenames
- Per-persona directories keep related jobs together
- Git history shows when each job was added/changed independently
- `@jtbd` annotations enable targeted review (only check jobs relevant to the file being changed)
- Backward compatible with existing single-file projects

### Neutral

- More files to manage (mitigated by the update-guide skill generating the structure)
- Agent needs to read multiple files (mitigated by reading only relevant ones per review)

### Bad

- Migration effort for existing projects using `docs/JOBS_TO_BE_DONE.md`
- More complex enforce hook logic (directory vs file detection)

## Confirmation

- Eval hook detects `docs/jtbd/README.md` and suggests `update-guide` when missing
- Eval hook falls back to `docs/JOBS_TO_BE_DONE.md` for backward compatibility
- Enforce hook hashes `docs/jtbd` directory for drift detection
- Enforce hook exempts `docs/jtbd/` files from the JTBD gate
- Mark-reviewed hook stores hash for `docs/jtbd` directory
- Agent reads from `docs/jtbd/` when it exists, falls back to single file
- Update-guide skill generates the directory structure with personas and jobs
- BATS tests updated for both directory and single-file paths
- Existing projects with only `docs/JOBS_TO_BE_DONE.md` continue to work

## Reassessment Criteria

- **Code annotation tooling**: If Claude Code adds native support for linking code to documentation (beyond text comments), the `@jtbd` annotation pattern may need updating.
- **Job count exceeds 100 per persona**: Consider whether the flat file structure within persona directories needs sub-grouping.
