---
"@windyroad/itil": patch
---

Adopter-safe path resolution in shipped SKILLs (P317 / RFC-009).

Fixes 24 references in published SKILLs that used repo-relative `packages/itil/...` paths — these only resolve in the source monorepo and broke in adopter installs (the create-gate marker step failed, so `capture-problem` / `capture-rfc` / `manage-problem` could not create tickets).

- New PATH-shim commands (ADR-049): `wr-itil-mark-create-gate`, `wr-itil-mark-rfc-capture-gate`, `wr-itil-migrate-problems-layout`, `wr-itil-check-upstream-cache-staleness` — each resolves its libs relative to the script, not cwd.
- New per-script shims for the `update-*-section` scripts; the 17 `$(wr-itil-script-path || echo packages/...)` call sites now invoke them by name.
- `capture-rfc` gains its previously-missing create-gate marker step.
- A CI lint now fails the build on any repo-relative `source packages/...` or `|| echo packages/...` reference in a shipped SKILL, so the class cannot recur.
