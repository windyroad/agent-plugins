# Problem 006: Setup Skill Leaked Secrets by Reading 1Password FIFO

**Status**: Open
**Reported**: 2026-04-14
**Priority**: 10 (High) — Impact: Severe (5) x Likelihood: Unlikely (2)

## Description

During the wr-connect setup, the agent ran `cat .env` to check the file format. The `.env` was a 1Password FIFO (named pipe) that served all resolved secrets from the 1Password vault — including API keys, tokens, and passwords for multiple services (OpenAI, GitHub, npm, MongoDB, Clerk, Cloudflare, Namecheap). All secrets were dumped into the conversation context.

## Symptoms

- `cat .env` on a FIFO reads the full secret payload into the conversation
- All secrets from the 1Password environment were exposed in the Claude Code session
- Credentials need rotation after exposure

## Workaround

Never `cat`, `head`, `tail`, or `Read` a `.env` file without first checking if it's a FIFO (`[ -p .env ]`). If it is a FIFO, do not read it.

## Impact Assessment

- **Who is affected**: Anyone using 1Password's environment injection with the FIFO approach
- **Frequency**: Rare — only happens if the agent reads the .env file
- **Severity**: Severe — full credential dump into conversation context
- **Analytics**: N/A

## Root Cause Analysis

### Confirmed Root Cause

The agent ran `cat .env` without checking the file type. The `.env` was a named pipe (FIFO) created by 1Password's desktop app "Environments" feature. Reading a FIFO consumes its content and serves all resolved secrets, not template references.

### Fix Strategy

1. Add a safety check to the setup skill: `[ -p .env ] && echo "WARNING: .env is a 1Password FIFO — do not read it"` before any file operations on `.env`
2. Consider adding a general rule to CLAUDE.md: "Never read `.env` files without checking `[ -p .env ]` first"
3. The `.env.tpl` approach (committed template with `op://` refs, `op inject` to produce `.env`) avoids the FIFO entirely

### Investigation Tasks

- [x] Confirm root cause — agent read FIFO without checking type
- [ ] Add FIFO detection to the setup skill
- [ ] Add FIFO warning to CLAUDE.md or BRIEFING.md
- [ ] Consider adding FIFO detection to the secret-leak-gate hook

## Related

- `packages/connect/skills/setup/SKILL.md` — setup skill that triggered the read
- `packages/risk-scorer/hooks/secret-leak-gate.sh` — could be extended to detect FIFO reads
- P005 — related setup flow issues
