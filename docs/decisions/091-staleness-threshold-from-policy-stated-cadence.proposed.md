---
status: "proposed"
date: 2026-07-05
human-oversight: confirmed
oversight-date: 2026-07-04
oversight-confirmed-date: "2026-07-04 — interactive decision drain: user ratified P408 fix option (a) — derive the RISK-POLICY staleness threshold from the policy's stated review cadence (weekly=7/monthly=30/quarterly=90/annually=365, fallback=14 when the cadence line is absent/unrecognised). Recorded in P408 § Ratified Direction."
oversight-note: "born-confirmed on a real substance-confirm event (the 2026-07-04 drain), not the P340/P348 hollow-marker path. The fortnightly/biweekly=14 entries and the yearly synonym are behaviour-identical additive elaborations beyond the drain-ratified list (14 equals the ratified fallback; yearly aliases annually) — noted here so the confirm provenance stays honest."
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, downstream adopters]
reassessment-date: 2026-10-05
---

# Commit-gate staleness threshold derives from RISK-POLICY.md's stated review cadence

## Context and Problem Statement

`packages/risk-scorer/hooks/risk-score-commit-gate.sh` blocks commits when `RISK-POLICY.md` was last reviewed more than **14 days** ago. The `14` is hardcoded; the gate never reads the policy's own stated review cadence (the `> Reviewed <cadence> ...` line the policy carries near its header). P408 witnessed the consequence on 2026-07-02: a policy stating a quarterly cadence, reviewed 16 days earlier — current by its own terms — was flagged stale and every commit blocked, a ~6× disagreement between the gate and the doc. Any adopter whose stated cadence exceeds 14 days hits this routinely.

ADR-086 (superseding ADR-065, which remains lineage only) pinned the derive-from-policy principle for the pipeline *appetite/score* threshold: the policy document, not a plugin-hardcoded constant, is the source of truth the gate enforces. The *staleness* threshold is the remaining hardcoded constant that ignores a machine-readable field already present in the doc. Applying the same principle here introduces a NEW machine-read contract on `RISK-POLICY.md` — the prose cadence line becomes load-bearing parsed input with an adopter-inherited vocabulary — so ADR-073's confirmation clause required this sibling ADR before implementation.

## Decision Drivers

- **Single source of truth** — the policy doc and the gate must not be able to drift; the doc's stated cadence IS the threshold (same driver as ADR-086's appetite derivation).
- **Adopter portability** — the gate parses the adopter's own `RISK-POLICY.md`; no repo-specific constants (JTBD-001, developer persona: guardrails without false-positive friction).
- **Enforcement preserved** — a policy that states no cadence keeps the existing 14-day behaviour; the fix removes false positives without weakening the gate.
- **Parse safety** — the cadence line (`> Reviewed monthly ...`) and the review-date line (`> Last reviewed: <date>`) differ only in capitalisation and prefix; the machine-read contract must never bind the wrong line.

## Considered Options

1. **Derive the threshold from the policy's stated cadence; fallback 14 when absent/unrecognised (chosen; ratified in the 2026-07-04 drain as P408 fix option (a)).**
2. **Hardcode the gate to ~30 days (monthly)** — quick; keeps the doc↔gate coupling implicit; can drift again (rejected in the drain).
3. **Keep the 14-day gate; state a two-week cadence in the doc** — inverts the source of truth: the plugin constant would dictate the adopter's policy prose (rejected in the drain).

## Decision Outcome

Chosen option: **derive from the stated cadence**, because it makes `RISK-POLICY.md` the single source of truth for its own staleness — the doc and the gate can never disagree — and it is the option the user ratified in the 2026-07-04 interactive decision drain.

**The machine-read contract** (binding on `RISK-POLICY.md` and on the gate):

- The policy states its cadence on a line matching the **case-sensitive, line-anchored** regex `(?m)^>?\s*Reviewed\s+([A-Za-z]+)` — a capital-`R` `Reviewed` followed by the cadence word (e.g. `> Reviewed monthly and after any significant change ...`). The regex never binds the lowercase `> Last reviewed: <date>` review-date line; that collision is the load-bearing regression case and carries a behavioural test.
- Cadence vocabulary → threshold days: `weekly` = 7, `fortnightly` / `biweekly` = 14, `monthly` = 30, `quarterly` = 90, `annually` / `yearly` = 365. Matching is exact on the captured word, case-sensitive lowercase.
- **Fallback**: when the cadence line is absent or the captured word is unrecognised, the threshold is **14 days** (the pre-existing behaviour, unchanged for policies that state no cadence).
- The gate compares `(today − Last-reviewed date) > threshold` and its deny message names the derived threshold and the cadence word it came from (e.g. "over 30 days ago per the policy's stated monthly cadence"), so the reason always matches the doc.

## Consequences

### Good

- Eliminates the false-positive stale-policy commit block for every adopter whose stated cadence exceeds 14 days (P408's class), with zero behaviour change for policies that state no cadence.
- The doc↔gate contract is self-describing: editing the policy's cadence line retunes the gate with no plugin release.
- Sibling consistency with ADR-086 — both gate thresholds now derive from the policy.

### Neutral

- The cadence line joins the `Last reviewed:` date line as machine-read input; `/wr-risk-scorer:update-policy` already writes both.

### Bad

- A typo in the cadence word silently falls back to 14 days (strict vocabulary, no fuzzy match). The deny message naming the derived threshold is the detection surface.

## Confirmation

Behavioural bats in `packages/risk-scorer/hooks/test/` exercise the gate end-to-end with fixture `RISK-POLICY.md` variants (ADR-052):

1. Stated `monthly` cadence, reviewed 16 days ago → commit ALLOWED (the P408 witnessed case).
2. No cadence line, reviewed 16 days ago → commit DENIED (14-day fallback preserved).
3. Both `> Last reviewed: <date>` and `> Reviewed <cadence>` lines present → the cadence parses from the capital-`R` line, never the date line (regression guard on the regex).
4. Stated cadence elapsed (e.g. monthly, reviewed 31+ days ago) → commit DENIED, deny message names the derived threshold and cadence word.

## More Information

- P408 (`docs/problems/`) — driving problem; § Ratified Direction records the 2026-07-04 drain confirmation.
- ADR-086 — sibling: appetite threshold derived from the policy (in force). ADR-065 — lineage only (superseded by ADR-086).
- ADR-073 — the fix-approach-needs-a-ratified-ADR clause this ADR discharges; RFC-043 traces the fix.
