# Ask Hygiene — 2026-05-06 (I001 mitigation session)

Per ADR-044 (Decision-Delegation Contract — framework-resolution boundary). Records every `AskUserQuestion` call from the session, classified per the 6-class taxonomy. **Lazy count is the regression metric** (target 0).

## Calls

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Severity / Start time / Scope / Title (4 questions in one call) — I001 declaration | **lazy** (3 of 4) + direction (1 of 4) | Framework: title was derivable from user prose (kebab-case the description), severity ratable from RISK-POLICY.md matrix + observable evidence (held-cluster age, scorer state), start time pullable from `git log --diff-filter=A --follow -- docs/changesets-holding/`. Only Scope was genuine direction-setting (downstream-adopter-risk inclusion was user-judgment). User correction: "why are you asking me this???" — strong-signal P078. Captured in feedback memory `feedback_dont_subcontract_declaration_fields.md`. |

## Counts

**Lazy count: 3** (scope-aware: 3 of 4 sub-questions were lazy; only 1 was direction)
**Direction count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## R6 Reassessment Trigger Status

Cross-session trail:

```
RETRO 2026-05-04 lazy=0 direction=0 override=0 silent=2 taste=0 correction=1
RETRO 2026-05-05 lazy=0 direction=0 override=0 silent=0 taste=0 correction=0
RETRO 2026-05-06 lazy=0 direction=1 override=0 silent=0 taste=0 correction=0  ← earlier today (iter 2 subprocess retro)
RETRO 2026-05-06-i001-mitigation lazy=3 direction=1 override=0 silent=0 taste=0 correction=0  ← THIS retro
```

Lazy count was 0 across all prior retros in the trail. This retro is the first lazy ≥ 2 event. R6 numeric gate (lazy ≥ 2 across 3 consecutive retros) does NOT fire yet — needs 2 more consecutive retros at lazy ≥ 2 for the deviation-candidate auto-queue.

The single-cluster lazy spike here is captured + memory'd; behaviour-correction is the in-loop discipline going forward, not an ADR-044 amendment yet.
