# Plugin Environment Setup

Discord and 1Password environment details split from [`plugin-distribution.md`](./plugin-distribution.md) during the 2026-08-29 Tier 3 budget rotation.

## What You Need to Know

- **Discord plugin setup**: Use `/discord:configure <token>` to save the bot token (stored at `~/.claude/channels/discord/.env`). Restart with `--channels plugin:discord@claude-plugins-official` to connect. Pair via DM, then lock down with `/discord:access policy allowlist`. <!-- signal-score: -4 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->
- **Each repo should have its own Discord bot** for wr-connect. Name it after the org/repo so sessions are distinguishable in Discord. One shared bot means all sessions look identical. <!-- signal-score: -4 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->
- **`.env` may be a 1Password FIFO** (named pipe). Never overwrite it directly. Use `.env.tpl` with `op://` references and `op inject -i .env.tpl -o .env` instead. <!-- signal-score: -4 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->
- **1Password Developer Environments** are not accessible through the `op` CLI (`op env get` does not exist). To read a value into a script, use a vault item or an existing project `.env`. <!-- signal-score: -4 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->
