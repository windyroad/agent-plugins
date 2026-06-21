# Problem 164: Latent octal-eval bug in next-ID formula across all 4 ticket-creator skills — `$(( $local_max + 1 ))` fails with "value too great for base" when local_max reaches 099

**Status**: Known Error
**Origin**: inbound-reported (#273) — Phase 2 scope-expansion surfaced 2026-06-21 by external user report. Phase 1 was internal capture 2026-05-04.
**Reported**: 2026-05-04 (Phase 1) · 2026-06-21 (Phase 2 reopen — Verifying → Known Error)
**Fix Released**: Phase 1 — 2026-05-11 (committed; awaiting next plugin release for field verification of the 6 ticket-creator SKILL.md formulas). Phase 2 — pending: extends fix to script-surface formulas of the same class that Phase 1's `\$\(\(\s*\$\(echo` grep pattern missed.
**Priority**: 16 (High) — Impact: Significant (4) x Likelihood: Almost certain (4) — preserved from Phase 1; Phase 2 re-rate deferred to next /wr-itil:review-problems

**WSJF**: (16 × 1.0) / 1 = **16.0** (Phase 1 baseline; Phase 2 may revise once Effort is re-rated)

> Captured 2026-05-04 by `/wr-itil:work-problems` AFK loop iter 7 surfacing pass per user direction "capture all four now". Sibling finding from iter 3 P156 commit. **Latent — currently masked because ADR-NNN and P-NNN counts are below 099. Will fire when first ticket-creator skill's local_max reaches 099 and the bash arithmetic interpreter parses `099` as octal.**

## Description

The next-ID formula used by all four ticket-creator skills (`/wr-itil:manage-problem` Step 3, `/wr-architect:create-adr` Step 3, `/wr-itil:capture-problem` Step 2, `/wr-architect:capture-adr` Step 2) computes:

```bash
next=$(printf '%03d' $(( $(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

When `local_max` (or `origin_max`) reaches `099`, the bash arithmetic context `$(( ... ))` parses the leading-zero number as octal. `099` is invalid in octal (digits ≥ 8); bash emits:

```
bash: 099: value too great for base (error token is "099")
```

The skill exits non-zero before writing the marker, before opening the file. The user sees a cryptic bash error.

This is a **latent** bug — the trigger (local_max == 099) hasn't fired yet because:
- Problem tickets are at P166 today, but the formula compares the max (well past 099 already? No — the formula reads filename prefix not zero-padded), so the bash arithmetic on `162` etc. is fine because `162` doesn't match octal-leading-zero.

Actually re-reading: `local_max` is extracted via `grep -oE '^[0-9]+' | sort -n | tail -1`. For P162, this returns `162` not `0162`. `$(( 162 + 1 ))` is fine (no leading zero, no octal interpretation).

**The bug fires only when local_max returns `099`** — which would happen briefly between P099 and P100 creation. **Already passed** for problem tickets (P099 → P100 transition happened earlier this loop's history). Will fire next when a NEW ticket-creator surface starts a fresh sequence and the first 99 entries happen to be created (e.g. a new ADR series, a new risk register R series, a future ticket-creator pattern).

The risk surfaces specifically when:
1. `local_max == "099"` (extracted from `099-something.open.md` or similar)
2. The bash `$(( ... ))` operator parses it as octal
3. The first arithmetic operation hits the invalid-octal-digit fail

Standard fix: prefix with `10#` to force base-10:

```bash
next=$(printf '%03d' $(( 10#$(echo -e "${local_max:-0}\n${origin_max:-0}" | sort -n | tail -1) + 1 )))
```

Or unset the leading zero pre-arithmetic via `${var#0}` parameter expansion — slightly less robust because it misses `099` (only strips one zero).

## Symptoms

- Next-ID computation fails when local_max reaches `099`. Cryptic `bash: 099: value too great for base` error.
- Currently silent / latent across the 4 ticket-creator skills.

## Workaround

When the bug fires: manually pass `local_max=99` (one fewer) via env-var, or compute next-ID manually, or run the skill from inside Python/Node where decimal-leading-zero is unambiguous.

## Impact Assessment

- **Who is affected**: Every project using `/wr-itil:manage-problem`, `/wr-architect:create-adr`, `/wr-itil:capture-problem`, or `/wr-architect:capture-adr` whose ticket count crosses 099 in the relevant filename glob.
- **Frequency**: Bug fires once per ticket-creator surface per project lifetime (the `099 → 100` transition). After that it's silent again.
- **Severity**: Significant — cryptic bash error halts ticket creation; user has to debug.
- **Likelihood**: Almost certain — every project will eventually cross 099. This repo already crossed it for problems but the historical commits don't indicate the bug fired (might have used the marginal-error-recovery path: existing ticket counter started higher, or the bug DID fire silently and was retried).

## Root Cause Analysis

Bash's `$(( ... ))` arithmetic interpreter applies number-base conventions: leading `0` means octal, leading `0x` means hex, otherwise decimal. The skills' formulas treat the zero-padded ID string (e.g. `099`) as a decimal number but bash treats it as octal-with-invalid-digit.

The fix is the standard `10#` base-10 prefix that all robust shell-arithmetic-on-string-numbers code uses.

### Investigation Tasks

- [x] Confirm the ticket-creator skills affected — grep for `\$\(\(\s*\$\(echo` shape verified **6 affected SKILL.md** (scope expanded from the originally-named 4): `manage-problem`, `capture-problem`, `capture-rfc`, `create-adr`, `capture-adr`, `create-risk`.
- [x] Apply the `10#` fix consistently across all six skills.
- [x] Add regression bats fixture: synthetic `099-foo.open.md` + assert next-ID computation returns `100` cleanly without bash error. Added to `capture-adr.bats` (test 6) and `capture-problem.bats` (test 21); both pass.
- [ ] Optionally: shared helper `lib/next-id.sh` with the canonical formula, sourced by all six skills. **Deferred** — DRY benefit is small versus the risk of introducing a sourcing-order regression across the 6 currently-independent skills. Re-evaluate if a 7th ticket-creator surface is added.

## Fix Strategy

Phase 1 (completed 2026-05-11): applied the `10#` prefix across all 6 SKILL.md (verified by re-grep showing zero `\$\(\(\s*\$\(echo` matches without `10#`). Bats regression fixtures added to `packages/itil/skills/capture-problem/test/capture-problem.bats` and `packages/architect/skills/capture-adr/test/capture-adr.bats`. Single commit per ADR-014 covers all 6 fixes + regression tests.

Sanity check confirming the unfixed formula fires the documented error:
```
$ bash -c 'local_max=099; $(( $(echo -e "${local_max}\n0" | sort -n | tail -1) + 1 ))'
bash: line 1: 099: value too great for base (error token is "099")
$ bash -c 'local_max=099; echo $(( 10#$(echo -e "${local_max}\n0" | sort -n | tail -1) + 1 ))'
100
```

## Dependencies

- **Blocks**: (none — latent bug; nothing blocked today)
- **Blocked by**: (none)
- **Composes with**: P056 (next-ID formula `--name-only` correctness — this is the same formula's adjacent failure mode), ADR-019 (orchestrator preflight that fetches origin/<base> for the formula's input)

## Related

- P056 (`docs/problems/056-...closed.md`) — sibling on the same formula (`--name-only` for ls-tree).
- ADR-019 (`docs/decisions/019-afk-orchestrator-preflight.proposed.md`) — preflight contract that ensures origin_max is current.
- iter 3 P156 retro — `docs/retros/2026-05-03-p156-iter.md`.

## Change Log

- **2026-05-04** — Opened by orchestrator's main turn at end of `/wr-itil:work-problems` AFK loop iter 7 per user direction "capture all four now". Sibling finding from iter 3 P156 commit. Skeleton ticket; one-line fix scope plus bats fixture.
- **2026-05-11** — Fix applied by `/wr-itil:work-problems` AFK iter. Scope expanded from 4 → 6 SKILL.md after grep verification (added `capture-rfc` and `create-risk` to the originally-named 4). All 6 SKILL.md formulas now use `10#` base-10 prefix. Two regression bats tests added (`capture-adr` + `capture-problem`, exercising the `099 → 100` boundary). All 28 bats tests pass. Manual sanity check confirms unfixed formula fires `bash: 099: value too great for base` and fixed formula returns `100`. Architect + JTBD reviews PASS. Status: Open → Verifying (awaiting field verification on next plugin release per ADR-014).
- **2026-06-21** — Verifying → Known Error per user direction during inbound-discovery routing of #273. Phase 2 scope-expansion: external user reported `bash: 008: value too great for base` from `scripts/extract-risks-from-reports.sh:217` — `NEXT_ID=$(( ${LOCAL_MAX:-0} + 1 ))`. Same root cause class as Phase 1 (bash arithmetic + leading-zero-as-octal interpretation), but Phase 1's `\$\(\(\s*\$\(echo` grep pattern missed this simpler shape (no echo pipe). Phase 1's "all 6 SKILL.md" scope was the same survey-too-narrow class that Phase 1 itself scope-expanded once (4 → 6 SKILL.md); Phase 2 extends to all script-surface formulas. Reproduce: have `docs/risks/R008-*.active.md` present, run `/wr-risk-scorer:bootstrap-catalog` re-run, observe `LOCAL_MAX=008` trips the bash octal evaluator. Origin field set to `inbound-reported (#273)`. Reported field updated to dual-date. Phase 2 Investigation Tasks added below.

- **2026-06-22** — Phase 2 fix applied by `/wr-itil:work-problems` AFK iter via `/wr-itil:manage-problem`. Repo-wide survey (broadened beyond Phase 1's `\$\(\(\s*\$\(echo` pattern to all bash arithmetic over zero-padded ID strings) found **exactly one** remaining vulnerable surface: `extract-risks-from-reports.sh:217`. Applied `10#` base-10 prefix (`NEXT_ID=$(( 10#${LOCAL_MAX:-0} + 1 ))`). Added regression bats (test 21, `008 → 009` boundary) — RED→GREEN verified; all 21 `extract-risks-from-reports.bats` tests pass. Shared-helper re-evaluation: kept deferred (heterogeneous surfaces; architect endorsed, no new ADR). I13 propose-fix RFC-trace gate auto-created RFC-027 (problem-traced). Architect + JTBD reviews PASS. Status stays Known Error — the K→Verifying transition fires on next plugin release per ADR-022, not in this iter.

### Phase 2 Investigation Tasks (added 2026-06-21)

- [ ] Re-rate Phase 2 Effort and Priority at next /wr-itil:review-problems (currently inheriting Phase 1's 16 High; Phase 2 may revise).
- [x] **Broaden the survey grep pattern** from `\$\(\(\s*\$\(echo` to ALL bash arithmetic over zero-padded ID strings. Surveyed candidate patterns:
  - `\$\(\(\s*\$\{[A-Z_]+:?-?0?\}\s*\+` — captures `$(( ${LOCAL_MAX:-0} + 1 ))` (the #273 witness shape).
  - `\$\(\(\s*\$\{[A-Z_]+\}\s*[+\-*/]` — captures any bare-variable arithmetic.
  - Cross-referenced every `grep -oE '^?[0-9]+'` zero-padded-ID extraction against its downstream `$((` usage.
- [x] **Survey scope expansion**: grepped all `packages/**/scripts/*.sh`, `packages/**/lib/*.sh`, `packages/**/hooks/**/*.sh`, repo-root `scripts/*.sh`, and `bin/`. **Result: exactly one remaining vulnerable surface** — `packages/risk-scorer/scripts/extract-risks-from-reports.sh:217` (the #273 witness). All other next-ID arithmetic surfaces (`drain-register-queue.sh:80`, `enumerate-postrelease-kv-candidates.sh:90`, `derive-release-vehicle.sh:103`) already carry `10#`; every other zero-padded-ID extraction (`update-problem-references-section.sh`, `generate-decisions-compendium.sh`, `is-decision-unconfirmed.sh`, `is-job-or-persona-unconfirmed.sh`) feeds string/glob contexts only, never `$(( ... ))`. The remaining `$((...))` matches across the repo are all counter increments (`count + 1`) that start at 0 — not vulnerable.
- [x] **Apply `10#` fix** to `extract-risks-from-reports.sh:217`: `NEXT_ID=$(( 10#${LOCAL_MAX:-0} + 1 ))`. Line 334 (`NEXT_ID=$((NEXT_ID + 1))`) needs no fix — by that point `NEXT_ID` is a clean decimal integer (no leading-zero re-entry).
- [x] **Regression bats** — added `008 → 009` boundary test to `packages/risk-scorer/scripts/test/extract-risks-from-reports.bats` (test 21): synthetic `R008-*.active.md` fixture + assert `extract-risks-from-reports.sh` allocates `R009` cleanly with no `value too great for base` error. Genuine RED→GREEN guard confirmed (fails on unfixed script, passes on fixed). All 21 tests pass.
- [x] **Optional shared helper `lib/next-id.sh`** — re-evaluated at Phase 2 close: **kept deferred** (same as Phase 1). The next-ID surfaces are heterogeneous (different ID prefixes R/P/ADR; filesystem-only-bootstrap vs ADR-019 dual-source) and each already handles `10#` inline; DRY benefit remains small versus sourcing-order risk across independent call sites. The Phase 2 survey strengthens the deferral case (heterogeneity confirmed, not the homogeneous batch Phase 1 assumed). Architect endorsed — no new ADR required (local/reversible choice). Re-trigger if a future surface forces a 4th+ consumer with genuinely shared semantics.

### Phase 2 Fix Strategy (deferred)

Likely shape: same `10#` prefix applied to each identified script-surface formula. Single commit per ADR-014. Behavioural bats per ADR-052. The shared-helper deferral may be revisited (Phase 1 deferred it at 6 surfaces; Phase 2 may push the count to 8-10 surfaces and tip the balance).

## Reported Upstream

- **#273** (https://github.com/windyroad/agent-plugins/issues/273) — filed 2026-06-21T10:38:33Z by external user. Reports two defects in `scripts/extract-risks-from-reports.sh`:
  1. **Octal eval bug at line 217** (`LOCAL_MAX` keeps zero-padded id; `$(( 008 + 1 ))` fails) — folded into THIS ticket (P164 Phase 2). Suggested fix matches the canonical Phase 1 shape: `$(( 10#${LOCAL_MAX:-0} + 1 ))`.
  2. **Hardcoded suite name in adopter README** (heredoc line 350) — captured as separate ticket P374 (different class: published-artefacts-reference-repo-internal-text; not octal-eval).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-027 | proposed | Apply `10#` base-10 prefix to script-surface next-ID formula (P164 Phase 2 octal-eval fix) |
