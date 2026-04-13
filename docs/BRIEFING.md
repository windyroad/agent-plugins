# Project Briefing

## What You Need to Know

- **Plugin hooks run from the marketplace cache**, not from source. After fixing hook code, you must: push, update marketplace (`claude plugin marketplace update windyroad`), reinstall (`claude plugin install ... --scope project`), and restart Claude Code.
- **Skill invocation names are `{plugin-name}:{skill-dir-name}`**. The `name` field in SKILL.md is display-only. Directory names must not contain colons.
- **Three edit gates fire on every edit**: architect review, WIP risk assessment, and TDD enforcement. Each requires its own agent delegation before the edit is allowed. Plan for this overhead.
- **GITHUB_TOKEN pushes don't trigger pull_request events**. The release preview uses `workflow_run` trigger instead. If adding new PR-triggered workflows for changesets PRs, use the same pattern.
- **npm won't overwrite a published version**. Preview publishes use pre-release suffixes (e.g., `0.1.2-preview.13`) to avoid blocking `changeset publish` from publishing the clean version to `latest`.
- **Risk appetite is Low (4)**. Changes scoring Medium (5+) need explicit acknowledgement. See `RISK-POLICY.md`.
- **The `push:watch` script** in root `package.json` is the sanctioned way to push — it runs `git push` then watches the CI run. The git-push-gate hook blocks bare `git push`.
- **Install at project scope** (`--scope project`) to avoid breaking other active projects. ADR-004 documents this.

## What Will Surprise You

- **anthropics/claude-code#35641 is fixed** — marketplace skills show in autocomplete. The `skills` npm package workaround is no longer needed (ADR-003).
- **Each edit consumes the architect/WIP marker** — you need a fresh agent review for every blocked edit, not just one per session. If you have multiple edits, expect multiple review cycles.
- **The risk-scorer PostToolUse hook uses regex dot** (`.`) not literal characters to match agent names. This was a deliberate fix — don't "correct" it back to dashes.
- **The `skills` npm package installs to 45 AI tools** (Codex, Cursor, Cline, etc.), not just Claude Code. If cross-tool distribution is ever needed again, that's the mechanism.
