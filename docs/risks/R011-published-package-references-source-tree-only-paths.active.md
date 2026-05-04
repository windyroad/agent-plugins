---
risk_id: R011
slug: published-package-references-source-tree-only-paths
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [packages/*/skills/*/SKILL.md, packages/*/skills/*/REFERENCE.md, packages/*/agents/*.md, packages/*/hooks/*.sh, packages/*/README.md, packages/*/package.json (files array)]
cascade_scope: every adopter session that runs an affected skill / reads an affected SKILL.md / has an agent invoked that reads an affected agent prompt; spans every published `@windyroad/*` plugin currently shipping
afk_class: both — interactive surfaces broken-link UX cost; AFK orchestrators hit hard-fail at Step 0 of any skill that bash-invokes a missing path
reversal_class: npm-permanent-with-republish-cycle (broken references in published versions remain on npm registry indefinitely; repaired versions ship via patch/minor bump; adopters' cached versions until reinstall)
control_budget_class: free-detector (npm-pack walk + source-tree grep) + per-edit-llm at architect/JTBD review of new SKILL/agent prose
dogfood_days: ADR-049 ~14 days, ADR-055 + P137 detector ~7 days, P154 npm-pack-extension ~3 days
authority_class: framework-resolved (detector classifications mechanical); deviation-approval (Permitted Exception requires citation)
prompt_cache_window: ongoing
ci_a: integrity (published prose advertises behaviour adopters can't actually trace); availability (hard-fail at Step 0 of skills that bash-invoke missing paths)
agentic_category: drift (publish-manifest vs source-tree), cascade (one missing path affects every dependent skill)
---

# Risk R011: Published packages reference source-tree-only paths and IDs

## Description

`@windyroad/*` plugins are authored in a monorepo where SKILL.md / agent.md / hook prose can freely reference repo-only artefacts: `docs/decisions/NNN-...md` (ADRs that live at the repo root, not in the per-plugin tarball), `docs/problems/PNNN`, `docs/jtbd/<persona>/JTBD-NNN-...md`, `RISK-POLICY.md`, sibling `packages/<other-plugin>/scripts/foo.sh`, etc. When the plugin is published to npm, only `packages/<this-plugin>/` ships in the tarball. Adopters install the plugin into their own project; the tarball is extracted into their `~/.claude/plugins/cache/<org>/<plugin>/<version>/` tree, which contains ONLY the plugin's own files.

Two distinct failure modes:

1. **Internal-ID leakage** (P137): published prose cites `ADR-049` or `JTBD-001` or `P137` as if they're universally meaningful. In an adopter's project, those IDs either don't resolve at all (best case — agent ignores) or resolve to UNRELATED decisions/jobs in the adopter's own `docs/decisions/` (worst case — agent applies wrong semantics in the adopter's context).

2. **Repo-relative path leakage** (P151): published bash commands like `bash packages/itil/scripts/reconcile-readme.sh` resolve correctly in the source repo but hard-fail at adopter installs because `packages/itil/scripts/` doesn't exist in the adopter's tree. ADR-049 mitigates via `$PATH` `bin/` shims (e.g. `wr-itil-reconcile-readme`) — but ONLY for paths the author chose to wrap.

3. **Publish-manifest drift** (P154): `package.json` `files` array determines what ships in the tarball. A `bin/` shim that exists in the source tree but isn't listed in `files` ships broken — adopter installs the plugin, the shim is missing from the tarball, every skill that invokes the shim hard-fails. Source-tree-walking detectors miss this because the source tree HAS the shim; only npm-pack output reveals the gap.

**Source → event → consequence chain**: source = SKILL/agent/hook prose adds a reference to a repo-only path or ID without applying ADR-049 ($PATH shim) / ADR-055 (namespace-prefix permalink) / explicit `files` array entry; event = plugin publishes; adopter installs and invokes the affected skill/agent; consequence = hard-fail at Step 0 (path case) OR degraded-semantics misleading the adopter agent (ID case) OR confused-context applying wrong-decision rules (mis-resolved ID case).

## Inherent Risk

- **Impact**: 4/5 (Significant) — adopter workflows break (hard-fail) or adopter agents apply wrong semantics (degraded). P151 surfaced as "hard runtime failure ... skill cannot proceed past Step 0"; P137 surfaced as "may resolve to UNRELATED decisions ... agent applies wrong semantics".
- **Likelihood**: 5/5 (Almost certain) — corpus evidence: P137 documents the class is pervasive ("Every published `@windyroad/*` plugin ships SKILL.md / hook / agent files dense with `ADR-NNN` / `JTBD-NNN` / `P-NNN` references"). P154 documents an actual production-shipped instance (`@windyroad/itil@0.23.2 → 0.24.0` shipped broken bin shims because `package.json` `files` array missed `scripts/`). Pre-control state: every release introduced new instances by default.
- **Inherent Score**: 20
- **Inherent Band**: Very High

## Controls

- **ADR-049 plugin-bundled scripts via `$PATH` `bin/`** — codifies thin shim wrappers in `packages/<plugin>/bin/wr-<plugin>-<command>` that dispatch to canonical bodies in `packages/<plugin>/scripts/`. SKILL.md prose calls the shim by name (`wr-itil-reconcile-readme`); the shim resolves at adopter install time via `$PATH`. **Effectiveness**: high for paths covered (mechanical resolution); zero for paths the author hasn't wrapped. Reduces likelihood from 5 to 3 for the script-path failure mode (P151 class).
- **ADR-055 namespace-prefixed permalinks** — internal IDs in published prose use the `@windyroad/<plugin>:` namespace prefix so adopter agents can recognise them as publisher-scope references, not adopter-scope references. **Effectiveness**: medium-high for new prose; doesn't retroactively fix existing references. Reduces likelihood from 3 to 2 for the ID-leakage failure mode (P137 class).
- **`packages/retrospective/scripts/check-namespace-prefix-leakage.sh`** (P137 detector, ADR-055) — advisory script that walks plugin source for unprefixed IDs and surfaces them at retro time. **Effectiveness**: medium — advisory-only; detects but doesn't enforce; covers source-tree only (not npm-pack output — see P154 extension).
- **P154 npm-pack-extension to detector** — runs the namespace-prefix detector against `npm pack` tarball output instead of (or in addition to) source tree, catching publish-manifest drift like missing `files` array entries. **Effectiveness**: high for the publish-manifest drift class specifically. Reduces likelihood for that sub-class from 5 to 1 (catches at pack-time, before publish).
- **Architect + JTBD review on every plugin SKILL/agent edit** — reviewers see new prose and can flag unprefixed IDs / repo-relative paths. **Effectiveness**: medium — depends on reviewer attention to publish-boundary dimension.
- **`packages/<plugin>/package.json` `files` array curation** — explicit allowlist of paths to include in the npm tarball. **Effectiveness**: high when correctly maintained; the failure mode is omission (e.g. `scripts/` not in the array) — addressed by the P154 detector extension.

## Residual Risk

- **Impact**: 3/5 (Moderate) — controls reduce blast radius; remaining residual is mostly degraded-semantics (mis-resolved IDs in adopter agents) rather than hard-fail (paths). Hard-fails are now substantially mitigated by ADR-049 + P154 detector.
- **Likelihood**: 2/5 (Unlikely) — multiple independent control paths (shim pattern + permalink prefix + source detector + npm-pack detector + review gates) each contribute reduction. Observed catch rate in the most recent release cycle was high (P154 caught the `@windyroad/itil` files-array regression after 5 versions of broken shims; all subsequent releases clean).
- **Residual Score**: 6
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; structural fix would be CI-blocking (vs advisory) detector + lint rule preventing unprefixed IDs in SKILL/agent prose.

## Treatment

**Mitigate**. Continue ADR-049 + ADR-055 + detectors as primary controls. Phase 2 extension when evidence justifies: promote the namespace-prefix detector from advisory to commit-blocking (load-bearing pattern from P159 / R001 control approach).

**Active mitigations**:
1. ADR-049 shim pattern for any new repo-relative script invocation in published SKILL.md prose.
2. ADR-055 namespace-prefix on new ADR / JTBD / problem citations in published prose.
3. P137 detector at retro time (advisory).
4. P154 detector against npm-pack output (catches publish-manifest drift).
5. Architect / JTBD review attention to publish-boundary on every plugin edit.
6. Per-package `files` array audit when adding new directories under `packages/<plugin>/`.

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: an adopter reports a hard-fail at Step 0 of any published skill (signal: ADR-049 shim coverage incomplete). Or: an adopter reports an agent applying mis-resolved-ID semantics (signal: ADR-055 prefix coverage incomplete). Or: P137 / P154 detector firing rate increases over a release cycle (signal: prose authors not internalising the patterns).
- **Metrics**: count of ADR-049 shims per plugin (target: every script invoked from published SKILL.md); count of unprefixed internal IDs per plugin per release (target: 0 trending); count of npm-pack-extracted broken-reference instances per release (target: 0); P137/P154 detector advisory count per retro (target: trending toward 0).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P137 (internal-ID leakage driver — verifying), P151 (script-path leakage driver — verifying), P154 (npm-pack-extension to detector — verifying), `@windyroad/itil@0.23.2 → 0.24.0` shipped-broken-shims production instance documented in P154 body.
- **Generalisation-of**: R008 (functional defects in shipped behaviour) — R011 specialises by addressing the publish-boundary specifically. R004 (cache divergence) is sibling but distinct: R004 is about same-content-different-version drift; R011 is about same-version content NOT MATCHING what's expected to be in it.
- **Treatment ADRs**: ADR-049 (plugin-bundled scripts via `$PATH` `bin/`), ADR-055 (namespace-prefixed permalinks), ADR-014 (single-commit grain — files array changes ride with the source change), ADR-052 (behavioural-tests default — fixture tests for shim resolution).
- **Personas affected**: plugin-user (every adopter pays the broken-link / hard-fail / mis-resolved-ID cost); plugin-developer (JTBD-101 — clear patterns for cross-package boundaries); plugin-maintainer (publish-manifest-correctness cost).

## Source Evidence

- `docs/problems/137-published-plugin-artifacts-reference-internal-ids-confuses-adopter-agents.verifying.md` — driver for the ID-leakage failure mode; user direction verbatim: "they may have their own ADRs and these references could very easily confuse and mislead agents".
- `docs/problems/151-published-skills-reference-repo-relative-script-paths.verifying.md` — driver for the script-path failure mode; user direction verbatim: "some of the published skills (like manage-problem) references files in this repo (like packages/itil/scripts/reconcile-readme.sh), which users of the plugins CANNOT ACCESS".
- `docs/problems/154-p137-detector-must-run-against-npm-pack-output-not-source-tree.verifying.md` — production instance: `@windyroad/itil@0.23.2 → 0.24.0` shipped broken bin shims because `files` array missed `scripts/`.
- `docs/decisions/049-plugin-script-resolution-via-bin-on-path.proposed.md` — control authority for shim pattern.
- `docs/decisions/055-plugin-published-namespace-prefixed-internal-ids.proposed.md` — control authority for permalink prefix.
- `packages/retrospective/scripts/check-namespace-prefix-leakage.sh` — control implementation.

## Change Log

- 2026-05-04: Bootstrapped post-wipe addressing user observation 2026-05-04 ("we also have a risk (captured in some of the problems) of the packaged software referencing paths and document IDs within the repo that aren't withing the published package"). Inherent / Residual estimated from P137 + P151 + P154 priority scoring (each Inh 20-15) + control inventory (ADR-049 + ADR-055 + detectors) + observed production-shipped instance (`@windyroad/itil` files array regression).
