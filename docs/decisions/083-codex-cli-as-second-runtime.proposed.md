---
status: "proposed"
date: 2026-06-23
human-oversight: confirmed
oversight-date: 2026-08-13
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-09-23
---

# Codex CLI as second runtime

> Captured via `/wr-architect:capture-adr` and completed retrospectively from
> the shipped architect, risk-scorer, and Cruise implementations.

## Context and Problem Statement

`@windyroad/*` plugins have shipped Claude Code only; ADR-002 (Monorepo per-plugin packages) line 241 and ADR-003 (Marketplace-only distribution) line 93 named Codex/Copilot support as a reassessment trigger but did not record the choice. OpenAI's Codex CLI (codex-cli 0.137.0) reached a stable plugin marketplace + custom-collaborator-agent surface, so the trigger fired.

## Decision Drivers

- **Preserve Claude Code compatibility.** Claude remains the default runtime;
  adding Codex must not rename, replace, or weaken existing Claude manifests,
  skills, agents, hooks, or installer behaviour.
- **Keep independently installable packages.** Codex support should extend the
  existing `packages/<plugin>` unit rather than create a second product tree.
- **Keep one source of truth per behaviour.** Runtime-neutral instructions and
  Claude agent markdown remain canonical; runtime-specific manifests, skill
  projections, and custom-agent files are generated or drift-checked where the
  runtimes require different formats.
- **Ship only real capabilities.** A package exposes Codex skills, hooks, or
  custom agents only when its behaviour needs those surfaces; skill-only
  packages do not gain speculative agents or hooks.
- **Prove installability from the published artefact.** Validation must pack the
  scoped npm package, install it through an isolated Codex marketplace, and
  exercise discovery outside the source checkout.
- **Roll out incrementally.** One package proves each required compatibility
  shape before that machinery is reused by another package; partial rollout is
  reported as partial rather than suite-wide parity.

## Considered Options

1. **Option A (chosen) — Extend each existing package to both runtimes.** Add
   `--runtime claude|codex|both` to package installers while keeping Claude as
   the default. Each migrated package carries a separate
   `.codex-plugin/plugin.json`, package-local and repo-local marketplace
   metadata, and only the Codex projections its behaviour requires. Shared
   install utilities and manifest versions use the repository's existing sync
   and drift-check pattern. `AGENTS.md` and `CLAUDE.md` remain runtime-specific
   projections of shared governance. Where custom agents exist, Claude markdown
   remains canonical and generated Codex TOML is installed outside the plugin
   bundle with ownership-safe update and removal.
2. **Option B — Create a separate Codex package tree or repository.** Fork the
   Claude packages, instructions, installers, and release flow into Codex-owned
   copies that can evolve independently.
3. **Option C — Distribute skills directly without plugin parity.** Publish or
   copy portable skills through native skill directories, without Codex plugin
   manifests, marketplace registration, or consistent npm-backed
   install/update/uninstall behaviour.
4. **Option D — Remain Claude-only.** Keep the existing product and distribution
   model unchanged and decline Codex support.

## Decision Outcome

Chosen option: **"Option A — Extend each existing package to both runtimes"**,
because it preserves the independently installable package boundary and reuses
the repository's established sync-and-drift controls without duplicating the
product. Claude remains the default and source-compatible runtime; Codex is an
opt-in package capability added one plugin at a time.

The initial architect pilot was verified end to end with codex-cli 0.137.0:
marketplace registration, plugin installation, and `codex exec` from an adopter
directory with no project `.codex/` configuration produced the expected
architecture-review verdict. Subsequent shipped proof covers three distinct
package shapes: architect installs one generated custom agent; risk-scorer
installs multiple generated agents and completion adapters; Cruise installs a
skill plus runtime-specific quota hooks and producer support. This is evidence
for those packages and the rollout pattern, not a claim of suite-wide Codex
parity. Remaining packages migrate independently when their actual surfaces are
implemented and validated.

Each Codex-bearing skill carries hand-authored picker metadata at
`skills/<skill>/agents/openai.yaml`, using the display-name grammar
`WR <Package Title>: <Skill Title Case>`. Packages that rewrite skills during
packing preserve this metadata in the packed output. Display labels do not
change machine invocation names, and metadata-test coverage is derived from
`.codex-plugin` presence so a newly Codex-bearing package or skill cannot ship
without it.

Generated custom-agent files carry an ownership marker and the hash of their
last generated payload. Installers update or remove a generated file only while
that payload still matches, preserving unmarked collisions and user-modified
TOML.

For risk-scorer specifically, custom-agent completion uses `SubagentStop` as the
primary desktop signal and the completed-close response as the CLI and
older-runtime fallback. Both routes normalize through the existing marker
parser and share atomic `(session_id, agent_id)` claim state so one completion
is processed once. The adapter does not parse transcripts or launch nested
Codex processes; missing, malformed, or unrecognised completion fails closed.
Claude continues to use `PostToolUse:Agent`, and the Codex external-comms agent
emits the canonical draft key because completion payloads do not expose the
spawn prompt.

## Consequences

### Good

- Claude users keep the existing default command, manifests, and behaviour.
- Codex support stays inside the same independently versioned npm package, so
  source, release, and ownership boundaries do not split by runtime.
- Canonical sources plus generated or drift-checked projections prevent silent
  divergence between runtime formats.
- Incremental rollout contains failures and allows skill-only packages to remain
  skill-only.

### Neutral

- Each migrated package carries additional manifest, marketplace, packaging,
  installer, and validation surfaces.
- Runtime capabilities are not identical: Claude and Codex may need different
  discovery, hook, and custom-agent adapters while preserving the same intent.
- Codex support is package-scoped; the suite can be partially migrated for an
  extended period.

### Bad

- Codex CLI and desktop surfaces can differ, requiring explicit compatibility
  probes and fallback paths rather than one assumed hook contract.
- Pack-time projections and generated agent files add drift and ownership risks;
  missing checks could publish an internally inconsistent plugin.
- Supporting two runtimes increases the install and behavioural test matrix for
  every package that opts in.

## Confirmation

For every Codex-bearing package:

1. Running its installer without `--runtime` exercises only the unchanged
   Claude path; `--runtime codex` and `--runtime both` select the additional
   paths explicitly.
2. The scoped npm tarball contains its `.codex-plugin` manifest, package-local
   marketplace metadata, skill interface metadata, and only the scripts, hooks,
   or generated-agent machinery the package uses.
3. Installation stages that tarball under a package-owned temporary marketplace
   root before Codex registration; install, update, and uninstall do not remove
   another package's marketplace or user-modified generated files.
4. `scripts/sync-codex-plugin-manifests.mjs --check` proves the Codex manifest
   version matches `package.json`; agent and skill projection checks prove
   generated outputs match their canonical sources where projection is needed.
5. A behavioural package test installs the packed artefact into an isolated
   `CODEX_HOME` and confirms Codex discovers the exact plugin version. A Codex
   promptfoo or equivalent smoke invokes the installed package's principal
   skill or agent outside the source checkout.
6. Packages with custom agents test exact identities, scope, idempotent repair,
   marker-and-hash ownership, collision preservation, modified-file
   preservation, and ownership-safe uninstall. Skill-only packages add no
   custom agent or hook merely to satisfy a generic template.
7. `npm run check:agent-instructions` keeps runtime-neutral governance aligned
   across `CLAUDE.md`, `AGENTS.md`, and their shared source.
8. Risk-scorer completion fixtures replay desktop `SubagentStop`, empty CLI
   wait, completed-close fallback, duplicate delivery, and malformed delivery;
   the paths share one parser and cannot duplicate a marker write.

As of this completion, architect, risk-scorer, and Cruise supply shipped proof
for their respective shapes. Other packages do not satisfy this decision until
their own package-level confirmation passes.

## Pros and Cons of the Options

### Option A — Extend each existing package to both runtimes

- Good: reuses the current monorepo, package boundaries, canonical sources,
  release process, and sync controls.
- Good: preserves Claude compatibility and makes Codex opt-in per package.
- Good: supports the smallest real surface for each package rather than forcing
  feature parity where none is needed.
- Bad: requires package-specific adapters and a wider validation matrix.
- Bad: partial rollout must be communicated precisely.

### Option B — Separate Codex package tree or repository

- Good: permits independent Codex-specific design and release cadence.
- Bad: duplicates sources, packages, governance, and fixes.
- Bad: conflicts with the existing monorepo decision that other runtimes extend
  the independently installable per-plugin packages.

### Option C — Skills-only direct/native distribution

- Good: smallest initial path for portable instruction-only skills.
- Bad: cannot carry package hooks or custom agents and provides no plugin-level
  installation parity.
- Bad: conflicts with marketplace-only distribution and loses consistent npm
  install, update, and uninstall behaviour.

### Option D — Remain Claude-only

- Good: no additional compatibility or validation cost.
- Bad: declines a demonstrated second-runtime capability and leaves Codex users
  without supported package installation.

## Reassessment Criteria

Revisit this decision when any of the following occurs:

- Codex adopts plugin-bundled custom agents or a stable cross-surface hook model
  that makes the generated external TOML or compatibility adapters unnecessary.
- A migrated package cannot preserve materially equivalent intent across Claude
  and Codex without forking its canonical behaviour.
- Two package migrations require the same new adapter, triggering extraction
  into the existing shared-and-synced machinery; one package alone does not.
- Isolated package tests stop matching the supported Codex CLI or desktop
  behaviour, or a published package cannot be installed and removed without
  touching another package's state.
- Maintenance evidence shows the dual-runtime test and projection cost exceeds
  the value of supported Codex installs, in which case retaining only selected
  packages or reverting to Claude-only support should be reconsidered.
