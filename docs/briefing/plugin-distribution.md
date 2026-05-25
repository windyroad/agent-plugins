# Plugin Distribution and Environment

Cross-session learnings about the marketplace, npm package naming, Discord wiring, 1Password-backed env files, and the gap between "released" and "usable". Cache and install mechanics live in the sibling [`plugin-distribution-cache-mechanics.md`](./plugin-distribution-cache-mechanics.md) after the 2026-05-19 split-by-subtopic rotation (P145 Tier 3 MUST_SPLIT trigger).

## What You Need to Know

- **Skill invocation names are `{plugin-name}:{skill-dir-name}`**. The `name` field in SKILL.md is display-only. Directory names must not contain colons.
- **Discord plugin setup**: Use `/discord:configure <token>` to save the bot token (stored at `~/.claude/channels/discord/.env`). Restart with `--channels plugin:discord@claude-plugins-official` to connect. Pair via DM, then lock down with `/discord:access policy allowlist`.
- **Each repo should have its own Discord bot** for wr-connect. Name it after the org/repo so sessions are distinguishable in Discord. One shared bot = all sessions look identical.
- **`.env` may be a 1Password FIFO** (named pipe). Never `cat >` to it. Use `.env.tpl` with `op://` references and `op inject -i .env.tpl -o .env` instead.
- **1Password "Developer Environments"** (UI feature) are NOT accessible via `op` CLI (no `op env get`). To read a value into a script, fall back to a vault item or a project `.env` that already has it. Voder env vars include `NPM_AUTH_TOKEN` available in `bbstats/.env`.

## What Will Surprise You

- **The `skills` npm package installs to 45 AI tools** (Codex, Cursor, Cline, etc.), not just Claude Code. If cross-tool distribution is ever needed again, that is the mechanism.
- **Repo-local skills live in `.claude/skills/<name>/SKILL.md` and are invoked as `/<name>` (no plugin prefix)** per ADR-030. They are NOT distributed via the marketplace. First example: `/install-updates` (end-of-session plugin refresh across this project + sibling projects). Constraints: first action must be `AskUserQuestion` listing cross-project side effects before any write, no hooks, no CHANGELOG. See ADR-030 for the full contract and when a new repo-local skill is appropriate vs. a marketplace skill.
- **Windyroad npm package names drop the `wr-` prefix** that plugin names and marketplace cache keys use. Plugin name / marketplace cache key = `wr-itil`; npm package = `@windyroad/itil` (= source-directory name under `packages/`). `npm view @windyroad/wr-itil version` returns empty with exit 0 — silently — for ALL windyroad plugins if you guess the name wrong. Treat empty `npm view` output as "verify the package name" before concluding "the package is not public." (closed P092)
