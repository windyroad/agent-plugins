# R074: Shipped plugin entrypoint loses its executable mode bit → inert at adopter installs

Plugin hooks, `bin/` shims, and `scripts/` entrypoints are invoked **directly** by Claude Code and the ADR-049 shim wrappers (as a bare command path, not `sh <path>`). Execution therefore requires the file's executable bit. Git tracks the mode (`100755` vs `100644`), and **npm-tarball extraction preserves it** — so an entrypoint committed at `100644` ships non-executable to every adopter, where `/bin/sh -c '<path>'` refuses it with `Permission denied`. If the hook fails open (non-blocking), the plugin installs cleanly but is **silently inert** — the worst failure shape, because nothing signals the capability isn't running.

Production evidence: `@windyroad/cruise` shipped both hooks at `100644` for every version 0.2.0–0.3.2 (P447). The throttle emitted `PreToolUse hook error / Permission denied` on every tool call and did zero pacing; observed live 2026-07-12. Source-repo dogfooding masked it — the maintainer's own session ran an earlier working state; the defect only manifests in the extracted tarball copy.

This is the mode-integrity sibling of R006 (published-package vs source-tree divergence): same "the shipped copy differs from what works in source, and the boundary hides it" shape, but the divergence is the **file mode**, not path/ID content.

## Recogniser

**Path patterns** (any match → consider this entry):

- `packages/*/hooks/*.sh` (directly-invoked hook entrypoints — NOT `hooks/lib/*`)
- `packages/*/scripts/*.sh` (directly-invoked scripts — NOT `scripts/lib/*`)
- `packages/*/bin/*` (ADR-049 shim wrappers)
- `packages/shared/*.sh`

**Diff-content signals** (any match → consider):

- A new entrypoint file added under the paths above (new files inherit the author's umask; `git add` records `100644` unless the working-tree file was `chmod +x` first).
- `create mode 100644 packages/*/hooks/*.sh` (or `/bin/`, `/scripts/`) in the commit's `git show --stat`.
- `hooks.json` / marketplace manifest that invokes a command path directly.

**Anti-patterns** (looks like R074 but isn't):

- `*/hooks/lib/*.sh` and `*/lib/*.sh` — these are `source`d (read-only), correctly ship `100644`, and are OUT of scope. Flagging them is a false positive.
- Non-executable data/config assets under `bin/` (none currently ship, but if added they are not entrypoints).

## Stage applicability

| Stage | Fires? | Notes |
|-------|--------|-------|
| commit | yes | The `100644` mode is recorded here |
| push | yes | cumulative |
| release | **primary** | Failure surfaces at adopter installation (tarball preserves the mode) |
| external-comms | no | Not an outbound-prose lens |

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 5 (Catastrophic) — a fail-open entrypoint that never runs makes the whole capability silently inert; the plugin's entire value proposition does not execute, with no error the user is likely to notice (P447).
- **Likelihood**: 5 (Almost certain) — new entrypoints inherit `100644` from the author's umask unless explicitly `chmod +x`'d before `git add`; a human is certain to forget, and dogfooding masks it. Production evidence: cruise shipped broken for 4 consecutive versions.
- **Inherent score**: 25
- **Inherent band**: Very High

## Controls (control-application table)

| Control | Fires when… | Path # | Band reduction | If absent for THIS action |
|---------|-------------|--------|---------------:|---------------------------|
| `check:executable-modes` CI guard (`scripts/check-executable-modes.sh`) | Every CI run — asserts every tracked entrypoint (hooks/scripts/bin, excluding `lib/`) is git mode `100755`; fails the build otherwise | 1 (commit-blocking on push/PR) | -3 likelihood (certain → rare) | Bump +3 — with no guard the class recurs on every new entrypoint |
| ADR-049 shim-wrapper template + `check:shim-wrappers` | New `bin/` shims are template-generated (the template carries the mode) | 2 (bin sub-class) | -1 likelihood for bin shims | Bump +1 if a `bin/` entrypoint is hand-authored |

The `check:executable-modes` guard is the load-bearing control: a single deterministic `git ls-files -s` mode assertion, commit-blocking in CI, that no new `100644` entrypoint can pass.

## Per-action modulators

Adjust likelihood for THIS action's specifics (composition: max-pessimistic):

| Modifier | Adjustment | Rationale |
|----------|------------|-----------|
| Commit adds a NEW entrypoint file under `hooks/`, `bin/`, or `scripts/` | +1 | New files are the failure surface — most likely to carry the umask default |
| `check:executable-modes` ran green for this commit | -3 | Empirical proof every entrypoint is `100755` |
| Entrypoint added but CI not yet run / guard not yet wired for this package | +2 | The guard is the only real control; without it firing, inherent likelihood stands |

## Residual risk

Residual reflects the CI guard firing-and-passing (per-action lens):

- **Likelihood after controls**: 1 (Rare) — the guard is deterministic and commit-blocking; a `100644` entrypoint cannot reach a release once CI is green.
- **Residual score**: 5 (Impact 5 × Likelihood 1)
- **Residual band**: Low — **within appetite** (the Impact-5/Likelihood-1 floor for severe-but-rare classes admitted under ADR-086, same shape as R008).

The residual is Impact-bound, not control-bound: the guard drives likelihood to the floor, but the impact of a hypothetical escape stays Catastrophic. The control being deterministic + commit-blocking (not advisory) is what distinguishes this from R006's above-appetite residual.

## Watch-out

- Scope the guard to **entrypoints only** — `*/lib/*` files are sourced and correctly `100644`; policing them would be a false positive that pressures authors to wrongly `chmod +x` library files.
- The bit is set at `git add` time from the working-tree mode. `chmod +x` the file BEFORE `git add`, or use `git update-index --chmod=+x <file>` after — editing the file later does not change the tracked mode.
- Dogfooding does not catch this — the source working tree may be executable locally while the committed mode is `644`. Only `git ls-files -s` (tracked mode) or a fresh tarball install reveals it.

## See also

- **Generalisation**: R006 (published-package vs source-tree divergence) — R074 is the file-mode specialisation of the same publish-boundary class.
- **Sibling**: R003 (hook regression shipped to adopters), R009 (functional defects in shipped behaviour).
- **Drivers / ADRs**: P447 (the driver — cruise hooks shipped `644`), P446 (throttle-inert sibling), P151/P153/P219/P317 (repo-relative-path class — the same source-repo-masks-it shape), ADR-049 (`$PATH bin/` shims), ADR-014 (commit grain).
