# Problem 369: Plugin removes hook file but adopter session still invokes it via stale binding — `architect-compendium-refresh-discipline.sh` case 2026-06-17

**Status**: Open
**Reported**: 2026-06-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next `/wr-itil:review-problems`)
**Origin**: internal
**Effort**: M (deferred — re-rate at next `/wr-itil:review-problems`)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

Surfaced 2026-06-17 by direct user observation: *"you've got bad paths again. I thought we put controls in place to prevent this!!!"* — accompanied by a screenshot of an adopter project hitting a `PreToolUse:Bash hook error` with the message:

```
Failed with non-blocking status code: /bin/sh: /Users/tomhoward/.claude/plugins/marketplaces/windyroad/packages/architect/hooks/architect-compendium-refresh-discipline.sh: No such file or directory
```

**Diagnostic findings (this session):**

1. The hook file `architect-compendium-refresh-discipline.sh` was retired per ADR-078 (Option 9) — the compendium is now updated incrementally by `architect-compendium-update-entry.sh` (PostToolUse hook) on every ADR edit. The retirement landed in `@windyroad/architect@0.17.x`.
2. **Latest source-repo state is clean**: `packages/architect/hooks/` no longer contains the retired hook file; `packages/architect/hooks/hooks.json` no longer registers it.
3. **Latest marketplace state is clean**: `~/.claude/plugins/marketplaces/windyroad/packages/architect/hooks/` no longer contains the retired hook file; its `hooks.json` no longer registers it.
4. **Stale cache still contains the retired hook**: `~/.claude/plugins/cache/windyroad/wr-architect/0.15.6/hooks/architect-compendium-refresh-discipline.sh` still exists; its `hooks.json` still registers it.
5. The adopter project has `wr-architect@windyroad` enabled. Its `.claude/settings.json` does NOT directly reference the retired hook — the registration came from the plugin's bundled `hooks.json` at session-start time. Either:
   - The adopter session was launched against an OLDER cached plugin version (0.15.6 or similar) whose `hooks.json` still registers the retired hook, AND the harness retains that registration even though the marketplace HEAD has cleaned it up (session-time binding ≠ live binding); OR
   - The harness reads the registration from a cached snapshot that is more stale than the on-disk `hooks/<file>` content (registration-vs-file version skew).

**Recurring class — recorded in session memory `feedback_no_repo_relative_paths_in_published_artifacts.md`**: shipped artifacts referencing repo-relative `packages/...` paths in adopter installs is a recurring failure. Sibling tickets P151 / P153 / P219 / P317 all verifying or closed. THIS case is a NEW failure mode in the same family: **deletion-without-deregistration** (hook removed from file system AND from latest `hooks.json`, but adopter sessions still invoke it via stale binding).

**User's "controls in place" reference**: ADR-049 PATH shims + `packages/retrospective/scripts/check-tarball-shipped-shims.sh` (the shipped-shim discipline checker) — both guard against repo-relative paths INSIDE shipped scripts, but neither guards against **stale registrations referencing files that no longer exist**. The control surface gap is the lifecycle hygiene of plugin-bundled `hooks.json` updates propagating to live sessions / cached versions.

## Symptoms

- `PreToolUse:Bash` (and possibly other tool hooks the retired hook was registered against) prints `Failed with non-blocking status code: ... No such file or directory` every time the matching tool fires.
- The error is non-blocking so adopter work continues, but every Bash invocation surfaces noise — visible in the user's screenshot from the adopter session.
- Adopter trust in the plugin's stability (JTBD-302) is undermined — *"what other surfaces are broken silently?"*.

## Workaround

Adopter-side: restart the Claude Code session in the affected project (forces re-binding to current marketplace HEAD). Maintainer-side: run `/install-updates` per session memory `feedback_verify_cache_refresh_by_version_dir.md` to force-refresh the global plugin cache, then restart sessions in adopter projects.

## Impact Assessment

- **Who is affected**: every adopter project with `wr-architect@windyroad` enabled whose session-start bound against a plugin version that registered the retired hook (any session that resumed across the 0.17.x retirement boundary without a full session restart).
- **Frequency**: every PreToolUse:Bash event in an affected session. High-frequency surface — Bash is the most-used tool.
- **Severity**: LOW per-event (non-blocking), but HIGH on adopter-trust metric (JTBD-302 outcome: "I want to be confident the prose describes the version I just installed... and trust the documented contract without cross-checking against source") — recurring "bad paths" failure mode the user has flagged before AND has nominally-in-place controls for.
- **Analytics**: 1 user-reported observation today (the screenshot); class history covers P151/P153/P219/P317. Pattern is recurring.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next `/wr-itil:review-problems`
- [ ] Determine exact stale-binding mechanism: is the adopter session reading `hooks.json` from cache, from marketplace, or from a snapshot taken at session-start? (Read Claude Code's plugin-loading source / docs.)
- [ ] Investigate whether the marketplace-vs-cache plugin distribution model has an inherent version-skew window where one surface (file system) is updated faster than the other (settings registration).
- [ ] Identify the existing controls the user references ("I thought we put controls in place to prevent this!!!"): likely ADR-049 PATH shims + `check-tarball-shipped-shims.sh`. Document the gap: those controls guard against repo-relative paths INSIDE scripts, NOT against stale registrations referencing files-that-no-longer-exist.
- [ ] Design a control that closes the gap. Candidates: (a) plugin-side test asserting that every entry in `hooks.json` has a corresponding file on disk in the same tarball / marketplace snapshot; (b) harness-side check at session-start that warns when a registered hook file is missing; (c) plugin-side deprecation-cycle for hook removal (1 minor cycle with hook re-pointing to a no-op shim before file deletion); (d) `/install-updates` invariant: force-restart adopter sessions after major hook surface changes.
- [ ] Create reproduction test: scaffolded adopter project + plugin version downgrade-then-upgrade sequence reproducing the stale-binding observation.
- [ ] Decide whether this is an RFC-class scope (a real shipment-hygiene mechanism per ADR-082 territory) or a tightly-scoped prose-correction (deprecation-cycle discipline in maintainer SKILL/CONTRIBUTING docs).
- [ ] Cross-check with P368 (sibling captured 2026-06-16): `wr-architect-mark-oversight-confirmed` cannot discover session-id under cold-path conditions on macOS — the same shim's bash-tool sees `/tmp` differently than the hook does. The plugin-distribution-hygiene class spans multiple surfaces (path resolution, registration lifecycle, session binding) — may warrant an umbrella problem ticket if more sibling observations accumulate.

## Fix Strategy

(Step 4b Stage 2 — proposed fix strategy recorded at capture time; not yet ratified by user.)

**Option 3 — Other codification shape.**

**Shape**: CI step + test fixture (the existing controls layer per ADR-049 + `check-tarball-shipped-shims.sh`).

**Suggested name / locus**: a sibling discipline check next to `packages/retrospective/scripts/check-tarball-shipped-shims.sh` — e.g. `check-tarball-hooks-resolve.sh`.

**Mechanism candidates** (direction-setting; user picks at re-rate / RFC):

- (a) **Pre-publish CI check**: every `hooks/hooks.json` registration entry must resolve to a file present in the published tarball / marketplace snapshot. Run as a CI step on the release PR.
- (b) **PostPublish drift detector**: at session start, when a plugin's cache version updates, scan its `hooks.json` for entries referencing files-that-no-longer-exist relative to the new version's tree. Warn the user via the SessionStart hook surface.
- (c) **Deprecation-cycle discipline ADR**: when removing a hook, deprecate it to a no-op shim for one minor-version cycle BEFORE deleting the file — buffers adopter sessions across the transition. Codify as an ADR or as a maintainer's CONTRIBUTING note.
- (d) **`/install-updates` invariant**: post-install, force a session restart whenever a plugin's hook surface changes significantly (additions / removals / renames). Heavyweight but closes the live-session gap.

The cleanest first cut is (a) + (c): a CI check that asserts the invariant + a documented deprecation-cycle discipline. (b) and (d) are richer but add cross-session machinery that requires its own design pass.

**Triggers**: any commit that modifies `packages/<plugin>/hooks/hooks.json` or removes a file under `packages/<plugin>/hooks/`.

**Evidence (this session)**: 1 user-reported observation (2026-06-17 screenshot from an adopter project showing the orphan-hook PreToolUse:Bash error). Class history covers P151 / P153 / P219 / P317.

**Routing target**: when ratified, capture an RFC (per ADR-060) since the mechanism involves a cross-cutting check + a deprecation-cycle convention — multi-phase scope likely warrants RFC framing rather than direct skill/hook ship.

## Dependencies

- **Blocks**: adopter trust in plugin stability across `wr-architect` retirements. Until the gap closes, every hook surface refactor risks repeating this failure mode.
- **Blocked by**: (none)
- **Composes with**: P151 / P153 / P219 / P317 — same recurring class (repo-relative paths in shipped artifacts), different failure modes (this is the deletion-without-deregistration variant; the others are reference-to-source-monorepo-path variants).

## Related

(captured via `/wr-itil:capture-problem` 2026-06-17; hang-off-check dispatch was SKIPPED per SKILL candidate-cap short-circuit — 8 candidates > 5; recorded for review-time re-evaluation by `/wr-itil:review-problems`)

Pre-filter signal-sharing candidates (≥1 shared signal: architect-compendium-refresh-discipline, hook-stale-registration, plugin-deregister patterns):

- **P161** (`docs/problems/open/161-advisory-then-escalate-may-be-over-applied-for-drift-class-detectors-generally.md`) — drift-class detection generality
- **P288** (`docs/problems/open/288-new-jtbds-and-personas-need-human-oversight-confirmation-sibling-of-p283.md`) — sibling JTBD-oversight class (unrelated mechanism)
- **P098** (`docs/problems/verifying/098-project-and-user-owned-context-contributors-global-claude-md-and-local-skills.md`) — context-contributor lifecycle
- **P105** (`docs/problems/verifying/105-run-retro-needs-signal-vs-noise-pass-on-briefing-entries.md`) — different mechanism
- **P141** (`docs/problems/verifying/141-afk-iter-changeset-discipline-enforcement-hook.md`) — hook discipline class
- **P327** (`docs/problems/verifying/327-adr-bodies-dominate-session-token-usage.md`) — ADR body management
- **P337** (`docs/problems/verifying/337-decisions-compendium-omits-decision-outcome-for-57pct-of-adrs-only-extracts-chosen-tag-not-decision-section-body.md`) — sibling: compendium-update-entry hook (the REPLACEMENT for the retired hook this ticket names) and its known regressions
- **P366** (`docs/problems/verifying/366-architect-hooks-inline-git-commit-detection-instead-of-shared-command-detect-helper-bsd-awk-portability.md`) — architect-hooks portability class

Sibling class (recurring "bad paths in shipped artifacts" class — primary cross-references):

- **P151** (verifying) — published-skills-reference-repo-relative-script-paths
- **P153** (verifying) — published-skills-enumerate-repo-relative-directories
- **P219** (verifying) — manage-problem-skill-md-uses-repo-relative-script-path-that-fails-for-plugin-installed-users
- **P317** (closed) — capture-skills-create-gate-marker-sources-repo-relative-lib-paths-fail-in-adopter-installs
- **P368** (known-error) — wr-architect-mark-oversight-confirmed cannot discover session-id when CLAUDE_SESSION_ID empty and no announce markers (captured 2026-06-16; sibling-class on path-resolution-in-shipped-artifacts)

ADR / control references:

- **ADR-049** — `bin/` PATH shim grammar; the control intended to prevent repo-relative paths in shipped scripts.
- **ADR-078** (Option 9) — the architectural decision that retired the `architect-compendium-refresh-discipline.sh` hook in favour of the PostToolUse update-entry hook.
- **`packages/retrospective/scripts/check-tarball-shipped-shims.sh`** — the test guard that asserts shipped artifacts use shims, not repo-relative paths. Does NOT cover the stale-registration-after-removal failure mode.
- **`packages/architect/hooks/hooks.json`** — the registration file whose latest state is clean (no longer registers the retired hook) but whose stale-cached predecessors still register it.

Memory references:

- `feedback_no_repo_relative_paths_in_published_artifacts.md` — recurring-class memory note; this ticket is a new failure mode (deletion-without-deregistration) in the same family.
- `feedback_verify_cache_refresh_by_version_dir.md` — workaround mechanism (cache refresh + session restart).
- `feedback_automatic_cadence_or_it_doesnt_happen.md` — applies: a control without automatic enforcement is a control that doesn't happen.
