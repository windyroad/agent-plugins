---
"@windyroad/risk-scorer": patch
---

P208: push/release gate now consults CI status before scoring risk

`git-push-gate.sh` previously gated `npm run push:watch` and
`npm run release:watch` on the predicted risk score alone, so a low-risk
push could land on a CI-red master and a low-risk release could ship
broken code to npm.

A new `check_ci_status` helper in `lib/risk-gate.sh` queries
`gh run list --branch <current> --limit 1` for the working branch's most
recent CI run and denies when:

- `conclusion` is `failure`, `cancelled`, `timed_out`,
  `action_required`, or `startup_failure`
- `status` is `queued`, `in_progress`, `pending`, `requested`, or
  `waiting`
- the `gh` call fails (auth / timeout / API error) — fail-CLOSED per the
  P208 safe-high-fix-risk classifier so a buggy harden cannot degrade to
  bypass

Empty CI history (no prior runs on the branch) is allowed — the
documented "first push triggers CI" case requires no marker.

A one-shot `${RDIR}/ci-bypass-${ACTION}` marker provides an override
for the rare legitimate cases (infra incident, fresh branch with no
prior run). The `incident-release` bypass continues to short-circuit
the entire release gate, including the new CI check, so the JTBD-201
hotfix path is unaffected.

Ordering in `git-push-gate.sh`: existing bypass markers → CI status →
predicted-risk threshold.
