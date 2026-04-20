# Problem 065: No skill scaffolds intake files (ISSUE_TEMPLATE, SECURITY.md, CONTRIBUTING.md, SUPPORT.md) in downstream projects

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M — new `/wr-itil:scaffold-intake` skill in `@windyroad/itil` that writes the six intake files (config.yml, bug-report.yml, feature-request.yml, SECURITY.md, SUPPORT.md, CONTRIBUTING.md), templated from the versions this repo ships, with per-project substitutions (project name, plugin list, contact paths) and idempotent re-run behaviour. Includes a bats fixture test exercising a mock downstream repo.
**WSJF**: 6.0 — (12 × 1.0) / 2 — High-severity ecosystem gap, moderate effort; above P064 (3.0) but below P063 (9.0) in the dev-work queue.

## Description

`/wr-itil:report-upstream` (P055 Part B, `@windyroad/itil@0.8.0`) discovers upstream `.github/ISSUE_TEMPLATE/*` and `SECURITY.md` via `gh api` and targets them when a downstream agent files a report. The skill falls through to a structured default when the upstream has no templates, but the whole ecosystem works better when every project in the chain actually ships intake files — otherwise every report is a structured-default "default and hope the maintainer figures out the intent" prose blob, and security reports have no declared channel.

This repo shipped Part A (six intake files for `@windyroad/agent-plugins` itself): `.github/ISSUE_TEMPLATE/config.yml`, `bug-report.yml`, `feature-request.yml`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md` (commit `e36cf84`). These were hand-authored directly into the repo. **Nothing in the suite scaffolds equivalent files for downstream projects** that adopt `@windyroad/itil` (or any `@windyroad/*` plugin).

Consequence: a downstream project D (addressr, bbstats, any future adopter) that calls `/wr-itil:report-upstream` targeting some upstream U benefits from the skill — good. But D itself has no templates, no SECURITY.md, no CONTRIBUTING.md. When D's own downstreams (or any external reporter) try to file an issue against D, they hit the same gap P055 Part A closed for *this* repo: no structured intake, no private security-disclosure path, no usage-question routing. Every project in the Windy Road ecosystem that adopts the suite inherits this gap by default.

`packages/itil/bin/install.mjs` installs the plugin, skills, and hooks; it does NOT offer to scaffold intake files. No skill prompts for it either — `/wr-itil:manage-problem`, `/wr-itil:work-problems`, `/wr-itil:manage-incident`, `/wr-itil:report-upstream` all operate on existing problem tickets and never ask "does this project have intake files? would you like me to scaffold them?"

The fix is a new scaffolding skill (working title `/wr-itil:scaffold-intake`) that:

1. Detects whether the current project has `.github/ISSUE_TEMPLATE/`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`.
2. For each missing file, prompts the user (interactive) or defaults to scaffolding (AFK, per JTBD-006) with per-project substitutions.
3. Writes files templated from the versions this repo ships, substituting project name, plugin list, and contact paths appropriately.
4. Is idempotent — re-running the skill on a project that already has the files reports "already present" and offers to update / diff, never silently overwrites.

## Symptoms

- Downstream projects adopting `@windyroad/itil` have no `.github/ISSUE_TEMPLATE/` directory, no `SECURITY.md`, no `SUPPORT.md`, no `CONTRIBUTING.md`. Every external reporter filing an issue against D gets GitHub's default blank issue form.
- Security reports against downstream projects have no declared disclosure channel — reporters either open a public issue (exposure), contact the maintainer out-of-band if they happen to know one, or give up.
- `/wr-itil:report-upstream` targeting a downstream-ecosystem project (e.g. a Windy Road plugin reports upstream to another Windy Road plugin) falls through to the structured default because the target has no templates — every report loses the curated required-fields the intake would have defined.
- New downstream adopters have no guided path to match the intake quality of the Windy Road suite itself. Reputation of the ecosystem suffers because the reference-grade intake exists only in `@windyroad/agent-plugins`, not in its consumers.
- Per ADR-024 Confirmation criterion 6 (advisory): downstream adoption of `/wr-itil:report-upstream` within 3 months is a reassessment trigger. Adoption is frictional when every downstream also has to hand-author intake files.

## Workaround

Downstream project maintainers hand-author the six files by copying this repo's versions and adjusting names/links manually. That's exactly the "clear patterns, not reverse-engineering" pain JTBD-101 is designed against, and it doesn't scale: every adopter re-does the same work, and drift between copies accumulates over time.

## Impact Assessment

- **Who is affected**:
  - **Plugin-developer persona (JTBD-101)** — "Extend the Suite with Clear Patterns"; downstream adopters face reverse-engineering exactly the pattern P055 Part A established in this repo. The promise fails at the replication step.
  - **Solo-developer persona (JTBD-001)** — agents working in downstream projects have no structured prompt to scaffold intake. The user either remembers to ask for it or gets surprised later when an external reporter hits a default blank form.
  - **Tech-lead persona (JTBD-201)** — auditability depends on every project having a declared intake surface. Without scaffolded intake, downstream projects can't be reliable sources/targets for the bi-directional issue linkage ADR-024 assumes.
  - **External reporters of downstream projects** — no structured path to report bugs or security issues against any Windy-Road-adopting project other than this repo. Reputation compound: more projects adopt the suite → more projects lack intake → more reporters hit blank forms → ecosystem looks less maintained.
  - **Addressr, bbstats, any future adopter** — confirmed downstreams today; each independently lacks intake surface.
- **Frequency**: Every downstream adoption of `@windyroad/itil` (or any `@windyroad/*` plugin whose presence implies a maintained OSS repo). Likelihood scales with adoption count.
- **Severity**: High for the ecosystem, Moderate for any single adopter. Ecosystem-level: this is the "Part A isn't reusable" seam — P055 Part A's value was supposed to be the reference intake shape that `/wr-itil:report-upstream` can target; the shape exists only in one repo unless something scaffolds it elsewhere.
- **Analytics**: None today; ecosystem-level gap visible only through downstream-project audits (addressr and bbstats confirmed lacking).

## Root Cause Analysis

### Structural

P055 planned Part A as "ship intake files in this repo" and Part B as "ship the skill that reports upstream". The three-way coupling — (A) upstream has intake, (B) downstream calls report-upstream, **(C) downstream also has its own intake so it can be targeted by its own downstreams** — was never scoped. ADR-024's scope boundary explicitly excludes "the intake scaffolding half of P055 (CONTRIBUTING.md, SUPPORT.md, SECURITY.md, `.github/ISSUE_TEMPLATE/` in THIS repo)" and leaves scaffolding-for-downstream-projects out of its scope entirely.

`packages/itil/bin/install.mjs` is a plugin installer, not a project-scaffolder. It adds the plugin to the host Claude Code project but does not inspect the host's OSS-hygiene surface, nor does it prompt to scaffold intake files. No companion skill exists either — `/wr-itil:manage-problem` and peers work on existing `docs/problems/` content and assume the project is already set up.

### Candidate fix

Add a new action skill to `@windyroad/itil` (working title `/wr-itil:scaffold-intake` — alternative names: `init-intake`, `setup-intake`, `scaffold-oss-hygiene`). Rationale for placement in `@windyroad/itil`:

- Intake files are the receiving end of `/wr-itil:report-upstream`; both live naturally in the same plugin per ADR-024's "skill in itil vs new plugin" rationale (Option 1 of ADR-024, extended).
- No new package to publish; no ADR-002 dependency-graph churn.
- Alternative placements considered: (a) a new `@windyroad/oss-hygiene` plugin — adds a package publish for a narrow capability; (b) a companion to `@windyroad/agent-plugins` — wrong scope, that's the marketplace not a downstream-consumable plugin.

Skill contract (draft):

- Invocation: `/wr-itil:scaffold-intake [--dry-run] [--force] [--project-name <name>] [--project-url <url>]`
- Steps:
  1. Detect project name (from `package.json` `name`, fallback to directory name) and project URL (from `package.json` `repository.url`, fallback `git remote get-url origin`).
  2. Check for existing `.github/ISSUE_TEMPLATE/`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/config.yml`.
  3. For each missing file, emit a templated version with per-project substitutions. Use `AskUserQuestion` in interactive mode to confirm each file or batch; in AFK mode default to scaffolding missing files (per JTBD-006 — agent must not trust itself to make judgement calls, but "scaffold a missing standard file" is within policy-authorised scope).
  4. For each present file, report "already exists" and offer `--force` diff-and-replace behaviour. Never silently overwrite.
  5. Write the files. Commit per ADR-014 (work → score via wr-risk-scorer:pipeline → commit). Commit message: `docs: scaffold OSS intake (ISSUE_TEMPLATE, SECURITY, SUPPORT, CONTRIBUTING)`.
- Templates:
  - Seeded from this repo's versions (commit `e36cf84`) with substitution tokens for project name, plugin list, security-contact path, and any plugin-specific fields.
  - Ship as skill-local template files under `packages/itil/skills/scaffold-intake/templates/*.yml.tmpl`, `*.md.tmpl`.
  - Use a minimal mustache-style substitution (no runtime dependency) so the skill works against any project without adding new tooling.
- Architect review needed to decide:
  - Whether this earns its own ADR or rides under ADR-024 as the reciprocal-scaffolding extension.
  - Whether `/wr-itil:manage-problem` and `/wr-itil:work-problems` should prompt-once when they detect missing intake in the host project ("scaffold intake now? one-time prompt").

### Investigation Tasks

- [ ] Confirm placement decision: skill in `@windyroad/itil` vs. new plugin. Architect review.
- [ ] Decide whether a new ADR is needed or an extension of ADR-024's scope. Architect review.
- [ ] Enumerate template files and their substitution tokens. Start from `e36cf84` versions; abstract the repo-specific strings.
- [ ] Design the interactive and AFK flows; decide default-on vs. prompt-always behaviour per JTBD-006.
- [ ] Decide whether `manage-problem` / `work-problems` get a one-shot "scaffold intake missing?" prompt on first run in a new project.
- [ ] Build a fixture-based bats test exercising a mock empty downstream repo, asserting all six files are scaffolded with correct substitutions.
- [ ] Add an idempotency test: re-running the skill on a scaffolded project reports "already present" and does not overwrite.
- [ ] Cross-reference the new skill from `packages/itil/skills/manage-problem/SKILL.md` (section on how projects are set up) and from ADR-024 (reciprocal-scaffolding note).
- [ ] Update ADR-002's `itil/` inventory to include the new skill.
- [ ] Update `CONTRIBUTING.md` of this repo and of the itil package README to point new adopters at the scaffolding command.

## Related

- **P055** — parent ticket; Part A shipped intake files for THIS repo but did not scaffold for downstreams. This ticket closes that ecosystem gap.
- **P063** — manage-problem does not trigger `/wr-itil:report-upstream` when root cause is external. Adjacent wiring gap; both are "trigger surfaces missing" for shipped capabilities.
- **P064** — no risk-scoring gate on external comms. Sibling external-surface ticket.
- **P034** — centralise risk reports; shares the "cross-project pattern should be scaffold-able" motif.
- **ADR-024** — cross-project problem-reporting contract; scope explicitly excluded intake scaffolding, leaving this ticket open.
- **ADR-002** — monorepo with per-plugin packages; the new skill's placement decision (itil vs new plugin) is made against this graph.
- **ADR-010** — skill naming pattern (`<verb>-<object>`); `scaffold-intake` fits.
- **ADR-011** — action-skill precedent (manage-incident wrapping); `scaffold-intake` is an action skill with the same shape.
- **ADR-013** — structured user interaction; Rule 1 governs the per-file scaffolding prompts; Rule 6 governs the AFK default-on branch.
- **ADR-014** — governance skills commit their own work; the skill writes files and commits per the standard ordering.
- **JTBD-001** (Enforce Governance Without Slowing Down) — the persona that benefits from one-command scaffolding vs. hand-authoring.
- **JTBD-101** (Extend the Suite with Clear Patterns) — the persona that most directly motivates this fix.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — downstream projects need declared intake to serve as reliable sources/targets of bi-directional linkage.
- **JTBD-006** — AFK persona constraint; scaffolding missing-and-standard files is within policy-authorised scope, but the skill must not overwrite existing content without user opt-in.
- `packages/itil/bin/install.mjs` — current installer; does not scaffold intake files, candidate for a `--with-intake` flag or a post-install prompt.
- Commit `e36cf84` — the P055 Part A intake files that become the template source.
- addressr, bbstats — confirmed downstream adopters lacking intake; dogfood candidates.
