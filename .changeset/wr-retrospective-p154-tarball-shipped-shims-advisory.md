---
"@windyroad/retrospective": minor
---

P154: ship `check-tarball-shipped-shims.sh` advisory + dogfood-fix `scripts/` in `files` array so detector + sibling shims actually resolve in adopters

Closes the iter-20 sibling-finding regression class — `bin/wr-<plugin>-<name>` shims that exec into `../scripts/<name>.sh` but ship broken because `package.json#files` omits `scripts/`. The source-tree-walking detector shipped in `@windyroad/retrospective@0.15.0` (ADR-055 + check-internal-id-leaks.sh, P137 Phase 1) measures source-tree namespace-prefix drift but cannot see this publishing-manifest leak — `scripts/` exists on disk so the source-tree advisory finds nothing, while the npm tarball ships without it so adopters hit `no such file or directory` at invocation time.

P154 closes that prevention surface from the publish-manifest side.

Adds:

- `packages/retrospective/scripts/check-tarball-shipped-shims.sh` — diagnose-only advisory that runs `npm pack --dry-run --json` per workspace, parses the `files` array, and asserts every `bin/wr-<plugin>-<name>` shim's `exec`'d `scripts/<name>.sh` target is also in the tarball. Silent-on-pass (no output when clean) per ADR-045. Always exits 0 (advisory only) per ADR-013 Rule 6 + ADR-040 declarative-first. Emits `TARBALL_DRIFT package=<name> shim=<bin/...> target=<scripts/...> tarball-status=missing` lines + `TOTAL packages=<N> with_drift=<M> missing_targets=<K>` summary on drift, terse machine-readable per ADR-038. Skips non-ADR-049-grammar bins (`bin/install.mjs`, `bin/check-deps.sh`, `bin/windyroad-<plugin>` legacy installers) — only ADR-049-shape shims are subject to the contract. Pre-checks for `npm` on PATH; exits 2 if root dir or npm missing.
- `packages/retrospective/bin/wr-retrospective-check-tarball-shipped-shims` — `$PATH`-resolved shim per ADR-049 grammar. Adopter invocation point for the new advisory.
- `packages/retrospective/scripts/test/check-tarball-shipped-shims.bats` — 15 behavioural tests per ADR-052 default. Asserts script output on temp-fixture trees: clean workspace produces no output; broken-shape workspace (`files: ["bin/"]` omitting `scripts/`) emits the canonical `TARBALL_DRIFT` line; multi-package + multi-shim drift aggregates correctly; non-ADR-049-grammar bins are silently ignored; output is sorted deterministically by `<package>/<shim>` identifier.

Dogfood-fix:

- `packages/retrospective/package.json` — adds `"scripts/"` to the `files` array. The new tarball-shipped-shims script + the 5 sibling check-* shims (P137 Phase 1 + sibling advisories) all `exec` into `../scripts/` paths; without `scripts/` in `files`, the tarball ships every adopter shim broken. Same fix-and-continue R-pattern as `@windyroad/itil@0.23.x` → `0.24.0` (commit 3f671b9, P140 R1 — adopter shims silently broken across 5 published versions before P154's detector existed to catch it).

Live-repo verification (pre-fix): `packages/retrospective/scripts/check-tarball-shipped-shims.sh .` reported 5 broken shims under `@windyroad/retrospective` (the iter-20 regression class replicated). Post-fix: silent-on-pass — all targets resolve in the tarball.

Composes with:

- ADR-049 (executable correctness — sibling `bin/`-on-PATH ADR; P154 detector enforces ADR-049's confirmation criterion 5 from the publish-manifest side).
- ADR-052 (behavioural-tests-default — fixture asserts script output on temp trees, not source content).
- ADR-055 (sibling adopter-context decision — same `packages/retrospective/scripts/` home + retro Step 2b cross-reference target when P137 Phase 2 wiring lands per ADR-055 Confirmation criterion 4).
- ADR-040 (declarative-first then enforce — Phase 1 advisory, Phase 2 R6-gated escalation to release-time CI gate deferred per ticket).
- ADR-038 (progressive disclosure — terse machine-readable signal).
- ADR-045 (hook injection budget — silent-on-pass discipline).
- ADR-013 Rule 6 (advisory-then-escalate fail-safe).

JTBD-302 (Trust That the README Describes the Plugin I Just Installed — plugin-user persona) is the primary anchor: adopter-installed shims that hard-fail with `no such file or directory` are exactly the trust-violation the JTBD codifies. JTBD-101 (Extend the Suite with New Plugins — plugin-developer) is the secondary anchor: future contributors adding new `bin/wr-<plugin>-<name>` shims get retro-time feedback before the regression ships.

Phase 2 (deferred): wire the advisory into `/wr-retrospective:run-retro` Step 2b alongside check-internal-id-leaks.sh and check-readme-jtbd-currency.sh; promote to load-bearing PreToolUse hook iff drift_instances ≥ 1 across 3 consecutive `chore: version packages` releases without correction.
