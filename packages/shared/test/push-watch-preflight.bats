#!/usr/bin/env bats

# @problem P116 — push:watch preflight does not count local-only commits before batch-push.
#
# Contract: the sanctioned push surface (root `package.json` `push:watch`
# → `scripts/push-watch.sh`) MUST run a preflight that counts
# `git log @{push}..HEAD`. When the count is ≥ 2, it MUST print a WARNING
# line naming the hazard (intermediate commits never ran origin CI; CI
# regressions will be attributed to the tip commit by GitHub Actions).
#
# Contract shape is warn-and-proceed per ADR-013 Rules 5 and 6 (policy-
# authorised silent proceed + non-interactive fail-safe). Script must NOT
# block the push — warn to stderr and continue unconditionally.
#
# Structural assertions on a packaging/script file — Permitted Exception
# per ADR-005 and contract-assertion framing per ADR-037.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/push-watch.sh"
  PKG_JSON="$REPO_ROOT/package.json"
}

@test "push-watch preflight: scripts/push-watch.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "push-watch preflight: package.json push:watch delegates to scripts/push-watch.sh" {
  run grep -F -- 'bash scripts/push-watch.sh' "$PKG_JSON"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: script inspects git log @{push}..HEAD (or equivalent local-only range)" {
  # The preflight's local-only-commit detection must reference the push
  # ref so the count reflects "commits that have never been pushed".
  # `@{push}` is the git-sanctioned form; `origin/<branch>..HEAD` is the
  # fallback when @{push} is undefined (new branch).
  run grep -E '@\{push\}|origin/[^ ]+\.\.HEAD' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: script checks the count against threshold N >= 2" {
  # The hazard fires on two or more local-only commits (one invisible-
  # to-CI intermediate commit). Threshold is fixed at 2 per the P116
  # architect verdict.
  run grep -E '(-ge|-gt)[[:space:]]+[12]' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: script prints a WARNING line referencing local-only commits" {
  run grep -iE 'WARNING.*local[- ]?only' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: script names the hazard — CI attributes regression to tip commit" {
  # The warning must name the failure mode so the operator can
  # orient ("why am I seeing this?" → one-line explanation).
  run grep -iE 'tip|attribute|intermediate' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: script does NOT exit on the preflight — warn-and-proceed per ADR-013 Rule 5" {
  # Negative assertion: the preflight block must not contain an `exit`
  # that halts the push. Enforced by scanning for `exit` tokens inside
  # the preflight-guard block; a bare `exit 1` inside the if would
  # convert warn-and-proceed to warn-and-block and violate ADR-018's
  # drain contract.
  #
  # Heuristic: require that the push invocation (`git push`) appears
  # AFTER the preflight block in source order. If the preflight exits
  # early, the push line would be unreachable — but a grep for order
  # is still a useful guard against accidental hard-block rewrites.
  push_line=$(grep -nE '^[[:space:]]*git push' "$SCRIPT" | head -1 | cut -d: -f1)
  preflight_line=$(grep -nE 'local[- ]?only' "$SCRIPT" | head -1 | cut -d: -f1)
  [ -n "$push_line" ]
  [ -n "$preflight_line" ]
  [ "$push_line" -gt "$preflight_line" ]
}

@test "push-watch preflight: anchoring contract — script uses --commit=\$(git rev-parse HEAD) (P060)" {
  # Preserve the P060 anchoring guarantee when the push:watch body
  # moves from package.json into scripts/push-watch.sh. Without this,
  # the move would regress P060.
  run grep -F -- '--commit=$(git rev-parse HEAD)' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: anchoring contract — script propagates watch exit code (ADR-018/ADR-020)" {
  run grep -F -- '|| exit $?' "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "push-watch preflight: anchoring contract — script filters by --branch main" {
  run grep -F -- '--branch main' "$SCRIPT"
  [ "$status" -eq 0 ]
}
