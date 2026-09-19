# Problem 549: The tarball shim-integrity detector silently skips any package whose pack lifecycle prints to stdout, so the two packages carrying the most shims are never checked

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a; one parser change in a single script plus a fixture that proves the skip
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`packages/retrospective/scripts/check-tarball-shipped-shims.sh` walks each workspace, runs `npm pack --dry-run --json`, and parses the result to confirm every shipped `bin/wr-<plugin>-<name>` shim has its `scripts/<name>.sh` dispatch target in the same tarball. It parses with `python3 json.load(sys.stdin)` guarded by `|| continue`.

Two workspaces print to stdout from their pack lifecycle scripts, so their output is not JSON — it is three lines of prose followed by the JSON object:

```
Packed 4 Codex-facing architect skill file(s).
Restored Claude architect skill source after pack.
Restored architect published source after pack.
{
  "@windyroad/architect": { ... }
}
```

`json.load` raises, the `|| continue` swallows it, and the workspace is skipped. Those two workspaces are `packages/architect` and `packages/risk-scorer` — between them the largest concentration of ADR-049 shims in the repo. A broken shim in either would read as clean, because the detector never looked.

The failure is also invisible to read as a failure. The script's contract is silent-on-pass, so a clean walk emits nothing; a walk that skipped two workspaces also emits nothing, plus a raw Python traceback on stderr that no caller surfaces. Clean and blind produce the same observable.

Observed 2026-09-19 while running the detector as part of verifying the P437 wardley shim fix.

## Symptoms

- `bash packages/retrospective/scripts/check-tarball-shipped-shims.sh .` exits 0 with empty stdout and a `json.decoder.JSONDecodeError` traceback on stderr.
- `packages/architect` and `packages/risk-scorer` are never assessed; every other workspace is.
- A deliberately broken shim in either package would not be reported.

## Workaround

Check those two workspaces by hand: run `npm pack --dry-run --json` in the package directory, strip the leading prose lines, and confirm each `bin/wr-*` shim's `scripts/<name>.sh` target is in the file list.

## Impact Assessment

- **Who is affected**: plugin developers relying on the detector to catch a shim whose dispatch target does not ship — the exact defect class that shipped five broken `@windyroad/itil` versions.
- **Frequency**: every invocation; the lifecycle scripts are permanent, so the blind spot is permanent.
- **Severity**: Medium — the detector is a backstop rather than the only control (`check:shim-wrappers` and per-package pack tests still apply), but its blind spot covers the packages where a shim is most likely to exist.
- **Analytics**: N/A.

## Root Cause Analysis

The parser assumes `npm pack --dry-run --json` writes nothing but JSON to stdout. npm runs `prepack` / `postpack` lifecycle scripts with their stdout inherited, so any package whose lifecycle prints a progress line breaks that assumption. The `|| continue` that keeps one bad workspace from killing the loop is also what makes the skip silent.

Two fix shapes, both small:

- Make the parser tolerant — slice from the first `{` before decoding, so a prose preamble is ignored.
- Or make the skip loud — on parse failure emit a `TARBALL_SKIP package=<name> reason=unparseable-pack-output` line so a blind walk is distinguishable from a clean one.

The second is worth doing regardless of the first: silent-on-pass is only safe when a skip is not silent too.

### Investigation Tasks

- [x] Confirm the detector skips `packages/architect` and `packages/risk-scorer`.
- [x] Confirm the cause is lifecycle-script stdout preceding the JSON.
- [ ] Make the parser tolerate a non-JSON preamble, and make an unparseable workspace emit a skip line rather than nothing.
- [ ] Add a behavioural fixture: a workspace whose pack output carries a prose preamble, asserted to be assessed rather than skipped.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P154 (the detector this defect is in — its fix shipped and is awaiting verification; this is a coverage hole in that fix, not a regression of it).

## Related

- P154 — the ticket whose fix is this detector. Left in Verification Pending per the retro contract on exercised-with-regression findings; this ticket carries the finding.
- P137 / P151 / P317 — the published-artifact path-portability class the detector exists to backstop.
- ADR-049 — plugin scripts resolve via `bin/` on `$PATH`; the shim grammar the detector walks.
- Surfaced by the `/wr-retrospective:run-retro` Step 2b pipeline-instability scan on the P437 iteration (captured via /wr-itil:capture-problem).
