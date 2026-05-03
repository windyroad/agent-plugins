---
"@windyroad/itil": patch
---

Ship `scripts/` in the published tarball so `bin/wr-itil-*` shims resolve in adopter installs.

Iter 3's P151 fix added `bin/wr-itil-reconcile-readme` and `bin/wr-itil-check-problems-readme-budget` shims that exec `../scripts/<name>.sh "$@"` per ADR-049. The published `package.json` `files` array did not include `scripts/`, so adopter installs of `@windyroad/itil@0.23.2` through `@windyroad/itil@0.24.0` got the shims but not the scripts they reference — invocation hits a "no such file or directory" at the `exec` line.

Surfaced 2026-05-03 by iter 20 (P033 Phase 2b) as a sibling-finding while adding `scripts/` to `@windyroad/risk-scorer/package.json` for that plugin's own new `wr-risk-scorer-drain-register-queue` shim. First production-real instance of the regression class P137 covers (ADR-055 namespace-prefix advisory walks source-tree only; missed this because source tree exposes `scripts/` even when published tarball doesn't). Composes with P137 follow-up — npm-pack-output detector — which would catch this class at release-time CI, not in source-tree advisory.

Closes the broken-shim publishing gap as ADR-042 above-appetite Step 6.5 fix-and-continue per Rule 2 / R1 (residual risk 15/25 → 3/25 with this remediation). Architect PASS-WITH-NOTES + JTBD PASS (JTBD-302 primary fit — adopter trust in README invocability claims). One-line fix; sibling-fix-shape to iter 20's risk-scorer files-array fix.

Re-rate of impact across already-published versions (0.23.2 → 0.24.0): adopters who installed those versions retain broken shims until they upgrade. `npm install @windyroad/itil@latest` after this patch ships resolves to a fixed tarball; no `npm deprecate` action required (the next version supersedes by SemVer convention).
