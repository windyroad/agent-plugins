---
"@windyroad/retrospective": minor
---

P097 Phase 1 — SKILL.md runtime budget policy advisory detector.

Adds `check-skill-md-budgets.sh` at
`packages/retrospective/scripts/check-skill-md-budgets.sh` — a read-only
advisory script that walks `<root>/packages/*/skills/*/SKILL.md` and
`<root>/.claude/skills/*/SKILL.md`, measures byte size, and reports each
SKILL.md exceeding the WARN threshold (default 8192 bytes) or the
MUST_SPLIT threshold (default 16384 bytes) in the OVER / MUST_SPLIT
output vocabulary inherited verbatim from `check-briefing-budgets.sh`
(P099 / P145 / ADR-040).

REFERENCE.md sibling files are excluded from the scan per ADR-054 — they
are intentionally lazy-loaded via explicit SKILL.md pointers and not
subject to the runtime budget.

Bin shim ships at
`packages/retrospective/bin/wr-retrospective-check-skill-md-budgets`
per ADR-049 grammar.

Behavioural bats fixture ships at
`packages/retrospective/scripts/test/check-skill-md-budgets.bats` —
21 tests, all behavioural per ADR-052 (asserts script output on
temp-fixture skill trees, no greps of script source).

Companion ADR in `docs/decisions/`:

- ADR-054 (proposed) — SKILL.md runtime budget policy. Codifies the
  `[runtime]` / `[reference]` / `[deprecated]` content classification
  taxonomy, the sibling REFERENCE.md lazy-load pattern, the per-skill
  pointer-overhead ceiling (≤ 20 pointers / ≤ 1.6 KB), the byte
  budgets, and the P132 / ADR-044 silent-framework carve-out for
  REFERENCE.md reads.

Thresholds are env-var overridable (`SKILL_MD_WARN_BYTES`,
`SKILL_MD_MUST_SPLIT_BYTES`).

Phase 1 advisory only. Phase 2-3 (retroactive `[reference]` extraction
across the top-10 SKILL.md offenders) is `Blocked by: P081` Layer B
maturity per the 2026-04-27 P097 Phase 1 audit finding (80 of 116
manage-problem contract assertions structural-grep SKILL.md prose;
behavioural retrofit needs P081 Layer B harness primitives first).
