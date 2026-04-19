---
status: "superseded"
date: 2026-04-14
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-07-14
superseded-by: [008-jtbd-directory-structure]
---

# JTBD Project-Wide Enforcement

> **Superseded by [ADR-008](008-jtbd-directory-structure.proposed.md)**. The project-wide enforcement scope from this decision is preserved in ADR-008. The change is to the JTBD document structure AND the document artefact itself: ADR-008 (Option 3 chosen 2026-04-20 per P019) makes `docs/jtbd/` the sole canonical layout. The legacy single-file `docs/JOBS_TO_BE_DONE.md` artefact name referenced throughout this ADR is no longer recognised at runtime by any hook, agent, or skill — with the single carve-out that `wr-jtbd:update-guide` may read it for one-shot migration. Format change, not just structure change.

## Context and Problem Statement

The JTBD plugin (`wr-jtbd`) currently only applies to web UI file types (`.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`, `.ejs`, `.hbs`). This scoping assumes JTBD is a UI concern, but it is not — Jobs To Be Done applies to any product: CLI tools, plugin suites, APIs, libraries, and web apps alike.

As a result, projects without web UI files (like this plugin suite) never get prompted to create `docs/JOBS_TO_BE_DONE.md`, and the enforcement gate never fires. The JTBD plugin is effectively invisible for non-UI projects.

## Decision Drivers

- **JTBD is product-level, not UI-level**: Every product has users with jobs to be done, whether the interface is a web page, a CLI command, a hook script, or a skill file.
- **Consistency with architect gate**: The architect plugin gates all project files (with a narrow exclusion list). JTBD should have the same scope.
- **Auto-suggest guide creation**: When `docs/JOBS_TO_BE_DONE.md` doesn't exist, the eval hook should always suggest creating it, regardless of project type.

## Considered Options

### Option 1: Broaden to All Project Files (with exclusions)

Remove the UI-only file extension guard. Apply JTBD enforcement to all project files using the same exclusion list as the architect gate. Both the eval hook (suggestion) and enforce hook (blocking) are broadened.

### Option 2: Keep UI-Only Enforcement

Status quo. JTBD enforcement only fires on `.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`, `.ejs`, `.hbs` files. Non-UI projects are not covered.

### Option 3: Configurable Scope per Project

Add a config option (e.g., in `docs/JOBS_TO_BE_DONE.md` frontmatter or a separate config file) that lets each project define which file types JTBD applies to. Default to UI files, allow broadening.

## Decision Outcome

**Chosen option: Option 1 — Broaden to all project files with exclusions**, because JTBD is a product concern, not a UI concern. Any change to a project file could affect how well the product serves its users' jobs.

### Changes

**Eval hook (`jtbd-eval.sh`):**
- Remove the `ls src/**/*.tsx src/**/*.jsx src/**/*.html` guard
- Always output the suggestion to run `/wr-jtbd:update-guide` when `docs/JOBS_TO_BE_DONE.md` is missing
- Update messaging from "user-facing UI file" to "project file"

**Enforce hook (`jtbd-enforce-edit.sh`):**
- Remove the UI-only file extension case guard
- Apply to all project files with the same exclusion list as the architect gate:
  - CSS/SCSS/SASS/LESS
  - Images (PNG, JPG, JPEG, SVG, ICO, WEBP, GIF)
  - Fonts (WOFF, WOFF2, TTF, EOT)
  - Lockfiles (package-lock.json, yarn.lock, pnpm-lock.yaml)
  - Source maps (`.map`)
  - Changesets (`.changeset/*.md`)
  - Memory files (`MEMORY.md`, `.claude/projects/*/memory/*`)
  - Plan files (`.claude/plans/*.md`)
  - Risk reports (`.risk-reports/*`)
  - Briefing (`docs/BRIEFING.md`)
  - Problem tickets (`docs/problems/*.md`)
  - Risk policy (`RISK-POLICY.md`)

### Dual-Gate Interaction

With this change, every edit to a non-excluded project file triggers two independent gates:

1. **Architect gate** — reviews against `docs/decisions/*.md`
2. **JTBD gate** — reviews against `docs/JOBS_TO_BE_DONE.md`

Each gate requires its own subagent review. This adds latency and token cost per edit cycle, but the reviews serve different purposes: the architect checks structural/technology decisions while JTBD checks product/user alignment.

If `docs/JOBS_TO_BE_DONE.md` does not exist, the JTBD enforce gate blocks edits and directs the user to create the document via `/wr-jtbd:update-guide`.

## Consequences

### Good

- JTBD enforcement applies to all products, not just web UIs
- Non-UI projects get prompted to document jobs
- Consistent scoping with the architect gate

### Neutral

- Every edit now triggers two review gates (architect + JTBD)
- Additional token cost per edit cycle for the JTBD subagent review

### Bad

- Increased friction for projects that have not yet created `docs/JOBS_TO_BE_DONE.md` — all edits are blocked until the document exists
- Double-gating may feel heavy for small changes

## Confirmation

- `jtbd-eval.sh` suggests `/wr-jtbd:update-guide` for any project missing the doc (no UI file check)
- `jtbd-enforce-edit.sh` gates all project files except the exclusion list
- `jtbd-enforce-edit.sh` allows: `.css`, `.scss`, `.png`, `.jpg`, `.svg`, `.woff`, `package-lock.json`, `.changeset/*.md`, `MEMORY.md`, `.claude/plans/*.md`, `.risk-reports/*`, `docs/BRIEFING.md`, `docs/problems/*.md`, `RISK-POLICY.md`
- `jtbd-enforce-edit.sh` blocks: `.ts`, `.js`, `.sh`, `.mjs`, `.json` (non-lockfile), `.md` (non-excluded)
- BATS tests exist for the broadened scope

## Pros and Cons of the Options

### Option 1: Broaden to All Project Files

- Good: JTBD applies to all products
- Good: Consistent with architect gate scope
- Good: Forces JTBD documentation early
- Bad: Double-gating adds latency
- Bad: Blocks all edits if JTBD doc doesn't exist

### Option 2: Keep UI-Only

- Good: No additional friction for non-UI projects
- Good: Lighter enforcement
- Bad: JTBD is invisible for CLI tools, plugins, libraries
- Bad: Inconsistent with the principle that JTBD is product-level

### Option 3: Configurable Scope

- Good: Maximum flexibility per project
- Bad: Configuration complexity — another config file or frontmatter to manage
- Bad: Default to UI-only means most projects still miss coverage
- Bad: Implementation effort for a config parser in bash

## Reassessment Criteria

- **Dual-gate friction is too high**: If the two gates cause excessive delays, consider merging the architect and JTBD reviews into a single compound agent, or making JTBD advisory (suggest, not block) for non-UI projects.
- **Gate ordering/caching**: If Claude Code adds support for gate ordering or shared review sessions, revisit whether dual-gate overhead can be reduced.
- **New project types**: If the suite starts supporting project types with fundamentally different "user-facing" definitions, consider whether the exclusion list needs project-type-specific variants.
