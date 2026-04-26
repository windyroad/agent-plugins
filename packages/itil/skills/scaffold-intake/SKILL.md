---
name: wr-itil:scaffold-intake
description: Scaffold the four OSS intake surfaces (.github/ISSUE_TEMPLATE/, SECURITY.md, SUPPORT.md, CONTRIBUTING.md) for a downstream project that adopts @windyroad/itil. Idempotent, foreground-synchronous, and respects ADR-009 marker semantics. Implements the contract in ADR-036.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Scaffold Intake — Downstream OSS Intake Skill

Scaffold the five intake files every project in the Windy Road ecosystem needs to receive structured problem reports and route security disclosure properly:

- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/problem-report.yml`
- `SECURITY.md`
- `SUPPORT.md`
- `CONTRIBUTING.md`

Templates are seeded from this repo's P066-corrected problem-first intake set and are substituted with per-project values for project name, repository URL, plugin list, and security-contact path.

This skill implements the contract in [ADR-036](../../../../docs/decisions/036-scaffold-downstream-oss-intake.proposed.md) (Scaffold downstream OSS intake — skill + layered triggers). It is the reciprocal of [`/wr-itil:report-upstream`](../report-upstream/SKILL.md) — that skill files reports against upstream intake; this skill creates the intake surface so a downstream project can be a target.

## Pattern

This skill is **foreground-synchronous** per [ADR-032](../../../../docs/decisions/032-governance-skill-invocation-patterns.proposed.md) (Governance skill invocation patterns). Scaffolding writes files into the project that the user normally wants to review before they commit; the wrapped-pattern subagent shape would defeat that review. The skill commits its own work per [ADR-014](../../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md).

## Invocation

```
/wr-itil:scaffold-intake [--dry-run] [--force] [--project-name <name>] [--project-url <url>] [--security-contact <path>] [--ci]
```

| Flag | Effect |
|---|---|
| `--dry-run` | Preview the files that would be scaffolded; no writes. |
| `--force` | Overwrite present files after a diff-and-replace prompt. Off by default — present files are reported as "already present" and skipped. |
| `--project-name <name>` | Override auto-detected project name (default: `package.json` `name`, fallback to repo dirname). |
| `--project-url <url>` | Override auto-detected repository URL (default: `package.json` `repository.url`, fallback to `git remote get-url origin`). |
| `--security-contact <path>` | Override the security-disclosure path written into SECURITY.md (default: `Use GitHub Security Advisories`). |
| `--ci` | Also emit `.github/workflows/intake-check.yml` (Trigger 3, optional). |

## Steps

### 1. Detect project metadata

```bash
PROJECT_NAME=$(node -p "require('./package.json').name" 2>/dev/null || basename "$PWD")
PROJECT_URL=$(node -p "require('./package.json').repository?.url || ''" 2>/dev/null \
              | sed -E 's|^git\+||; s|\.git$||' \
              || git remote get-url origin 2>/dev/null \
              || echo "")
YEAR=$(date +%Y)
```

`--project-name` and `--project-url` flags override the auto-detected values when supplied. `package.json` shapes vary across adopters; if detection produces empty values, surface a clear error suggesting the override flags rather than substituting an empty token.

Plugin list: enumerate installed `@windyroad/*` packages from `.claude-plugin/plugin.json` (if present) or from `package.json` dev-dependencies. Used for the SUPPORT.md "affected plugin or component" enumeration.

### 2. Enumerate target paths

Required intake files (per ADR-036 Detection step 5):

```
.github/ISSUE_TEMPLATE/config.yml
.github/ISSUE_TEMPLATE/problem-report.yml
SECURITY.md
SUPPORT.md
CONTRIBUTING.md
```

For each path: classify as **missing**, **present-and-current** (template-substituted output matches existing file content), or **present-and-outdated** (existing differs from substituted template).

### 3. AskUserQuestion: which files to scaffold (foreground only)

In foreground (interactive) mode, fire `AskUserQuestion` per ADR-013 Rule 1 with options scoped to the missing set:

- **Scaffold all missing** — write every absent template, skip present files.
- **Scaffold with review** — preview each substituted template before writing.
- **Dry-run** — preview only, no writes.
- **Cancel** — exit without action.

If `--force` is set AND outdated-present files exist, the prompt offers a fifth option for diff-and-replace per file. Architect direction (2026-04-26): keep the prompt one-shot when missing list is small; per-file prompts only when the user explicitly opts into review.

### 4. Substitute templates and write files

Templates live in `templates/` adjacent to this SKILL.md. Substitution is mustache-style — no runtime dependency:

| Token | Value source |
|---|---|
| `{{project_name}}` | Detected or `--project-name` flag. |
| `{{project_url}}` | Detected or `--project-url` flag. |
| `{{plugin_list}}` | Comma-separated installed `@windyroad/*` plugins. |
| `{{security_contact}}` | Detected from existing SECURITY.md (when only that file is present); else `--security-contact` flag; fallback `Use GitHub Security Advisories`. |
| `{{year}}` | `date +%Y` at scaffold time. |

`sed` substitution sketch (idempotent, no runtime tooling):

```bash
sed \
  -e "s|{{project_name}}|$PROJECT_NAME|g" \
  -e "s|{{project_url}}|$PROJECT_URL|g" \
  -e "s|{{plugin_list}}|$PLUGIN_LIST|g" \
  -e "s|{{security_contact}}|$SECURITY_CONTACT|g" \
  -e "s|{{year}}|$YEAR|g" \
  templates/SECURITY.md.tmpl > SECURITY.md
```

For each missing file: substitute, write to the target path, report the write + a short diff to stdout.

For each present-and-current file: report "already present — skipped" without modification.

For each present-and-outdated file: when `--force` is set, offer diff-and-replace; otherwise skip with a clear note that `--force` would update it.

### 5. Mark scaffold as done

After successful write:

```bash
mkdir -p .claude
: > .claude/.intake-scaffold-done
```

The marker suppresses Trigger-1 first-run prompts in subsequent `/wr-itil:manage-problem` and `/wr-itil:work-problems` invocations. ADR-009 marker semantics — persistent (no TTL), file-presence is the policy signal, deletable to reset.

### 6. Commit per ADR-014

```bash
git add .github/ISSUE_TEMPLATE/ SECURITY.md SUPPORT.md CONTRIBUTING.md .claude/.intake-scaffold-done
git -c commit.gpgsign=false commit -m "docs: scaffold OSS intake (ISSUE_TEMPLATE, SECURITY, SUPPORT, CONTRIBUTING)"
```

Follow the project's existing commit-gate flow: the commit triggers `wr-risk-scorer:pipeline` per ADR-014; remediation suggestions are applied per ADR-042 if residual exceeds appetite.

## Idempotency

The skill is idempotent by construction:

- Present files are skipped unless `--force`.
- Re-running the skill on a fully-scaffolded project produces no diff.
- The done marker prevents the host first-run prompt from re-firing.

## Rule 6 audit (per ADR-032)

Every `AskUserQuestion` branch this skill uses must enumerate its AFK fail-safe per ADR-013 Rule 6. The audit table below documents each branch:

| AskUserQuestion branch | Resolution |
|---|---|
| Step 3: "Which files to scaffold?" (foreground invocation) | Foreground-synchronous — user is in-session; `AskUserQuestion` fires normally. |
| Step 4: "Overwrite outdated present file with updated template?" (with `--force`) | Foreground-synchronous; same as Step 3. |
| First-run prompt fired from `/wr-itil:manage-problem` or `/wr-itil:work-problems` (foreground invocation) | Foreground-synchronous per the hosting skill's pattern. |
| First-run prompt fired from an AFK orchestrator iteration | **Fail-safe (Rule 6)**: do NOT fire `AskUserQuestion` and do NOT auto-scaffold. Append a single one-line "pending intake scaffold" note to the orchestrator's iteration report; defer the prompt to the user's next interactive session. JTBD-006 forbids the agent from making this judgement call. |

## Trigger surfaces (layered)

The skill is reachable via three trigger surfaces, layered so a soft prompt fires weeks before the hard publish stop. ADR-036 specifies the exact contract.

### Trigger 1: First-run prompt from manage-problem / work-problems

When `/wr-itil:manage-problem` or `/wr-itil:work-problems` fires in a foreground session, the host skill's preamble checks:

- Is `.github/ISSUE_TEMPLATE/` missing OR are any of the four other intake files absent?
- Is `.claude/.intake-scaffold-declined` absent?
- Is `.claude/.intake-scaffold-done` absent?

When all three checks pass, the host emits a one-shot `AskUserQuestion` prompt with three options — **Scaffold now**, **Not now (ask again next session)**, **Decline (never prompt in this project)**. On "Decline", write `.claude/.intake-scaffold-declined` and never re-prompt unless the user deletes the marker.

**AFK fail-safe**: when the host is invoked from an AFK orchestrator, do NOT fire the prompt. Append a one-line "pending intake scaffold" note to the iteration report and continue. The user catches up on next interactive session.

### Trigger 2: Pre-publish PreToolUse gate (hard stop)

`packages/itil/hooks/pre-publish-intake-gate.sh` matches `npm publish` and `gh pr merge ... changeset-release/*` and denies if any of the five intake files are missing AND the decline marker is absent AND `INTAKE_BYPASS` is not set.

**Override paths** (in priority order):
1. `INTAKE_BYPASS=1 npm publish` — short-circuits the gate before existence check (consistent with `RISK_BYPASS` naming).
2. `.claude/.intake-scaffold-declined` marker — explicit opt-out.
3. Run `/wr-itil:scaffold-intake` to remove the cause.

### Trigger 3: Optional CI check (deferred to v2)

`--ci` flag emits `.github/workflows/intake-check.yml` asserting the four files exist on every PR. Not shipped by default; layered ADD-on for adopters with GitHub Actions.

## Idempotent re-runs and template drift

When this repo's intake files evolve (e.g., a future P066-style reform), downstream adopters' previously-scaffolded files stay frozen. Re-running the skill at any time picks up the diff: the present-and-outdated branch reports each file's diff and, with `--force`, performs diff-and-replace. Template drift policy (when this should fire automatically) is out of scope for v1 — see ADR-036 Reassessment Criteria.

## Related

- [ADR-036](../../../../docs/decisions/036-scaffold-downstream-oss-intake.proposed.md) — design record (driver decision).
- [ADR-024](../../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) — sibling skill (`/wr-itil:report-upstream`); reciprocal pair.
- [ADR-032](../../../../docs/decisions/032-governance-skill-invocation-patterns.proposed.md) — foreground-synchronous pattern + Rule 6 audit requirement.
- [ADR-013](../../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — Rule 1 (interactive prompt) + Rule 6 (AFK fail-safe).
- [ADR-009](../../../../docs/decisions/009-gate-marker-lifecycle.proposed.md) — marker lifecycle (the `.intake-scaffold-{done,declined}` markers).
- [ADR-014](../../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md) — commit discipline.
- P065 — driver ticket.
- P066 — parent (template seed source); the corrected problem-first intake shape this skill propagates.
- JTBD-301 — primary persona; downstream-project intake coverage.
- JTBD-101 — clear patterns for adopters extending the suite.
- JTBD-006 — AFK fail-safe constraint.
