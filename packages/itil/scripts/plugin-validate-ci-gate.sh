#!/usr/bin/env bash
# packages/itil/scripts/plugin-validate-ci-gate.sh
#
# P263 / ADR-063 §Confirmation #11 — CI pre-publish manifest-validity
# gate. Loops every `packages/*/.claude-plugin/plugin.json` in CWD,
# runs `claude plugin validate <plugin_dir>` (NON-strict — see RCA
# note below), accumulates failures, and exits non-zero if ANY plugin
# manifest fails validation.
#
# WHY NON-STRICT (P263 / P258 refined RCA, 2026-05-30):
#   - The historical P258 incident's failure class was a RECOGNISED
#     top-level key (`hooks` / `skills` / `agents` / `commands`)
#     carrying wrong-typed content — caught by `claude plugin validate`
#     non-strict as a hard ERROR (`Validation errors: hooks: Invalid
#     input`).
#   - ADR-063 Amendment 2026-05-18's chosen safe-extension pattern
#     places maturity records at top-level `maturity:` — an
#     UNRECOGNISED top-level key — because unrecognised keys are
#     warning-only and the plugin still loads. This is the durable
#     design. `--strict` would promote `unknown field 'maturity'` to
#     an error and REJECT every @windyroad/* plugin.
#   - Non-strict therefore catches the historical incident's
#     mechanism without rejecting the safe-extension pattern. The
#     prose Confirmation #11 originally named `claude plugin install
#     --dry-run`; P258 investigation refined to `claude plugin
#     validate --strict`; this script's RCA refined further to
#     non-strict.
#
# CLI VERSION PIN (set in `.github/workflows/ci.yml`):
#   CI installs `@anthropic-ai/claude-code@2.1.150` before invoking
#   this script. The exact pin protects against Anthropic-side CLI
#   behaviour change silently breaking the gate. 2.1.150 is the
#   version P263 iter 6 empirically tested against. Bump the pin
#   only after re-running the iter-6 probe against the new version.
#
# LOOP CONTRACT:
#   - Walks `packages/*/.claude-plugin/plugin.json` from CWD.
#   - Does NOT short-circuit on first failure — every plugin is
#     exercised so CI surfaces every defect at once.
#   - `nullglob` makes a zero-plugin tree a no-op exit 0 (adopter-
#     tree portability per ADR-049).
#
# References:
#   ADR-063  — Amendment 2026-05-18 + §Confirmation #11
#   ADR-049  — PATH-on-shim grammar (`wr-itil-plugin-validate-ci-gate`)
#   ADR-052  — behavioural tests default (bats at
#              `scripts/test/plugin-validate-ci-gate.bats`)
#   ADR-014  — single-commit grain (script + shim + bats + CI + ADR
#              amendment + changeset land together)
#   P258     — root-cause driver (recognised vs unrecognised key
#              distinction)
#   P246     — sibling-class "gate-the-actual-load-bearing-surface"
#   P263     — this implementation's ticket

set -e
shopt -s nullglob

fail=0
for manifest in packages/*/.claude-plugin/plugin.json; do
  plugin_dir=$(dirname "$(dirname "$manifest")")
  name=$(basename "$plugin_dir")
  echo "--- $name ---"
  if ! claude plugin validate "$plugin_dir"; then
    echo "FAIL: $name plugin manifest validation"
    fail=1
  fi
done

[ "$fail" = "0" ] || exit 1
exit 0
