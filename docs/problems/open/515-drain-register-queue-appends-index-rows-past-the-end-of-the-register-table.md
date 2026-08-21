# Problem 515: `drain-register-queue.sh` appends index rows past the end of the register table, so auto-scaffolded risks never reach the index

**Status**: Open
**Reported**: 2026-08-21
**Priority**: 10 (High) — Impact: 2 (Minor — a shipped plugin script misbehaves, but the damage is confined to a docs artefact; nothing fails to load and no install breaks) × Likelihood: 5 (Almost certain — previously observed failure mode, no controls, deterministic on every drain that creates an entry; 59 rows accumulated as proof) — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: S — two localised edits in one Python block (`packages/risk-scorer/scripts/drain-register-queue.sh` lines 242-254 and 247) plus two bats assertion rewrites; no cross-package surface, no migration — cf. P171 (M) which had to reconcile four consumers of the R-file shape, where this touches one insert path
**WSJF**: 10.0 — (10 × 1.0) / 1
**JTBD**: JTBD-303
**Persona**: plugin-user

## Description

`packages/risk-scorer/scripts/drain-register-queue.sh` appends malformed index
rows **past the end** of the register table, so risks it auto-scaffolds never
appear in the index. Two defects compose in the README-insert path
(lines 242-254):

**(i) The insert anchors on a heading that does not exist.** Line 249 tests
`if "## Retired" in readme:` and line 250 inserts the new rows before it.
`docs/risks/README.md` has no `## Retired` heading (`grep -c "## Retired"`
returns `0`), so control always falls through to line 252:

```python
readme = readme.rstrip() + "\n" + new_rows_block
```

That appends the rows after the closing prose of the whole file, not inside
`## Entries`. The catalogue's self-pruning convention retires an entry by
renaming the file to `R<NNN>-<slug>.retired.md` — it never introduced a
`## Retired` section — so the anchor has never matched and the fallback has
always been the live path.

**(ii) The row is emitted with the wrong number of columns.** Line 247 emits
eight:

```python
rows.append(f"| [{rid}]({fn}) | {title} | pending | — | — | pending | pending | {today} |")
```

The `## Entries` table it is meant to join has a five-column header:

```
| ID | Class | Inherent | Residual | Status |
|----|-------|----------|----------|--------|
```

Either defect alone breaks the row. Together, the rows land outside the table
**and** would not render inside it even if the anchor were fixed — so fixing
only the anchor produces a broken table rather than a correct index.

**Observed:** 59 rows had accumulated below the table between May and
2026-08-21 before being repaired by hand at commit `0d46405c`. Without a fix
they re-accumulate from the next drain onward.

**NOTE FOR THE FIXER — the tests encode the bug as the contract.**
`packages/risk-scorer/scripts/test/drain-register-queue.bats` line 28 seeds its
fixture by copying the **live** `docs/risks/README.md`, and its assertions at
lines 121 and 123 expect the tail-appended eight-column shape:

```bash
grep -qE '\| \[R002\]\(R002-my-test-risk\.active\.md\) \|' docs/risks/README.md
grep -qE 'R002.*my-test-risk.*\|.*—.*\|.*—.*\|.*pending' docs/risks/README.md
```

Line 123's two em-dash columns and trailing `pending` only match the
eight-column row. Both assertions must be rewritten to the five-column in-table
shape **in the same commit as the fix**, or the fix lands red on CI.

## Symptoms

- Risks auto-scaffolded by the Phase 2b drain (ADR-056) have a file under
  `docs/risks/` but no row in the `## Entries` table of `docs/risks/README.md`.
- `docs/risks/README.md` accumulates a growing block of eight-column pipe rows
  below its closing paragraph, rendering as loose text rather than as a table.
- Repaired by hand at `0d46405c` after 59 rows had accumulated; the repair is
  not durable because the emitter is unchanged.

## Workaround

Hand-repair `docs/risks/README.md` after a drain — move the appended rows into
`## Entries` and reshape them to five columns (what `0d46405c` did).

## Impact Assessment

- **Who is affected**: anyone reading the risk register index to see the
  standing-risk catalogue — maintainers here, and adopters of
  `@windyroad/risk-scorer`, whose own `docs/risks/README.md` the shipped script
  writes into.
- **Frequency**: every drain that creates a new register file.
- **Severity**: the register index under-reports the catalogue it indexes, and
  the artefact it corrupts is a governance document an adopter reads as
  authoritative. Bounded: the per-risk files themselves are written correctly,
  so no risk data is lost — only its index entry.
- **Analytics**: 59 rows outside the table as of the `0d46405c` repair;
  `## Retired` occurrences in `docs/risks/README.md` = 0.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm the `## Retired` anchor was never valid for this repo's register
      shape (the retire convention is a `.retired.md` filename rename, not a
      README section) and decide whether to fix the anchor or replace it with a
      real insert point — locate the end of the `## Entries` table body and
      insert there.
- [ ] Reshape the line 247 row emission to the five-column
      `| ID | Class | Inherent | Residual | Status |` header, deciding what the
      stub Inherent / Residual / Status cells should read for an uncurated
      entry (`pending` / `—` / `pending review` are the candidates already in
      use elsewhere in the file).
- [ ] Rewrite `drain-register-queue.bats` lines 121 and 123 to the five-column
      in-table shape **in the same commit** — they currently encode the
      tail-appended eight-column bug as the expected contract.
- [ ] Reconsider the line 28 fixture seeding, which copies the live
      `docs/risks/README.md` — a fixture that tracks a moving artefact makes the
      test's meaning drift with the repo (same class as the vacuous-search-root
      trap the bats suite has been bitten by before).
- [ ] Add a behavioural test asserting the drained row lands **inside**
      `## Entries` with a column count matching the header, per ADR-052.
- [ ] Sweep the register README for rows still outside the table after the fix
      lands, and confirm `0d46405c`'s repair covered all 59.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P411 (no interactive oversight drain for pending-review
  register entries) — P411 is about curating entries that exist; this is about
  entries never reaching the index in the first place. Both degrade the same
  artefact from different ends.

## Related

(captured via /wr-itil:capture-problem)

- **P171** (`docs/problems/closed/171-drain-register-queue-script-and-tests-reference-obsolete-pre-wipe-r-file-shape.md`)
  — closed. Same script, adjacent class: the R-file **naming** contract drifted
  from the post-wipe canonical shape. P171's fix swept the filename and dedupe
  regex; it did not touch the README-insert path, which is this defect.
- **P309** (`docs/problems/closed/309-drain-register-queue-no-ops-on-unrepresented-slugs-without-truncating.md`)
  — closed, fold-fixed by P171. Same script, the drain **no-op** class. Its
  regression test proves entries now get created — which is precisely what
  makes this index defect reachable.
- Both siblings are Closed and so cannot absorb this scope; a new ticket is the
  right shape rather than reopening a closed fix.
- **Hang-off candidates deferred to review-time (Step 2b candidate-cap
  short-circuit — 7 candidates share the `docs/risks/README.md` signal, over the
  5-candidate dispatch cap):** P493, P494, P102, P167, P168, P373, P374.
  Re-evaluate the absorb-vs-sibling question for these at the next
  `/wr-itil:review-problems` cluster pass.
- **ADR-056** — the Phase 2b queue-and-drain write contract this script
  implements; the README index row is its step 3d deliverable.
- `packages/risk-scorer/scripts/drain-register-queue.sh` lines 242-254, 247 —
  the defect site.
- `packages/risk-scorer/scripts/test/drain-register-queue.bats` lines 28, 121,
  123 — the tests that must change with the fix.
- Commit `0d46405c` — the manual repair of the 59 accumulated rows.
