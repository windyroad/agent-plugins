# Problem 004: Edit Gates Block Non-Project Files

**Status**: Open
**Reported**: 2026-04-14
**Priority**: 4 (Low) — Impact: Minor (2) x Likelihood: Likely (4) when using Discord plugin

## Description

The architect and JTBD enforce hooks block Write/Edit to files outside the project directory (e.g., `~/.claude/channels/discord/access.json`). These files are user configuration, not project files, and should not require architecture or JTBD review.

## Symptoms

- Writing to `~/.claude/channels/discord/access.json` triggers "BLOCKED: Cannot edit 'access.json' without architecture review"
- Writing to any file with a recognised extension (`.json`, `.md`) outside the project triggers gates
- Workaround: use `bash cat >` to bypass the hook system

## Workaround

Use bash (`cat >` or `echo >`) to write non-project files directly, bypassing the Claude Code tool hook system.

## Impact Assessment

- **Who is affected**: Users of wr-connect plugin during Discord setup
- **Frequency**: During initial setup and access policy changes
- **Severity**: Low — bash workaround is simple but unintuitive
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

The enforce hooks check the file extension but not whether the file is inside the project directory. They should only gate files within the project root (`$PWD` or the git repo root). Files in `~/.claude/` or other system locations should pass through.

### Investigation Tasks

- [ ] Confirm the hooks don't check project directory scope
- [ ] Add a project-root check to the enforce hooks (compare `FILE_PATH` prefix against `$PWD`)
- [ ] Check if this affects the architect, JTBD, voice-tone, style-guide, and risk-scorer hooks

## Related

- `packages/architect/hooks/architect-enforce-edit.sh`
- `packages/jtbd/hooks/jtbd-enforce-edit.sh`
- P001 — related gate friction issue
