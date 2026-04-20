# Contributing

Thanks for your interest in `@windyroad/agent-plugins`. This guide covers how to contribute code, decisions, and bug reports.

## Before you start

- **Problems**: open an issue first using the **Report a problem** template under `.github/ISSUE_TEMPLATE/`. You do not need to pre-classify it as a bug or a feature -- this project practises ITIL problem management, so triage decides the category. Drive-by PRs without an issue are harder to merge because the problem framing is missing.
- **Security vulnerabilities**: do not open a public issue. See [SECURITY.md](SECURITY.md).
- **Usage questions**: use [Discussions](https://github.com/windyroad/agent-plugins/discussions), not issues.

## Repo layout

This is an npm workspaces monorepo. Each plugin lives in its own package under `packages/`:

```
packages/
  agent-plugins/   # umbrella installer
  architect/       # @windyroad/architect
  c4/              # @windyroad/c4
  itil/            # @windyroad/itil
  ...
```

The `packages/*/` layout is set by [ADR-002](docs/decisions/002-monorepo-per-plugin-packages.proposed.md). New plugins go under `packages/<name>/`. Repo-local skills (not published) live under `.claude/skills/` per [ADR-030](docs/decisions/030-repo-local-skills-for-workflow-tooling.proposed.md).

## Local development

```bash
git clone https://github.com/windyroad/agent-plugins.git
cd agent-plugins
npm install
npm test
```

`npm test` runs the bats suite over hooks, skills, and shared utilities. The test runner is bats per [ADR-005](docs/decisions/005-plugin-testing-strategy.proposed.md). Add tests under `packages/<plugin>/hooks/test/`, `packages/<plugin>/skills/<skill>/test/`, or `packages/<plugin>/agents/test/` -- the glob in `package.json` picks them up automatically.

## Pull requests

1. **Branch off `main`**.
2. **Make your change** with tests where applicable.
3. **Add a changeset** for any change to a published package: `npx changeset`. Pick the affected packages and the bump type (patch / minor / major). Skip changesets for repo-internal changes (docs, CI tweaks, repo-local skills) -- the changeset bot will not flag them.
4. **Verify versions are in sync**: `npm run check:plugin-manifests`. The CI gate checks that each `packages/<name>/plugin.json` `version` matches the package's `package.json` version. See [ADR-021](docs/decisions/021-plugin-manifest-version-sync-mechanism.proposed.md).
5. **Open the PR**. CI runs `npm test`, plugin-manifest sync check, and install-utils drift check.
6. Maintainers review against the existing decisions in `docs/decisions/` and the persona jobs in `docs/jtbd/`.

### Commit style

- Follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, etc.).
- Reference problem tickets in the commit message when the work closes one (e.g. `fix(itil): ... (closes P058)`).
- Sign-off is not required.

## Architectural decisions

New patterns, conventions, or cross-package designs go through ADRs (Architecture Decision Records) under `docs/decisions/`. Use the skill:

```
/wr-architect:create-adr
```

The skill walks you through MADR 4.0 structure. The architect agent reviews edits against existing ADRs to catch conflicts -- see [ADR-013](docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) for the structured-interaction policy.

## Filing problems

Bugs and process friction get tracked as problem tickets under `docs/problems/`. From inside Claude Code:

```
/wr-itil:manage-problem
```

The skill follows ITIL problem management with WSJF prioritisation. Problem tickets transition through `.open.md` → `.known-error.md` → `.verifying.md` → `.closed.md` as the work progresses (see [ADR-022](docs/decisions/022-problem-lifecycle-verification-pending-status.proposed.md)).

## Governance skills

Most of the work in this repo is done through the suite's own governance skills. They commit their own work per [ADR-014](docs/decisions/014-governance-skills-commit-their-own-work.proposed.md) and run risk assessments before pushing. If you contribute to a governance skill (architect, jtbd, tdd, risk-scorer, etc.), the skill's own commit gate applies to your changes too.

## Code of conduct

Be kind. Engage in good faith. Critique ideas, not people. Maintainers reserve the right to lock or remove discussions, issues, or PRs that derail into personal attacks.

## License

By contributing, you agree your contributions are licensed under the project's MIT license (see the `license` field in `package.json`).
