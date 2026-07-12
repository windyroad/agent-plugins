# Problem 447: cruise hooks ship non-executable (git mode 644) — /bin/sh Permission denied on every PreToolUse, throttle silently inert

**Status**: Open
**Reported**: 2026-07-13
**Priority**: 25 (Critical) — Impact: 5 (Catastrophic — the plugin is entirely inert; the throttle does zero pacing on every install, defeating cruise's whole purpose, sibling to P446) × Likelihood: 5 (Certain — every published version 0.2.0–0.3.2, every PreToolUse firing; observed live 2026-07-12) — derived at capture per Step 4a
**Origin**: internal
**Effort**: S — chmod +x two files + git mode 755 + release; plus a small CI/behavioural mode guard to close the class.
**JTBD**: JTBD-010
**Persona**: developer

## Description

cruise's PreToolUse throttle hook (`quota-pace-throttle.sh`) and SessionStart producer hook (`quota-state-producer-install.sh`) ship non-executable (git mode `100644`, missing `+x`) in every published version 0.2.0–0.3.2. Claude Code invokes hooks directly as bare command paths (`${CLAUDE_PLUGIN_ROOT}/hooks/quota-pace-throttle.sh` — the same form every sibling plugin uses), so `/bin/sh -c` refuses them with `Permission denied` on EVERY PreToolUse firing.

Observed live 2026-07-12 in a real newsletter-authoring session: the throttle spams `PreToolUse:Agent hook error / Failed with non-blocking status code: .../wr-cruise/0.3.2/hooks/quota-pace-throttle.sh: Permission denied` and does no throttling at all. It fails OPEN (non-blocking) so the session is not broken, but the plugin is INERT — the exact "installed but silently doing nothing" failure cruise exists to prevent (sibling to P446).

Root cause: the two hooks were committed at mode 644 and never `chmod +x`'d; every other windyroad plugin ships hooks at 755, and cruise's own `bin/`+`scripts/` executables are 755 — the hooks are the sole outlier. Because Claude Code exec's the command path directly (rather than `sh <path>`), the missing execute bit is fatal, not cosmetic.

**Immediate fix**: `chmod +x packages/cruise/hooks/*.sh` → git mode 755 → release.

**Durable class fix** (recurring shipped-artifact class, sibling to the repo-relative-path class P151/P153/P219/P317): add a CI/behavioural guard asserting every tracked `packages/*/hooks/*.sh` (and `bin/`+`scripts/` executables) is mode 755, so a 644 hook can never ship again. Source-repo dogfooding did not catch it because the maintainer's own session ran an earlier working state; the published tarball is where the inert copy lands.

## Symptoms

- `PreToolUse:Agent hook error / Failed with non-blocking status code: .../wr-cruise/<ver>/hooks/quota-pace-throttle.sh: Permission denied` on every tool call.
- No `~/.claude/quota-state` throttle grip; sleeps never injected; usage sails past the pace line.

## Workaround

None user-facing (the hook fails open, so no manual unblock is needed — but no pacing occurs). A local `chmod +x` on the installed cache copy restores it until the next reinstall overwrites it.

## Impact Assessment

- **Who is affected**: every user of the throttle on every install (0.2.0–0.3.2).
- **Frequency**: every PreToolUse firing.
- **Severity**: Catastrophic — the entire value proposition (pace burn, never hard-stop) does not run.
- **Analytics**: n/a.

## Root Cause Analysis

### Investigation Tasks

- [x] Confirm git mode of both hooks (`git ls-files -s` → 100644)
- [x] Confirm sibling plugins ship hooks 755 (itil → 100755)
- [ ] chmod +x both hooks; verify installed tarball copy is 755
- [ ] Add mode guard (CI/behavioural) over `packages/*/hooks/*.sh` + executables
- [ ] Release the fix + verify the throttle fires on a fresh install

## Dependencies

- **Blocks**: (none — the plugin still installs; it is inert)
- **Blocked by**: (none)
- **Composes with**: P446 (throttle-inert class — glide too weak); this is a distinct, more basic inertness (hook never runs at all)

## Related

- **P446** — sibling throttle-inert class (glide too weak); this ticket is the more basic "hook never executes" inertness.
- **P151 / P153 / P219 / P317** — the recurring shipped-artifact class (repo-relative paths); the mode-644 defect is the same class shape (source-repo dogfooding masks a defect that only manifests in the published/installed copy).
- **JTBD-010** — sustain quota / never inert.
- **RFC-046 / STORY-042** — the shipping RFC + extraction story for `@windyroad/cruise`.
- Captured via /wr-itil:capture-problem.
