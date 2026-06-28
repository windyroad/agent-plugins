# Problem 392: Blessed replace-section `awk -v section="$multiline"` idiom fails on BSD awk (macOS)

**Status**: Verification Pending
**Reported**: 2026-06-27
**Transitioned to Known Error**: 2026-06-28 (root cause confirmed empirically — host BSD awk 20200816 aborts `awk -v section="$multiline"` with `awk: newline in string`; single live site fixed + behavioural bats added + committed. Awaits release → Verifying.)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Fix Released

Shipped in **@windyroad/itil@0.55.1**. The single live BSD-awk defect (`update-problem-references-section.sh:266`, insert-before-`## Fix Released` branch) is fixed via the getline-from-tempfile pattern proven in `effort-tally.sh`; behavioural bats proven RED→GREEN on host BSD awk. Sibling section-updaters confirmed not affected (EOF-append). Shared-helper extraction deferred (P366 tracks the thesis).

**Awaiting user verification** — on macOS (BSD awk), run a multi-line `## RFCs` / `## Stories` section refresh through `update-problem-references-section.sh` and confirm no `awk: newline in string` abort.

## Description

The replace-section section-updater idiom in `packages/itil/scripts/update-problem-references-section.sh` (line ~266: `awk -v section="$new_section" ... printf "%s\n", section`) passes a multi-line string via `awk -v`. GNU awk (CI / Linux) tolerates embedded newlines in a `-v` assignment; **BSD awk (the macOS default) rejects it** with `awk: newline in string ... at source line 1` and aborts non-zero.

Discovered 2026-06-27 while building the P248 effort-tally `--write` mode, which initially copied this idiom verbatim and failed on macOS. Worked around there by writing the section to a temp file and reading it back via `awk` `getline` (portable across BSD awk + gawk). The sibling section-updaters — `update-problem-references-section.sh` (the canonical replace-section helper, used for the `## RFCs` / `## Stories` / `## Story Maps` reverse-trace sections) and any future script copying the idiom — still carry the latent defect. They only work today because CI runs gawk and the reverse-trace updaters fire on macOS only when tracing artefacts exist (RFCs / stories with `problems:` frontmatter), which masks the bug in routine dogfooding.

Impact: a contributor / adopter running `/wr-itil:manage-problem` (or the section-updaters directly) on macOS with tracing artefacts present would hit a hard `awk` failure, silently dropping the `## RFCs` / `## Stories` / `## Story Maps` section refresh.

## Symptoms

- `awk -v section="$multiline" ...` aborts with `awk: newline in string <first line>... at source line 1` under BSD awk (macOS); works under gawk (Linux / CI).
- The reverse-trace section refresh in `update-problem-references-section.sh` is the live exposure; the bug is masked when no tracing artefacts exist (the `nullglob` loop finds nothing to render, so `new_section` stays empty and the awk insert branch is skipped).

## Workaround

Write the multi-line section to a temp file and read it via `awk` `getline` inside the insertion block instead of passing it through `awk -v`. Proven in `packages/itil/scripts/effort-tally.sh` (`--write` mode, commit 1c967ba0):

```sh
section_file="$(mktemp)"; printf '%s' "$new_section" > "$section_file"
awk -v sf="$section_file" -v anchor="$anchor" '
  $0 ~ anchor && !done { while ((getline ln < sf) > 0) print ln; close(sf); print ""; done=1 }
  { print }' "$tmp_file"
```

## Impact Assessment

- **Who is affected**: macOS contributors / adopters running manage-problem or the section-updater scripts directly with tracing artefacts present.
- **Frequency**: (deferred to investigation) — latent; fires only on the multi-line-section insert path under BSD awk.
- **Severity**: (deferred to investigation) — hard non-zero abort that silently drops a section refresh.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Audit all section-updater scripts for the `awk -v <multiline>` idiom. **Result: exactly ONE live defect** — `update-problem-references-section.sh:266` (the insert-before-`## Fix Released` branch). The siblings `update-{jtbd,rfc,story}-references-section.sh` insert the multi-line section via `printf '\n%s' "$new_section" >> "$tmp_file"` (EOF append), NOT via `awk -v`, so they are NOT affected. `effort-tally.sh` and `update-rfc-commits-section.sh` already use the getline-from-tempfile pattern. The remaining `awk -v sec="## $SECTION_NAME"` uses across the siblings pass a SINGLE-LINE section header — portable, not affected.
- [x] Apply the getline-from-tempfile fix (proven in effort-tally.sh) to the affected site. Done at `update-problem-references-section.sh:266`. **Shared-helper extraction (Fix Strategy part 2) deferred** — the strip+normalise+insert awk is duplicated across 6 scripts but with divergent placement rules (problem inserts-before-`## Fix Released`; siblings EOF-append; effort-tally inserts-at-anchor), so a clean shared helper is unbounded scope above the single-site bug's Low(5) appetite. Architect confirmed deferral is correct (ADR-017 is cross-package-only; ADR-074 — substance-confirm-before-build — reinforces not doing the ad-hoc extraction). The structural "shared tested helper" thesis stays tracked under [[P366]]. **Follow-up: extract a shared `replace-section` helper** if/when a 3rd insert-before-anchor site appears or P366 is scheduled.
- [x] Create a behavioural bats asserting the multi-line section insert works under the host awk (guards regression on both BSD + GNU). Done: `update-problem-references-section.bats` test "multi-line section inserts before ## Fix Released under host awk" — proven RED against the pre-fix `-v` idiom on host BSD awk, GREEN with the getline fix.

## Fix Strategy

**Kind**: improve. **Shape**: shell-script + bats (Step 4b Option 3 — `Other codification shape`).

Two-part fix:
1. Replace every `awk -v section="$multiline"` site with the getline-from-tempfile pattern proven in `effort-tally.sh --write` (commit 1c967ba0).
2. Strongly consider extracting a single shared `replace-section` helper (the strip + normalise + idempotent-insert awk is duplicated across `effort-tally.sh` and `update-problem-references-section.sh`) so the BSD-awk fix lives in one tested place — directly answers the recurring-class concern that template-copy keeps re-introducing the same divergence (the P366 thesis).

Pair each with a behavioural bats that exercises a multi-line insert under the host awk so CI (gawk) AND a macOS dev (BSD awk) both prove it.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P328, P366 (same BSD/GNU awk-divergence class — see Related)

## Related

(captured via /wr-itil:capture-problem; wider hang-off search performed per feedback_hang_off_existing_ticket_before_capturing_new — none of the cluster tickets absorb this cleanly: different mechanism + different fix locus + both verifying/near-closed. Consolidation deferred to /wr-itil:review-problems.)

- **BSD/GNU awk portability cluster** — this is the 4th instance of the class:
  - **P334** (closed, `docs/problems/closed/334-...md`) — awk `substr` Unicode-ellipsis not portable BSD vs GNU; fixed via ASCII.
  - **P328** (verifying, `docs/problems/verifying/328-bsd-locale-utf8-grep-sed-awk-friction-on-macos.md`) — the broad umbrella: BSD grep/sed/awk **locale/UTF-8** friction on macOS, fixed via `LC_ALL`. **This finding is a NON-locale failure mode `LC_ALL` does not fix** — it strengthens P328's fix-candidate #3 (a CI lint for unguarded grep/sed/awk would also need to catch `awk -v <multiline>`). Surfacing it here so the P328 verification reviewer sees the class is not fully guarded.
  - **P366** (verifying, `docs/problems/verifying/366-...md`) — architect-hook `\b` BSD bug propagated via template-copy; its residual ("inline-implementation vs shared tested helper") is the SAME structural thesis as this ticket's Fix Strategy part 2, but scoped to architect commit-detection rather than the itil section-updater idiom.
- **P248** (`docs/problems/open/248-...md`) — discovery context; `effort-tally.sh --write` carries the proven getline-from-tempfile fix.
- `packages/itil/scripts/update-problem-references-section.sh` — canonical replace-section helper carrying the latent defect.
- `packages/itil/scripts/effort-tally.sh` — the proven workaround (commit 1c967ba0).
- **ADR-052** — behavioural-tests-default for the regression bats.
