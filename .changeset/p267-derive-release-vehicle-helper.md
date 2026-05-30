---
'@windyroad/itil': minor
---

P267: codify `derive-release-vehicle.sh` helper for deterministic K→V release-cycle citation.

**Problem**: when `/wr-itil:transition-problem` Step 6 (Known Error → Verification Pending) transitions a ticket per ADR-022, the release-vehicle citation (changeset filename → version-packages commit → merge PR → merge commit) was composed by hand from `git log` browse output. Hand-typed citations are fragile to wrong-release-cited errors when a session pre-applies transitions across multiple sibling tickets before working any of them. Observed 2026-05-18 session 7 iter 1: P250's K→V citation referenced P247's release refs (`1ef3157` / PR #143) instead of P250's actual refs (`4a0e1b7` / PR #141).

**Fix**: ship `packages/itil/scripts/derive-release-vehicle.sh` + `packages/itil/bin/wr-itil-derive-release-vehicle` (ADR-049 PATH shim). The helper takes a ticket ID, reads the ticket body for the `.changeset/<name>.md` reference, walks `git log --diff-filter=D` for the deletion commit (`chore: version packages`), resolves the merge PR via first-parent ancestry-path merge commit (or `gh pr list` fallback when available), and emits a structured citation block:

```
RELEASE_VEHICLE:
  changeset: .changeset/<name>.md
  version-packages-commit: <SHA>
  pr: #<N>
  merge-commit: <SHA>
  release-date: <YYYY-MM-DD>
```

`/wr-itil:transition-problem` Step 6 now invokes the helper and uses the structured values verbatim in the `## Fix Released` section. ADR-044 framework-resolution boundary: helper is mechanical, no `AskUserQuestion` per transition. Exit-code routing documented in-skill (0 ok, 1 ticket not found, 2 no changeset reference, 3 unreleased, 4 no merge PR resolvable).

Sibling shim naming grammar (`wr-itil-reconcile-readme`, `wr-itil-classify-readme-drift`). Behavioural bats coverage (13 tests, all green) including happy path, per-state subdir layout, bare numeric ID, unreleased, no PR resolvable, default problems-dir, bin shim parity.

Architect APPROVE (composes with ADR-049 / ADR-022; no new ADR). JTBD PASS (serves JTBD-001 / JTBD-006 / JTBD-101).
