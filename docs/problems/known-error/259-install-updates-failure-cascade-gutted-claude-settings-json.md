# Problem 259: install-updates failure cascade gutted `.claude/settings.json` — uninstall succeeded but repeated installs failed, settings reduced to fallback-plugins-only

**Status**: Known Error
**Reported**: 2026-05-18
**Priority**: 6 (Medium) — Impact: 3 (Moderate — project temporarily lost all wr-* plugin enablement; subprocess dispatches would have failed if a fresh iter had launched; recovered via `git checkout HEAD -- .claude/settings.json`) x Likelihood: 2 (Unlikely — only fires when /install-updates loops through N plugins each with 3 failed install attempts)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; defensive snapshot-and-restore in /install-updates)
**Type**: technical

## Description

Surfaced 2026-05-18 during session 6's P0 incident response. The `/install-updates` script's `install_with_retry_rollback` function (per the SKILL.md Step 6 contract) attempted to uninstall + reinstall each of 11 plugins after the broken Phase 3 retroactive rollout (@windyroad/itil@0.35.1) shipped to npm. The uninstall side succeeded for every plugin, but the install side failed for every retry because the broken manifest was rejected by Claude Code's validator (`Validation errors: hooks: Invalid input, skills: Invalid input`).

Net effect: `.claude/settings.json` was reduced from 13 enabled plugins to 2 (only `discord@claude-plugins-official` + `fakechat@claude-plugins-official` survived — the non-windyroad plugins).

Recovery used `git checkout HEAD -- .claude/settings.json` to restore the pre-cascade state. The settings.json change isn't tracked by /install-updates contract — the script mutates settings via `claude plugin uninstall/install` commands which silently rewrite the file.

**Root cause**: `claude plugin uninstall <plugin>@<marketplace> --scope project` immediately removes the entry from `.claude/settings.json`'s `enabledPlugins` map. If the subsequent `install` call fails (broken manifest, network error, etc.), the settings.json is left WITHOUT the entry. The /install-updates retry-and-rollback shape (per ADR-030 P112 P133) was designed to handle install failures by attempting marketplace-refresh + one rollback install — but if the marketplace SOURCE itself is broken (broken manifest already published), the rollback also fails and the plugin is permanently gone from settings until manual restoration.

## Symptoms

- After /install-updates with a broken-manifest plugin in scope: `.claude/settings.json` `enabledPlugins` contains only fallback plugins (non-windyroad).
- Subsequent `claude plugin list` shows the windyroad plugins as not-installed at project scope.
- Subprocess dispatches (`claude -p`) launched after the cascade would NOT have access to wr-* plugins.

## Workaround

`git checkout HEAD -- .claude/settings.json` restores the pre-cascade state, then re-run /install-updates after the broken manifest is hotfixed.

## Impact Assessment

- **Who is affected**: Any project running /install-updates against a marketplace that has a broken-manifest release. Adopters who run /install-updates as part of their session-start auto-update flow would lose plugins silently.
- **Frequency**: Unlikely (2) — gated on broken-manifest releases; the P0 incident is the first known instance.
- **Severity**: Moderate — recovery requires git knowledge; non-git-savvy adopters would be stuck.
- **Analytics**: 1 instance this session.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Add a defensive snapshot-and-restore mechanism to /install-updates: capture `.claude/settings.json` before the uninstall+install loop, restore on FINAL install failure for any plugin (after all retries + rollback exhausted).
- [ ] Document the recovery path (`git checkout HEAD -- .claude/settings.json`) in `docs/briefing/plugin-distribution.md` "What Will Surprise You" section.
- [ ] Cross-reference P106 (claude plugin install silent-no-op) + P112 (install-updates rollback path) + P133 (zsh portability) — this is the next layer of failure modes in the same SKILL.

## Dependencies

- **Blocks**: (none — workaround keeps the project recoverable)
- **Blocked by**: (none — fix is /install-updates SKILL.md enhancement)
- **Composes with**: P258 (root cause of the broken-manifest class that triggers this cascade), P106 / P112 / P133 (sibling /install-updates surface tickets)

## Related

- `scripts/repo-local-skills/install-updates/SKILL.md` — surface to amend with snapshot-and-restore.
- ADR-030 — repo-local skills governance.
- P258 — driver: broken-manifest class that triggered the cascade.
- P106 — sibling install-updates silent-no-op friction.
- P112 — sibling install rollback path.
- P133 — sibling zsh portability.

(captured via /wr-retrospective:run-retro Step 4b Stage 1; expand at next investigation)
