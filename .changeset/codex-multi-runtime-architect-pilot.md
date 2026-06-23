---
"@windyroad/architect": minor
---

Codex CLI multi-runtime pilot — `@windyroad/architect` is now installable into OpenAI Codex CLI alongside Claude Code.

- New `--runtime claude|codex|both` flag on `npx @windyroad/architect` (defaults to `claude`; existing installs are unaffected).
- New `.codex-plugin/plugin.json` ships in the package; Codex auto-discovers the architect agent from `agents/agent.md` and exposes it as `wr-architect:agent`.
- `agents/agent.md` remains the single source of truth for agent prose across both runtimes; no agent content is duplicated.

Verified end-to-end with `codex-cli` 0.137.0 against a fresh adopter directory: `codex plugin marketplace add` + `codex plugin add wr-architect@<marketplace>` + `codex exec` spawning `wr-architect:agent` returned a canonical architect verdict (PASS / ISSUES FOUND / NEEDS DIRECTION).

Substance captured under ADR-083 (Codex CLI as second runtime), `human-oversight: unconfirmed` pending canonical review via `/wr-architect:create-adr 083`. Other `@windyroad/*` plugins remain Claude-only; their `lib/install-utils.mjs` carries the new shared API via sync but their `bin/install.mjs` does not yet expose `--runtime` — fan-out to follow per-iter once the architect pilot proves out.
