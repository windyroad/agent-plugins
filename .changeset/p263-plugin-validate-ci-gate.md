---
"@windyroad/itil": minor
---

P263 / ADR-063 §Confirmation #11 — adds `claude plugin validate` (non-strict) CI pre-publish gate covering every `@windyroad/*` plugin manifest. Catches the recognised-top-level-key-with-wrong-typed-content class that drove the P258 manifest-validity incident without rejecting the ADR-063 top-level `maturity:` safe-extension pattern (which `--strict` would reject). New canonical body at `packages/itil/scripts/plugin-validate-ci-gate.sh`, ADR-049 shim at `packages/itil/bin/wr-itil-plugin-validate-ci-gate`, behavioural bats at `packages/itil/scripts/test/plugin-validate-ci-gate.bats`. CI workflow wires the gate after the existing `Dry-run per-plugin installers` step.
