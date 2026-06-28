# Problem 394: Release publishes a new version of every package, not just the ones that changed

**Status**: Known Error
**Reported**: 2026-06-28
**Root cause identified**: 2026-06-28 (hypothesis REFUTED; real mechanism = P359 held-changeset batch-drain — see Root Cause Analysis)
**Going-forward decision**: remedy contract (accept-as-correct vs reduce-batch-cadence) deferred to user ratification — see Remedy option-ladder
**Priority**: 4 (Low) — Impact: 2 x Likelihood: 2 (re-rated this iter: no functional defect — bumps are correct; cosmetic/legibility only)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-002
**Persona**: plugin-developer

## Description

When we cut a release, it appears that a new version of **every** `@windyroad/*` package gets published — not just the packages whose source actually changed in the release. The expectation is that changesets only bumps + publishes the packages named in the `.changeset/*.md` entries (and the genuinely-affected dependents); instead the version PR seems to bump the whole suite, flooding the adopter-facing version stream with no-op bumps and obscuring which package actually changed.

## Symptoms

- A release whose changesets name a single package (e.g. `@windyroad/itil` patch) ships a version PR / npm publish that bumps multiple — possibly all 13 — `@windyroad/*` packages.
- Adopters tracking specific packages see version churn with no corresponding source change.
- (To confirm at investigation: capture one release's version-PR diff and count which `package.json` versions bumped vs which packages had source changes in the same release window.)

## Workaround

**The behaviour is correct — there is no over-publish to work around.** Each bumped package maps 1:1 to a changeset that names a genuinely-changed package, and `changeset publish` only publishes packages whose `package.json` version exceeds npm (the unbumped packages are skipped). To see *why* a given package bumped in a multi-package release, read its `CHANGELOG.md` entry or the drained `.changeset/*.md` frontmatter — the apparent "everything bumped" is the **P359 held-changeset backlog draining in one batch** (e.g. commit `24e46d19` graduated 16 held changesets at once). If release legibility matters, graduate held changesets in smaller cohorts / release more frequently (a P359 / ADR-082 cadence knob, not a `.changeset/config.json` knob).

## Impact Assessment

- **Who is affected**: plugin-developer (release hygiene) + adopters consuming `@windyroad/*` (noise in the update stream); JTBD-002 ship-with-confidence + JTBD-007 keep-plugins-current.
- **Frequency**: every release that carries internal-dependency-graph propagation (deferred — confirm).
- **Severity**: no functional break — packages still publish working versions — but version-stream noise + audit-trail dilution (can't tell what changed from the version bumps alone).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Leading hypothesis REFUTED (investigated 2026-06-28).** The capture hypothesis blamed `updateInternalDependencies: "patch"` propagating a patch bump across the internal-dependency closure. Empirical mapping disproves it:

- **Zero internal `@windyroad/*` dependencies exist.** `grep -rn "@windyroad/" packages/*/package.json` matches only the packages' own `"name"` fields — no `dependencies`, `peerDependencies`, or `devDependencies` references any sibling. With no internal edges, `updateInternalDependencies` is **inert** (it only governs how a dependent's pin is rewritten when a dep it lists bumps; there are no dependents to rewrite). `fixed: []` and `linked: []` confirm no lockstep grouping either.
- **Only 12 published packages, not 13.** `packages/shared/` is a source dir (synced hook libs / install-utils) with **no `package.json`** — it is never versioned or published. The "13" counts directories, not npm packages.

**Confirmed mechanism (empirical, from the actual version commits).** Changesets is behaving *correctly* — it bumps exactly the packages named in the drained `.changeset/*.md` entries, with no fan-out. Evidence from the most recent `chore: version packages` commit `32c1f0e8`:

| Drained changeset | Named package(s) |
|---|---|
| `migrate-briefing-skill-p204` | retrospective |
| `p082-commit-message-surface` | voice-tone, risk-scorer |
| `p205-wrap-as-skill-risk-scorer-trio` | risk-scorer |
| `p214-step-5-is-error-transient-halt` | itil |
| `p313-pre-edit-review-mode-carve-out` | architect, jtbd |
| `p351-auto-bootstrap-fail-soft-skip` | itil |

Union of named packages = {retrospective, voice-tone, risk-scorer, itil, architect, jtbd} = **exactly the 6 packages that bumped** in `32c1f0e8`. The other 6 (agent-plugins, c4, connect, style-guide, tdd, wardley) did **not** bump and would **not** publish. Earlier version commits bumped 2 / 1 / 3 / 1 packages (`e034a63f` / `b8d69291` / `7c7f4777` / `c16bff4a`) — never the whole suite. There is **no over-publish**: `changeset publish` only publishes packages whose `package.json` version exceeds npm.

**Why it *looks* like "every package bumps".** The driver is the **P359 held-changeset graduation pattern** (ADR-082): changesets are held (`git mv` to `docs/changesets-holding/`) while their code ships, then graduate in batches at a later release — e.g. commit `24e46d19` graduated **16 held changesets at once**. When a large held backlog drains in a single release, the union of named packages across those changesets is large, so most/all of the 12 packages legitimately bump in one version commit — each for a real source change recorded in its CHANGELOG. The symptom is therefore a **legibility artefact of batch graduation**, not a versioning defect.

**Net:** P394 is a downstream perception-side symptom of **P359** (held-changeset batch graduation), not an independent changeset-config bug. The original config-tuning remedies (`updateInternalDependencies: minor`, removing the setting) would change nothing because the setting is inert.

### Remedy option-ladder (genuine ≥2-option direction decision — QUEUED, not picked)

Because the bumps are *correct* (no defect to fix), the decision is whether the batch-graduation legibility cost is worth a cadence change. This touches release behaviour → `category:direction`; left to user ratification per ADR-074.

- **Option A — Accept as correct, no change (recommended / ponytail-YAGNI).** Every bump maps 1:1 to a real change; no over-publish exists. The "everything bumped" appearance is accurate (those packages really changed) — just batched. Cost: zero. Trade-off: adopters tracking one package still see it bump inside a large multi-package release, but its CHANGELOG explains why. Optional sub-step: nothing, or a one-line release-note convention summarising "N packages, each: <reason>".
- **Option B — Reduce graduation batch size / release more frequently.** Drain held changesets in smaller cohorts (or release per-iteration) so each version commit names few packages → legible 1:1 release-to-change story. Trade-off: more version commits + npm publish events; this is a **P359 / ADR-082 holding-cadence knob**, not a `.changeset/config.json` knob — so the decision likely folds into P359.
- **Option C — `updateInternalDependencies: minor` / remove the setting. REJECTED.** Addresses the refuted hypothesis; the setting is inert (no internal deps), so changing it does nothing. Recorded so it is not re-proposed.
- **Option D — Bundle into one package / per-package release pipelines. REJECTED.** Over-engineering; changesets already does correct independent versioning.

### Investigation Tasks

- [x] Re-rate Priority and Effort (done this iter: Low — cosmetic, no functional defect)
- [x] Confirm the symptom from a real release's version commit (bumped vs source-changed packages) — `32c1f0e8`: 6 bumped = 6 changeset-named; no fan-out
- [x] Map the `@windyroad/*` internal dependency graph + propagation closure — **zero internal deps**; hypothesis refuted
- [ ] **(QUEUED — user direction)** Decide remedy contract: Option A accept-as-correct vs Option B reduce-batch-cadence (folds into P359)
- [ ] Reproduction test — N/A (no defect to reproduce); covered by the empirical `32c1f0e8` evidence above

## Dependencies

- **Blocks**: (none)
- **Blocked by**: **P359** (held-changeset batch graduation) — confirmed upstream cause; Option B remedy folds into P359/ADR-082 cadence
- **Composes with**: P042 (changeset/manifest version sync), P304 (packages/shared duplicate-and-sync → bundler — note `shared` is unpublished, so it is NOT a versioning hub)

## Related

- `.changeset/config.json` — `updateInternalDependencies: "patch"`, `fixed: []`, `linked: []` (the configuration governing cross-package bump propagation).
- **P304** (`docs/problems/open/304-...`) — `packages/shared` duplicate-and-sync vs bundler approach; the shared-package shape is plausibly the propagation hub.
- **P042** / **P359** — sibling release-mechanics tickets (manifest-version sync; held-code-ships-with-sibling).
- (captured via /wr-itil:capture-problem; expand at next investigation)
